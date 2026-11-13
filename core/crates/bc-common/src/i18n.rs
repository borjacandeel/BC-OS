//! Localización mínima: español de España por defecto, inglés secundario.

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Lang {
    #[default]
    EsEs,
    En,
}

impl Lang {
    /// Interpreta un identificador de locale (`es_ES.UTF-8`, `en_US`, ...). Cualquier otro valor cae en español.
    pub fn parse(locale: &str) -> Self {
        if locale.to_ascii_lowercase().starts_with("en") {
            Lang::En
        } else {
            Lang::EsEs
        }
    }

    pub fn from_env() -> Self {
        let v = ["LC_ALL", "LC_MESSAGES", "LANG"]
            .iter()
            .find_map(|k| std::env::var(k).ok().filter(|v| !v.is_empty()));
        v.map(|v| Self::parse(&v)).unwrap_or_default()
    }
}

/// Traduce una clave. Si no existe devuelve la propia clave.
pub fn tr(lang: Lang, clave: &'static str) -> &'static str {
    match (lang, clave) {
        (Lang::EsEs, "activo") => "activo",
        (Lang::En, "activo") => "active",
        (Lang::EsEs, "inactivo") => "inactivo",
        (Lang::En, "inactivo") => "inactive",
        (Lang::EsEs, "desconocido") => "desconocido",
        (Lang::En, "desconocido") => "unknown",
        (Lang::EsEs, "sin_actualizaciones") => "El sistema está al día",
        (Lang::En, "sin_actualizaciones") => "System is up to date",
        (_, c) => c,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn espanol_por_defecto() {
        assert_eq!(Lang::default(), Lang::EsEs);
        assert_eq!(Lang::parse("es_ES.UTF-8"), Lang::EsEs);
        assert_eq!(Lang::parse("C"), Lang::EsEs);
        assert_eq!(Lang::parse("en_US.UTF-8"), Lang::En);
    }

    #[test]
    fn traduce_y_cae_en_la_clave() {
        assert_eq!(
            tr(Lang::EsEs, "sin_actualizaciones"),
            "El sistema está al día"
        );
        assert_eq!(tr(Lang::En, "activo"), "active");
        assert_eq!(tr(Lang::En, "otra.clave"), "otra.clave");
    }
}
