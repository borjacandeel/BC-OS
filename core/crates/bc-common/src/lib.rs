//! Utilidades compartidas por todos los servicios de BC Core.

pub mod bus;
pub mod error;
pub mod i18n;
pub mod logging;

pub use error::{BcError, Result};
