use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-antivirus-service");
    match bc_common::bus::servir(
        "org.bcos.Antivirus",
        "/org/bcos/Antivirus",
        bc_antivirus_service::Antivirus::new(),
    )
    .await
    {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-antivirus-service: {e}");
            ExitCode::FAILURE
        }
    }
}
