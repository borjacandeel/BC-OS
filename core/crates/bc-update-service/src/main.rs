use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-update-service");
    match bc_common::bus::servir(
        "org.bcos.Update",
        "/org/bcos/Update",
        bc_update_service::Update,
    )
    .await
    {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-update-service: {e}");
            ExitCode::FAILURE
        }
    }
}
