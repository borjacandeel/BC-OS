use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-daemon");
    match bc_common::bus::servir("org.bcos.Daemon", "/org/bcos/Daemon", bc_daemon::Daemon).await {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-daemon: {e}");
            ExitCode::FAILURE
        }
    }
}
