use std::process::ExitCode;
use std::time::Duration;

use bc_hardware_service::{render, Hardware};

const RUTA: &str = "/org/bcos/Hardware";

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    // `bc-hardware-service --perfil`: imprime el perfil gráfico (y lo deja en caché) sin D-Bus
    if std::env::args().any(|a| a == "--perfil") {
        let raiz = std::env::var_os("BC_HW_ROOT").map(Into::into).unwrap_or_else(|| "/".into());
        println!("{}", render::Estado::nuevo(raiz).json);
        return ExitCode::SUCCESS;
    }
    bc_common::logging::init("bc-hardware-service");
    let hw = Hardware::nuevo();
    let estado = hw.render.clone();
    let conexion = match bc_common::bus::conectar("org.bcos.Hardware", RUTA, hw).await {
        Ok(c) => c,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-hardware-service: {e}");
            return ExitCode::FAILURE;
        }
    };
    // Único monitor de baja frecuencia: energía, temperatura y hardware cada 20 s; avisa solo si cambia el nivel
    let monitor = async {
        let mut t = tokio::time::interval(Duration::from_secs(20));
        t.tick().await;
        loop {
            t.tick().await;
            let cambio = estado.lock().ok().and_then(|mut e| e.reevaluar().then(|| (e.nivel.como_str().to_string(), e.json.clone())));
            if let Some((nivel, json)) = cambio {
                tracing::info!(nivel, "nivel gráfico cambiado");
                if let Ok(iface) = conexion.object_server().interface::<_, Hardware>(RUTA).await {
                    let _ = Hardware::nivel_render_cambiado(iface.signal_emitter(), &nivel, &json).await;
                }
            }
        }
    };
    tokio::select! {
        _ = monitor => {}
        _ = bc_common::bus::esperar_senal() => {}
    }
    tracing::info!("parando");
    ExitCode::SUCCESS
}
