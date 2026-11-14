//! Interpretación de la salida de ClamAV SIN E/S: líneas de `clamscan`, versión, edad de la
//! base de firmas y cuándo avisar de que está antigua.

/// Días a partir de los cuales la base de firmas se considera antigua.
pub const UMBRAL_DB_DIAS: i32 = 7;

/// Máximo de errores por archivo que se conservan (evita crecer sin límite).
pub const MAX_ERRORES: usize = 50;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Linea {
    /// `ruta: OK`
    Limpio,
    /// `ruta: Firma FOUND`
    Infectado { ruta: String, firma: String },
    /// `ruta: motivo. ERROR`, `ERROR: …`, `LibClamAV Error: …`
    Error(String),
    /// Cualquier otra cosa (vacía, «Empty file», avisos, etc.).
    Otra,
}

/// Clasifica una línea de la salida de `clamscan`.
pub fn parsear_linea(linea: &str) -> Linea {
    let l = linea.trim_end_matches(['\r', '\n']).trim_end();
    if l.is_empty() {
        return Linea::Otra;
    }
    if let Some(resto) = l.strip_suffix(" FOUND") {
        // La firma no contiene «: », la ruta sí podría: se corta por el último.
        if let Some((ruta, firma)) = resto.rsplit_once(": ") {
            if !ruta.is_empty() {
                return Linea::Infectado {
                    ruta: ruta.to_string(),
                    firma: firma.to_string(),
                };
            }
        }
        return Linea::Otra;
    }
    if l.ends_with(": OK") {
        return Linea::Limpio;
    }
    let min = l.to_ascii_lowercase();
    if l.ends_with(" ERROR")
        || min.starts_with("error:")
        || min.starts_with("libclamav error:")
        || min.starts_with("clamscan: error")
    {
        return Linea::Error(l.to_string());
    }
    Linea::Otra
}

/// Resultado acumulado de un análisis.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Acumulado {
    /// Archivos revisados (limpios + infectados).
    pub escaneados: u64,
    pub infectados: Vec<String>,
    pub errores: Vec<String>,
}

impl Acumulado {
    pub fn aceptar(&mut self, linea: &str) {
        match parsear_linea(linea) {
            Linea::Limpio => self.escaneados += 1,
            Linea::Infectado { ruta, .. } => {
                self.escaneados += 1;
                self.infectados.push(ruta);
            }
            Linea::Error(e) => {
                if self.errores.len() < MAX_ERRORES {
                    self.errores.push(e);
                }
            }
            Linea::Otra => {}
        }
    }
}

/// Procesa una salida completa de `clamscan`.
pub fn parsear_salida(texto: &str) -> Acumulado {
    let mut a = Acumulado::default();
    for l in texto.lines() {
        a.aceptar(l);
    }
    a
}

/// ¿Terminó bien el análisis? Códigos de `clamscan`: 0 = sin virus, 1 = virus encontrados,
/// 2 = error. Debe ser coherente con lo parseado: un 0 con infectados, un 1 sin infectados,
/// un 2, una señal (`None`) o una cancelación NO son «ok».
pub fn analisis_ok(codigo: Option<i32>, n_infectados: usize, cancelado: bool) -> bool {
    if cancelado {
        return false;
    }
    match codigo {
        Some(0) => n_infectados == 0,
        Some(1) => n_infectados > 0,
        _ => false,
    }
}

/// Datos de `clamscan --version`: `ClamAV 1.4.1/27500/Tue Nov 11 08:12:11 2026`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InfoVersion {
    pub motor: String,
    pub firmas: Option<u32>,
    pub fecha_db: Option<String>,
}

pub fn parsear_version(salida: &str) -> Option<InfoVersion> {
    let linea = salida
        .lines()
        .map(str::trim)
        .find(|l| l.starts_with("ClamAV "))?;
    let resto = linea.strip_prefix("ClamAV ")?.trim();
    let mut partes = resto.splitn(3, '/');
    let motor = partes.next()?.trim();
    if motor.is_empty() {
        return None;
    }
    let firmas = partes.next().and_then(|s| s.trim().parse().ok());
    let fecha_db = partes
        .next()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty());
    Some(InfoVersion {
        motor: motor.to_string(),
        firmas,
        fecha_db,
    })
}

