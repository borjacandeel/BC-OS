use std::process::ExitCode;

#[tokio::main(flavor = "current_thread")]
async fn main() -> ExitCode {
    bc_common::logging::init("bc-security-service");
    match bc_common::bus::servir(
        "org.bcos.Security",
        "/org/bcos/Security",
        bc_security_service::Security,
    )
    .await
    {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "el servicio ha fallado");
            eprintln!("bc-security-service: {e}");
            ExitCode::FAILURE
        }
    }
}
