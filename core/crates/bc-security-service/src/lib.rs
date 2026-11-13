//! Estado de seguridad en solo lectura: cortafuegos (nftables vía systemd) y verificación de firmas de pacman.

use bc_common::{BcError, Result};
use std::process::Command;

/// Estado de una unidad systemd según la salida de `systemctl is-active`.
pub fn parse_is_active(salida: &str) -> (bool, String) {
    let estado = salida.trim();
    if estado.is_empty() {
        return (false, "desconocido".into());
    }
    (estado == "active", estado.to_string())
}

/// Evalúa el `SigLevel` de la sección `[options]` de `pacman.conf`.
/// Devuelve (nivel, ¿exige verificar firmas de paquetes?). Sin `SigLevel` explícito, pacman usa
/// «Required DatabaseOptional», que sí verifica.
pub fn parse_siglevel(conf: &str) -> (String, bool) {
    let mut en_options = false;
    for linea in conf.lines() {
        let l = linea.split('#').next().unwrap_or("").trim();
        if l.starts_with('[') && l.ends_with(']') {
            en_options = l == "[options]";
        } else if en_options {
            if let Some((k, v)) = l.split_once('=') {
                if k.trim() == "SigLevel" {
                    let v = v.trim().to_string();
                    let verifica = !v.split_whitespace().any(|t| {
                        t == "Never"
                            || t == "PackageNever"
                            || t == "PackageOptional"
                            || t == "Optional"
                    }) && v
                        .split_whitespace()
                        .any(|t| t == "Required" || t == "PackageRequired");
                    return (v, verifica);
                }
            }
        }
    }
    ("Required DatabaseOptional".into(), true)
}

pub fn cortafuegos() -> Result<(bool, String)> {
    let out = Command::new("systemctl")
        .args(["is-active", "nftables"])
        .output()
        .map_err(|e| BcError::Orden {
            orden: "systemctl is-active nftables".into(),
            detalle: e.to_string(),
        })?;
    // is-active devuelve código != 0 cuando no está activo; la salida sigue siendo válida.
    Ok(parse_is_active(&String::from_utf8_lossy(&out.stdout)))
}

pub fn firmas_pacman() -> Result<(String, bool)> {
    let ruta = "/etc/pacman.conf";
    let t = std::fs::read_to_string(ruta).map_err(|e| BcError::io(ruta, e))?;
    Ok(parse_siglevel(&t))
}

pub struct Security;

#[zbus::interface(name = "org.bcos.Security1")]
impl Security {
    /// (activo, estado de systemd) del servicio nftables.
    fn cortafuegos(&self) -> zbus::fdo::Result<(bool, String)> {
        Ok(cortafuegos()?)
    }

    /// (SigLevel configurado, ¿verifica firmas de paquetes?)
    fn firmas_pacman(&self) -> zbus::fdo::Result<(String, bool)> {
        Ok(firmas_pacman()?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn systemctl() {
        assert_eq!(parse_is_active("active\n"), (true, "active".into()));
        assert_eq!(parse_is_active("inactive\n"), (false, "inactive".into()));
        assert_eq!(parse_is_active("unknown"), (false, "unknown".into()));
        assert_eq!(parse_is_active(""), (false, "desconocido".into()));
    }

    #[test]
    fn siglevel_requerido() {
        let c = "[options]\nHoldPkg = pacman\nSigLevel = Required DatabaseOptional\n[core]\nSigLevel = Never\n";
        assert_eq!(
            parse_siglevel(c),
            ("Required DatabaseOptional".into(), true)
        );
    }

    #[test]
    fn siglevel_inseguro_y_por_defecto() {
        assert!(!parse_siglevel("[options]\nSigLevel = Never\n").1);
        assert!(!parse_siglevel("[options]\nSigLevel = Optional TrustAll\n").1);
        assert!(!parse_siglevel("[options]\nSigLevel = PackageOptional\n").1);
        // Comentarios y secciones de repositorio no cuentan.
        assert_eq!(
            parse_siglevel("[options]\n#SigLevel = Never\n[core]\nSigLevel = Never\n"),
            ("Required DatabaseOptional".into(), true)
        );
    }
}
