//! Ajustes de usuario persistidos en `$XDG_CONFIG_HOME/bcos/ajustes.toml`.

use bc_common::{BcError, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use zbus::object_server::SignalEmitter;

pub const IDIOMAS: &[&str] = &["es_ES", "en"];
pub const TEMAS: &[&str] = &["claro", "oscuro", "sistema"];
pub const CLAVES: &[&str] = &["idioma", "tema", "movimiento_reducido"];

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct Ajustes {
    pub idioma: String,
    pub tema: String,
    pub movimiento_reducido: bool,
}

impl Default for Ajustes {
    fn default() -> Self {
        Self {
            idioma: "es_ES".into(),
            tema: "sistema".into(),
            movimiento_reducido: false,
        }
    }
}

fn admitidos(l: &[&str]) -> String {
    l.join(", ")
}

impl Ajustes {
    pub fn get(&self, clave: &str) -> Result<String> {
        match clave {
            "idioma" => Ok(self.idioma.clone()),
            "tema" => Ok(self.tema.clone()),
            "movimiento_reducido" => Ok(self.movimiento_reducido.to_string()),
            _ => Err(BcError::ClaveDesconocida(clave.into())),
        }
    }

    pub fn set(&mut self, clave: &str, valor: &str) -> Result<()> {
        let invalido = |lista: &str| BcError::ValorInvalido {
            clave: clave.into(),
            valor: valor.into(),
            admitidos: lista.into(),
        };
        match clave {
            "idioma" if IDIOMAS.contains(&valor) => self.idioma = valor.into(),
            "idioma" => return Err(invalido(&admitidos(IDIOMAS))),
            "tema" if TEMAS.contains(&valor) => self.tema = valor.into(),
            "tema" => return Err(invalido(&admitidos(TEMAS))),
            "movimiento_reducido" => {
                self.movimiento_reducido = valor.parse().map_err(|_| invalido("true, false"))?
            }
            _ => return Err(BcError::ClaveDesconocida(clave.into())),
        }
        Ok(())
    }

    pub fn todos(&self) -> HashMap<String, String> {
        CLAVES
            .iter()
            .map(|c| (c.to_string(), self.get(c).expect("clave conocida")))
            .collect()
    }
}

/// Ruta del archivo de ajustes según `XDG_CONFIG_HOME` o `$HOME/.config`.
pub fn ruta_config(xdg: Option<&str>, home: Option<&str>) -> Option<PathBuf> {
    let base = match (
        xdg.filter(|v| !v.is_empty()),
        home.filter(|v| !v.is_empty()),
    ) {
        (Some(x), _) => PathBuf::from(x),
        (None, Some(h)) => Path::new(h).join(".config"),
        _ => return None,
    };
    Some(base.join("bcos").join("ajustes.toml"))
}

pub fn cargar(ruta: &Path) -> Result<Ajustes> {
    match std::fs::read_to_string(ruta) {
        Ok(t) => toml::from_str(&t).map_err(|e| BcError::Formato {
            ruta: ruta.into(),
            detalle: e.to_string(),
        }),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Ajustes::default()),
        Err(e) => Err(BcError::io(ruta, e)),
    }
}

/// Guardado atómico: escribe a un temporal y renombra.
pub fn guardar(ruta: &Path, a: &Ajustes) -> Result<()> {
    let dir = ruta.parent().unwrap_or(Path::new("."));
    std::fs::create_dir_all(dir).map_err(|e| BcError::io(dir, e))?;
    let tmp = ruta.with_extension("toml.tmp");
    let texto = toml::to_string_pretty(a).map_err(|e| BcError::Formato {
        ruta: ruta.into(),
        detalle: e.to_string(),
    })?;
    std::fs::write(&tmp, texto).map_err(|e| BcError::io(&tmp, e))?;
    std::fs::rename(&tmp, ruta).map_err(|e| BcError::io(ruta, e))
}

pub struct Settings {
    ruta: PathBuf,
    ajustes: Mutex<Ajustes>,
}

impl Settings {
    pub fn con_ruta(ruta: PathBuf) -> Result<Self> {
        let ajustes = cargar(&ruta)?;
        Ok(Self {
            ruta,
            ajustes: Mutex::new(ajustes),
        })
    }

