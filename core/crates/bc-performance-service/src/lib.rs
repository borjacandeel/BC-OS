//! Métricas de rendimiento leídas de `/proc` (solo lectura, sin privilegios).

use bc_common::{BcError, Result};
use std::time::Duration;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Memoria {
    pub total_kb: u64,
    pub disponible_kb: u64,
    pub swap_total_kb: u64,
    pub swap_libre_kb: u64,
}

impl Memoria {
    pub fn usada_kb(&self) -> u64 {
        self.total_kb.saturating_sub(self.disponible_kb)
    }
}

/// Parsea el contenido de `/proc/meminfo`.
pub fn parse_meminfo(texto: &str) -> Option<Memoria> {
    let campo = |nombre: &str| -> Option<u64> {
        texto
            .lines()
            .find_map(|l| l.strip_prefix(nombre)?.strip_prefix(':'))
            .and_then(|r| r.split_whitespace().next()?.parse().ok())
    };
    Some(Memoria {
        total_kb: campo("MemTotal")?,
        disponible_kb: campo("MemAvailable")?,
        swap_total_kb: campo("SwapTotal").unwrap_or(0),
        swap_libre_kb: campo("SwapFree").unwrap_or(0),
    })
}

/// Tiempos acumulados de CPU: (total, inactivo) de la línea agregada `cpu` de `/proc/stat`.
pub fn parse_cpu_stat(texto: &str) -> Option<(u64, u64)> {
    let linea = texto.lines().find(|l| l.starts_with("cpu "))?;
    let v: Vec<u64> = linea
        .split_whitespace()
        .skip(1)
        .map(|n| n.parse().ok())
        .collect::<Option<_>>()?;
    if v.len() < 5 {
        return None;
    }
    let total: u64 = v.iter().take(8).sum();
    let inactivo = v[3] + v[4]; // idle + iowait
    Some((total, inactivo))
}

/// Porcentaje de uso de CPU entre dos muestras de [`parse_cpu_stat`].
pub fn uso_cpu(antes: (u64, u64), despues: (u64, u64)) -> f64 {
    let total = despues.0.saturating_sub(antes.0);
    let inactivo = despues.1.saturating_sub(antes.1);
    if total == 0 {
        return 0.0;
    }
    (total - inactivo.min(total)) as f64 * 100.0 / total as f64
}

pub fn parse_loadavg(texto: &str) -> Option<(f64, f64, f64)> {
    let mut it = texto.split_whitespace();
    Some((
        it.next()?.parse().ok()?,
        it.next()?.parse().ok()?,
        it.next()?.parse().ok()?,
    ))
}

fn leer(ruta: &str) -> Result<String> {
    std::fs::read_to_string(ruta).map_err(|e| BcError::io(ruta, e))
}

fn formato(ruta: &str, detalle: &str) -> BcError {
    BcError::Formato {
        ruta: ruta.into(),
        detalle: detalle.into(),
    }
}

pub fn memoria() -> Result<Memoria> {
    parse_meminfo(&leer("/proc/meminfo")?).ok_or_else(|| formato("/proc/meminfo", "faltan campos"))
}

pub fn muestra_cpu() -> Result<(u64, u64)> {
    parse_cpu_stat(&leer("/proc/stat")?).ok_or_else(|| formato("/proc/stat", "línea cpu inválida"))
}

/// Número de procesos: entradas numéricas de `/proc`.
pub fn numero_procesos() -> Result<u32> {
    let rd = std::fs::read_dir("/proc").map_err(|e| BcError::io("/proc", e))?;
    Ok(rd
        .filter_map(|e| e.ok())
        .filter(|e| {
            e.file_name()
                .to_string_lossy()
                .bytes()
                .all(|b| b.is_ascii_digit())
        })
        .count() as u32)
}

pub struct Performance;

#[zbus::interface(name = "org.bcos.Performance1")]
impl Performance {
    /// (total_kb, disponible_kb, usada_kb, swap_total_kb, swap_libre_kb)
    fn memoria(&self) -> zbus::fdo::Result<(u64, u64, u64, u64, u64)> {
        let m = memoria()?;
        Ok((
            m.total_kb,
            m.disponible_kb,
            m.usada_kb(),
            m.swap_total_kb,
            m.swap_libre_kb,
        ))
    }

    /// Uso de CPU (%) medido durante `ms` milisegundos (máx. 10000).
    async fn uso_cpu(&self, ms: u32) -> zbus::fdo::Result<f64> {
        let a = muestra_cpu()?;
        tokio::time::sleep(Duration::from_millis(ms.clamp(50, 10_000).into())).await;
        let b = muestra_cpu()?;
        Ok(uso_cpu(a, b))
    }

    fn numero_procesos(&self) -> zbus::fdo::Result<u32> {
        Ok(numero_procesos()?)
    }

    /// Carga media a 1, 5 y 15 minutos.
    fn carga(&self) -> zbus::fdo::Result<(f64, f64, f64)> {
        parse_loadavg(&leer("/proc/loadavg")?)
            .ok_or_else(|| formato("/proc/loadavg", "formato inesperado").into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const MEMINFO: &str = "MemTotal:        8123456 kB\nMemFree:          100000 kB\nMemAvailable:    6000000 kB\nSwapTotal:       4096000 kB\nSwapFree:        4000000 kB\n";

    #[test]
    fn meminfo() {
        let m = parse_meminfo(MEMINFO).unwrap();
        assert_eq!(m.total_kb, 8_123_456);
        assert_eq!(m.disponible_kb, 6_000_000);
        assert_eq!(m.usada_kb(), 2_123_456);
        assert_eq!(m.swap_libre_kb, 4_000_000);
        assert!(parse_meminfo("MemTotal: 1 kB\n").is_none());
    }

    #[test]
    fn cpu() {
        let a =
            parse_cpu_stat("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 1 1 1 1 0 0 0 0 0\n").unwrap();
        assert_eq!(a, (1000, 800));
        let b = parse_cpu_stat("cpu  150 0 150 750 150 0 0 0 0 0\n").unwrap();
        // delta total 200, inactivo 100 -> 50 %
        assert!((uso_cpu(a, b) - 50.0).abs() < 1e-9);
        assert_eq!(uso_cpu(a, a), 0.0);
        assert!(parse_cpu_stat("intr 1 2 3").is_none());
    }

    #[test]
    fn loadavg() {
        assert_eq!(
            parse_loadavg("0.10 0.25 0.50 1/200 999\n"),
            Some((0.10, 0.25, 0.50))
        );
        assert!(parse_loadavg("x").is_none());
    }

    #[test]
    fn procesos_reales() {
        assert!(numero_procesos().unwrap() >= 1);
        assert!(memoria().unwrap().total_kb > 0);
    }
}
