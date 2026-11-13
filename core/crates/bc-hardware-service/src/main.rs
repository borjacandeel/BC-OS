use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-hardware-service");
    match bc_common::bus::servir(
        "org.bcos.Hardware",
        "/org/bcos/Hardware",
        bc_hardware_service::Hardware,
    )
    .await
    {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-hardware-service: {e}");
            ExitCode::FAILURE
        }
    }
}