fn mes(nombre: &str) -> Option<i64> {
    const M: [&str; 12] = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    M.iter()
        .position(|m| m.eq_ignore_ascii_case(nombre))
        .map(|i| i as i64 + 1)
}

/// Días desde 1970-01-01 para una fecha civil (algoritmo de Howard Hinnant).
fn dias_desde_epoch(y: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y - 1 } else { y };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let mp = (m + 9) % 12;
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

/// `Tue Nov 11 08:12:11 2026` (el día de la semana es opcional) -> segundos desde epoch (UTC).
pub fn parsear_fecha_clamav(texto: &str) -> Option<i64> {
    let t: Vec<&str> = texto.split_whitespace().collect();
    let t = match t.len() {
        5 => &t[1..],
        4 => &t[..],
        _ => return None,
    };
    let m = mes(t[0])?;
    let d: i64 = t[1].parse().ok()?;
    let hms: Vec<i64> = t[2].split(':').filter_map(|x| x.parse().ok()).collect();
    let y: i64 = t[3].parse().ok()?;
    if hms.len() != 3 || !(1..=31).contains(&d) || !(1970..=9999).contains(&y) {
        return None;
    }
    if hms[0] > 23 || hms[1] > 59 || hms[2] > 60 {
        return None;
    }
    Some(dias_desde_epoch(y, m, d) * 86_400 + hms[0] * 3600 + hms[1] * 60 + hms[2])
}

