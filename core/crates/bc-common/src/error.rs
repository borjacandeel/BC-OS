use std::path::PathBuf;

pub type Result<T> = std::result::Result<T, BcError>;

/// Errores de BC Core. Los mensajes (`Display`) son visibles al usuario y están en castellano.
#[derive(Debug, thiserror::Error)]
pub enum BcError {
    #[error("No se pudo acceder a «{}»: {fuente}", ruta.display())]
    Io {
        ruta: PathBuf,
        #[source]
        fuente: std::io::Error,
    },
    #[error("El archivo «{}» no tiene un formato válido: {detalle}", ruta.display())]
    Formato { ruta: PathBuf, detalle: String },
    #[error("La clave de ajuste «{0}» no existe")]
    ClaveDesconocida(String),
    #[error("El valor «{valor}» no es válido para «{clave}» (valores admitidos: {admitidos})")]
    ValorInvalido {
        clave: String,
        valor: String,
        admitidos: String,
    },
    #[error("No se pudo ejecutar «{orden}»: {detalle}")]
    Orden { orden: String, detalle: String },
    #[error("Error del bus D-Bus: {0}")]
    Bus(String),
}

impl BcError {
    pub fn io(ruta: impl Into<PathBuf>, fuente: std::io::Error) -> Self {
        Self::Io {
            ruta: ruta.into(),
            fuente,
        }
    }
}

impl From<zbus::Error> for BcError {
    fn from(e: zbus::Error) -> Self {
        Self::Bus(e.to_string())
    }
}

impl From<BcError> for zbus::fdo::Error {
    fn from(e: BcError) -> Self {
        match e {
            BcError::ClaveDesconocida(_) | BcError::ValorInvalido { .. } => {
                zbus::fdo::Error::InvalidArgs(e.to_string())
            }
            _ => zbus::fdo::Error::Failed(e.to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mensajes_en_castellano() {
        let e = BcError::ClaveDesconocida("color".into());
        assert_eq!(e.to_string(), "La clave de ajuste «color» no existe");
        let e = BcError::io("/x", std::io::Error::from(std::io::ErrorKind::NotFound));
        assert!(e.to_string().starts_with("No se pudo acceder a «/x»"));
    }

    #[test]
    fn conversion_a_error_dbus() {
        let e: zbus::fdo::Error = BcError::ClaveDesconocida("a".into()).into();
        assert!(matches!(e, zbus::fdo::Error::InvalidArgs(_)));
    }
}
