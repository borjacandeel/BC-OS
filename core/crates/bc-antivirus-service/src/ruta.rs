//! Validación de rutas SIN E/S. Solo se admiten rutas dentro de `$HOME` o estrictamente
//! dentro de `/tmp` (por ejemplo `/tmp/descarga`, nunca `/tmp` a secas).
//!
//! Se valida en dos pasos: primero la forma léxica (`normalizar`), y después, con E/S
//! hecha por el servicio, la ruta canónica (que ya resuelve los enlaces simbólicos)
//! con `esta_permitida`.

use std::path::{Component, Path, PathBuf};

/// Raíz temporal admitida además de `$HOME`.
pub const TMP: &str = "/tmp";

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ErrorRuta {
    Vacia,
    ConNul,
    NoAbsoluta,
    /// El `..` intenta salir de la raíz del sistema de archivos.
    EscapaDeRaiz,
    /// `$HOME` no es utilizable (vacío, relativo o `/`).
    HomeInvalido,
    FueraDePermitidos,
}

impl std::fmt::Display for ErrorRuta {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(match self {
            Self::Vacia => "La ruta está vacía",
            Self::ConNul => "La ruta contiene caracteres no válidos",
            Self::NoAbsoluta => "La ruta debe ser absoluta (empezar por «/» o por «~/»)",
            Self::EscapaDeRaiz => "La ruta intenta salir de la raíz del sistema de archivos",
            Self::HomeInvalido => "No se pudo determinar la carpeta personal del usuario",
            Self::FueraDePermitidos => {
                "Solo se pueden analizar rutas dentro de tu carpeta personal o de /tmp"
            }
        })
    }
}

impl std::error::Error for ErrorRuta {}

/// Resuelve `.`, `..` y `//` de forma puramente léxica. Admite `~` y `~/…` (carpeta personal).
/// No toca el disco, así que NO resuelve enlaces simbólicos: eso lo hace el servicio después.
pub fn normalizar(entrada: &str, home: &Path) -> Result<PathBuf, ErrorRuta> {
    if entrada.trim().is_empty() {
        return Err(ErrorRuta::Vacia);
    }
    if entrada.contains('\0') {
        return Err(ErrorRuta::ConNul);
    }
    let expandida: PathBuf = if entrada == "~" {
        home.to_path_buf()
    } else if let Some(resto) = entrada.strip_prefix("~/") {
        home.join(resto)
    } else {
        PathBuf::from(entrada)
    };
    if !expandida.is_absolute() {
        return Err(ErrorRuta::NoAbsoluta);
    }
    let mut salida = PathBuf::from("/");
    for c in expandida.components() {
        match c {
            Component::RootDir | Component::CurDir | Component::Prefix(_) => {}
            Component::ParentDir => {
                if !salida.pop() {
                    return Err(ErrorRuta::EscapaDeRaiz);
                }
            }
            Component::Normal(n) => salida.push(n),
        }
    }
    Ok(salida)
}

/// ¿Es `home` una carpeta personal utilizable? Absoluta y distinta de `/`.
pub fn home_valido(home: &Path) -> bool {
    home.is_absolute() && home.parent().is_some()
}

/// `ruta` ya normalizada (o canónica) está en `$HOME` (o es `$HOME`) o estrictamente bajo `tmp`.
/// Compara por componentes: `/home/bcx` NO está bajo `/home/bc`.
pub fn esta_permitida(ruta: &Path, home: &Path, tmp: &Path) -> bool {
    if !ruta.is_absolute() {
        return false;
    }
    if ruta.components().any(|c| matches!(c, Component::ParentDir)) {
        return false;
    }
    let en_home = home_valido(home) && ruta.starts_with(home);
    let en_tmp = ruta.starts_with(tmp) && ruta != tmp;
    en_home || en_tmp
}

/// Primer paso completo y sin E/S: normaliza y comprueba lo permitido.
pub fn validar_lexica(entrada: &str, home: &Path) -> Result<PathBuf, ErrorRuta> {
    if !home_valido(home) {
        // Aun así se permite /tmp, pero sin $HOME fiable se rechaza todo lo demás.
        let n = normalizar(entrada, Path::new("/nonexistent-home"))?;
        return if esta_permitida(&n, home, Path::new(TMP)) {
            Ok(n)
        } else {
            Err(ErrorRuta::HomeInvalido)
        };
    }
    let n = normalizar(entrada, home)?;
    if esta_permitida(&n, home, Path::new(TMP)) {
        Ok(n)
    } else {
        Err(ErrorRuta::FueraDePermitidos)
    }
}