    pub fn abrir() -> Result<Self> {
        let ruta = ruta_config(
            std::env::var("XDG_CONFIG_HOME").ok().as_deref(),
            std::env::var("HOME").ok().as_deref(),
        )
        .ok_or_else(|| BcError::Orden {
            orden: "localizar la carpeta de configuración".into(),
            detalle: "no están definidas XDG_CONFIG_HOME ni HOME".into(),
        })?;
        Self::con_ruta(ruta)
    }
}

#[zbus::interface(name = "org.bcos.Settings1")]
impl Settings {
    fn get(&self, clave: &str) -> zbus::fdo::Result<String> {
        Ok(self.ajustes.lock().unwrap().get(clave)?)
    }

    async fn set(
        &self,
        clave: &str,
        valor: &str,
        #[zbus(signal_emitter)] emisor: SignalEmitter<'_>,
    ) -> zbus::fdo::Result<()> {
        {
            let mut a = self.ajustes.lock().unwrap();
            let mut nuevo = a.clone();
            nuevo.set(clave, valor)?;
            if nuevo != *a {
                guardar(&self.ruta, &nuevo)?;
                *a = nuevo;
            }
        }
        tracing::info!(clave, valor, "ajuste cambiado");
        Self::cambiado(&emisor, clave, valor).await?;
        Ok(())
    }

    fn get_all(&self) -> HashMap<String, String> {
        self.ajustes.lock().unwrap().todos()
    }

    #[zbus(signal)]
    async fn cambiado(emisor: &SignalEmitter<'_>, clave: &str, valor: &str) -> zbus::Result<()>;
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tmp(n: &str) -> PathBuf {
        let d = std::env::temp_dir().join(format!("bc-set-{}-{n}", std::process::id()));
        let _ = std::fs::remove_dir_all(&d);
        d
    }

    #[test]
    fn valores_por_defecto_en_castellano() {
        let a = Ajustes::default();
        assert_eq!(a.get("idioma").unwrap(), "es_ES");
        assert_eq!(a.get("tema").unwrap(), "sistema");
        assert_eq!(a.get("movimiento_reducido").unwrap(), "false");
    }

    #[test]
    fn validacion() {
        let mut a = Ajustes::default();
        a.set("tema", "oscuro").unwrap();
        a.set("movimiento_reducido", "true").unwrap();
        assert!(a.movimiento_reducido);
        let e = a.set("tema", "rosa").unwrap_err().to_string();
        assert!(e.contains("no es válido") && e.contains("claro, oscuro, sistema"));
        assert!(a.set("idioma", "fr").is_err());
        assert!(a.set("movimiento_reducido", "quizá").is_err());
        assert_eq!(
            a.set("color", "x").unwrap_err().to_string(),
            "La clave de ajuste «color» no existe"
        );
        assert_eq!(a.todos().len(), 3);
    }

    #[test]
    fn rutas_xdg() {
        assert_eq!(
            ruta_config(Some("/cfg"), Some("/home/bc")),
            Some(PathBuf::from("/cfg/bcos/ajustes.toml"))
        );
        assert_eq!(
            ruta_config(Some(""), Some("/home/bc")),
            Some(PathBuf::from("/home/bc/.config/bcos/ajustes.toml"))
        );
        assert_eq!(ruta_config(None, None), None);
    }

    #[test]
    fn persistencia_toml() {
        let d = tmp("persist");
        let ruta = d.join("bcos").join("ajustes.toml");
        assert_eq!(cargar(&ruta).unwrap(), Ajustes::default());
        let mut a = Ajustes::default();
        a.set("tema", "claro").unwrap();
        a.set("idioma", "en").unwrap();
        guardar(&ruta, &a).unwrap();
        assert_eq!(cargar(&ruta).unwrap(), a);
        let texto = std::fs::read_to_string(&ruta).unwrap();
        assert!(texto.contains("tema = \"claro\""));
        // Claves ausentes toman valores por defecto.
        std::fs::write(&ruta, "tema = \"oscuro\"\n").unwrap();
        let b = cargar(&ruta).unwrap();
        assert_eq!((b.tema.as_str(), b.idioma.as_str()), ("oscuro", "es_ES"));
        // Archivo corrupto: error en castellano.
        std::fs::write(&ruta, "esto no es toml = = =").unwrap();
        assert!(cargar(&ruta)
            .unwrap_err()
            .to_string()
            .contains("no tiene un formato válido"));
        let _ = std::fs::remove_dir_all(&d);
    }
}
