//! Daemon coordinador: informa de la versión de BC Core y de qué servicios están presentes en el bus.

use bc_common::i18n::{tr, Lang};
use zbus::fdo::DBusProxy;
use zbus::names::BusName;

pub const SERVICIOS: &[&str] = &[
    "org.bcos.Settings",
    "org.bcos.Update",
    "org.bcos.Security",
    "org.bcos.Hardware",
    "org.bcos.Performance",
];

pub struct Daemon;

#[zbus::interface(name = "org.bcos.Daemon1")]
impl Daemon {
    #[zbus(property)]
    fn version(&self) -> String {
        env!("CARGO_PKG_VERSION").into()
    }

    /// Lista de (nombre del servicio, estado localizado: activo/inactivo) según el bus.
    async fn servicios(
        &self,
        #[zbus(connection)] conexion: &zbus::Connection,
    ) -> zbus::fdo::Result<Vec<(String, String)>> {
        let lang = Lang::from_env();
        let bus = DBusProxy::new(conexion).await?;
        let mut v = Vec::with_capacity(SERVICIOS.len());
        for nombre in SERVICIOS {
            let n =
                BusName::try_from(*nombre).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
            let activo = bus.name_has_owner(n).await?;
            let clave = if activo { "activo" } else { "inactivo" };
            v.push((nombre.to_string(), tr(lang, clave).to_string()));
        }
        Ok(v)
    }

    fn ping(&self) -> &'static str {
        "pong"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nombres_de_servicio_validos() {
        for n in SERVICIOS {
            assert!(BusName::try_from(*n).is_ok(), "{n}");
        }
    }
}