/// Edad en días completos de la base de firmas; `-1` si no se puede saber.
/// Una fecha futura (reloj desajustado) cuenta como 0.
pub fn edad_db_dias(info: Option<&InfoVersion>, ahora_epoch: i64) -> i32 {
    let Some(f) = info
        .and_then(|i| i.fecha_db.as_deref())
        .and_then(parsear_fecha_clamav)
    else {
        return -1;
    };
    let dias = (ahora_epoch - f).max(0) / 86_400;
    i32::try_from(dias).unwrap_or(i32::MAX)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AvisoDb {
    Ninguno,
    /// Más antigua que el umbral.
    Antigua,
    /// ClamAV está, pero no se pudo determinar la edad.
    Desconocida,
}

/// Decide si hay que avisar al usuario de la base de firmas.
pub fn aviso_db(disponible: bool, edad_dias: i32, umbral: i32) -> AvisoDb {
    if !disponible {
        AvisoDb::Ninguno
    } else if edad_dias < 0 {
        AvisoDb::Desconocida
    } else if edad_dias > umbral {
        AvisoDb::Antigua
    } else {
        AvisoDb::Ninguno
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn linea_infectada() {
        assert_eq!(
            parsear_linea("/home/bc/eicar.com: Win.Test.EICAR_HDB-1 FOUND"),
            Linea::Infectado {
                ruta: "/home/bc/eicar.com".into(),
                firma: "Win.Test.EICAR_HDB-1".into()
            }
        );
    }

    #[test]
    fn linea_infectada_con_dos_puntos_y_espacios_en_la_ruta() {
        assert_eq!(
            parsear_linea("/home/bc/mi: carpeta/a b.exe: Eicar-Signature FOUND\n"),
            Linea::Infectado {
                ruta: "/home/bc/mi: carpeta/a b.exe".into(),
                firma: "Eicar-Signature".into()
            }
        );
        assert_eq!(
            parsear_linea("/home/bc/ñandú/ü.txt: Foo.Bar FOUND\r\n"),
            Linea::Infectado {
                ruta: "/home/bc/ñandú/ü.txt".into(),
                firma: "Foo.Bar".into()
            }
        );
    }

    #[test]
    fn linea_found_mal_formada() {
        assert_eq!(parsear_linea("FOUND"), Linea::Otra);
        assert_eq!(parsear_linea(" FOUND"), Linea::Otra);
        assert_eq!(parsear_linea("sin separador FOUND"), Linea::Otra);
        assert_eq!(parsear_linea(": Sig FOUND"), Linea::Otra);
    }

    #[test]
    fn linea_limpia_vacia_y_otras() {
        assert_eq!(parsear_linea("/home/bc/a.txt: OK"), Linea::Limpio);
        assert_eq!(parsear_linea(""), Linea::Otra);
        assert_eq!(parsear_linea("\n"), Linea::Otra);
        assert_eq!(parsear_linea("/home/bc/vacio: Empty file"), Linea::Otra);
        assert_eq!(parsear_linea("OK"), Linea::Otra);
    }

    #[test]
    fn lineas_de_error() {
        for l in [
            "/home/bc/x: Permission denied. ERROR",
            "/home/bc/x: lstat() failed: No such file or directory. ERROR",
            "ERROR: Can't open file or directory",
            "LibClamAV Error: cl_load(): No such file or directory: /var/lib/clamav",
            "clamscan: error while loading database",
        ] {
            assert!(matches!(parsear_linea(l), Linea::Error(_)), "{l}");
        }
    }

    #[test]
    fn salida_con_infectados() {
        let s = "/home/bc/a.txt: OK\n\
                 /home/bc/virus1: Eicar-Test-Signature FOUND\n\
                 /home/bc/b.txt: OK\n\
                 /home/bc/dir/virus2: Win.Trojan.X-1 FOUND\n";
        let a = parsear_salida(s);
        assert_eq!(a.escaneados, 4);
        assert_eq!(a.infectados, vec!["/home/bc/virus1", "/home/bc/dir/virus2"]);
        assert!(a.errores.is_empty());
    }

    #[test]
    fn salida_sin_infectados() {
        let a = parsear_salida("/home/bc/a: OK\n/home/bc/b: OK\n");
        assert_eq!(a.escaneados, 2);
        assert!(a.infectados.is_empty());
        assert!(a.errores.is_empty());
    }

    #[test]
    fn salida_vacia() {
        assert_eq!(parsear_salida(""), Acumulado::default());
        assert_eq!(parsear_salida("\n\n"), Acumulado::default());
    }

    #[test]
    fn salida_con_errores() {
        let s = "/home/bc/x: Permission denied. ERROR\n\
                 /home/bc/y: OK\n\
                 LibClamAV Error: algo\n";
        let a = parsear_salida(s);
        assert_eq!(a.escaneados, 1);
        assert_eq!(a.errores.len(), 2);
    }

    #[test]
    fn errores_acotados() {
        let s = "/x: Permission denied. ERROR\n".repeat(MAX_ERRORES + 30);
        assert_eq!(parsear_salida(&s).errores.len(), MAX_ERRORES);
    }

    #[test]
    fn ok_segun_codigo() {
        assert!(analisis_ok(Some(0), 0, false));
        assert!(analisis_ok(Some(1), 2, false));
        assert!(!analisis_ok(Some(0), 1, false)); // incoherente
        assert!(!analisis_ok(Some(1), 0, false)); // incoherente
        assert!(!analisis_ok(Some(2), 0, false)); // error de clamscan
        assert!(!analisis_ok(Some(2), 3, false));
        assert!(!analisis_ok(None, 0, false)); // muerto por señal
        assert!(!analisis_ok(Some(0), 0, true)); // cancelado
        assert!(!analisis_ok(Some(1), 1, true));
    }

    #[test]
    fn version_completa() {
        let v = parsear_version("ClamAV 1.4.1/27500/Tue Nov 11 08:12:11 2026\n").unwrap();
        assert_eq!(v.motor, "1.4.1");
        assert_eq!(v.firmas, Some(27500));
        assert_eq!(v.fecha_db.as_deref(), Some("Tue Nov 11 08:12:11 2026"));
    }

    #[test]
    fn version_sin_base_de_firmas() {
        let v = parsear_version("ClamAV 1.4.1\n").unwrap();
        assert_eq!(v.motor, "1.4.1");
        assert_eq!(v.firmas, None);
        assert_eq!(v.fecha_db, None);
        let v = parsear_version("ClamAV 1.0.0/26000/").unwrap();
        assert_eq!(v.fecha_db, None);
    }

    #[test]
    fn version_invalida() {
        assert_eq!(parsear_version(""), None);
        assert_eq!(parsear_version("otra cosa 1.2"), None);
        assert_eq!(parsear_version("ClamAV /1/x"), None);
        assert_eq!(parsear_version("ClamAV "), None);
    }

    #[test]
    fn fecha_conocida() {
        // 2026-11-11 08:12:11 UTC
        assert_eq!(
            parsear_fecha_clamav("Tue Nov 11 08:12:11 2026"),
            Some(1_794_384_731)
        );
        assert_eq!(parsear_fecha_clamav("Thu Jan  1 00:00:00 1970"), Some(0));
        assert_eq!(
            parsear_fecha_clamav("Nov 11 08:12:11 2026"),
            Some(1_794_384_731)
        );
        // Año bisiesto: 2024-02-29 12:00:00
        assert_eq!(
            parsear_fecha_clamav("Thu Feb 29 12:00:00 2024"),
            Some(1_709_208_000)
        );
    }

    #[test]
    fn fecha_invalida() {
        for f in [
            "",
            "basura",
            "Tue Xyz 11 08:12:11 2026",
            "Tue Nov 32 08:12:11 2026",
            "Tue Nov 00 08:12:11 2026",
            "Tue Nov 11 25:12:11 2026",
            "Tue Nov 11 08:61:11 2026",
            "Tue Nov 11 08:12 2026",
            "Tue Nov 11 08:12:11 1969",
            "Tue Nov 11 08:12:11 x",
        ] {
            assert_eq!(parsear_fecha_clamav(f), None, "{f}");
        }
    }

    fn info(fecha: &str) -> InfoVersion {
        InfoVersion {
            motor: "1.4.1".into(),
            firmas: Some(1),
            fecha_db: Some(fecha.into()),
        }
    }

    #[test]
    fn edad_en_dias() {
        let base = 1_794_384_731; // Tue Nov 11 08:12:11 2026
        let i = info("Tue Nov 11 08:12:11 2026");
        assert_eq!(edad_db_dias(Some(&i), base), 0);
        assert_eq!(edad_db_dias(Some(&i), base + 86_399), 0);
        assert_eq!(edad_db_dias(Some(&i), base + 86_400), 1);
        assert_eq!(edad_db_dias(Some(&i), base + 10 * 86_400 + 5), 10);
        // Fecha futura (reloj desajustado).
        assert_eq!(edad_db_dias(Some(&i), base - 5 * 86_400), 0);
    }

    #[test]
    fn edad_desconocida() {
        assert_eq!(edad_db_dias(None, 1_794_384_731), -1);
        let sin = InfoVersion {
            motor: "1.4.1".into(),
            firmas: None,
            fecha_db: None,
        };
        assert_eq!(edad_db_dias(Some(&sin), 1_794_384_731), -1);
        assert_eq!(edad_db_dias(Some(&info("basura")), 1_794_384_731), -1);
    }

    #[test]
    fn avisos_de_base_antigua() {
        let u = UMBRAL_DB_DIAS;
        assert_eq!(aviso_db(false, 100, u), AvisoDb::Ninguno);
        assert_eq!(aviso_db(false, -1, u), AvisoDb::Ninguno);
        assert_eq!(aviso_db(true, -1, u), AvisoDb::Desconocida);
        assert_eq!(aviso_db(true, 0, u), AvisoDb::Ninguno);
        assert_eq!(aviso_db(true, u, u), AvisoDb::Ninguno);
        assert_eq!(aviso_db(true, u + 1, u), AvisoDb::Antigua);
        assert_eq!(aviso_db(true, i32::MAX, u), AvisoDb::Antigua);
    }
}
