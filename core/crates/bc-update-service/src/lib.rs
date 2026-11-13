//! Consulta de actualizaciones con `pacman -Qu` (solo lectura, sin root, no sincroniza bases).

use bc_common::{BcError, Result};
use std::process::Command;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pendiente {
    pub nombre: String,
    pub actual: String,
    pub nueva: String,
}

/// Parsea la salida de `pacman -Qu`: `nombre versión_actual -> versión_nueva`.
pub fn parse_qu(salida: &str) -> Vec<Pendiente> {
    salida
        .lines()
        .filter_map(|l| {
            let mut it = l.split_whitespace();
            let (n, a, flecha, v) = (it.next()?, it.next()?, it.next()?, it.next()?);
            (flecha == "->").then(|| Pendiente {
                nombre: n.into(),
                actual: a.into(),
                nueva: v.into(),
            })
        })
        .collect()
}

pub fn pendientes() -> Result<Vec<Pendiente>> {
    let orden = "pacman -Qu";
    let out = Command::new("pacman")
        .arg("-Qu")
        .env("LC_ALL", "C")
        .output()
        .map_err(|e| BcError::Orden {
            orden: orden.into(),
            detalle: e.to_string(),
        })?;
    let texto = String::from_utf8_lossy(&out.stdout);
    // pacman -Qu devuelve 1 sin salida cuando no hay actualizaciones.
    if !out.status.success() && !texto.trim().is_empty() {
        return Err(BcError::Orden {
            orden: orden.into(),
            detalle: String::from_utf8_lossy(&out.stderr).trim().to_string(),
        });
    }
    if !out.status.success() && out.status.code() != Some(1) {
        return Err(BcError::Orden {
            orden: orden.into(),
            detalle: format!("terminó con {}", out.status),
        });
    }
    Ok(parse_qu(&texto))
}

pub struct Update;

#[zbus::interface(name = "org.bcos.Update1")]
impl Update {
    /// Lista de (paquete, versión actual, versión nueva) según las bases locales.
    async fn pendientes(&self) -> zbus::fdo::Result<Vec<(String, String, String)>> {
        let lista = tokio::task::spawn_blocking(pendientes)
            .await
            .map_err(|e| zbus::fdo::Error::Failed(format!("Error interno: {e}")))??;
        Ok(lista
            .into_iter()
            .map(|p| (p.nombre, p.actual, p.nueva))
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parsea_salida_de_pacman() {
        let v = parse_qu("linux-aarch64 7.3.3-1 -> 7.3.4-1\nmesa 25.1.0-1 -> 25.1.1-2\n");
        assert_eq!(v.len(), 2);
        assert_eq!(
            v[0],
            Pendiente {
                nombre: "linux-aarch64".into(),
                actual: "7.3.3-1".into(),
                nueva: "7.3.4-1".into()
            }
        );
        assert_eq!(v[1].nueva, "25.1.1-2");
    }

    #[test]
    fn ignora_lineas_ajenas() {
        assert!(parse_qu("").is_empty());
        assert!(parse_qu("aviso: algo raro\nfoo 1 2 3\n").is_empty());
    }
}