/// Segundo paso (tras `canonicalize`, que resuelve enlaces simbólicos): la ruta real también
/// debe estar permitida. `home_canon` y `tmp_canon` son las versiones canónicas de las raíces.
pub fn validar_canonica(
    canonica: &Path,
    home_canon: &Path,
    tmp_canon: &Path,
) -> Result<(), ErrorRuta> {
    if esta_permitida(canonica, home_canon, tmp_canon) {
        Ok(())
    } else {
        Err(ErrorRuta::FueraDePermitidos)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const HOME: &str = "/home/bc";

    fn h() -> &'static Path {
        Path::new(HOME)
    }

    #[test]
    fn vacia_y_espacios() {
        assert_eq!(validar_lexica("", h()), Err(ErrorRuta::Vacia));
        assert_eq!(validar_lexica("   ", h()), Err(ErrorRuta::Vacia));
    }

    #[test]
    fn nul_rechazado() {
        assert_eq!(validar_lexica("/home/bc/a\0b", h()), Err(ErrorRuta::ConNul));
    }

    #[test]
    fn relativa_rechazada() {
        assert_eq!(validar_lexica("Descargas", h()), Err(ErrorRuta::NoAbsoluta));
        assert_eq!(validar_lexica("./a", h()), Err(ErrorRuta::NoAbsoluta));
        assert_eq!(validar_lexica("../a", h()), Err(ErrorRuta::NoAbsoluta));
    }

    #[test]
    fn dentro_de_home() {
        assert_eq!(
            validar_lexica("/home/bc", h()),
            Ok(PathBuf::from("/home/bc"))
        );
        assert_eq!(
            validar_lexica("/home/bc/Descargas", h()),
            Ok(PathBuf::from("/home/bc/Descargas"))
        );
        assert_eq!(
            validar_lexica("/home/bc/Descargas/", h()),
            Ok(PathBuf::from("/home/bc/Descargas"))
        );
        assert_eq!(
            validar_lexica("/home/bc//a///b", h()),
            Ok(PathBuf::from("/home/bc/a/b"))
        );
    }

    #[test]
    fn tilde() {
        assert_eq!(validar_lexica("~", h()), Ok(PathBuf::from("/home/bc")));
        assert_eq!(
            validar_lexica("~/Música", h()),
            Ok(PathBuf::from("/home/bc/Música"))
        );
        // «~otro» no es una expansión: es relativa.
        assert_eq!(validar_lexica("~root", h()), Err(ErrorRuta::NoAbsoluta));
        assert_eq!(
            validar_lexica("~/../root", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
    }

    #[test]
    fn punto_y_punto_punto_dentro_de_home() {
        assert_eq!(
            validar_lexica("/home/bc/./a/../b", h()),
            Ok(PathBuf::from("/home/bc/b"))
        );
        assert_eq!(
            validar_lexica("/home/bc/a/b/../../c", h()),
            Ok(PathBuf::from("/home/bc/c"))
        );
    }

    #[test]
    fn punto_punto_que_sale_de_home() {
        for r in [
            "/home/bc/..",
            "/home/bc/../..",
            "/home/bc/../otro",
            "/home/bc/../../etc/shadow",
            "/home/bc/a/../../../etc",
            "~/..",
            "~/../../etc",
        ] {
            assert_eq!(
                validar_lexica(r, h()),
                Err(ErrorRuta::FueraDePermitidos),
                "{r}"
            );
        }
    }

    #[test]
    fn punto_punto_por_encima_de_la_raiz() {
        assert_eq!(validar_lexica("/..", h()), Err(ErrorRuta::EscapaDeRaiz));
        assert_eq!(
            validar_lexica("/home/../../..", h()),
            Err(ErrorRuta::EscapaDeRaiz)
        );
    }

    #[test]
    fn prefijo_de_cadena_no_es_prefijo_de_ruta() {
        assert_eq!(
            validar_lexica("/home/bcx", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/home/bc-otro/a", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmpx/a", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmp2", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
    }

    #[test]
    fn fuera_de_home_rechazado() {
        for r in [
            "/",
            "/etc",
            "/etc/shadow",
            "/home",
            "/root",
            "/usr/bin",
            "/var/tmp/x",
        ] {
            assert_eq!(
                validar_lexica(r, h()),
                Err(ErrorRuta::FueraDePermitidos),
                "{r}"
            );
        }
    }

    #[test]
    fn tmp_solo_estrictamente_dentro() {
        assert_eq!(validar_lexica("/tmp/x", h()), Ok(PathBuf::from("/tmp/x")));
        assert_eq!(
            validar_lexica("/tmp/a/b/", h()),
            Ok(PathBuf::from("/tmp/a/b"))
        );
        assert_eq!(
            validar_lexica("/tmp", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmp/", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmp/..", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmp/../etc/passwd", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_lexica("/tmp/a/../..", h()),
            Err(ErrorRuta::FueraDePermitidos)
        );
    }

    #[test]
    fn home_invalido_solo_permite_tmp() {
        for home in ["", "/", "relativo"] {
            let home = Path::new(home);
            assert_eq!(
                validar_lexica("/etc", home),
                Err(ErrorRuta::HomeInvalido),
                "{home:?}"
            );
            assert_eq!(
                validar_lexica("/home/bc/a", home),
                Err(ErrorRuta::HomeInvalido),
                "{home:?}"
            );
            assert_eq!(
                validar_lexica("/tmp/a", home),
                Ok(PathBuf::from("/tmp/a")),
                "{home:?}"
            );
        }
        assert!(!esta_permitida(
            Path::new("/etc"),
            Path::new("/"),
            Path::new("/tmp")
        ));
    }

    #[test]
    fn esta_permitida_exige_absoluta_y_sin_punto_punto() {
        assert!(!esta_permitida(
            Path::new("home/bc/a"),
            h(),
            Path::new("/tmp")
        ));
        assert!(!esta_permitida(
            Path::new("/home/bc/../etc"),
            h(),
            Path::new("/tmp")
        ));
    }

    #[test]
    fn canonica_enlace_que_apunta_fuera() {
        let home = Path::new("/home/bc");
        let tmp = Path::new("/tmp");
        // Un enlace en $HOME hacia /etc se canonicaliza a /etc/...: rechazado.
        assert_eq!(
            validar_canonica(Path::new("/etc/shadow"), home, tmp),
            Err(ErrorRuta::FueraDePermitidos)
        );
        assert_eq!(
            validar_canonica(Path::new("/"), home, tmp),
            Err(ErrorRuta::FueraDePermitidos)
        );
        // Un enlace en /tmp hacia $HOME es legítimo.
        assert_eq!(
            validar_canonica(Path::new("/home/bc/Docs"), home, tmp),
            Ok(())
        );
        assert_eq!(validar_canonica(Path::new("/tmp/a"), home, tmp), Ok(()));
        assert_eq!(
            validar_canonica(Path::new("/tmp"), home, tmp),
            Err(ErrorRuta::FueraDePermitidos)
        );
    }

    #[test]
    fn canonica_con_home_y_tmp_en_enlaces() {
        // En sistemas donde /home es un enlace a /var/home, las raíces canónicas difieren.
        let home = Path::new("/var/home/bc");
        let tmp = Path::new("/private/tmp");
        assert_eq!(
            validar_canonica(Path::new("/var/home/bc/x"), home, tmp),
            Ok(())
        );
        assert_eq!(
            validar_canonica(Path::new("/private/tmp/x"), home, tmp),
            Ok(())
        );
        assert_eq!(
            validar_canonica(Path::new("/home/bc/x"), home, tmp),
            Err(ErrorRuta::FueraDePermitidos)
        );
    }

    #[test]
    fn mensajes_en_castellano() {
        assert!(ErrorRuta::FueraDePermitidos
            .to_string()
            .contains("carpeta personal"));
        assert_eq!(ErrorRuta::Vacia.to_string(), "La ruta está vacía");
    }
}
