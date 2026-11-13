use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-settings-service");
    let servicio = match bc_settings_service::Settings::abrir() {
        Ok(s) => s,
        Err(e) => {
            tracing::error!(error = %e, "no se pudieron cargar los ajustes");
            eprintln!("bc-settings-service: {e}");
            return ExitCode::FAILURE;
        }
    };
    match bc_common::bus::servir("org.bcos.Settings", "/org/bcos/Settings", servicio).await {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-settings-service: {e}");
            ExitCode::FAILURE
        }
    }
}
