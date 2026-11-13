//! Detección de hardware real: `/proc/cpuinfo`, `/sys/class/power_supply`, `/sys/class/thermal`.

use bc_common::{BcError, Result};
use std::path::Path;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Cpu {
    pub modelo: String,
    pub nucleos: u32,
}

/// Parsea `/proc/cpuinfo` (x86: «model name»; aarch64: «Hardware»/«Model» o «CPU part»).
pub fn parse_cpuinfo(texto: &str) -> Cpu {
    let valor = |clave: &str| {
        texto.lines().find_map(|l| {
            let (k, v) = l.split_once(':')?;
            (k.trim() == clave).then(|| v.trim().to_string())
        })
    };
    let nucleos = texto
        .lines()
        .filter(|l| {
            l.split_once(':')
                .is_some_and(|(k, _)| k.trim() == "processor")
        })
        .count() as u32;
    let modelo = valor("model name")
        .or_else(|| valor("Model"))
        .or_else(|| valor("Hardware"))
        .or_else(|| valor("CPU part").map(|p| format!("ARM CPU part {p}")))
        .unwrap_or_else(|| "desconocido".into());
    Cpu { modelo, nucleos }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Bateria {
    pub nombre: String,
    pub capacidad: i32,
    pub estado: String,
}

fn leer_trim(p: &Path) -> Option<String> {
    std::fs::read_to_string(p)
        .ok()
        .map(|s| s.trim().to_string())
}

/// Baterías (`type == Battery`) bajo un directorio tipo `/sys/class/power_supply`.
pub fn baterias_en(dir: &Path) -> Result<Vec<Bateria>> {
    let Ok(rd) = std::fs::read_dir(dir) else {
        return Ok(vec![]); // sin subsistema power_supply: equipo sin batería
    };
    let mut v: Vec<Bateria> = rd
        .filter_map(|e| e.ok())
        .filter_map(|e| {
            let p = e.path();
            (leer_trim(&p.join("type"))? == "Battery").then(|| Bateria {
                nombre: e.file_name().to_string_lossy().into_owned(),
                capacidad: leer_trim(&p.join("capacity"))
                    .and_then(|c| c.parse().ok())
                    .unwrap_or(-1),
                estado: leer_trim(&p.join("status")).unwrap_or_else(|| "desconocido".into()),
            })
        })
        .collect();
    v.sort_by(|a, b| a.nombre.cmp(&b.nombre));
    Ok(v)
}

/// Temperaturas en °C de las zonas térmicas bajo `/sys/class/thermal`.
pub fn temperaturas_en(dir: &Path) -> Result<Vec<(String, f64)>> {
    let Ok(rd) = std::fs::read_dir(dir) else {
        return Ok(vec![]);
    };
    let mut v: Vec<(String, f64)> = rd
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().starts_with("thermal_zone"))
        .filter_map(|e| {
            let p = e.path();
            let tipo = leer_trim(&p.join("type"))?;
            let milli: f64 = leer_trim(&p.join("temp"))?.parse().ok()?;
            Some((tipo, milli / 1000.0))
        })
        .collect();
    v.sort_by(|a, b| a.0.cmp(&b.0));
    Ok(v)
}

pub fn cpu() -> Result<Cpu> {
    let t =
        std::fs::read_to_string("/proc/cpuinfo").map_err(|e| BcError::io("/proc/cpuinfo", e))?;
    Ok(parse_cpuinfo(&t))
}

pub struct Hardware;

#[zbus::interface(name = "org.bcos.Hardware1")]
impl Hardware {
    /// (modelo, número de núcleos)
    fn cpu(&self) -> zbus::fdo::Result<(String, u32)> {
        let c = cpu()?;
        Ok((c.modelo, c.nucleos))
    }

    /// Lista de (nombre, capacidad %, estado). Vacía si no hay batería.
    fn baterias(&self) -> zbus::fdo::Result<Vec<(String, i32, String)>> {
        Ok(baterias_en(Path::new("/sys/class/power_supply"))?
            .into_iter()
            .map(|b| (b.nombre, b.capacidad, b.estado))
            .collect())
    }

    /// Lista de (tipo de zona, temperatura °C). Vacía si no hay sensores.
    fn temperaturas(&self) -> zbus::fdo::Result<Vec<(String, f64)>> {
        Ok(temperaturas_en(Path::new("/sys/class/thermal"))?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn cpuinfo_x86() {
        let c = parse_cpuinfo(
            "processor\t: 0\nmodel name\t: AMD EPYC\nprocessor\t: 1\nmodel name\t: AMD EPYC\n",
        );
        assert_eq!(
            c,
            Cpu {
                modelo: "AMD EPYC".into(),
                nucleos: 2
            }
        );
    }

    #[test]
    fn cpuinfo_aarch64() {
        let c = parse_cpuinfo("processor\t: 0\nBogoMIPS\t: 50.00\nCPU part\t: 0xd0c\nprocessor\t: 1\nCPU part\t: 0xd0c\n");
        assert_eq!(c.nucleos, 2);
        assert_eq!(c.modelo, "ARM CPU part 0xd0c");
        assert_eq!(parse_cpuinfo("").modelo, "desconocido");
    }

    fn tmp(nombre: &str) -> std::path::PathBuf {
        let d = std::env::temp_dir().join(format!("bc-hw-{}-{nombre}", std::process::id()));
        let _ = fs::remove_dir_all(&d);
        fs::create_dir_all(&d).unwrap();
        d
    }

    #[test]
    fn baterias_y_temperaturas() {
        let d = tmp("sys");
        let bat = d.join("BAT0");
        fs::create_dir_all(&bat).unwrap();
        fs::write(bat.join("type"), "Battery\n").unwrap();
        fs::write(bat.join("capacity"), "87\n").unwrap();
        fs::write(bat.join("status"), "Charging\n").unwrap();
        let ac = d.join("AC");
        fs::create_dir_all(&ac).unwrap();
        fs::write(ac.join("type"), "Mains\n").unwrap();
        let b = baterias_en(&d).unwrap();
        assert_eq!(
            b,
            vec![Bateria {
                nombre: "BAT0".into(),
                capacidad: 87,
                estado: "Charging".into()
            }]
        );

        let z = d.join("thermal_zone0");
        fs::create_dir_all(&z).unwrap();
        fs::write(z.join("type"), "cpu-thermal\n").unwrap();
        fs::write(z.join("temp"), "45500\n").unwrap();
        assert_eq!(
            temperaturas_en(&d).unwrap(),
            vec![("cpu-thermal".into(), 45.5)]
        );

        assert!(baterias_en(&d.join("no-existe")).unwrap().is_empty());
        let _ = fs::remove_dir_all(&d);
    }

    #[test]
    fn cpu_real() {
        assert!(cpu().unwrap().nucleos >= 1);
    }
}
