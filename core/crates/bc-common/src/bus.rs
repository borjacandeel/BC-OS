use crate::Result;
use zbus::connection::Builder;
use zbus::object_server::Interface;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BusKind {
    Session,
    System,
}

impl BusKind {
    /// Bus de sesión por defecto; `BC_BUS=system` selecciona el bus del sistema.
    pub fn from_env() -> Self {
        Self::parse(std::env::var("BC_BUS").ok().as_deref())
    }

    pub fn parse(valor: Option<&str>) -> Self {
        match valor {
            Some("system") => BusKind::System,
            _ => BusKind::Session,
        }
    }
}

/// Publica `iface` en `ruta` con el nombre `nombre` y devuelve la conexión (para emitir señales o tareas propias).
pub async fn conectar<I: Interface>(
    nombre: &'static str,
    ruta: &'static str,
    iface: I,
) -> Result<zbus::Connection> {
    let builder = match BusKind::from_env() {
        BusKind::Session => Builder::session()?,
        BusKind::System => Builder::system()?,
    };
    let conexion = builder.name(nombre)?.serve_at(ruta, iface)?.build().await?;
    tracing::info!(nombre, ruta, "publicado en D-Bus");
    Ok(conexion)
}

/// Publica `iface` en `ruta` con el nombre `nombre` y espera a SIGTERM/SIGINT.
pub async fn servir<I: Interface>(
    nombre: &'static str,
    ruta: &'static str,
    iface: I,
) -> Result<()> {
    let _conexion = conectar(nombre, ruta, iface).await?;
    esperar_senal().await;
    tracing::info!(nombre, "parando");
    Ok(())
}

/// Espera a SIGTERM o SIGINT.
pub async fn esperar_senal() {
    use tokio::signal::unix::{signal, SignalKind};
    let mut term = signal(SignalKind::terminate()).expect("señal SIGTERM");
    tokio::select! {
        _ = term.recv() => {}
        _ = tokio::signal::ctrl_c() => {}
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sesion_por_defecto_y_sistema_opcional() {
        assert_eq!(BusKind::parse(None), BusKind::Session);
        assert_eq!(BusKind::parse(Some("loquesea")), BusKind::Session);
        assert_eq!(BusKind::parse(Some("system")), BusKind::System);
    }
}
