use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-performance-service");
    match bc_common::bus::servir(
        "org.bcos.Performance",
        "/org/bcos/Performance",
        bc_performance_service::Performance,
    )
    .await
    {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-performance-service: {e}");
            ExitCode::FAILURE
        }
    }
}
