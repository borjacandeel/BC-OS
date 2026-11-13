use tracing_subscriber::EnvFilter;

/// Inicializa logs estructurados (JSON, una línea por evento) hacia stderr/journald.
/// Nivel configurable con `RUST_LOG` (por defecto `info`).
pub fn init(servicio: &'static str) {
    let filtro = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(filtro)
        .with_current_span(false)
        .with_writer(std::io::stderr)
        .init();
    tracing::info!(servicio, version = env!("CARGO_PKG_VERSION"), "arrancando");
}
