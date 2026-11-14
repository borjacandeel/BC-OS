//! Servicio de antivirus: envuelve ClamAV (`clamscan`) con una interfaz D-Bus de sesión.
//!
//! La lógica pura (rutas, interpretación de la salida de ClamAV, aviso de base de firmas
//! antigua) vive en [`ruta`] y [`salida`], sin E/S y con pruebas unitarias. Este módulo solo
//! pega esas piezas con procesos y D-Bus.

pub mod ruta;
pub mod salida;

use salida::{Acumulado, AvisoDb};
use std::collections::HashMap;
use std::ffi::OsString;
use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::{mpsc, oneshot};
use zbus::object_server::SignalEmitter;

/// Análisis simultáneos como máximo (clamscan es pesado).
pub const MAX_ANALISIS: usize = 2;

/// Errores D-Bus del servicio (`org.bcos.Antivirus1.<Nombre>`), con mensajes en castellano.
#[derive(Debug, zbus::DBusError)]
#[zbus(prefix = "org.bcos.Antivirus1")]
pub enum Error {
    #[zbus(error)]
    ZBus(zbus::Error),
    /// ClamAV (`clamscan`) no está instalado.
    NoDisponible(String),
    RutaNoPermitida(String),
    RutaInexistente(String),
    DemasiadosAnalisis(String),
    AnalisisDesconocido(String),
    Fallo(String),
}

/// Argumentos de `clamscan` para analizar `ruta`. Nunca sigue enlaces simbólicos.
/// Se imprime cada archivo (sin `--infected`) para poder informar del progreso real.
pub fn argumentos_clamscan(ruta: &Path) -> Vec<OsString> {
    let mut a: Vec<OsString> = [
        "-r",
        "--no-summary",
        "--stdout",
        "--follow-dir-symlinks=0",
        "--follow-file-symlinks=0",
    ]
    .iter()
    .map(OsString::from)
    .collect();
    a.push(ruta.as_os_str().to_owned());
    a
}

/// Identificador de análisis a partir de un contador.
pub fn id_analisis(n: u64) -> String {
    format!("scan-{n}")
}

/// Busca un ejecutable en una lista `PATH` (separada por `:`).
pub fn buscar_en_path(nombre: &str, path: &str) -> Option<PathBuf> {
    use std::os::unix::fs::PermissionsExt;
    path.split(':')
        .filter(|d| !d.is_empty())
        .map(|d| Path::new(d).join(nombre))
        .find(|p| {
            std::fs::metadata(p)
                .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
                .unwrap_or(false)
        })
}

/// Resultado de ejecutar `clamscan`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Resultado {
    pub acumulado: Acumulado,
    pub codigo: Option<i32>,
    pub cancelado: bool,
}

impl Resultado {
    pub fn ok(&self) -> bool {
        salida::analisis_ok(self.codigo, self.acumulado.infectados.len(), self.cancelado)
    }
}

/// Ejecuta `programa` sobre `ruta`, enviando por `progreso` el número de archivos revisados
/// (como mucho una vez por segundo y al final) y parando si `cancelar` se dispara.
pub async fn correr_clamscan(
    programa: &Path,
    ruta: &Path,
    mut cancelar: oneshot::Receiver<()>,
    progreso: mpsc::UnboundedSender<u64>,
) -> std::io::Result<Resultado> {
    let mut hijo = Command::new(programa)
        .args(argumentos_clamscan(ruta))
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .kill_on_drop(true)
        .spawn()?;
    let salida = hijo.stdout.take().expect("stdout canalizado");
    let mut lineas = BufReader::new(salida).lines();
    let mut tic = tokio::time::interval(Duration::from_secs(1));
    tic.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
    let mut acc = Acumulado::default();
    let mut enviado = 0;
    let mut cancelado = false;
    loop {
        tokio::select! {
            l = lineas.next_line() => match l {
                Ok(Some(l)) => acc.aceptar(&l),
                _ => break,
            },
            _ = tic.tick() => {
                if acc.escaneados != enviado {
                    enviado = acc.escaneados;
                    let _ = progreso.send(enviado);
                }
            }
            _ = &mut cancelar => {
                cancelado = true;
                let _ = hijo.kill().await;
                break;
            }
        }
    }
    let estado = hijo.wait().await?;
    if acc.escaneados != enviado {
        let _ = progreso.send(acc.escaneados);
    }
    Ok(Resultado {
        acumulado: acc,
        codigo: estado.code(),
        cancelado,
    })
}

struct Estado {
    clamscan: Option<PathBuf>,
    siguiente: AtomicU64,
    activos: Mutex<HashMap<String, oneshot::Sender<()>>>,
    ultimo_aviso: Mutex<Option<AvisoDb>>,
}

pub struct Antivirus {
    estado: Arc<Estado>,
}

impl Antivirus {
    /// Busca `clamscan` en `PATH`.
    pub fn new() -> Self {
        let path = std::env::var("PATH").unwrap_or_default();
        let clamscan = buscar_en_path("clamscan", &path);
        match &clamscan {
            Some(p) => tracing::info!(clamscan = %p.display(), "ClamAV encontrado"),
            None => tracing::warn!("clamscan no está en PATH: el análisis no estará disponible"),
        }
        Self::con_programa(clamscan)
    }

    pub fn con_programa(clamscan: Option<PathBuf>) -> Self {
        Self {
            estado: Arc::new(Estado {
                clamscan,
                siguiente: AtomicU64::new(1),
                activos: Mutex::new(HashMap::new()),
                ultimo_aviso: Mutex::new(None),
            }),
        }
    }

    fn programa(&self) -> Result<&Path, Error> {
        self.estado.clamscan.as_deref().ok_or_else(|| {
            Error::NoDisponible(
                "ClamAV no está instalado (falta «clamscan»). Instala el paquete «clamav».".into(),
            )
        })
    }
}

impl Default for Antivirus {
    fn default() -> Self {
        Self::new()
    }
}

fn ahora_epoch() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

/// Valida `entrada` completa (léxica + enlaces simbólicos) y devuelve la ruta canónica.
async fn validar_ruta_real(entrada: &str) -> Result<PathBuf, Error> {
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_default();
    let lexica =
        ruta::validar_lexica(entrada, &home).map_err(|e| Error::RutaNoPermitida(e.to_string()))?;
    let canonica = tokio::fs::canonicalize(&lexica).await.map_err(|e| {
        if e.kind() == std::io::ErrorKind::NotFound {
            Error::RutaInexistente(format!("La ruta «{}» no existe", lexica.display()))
        } else {
            Error::Fallo(format!("No se pudo acceder a «{}»: {e}", lexica.display()))
        }
    })?;
    let home_c = tokio::fs::canonicalize(&home).await.unwrap_or(home);
    let tmp_c = tokio::fs::canonicalize(ruta::TMP)
        .await
        .unwrap_or_else(|_| PathBuf::from(ruta::TMP));
    ruta::validar_canonica(&canonica, &home_c, &tmp_c).map_err(|e| {
        Error::RutaNoPermitida(format!("{e} (la ruta real es «{}»)", canonica.display()))
    })?;
    Ok(canonica)
}

#[zbus::interface(name = "org.bcos.Antivirus1")]
impl Antivirus {
    /// (¿ClamAV disponible?, versión del motor, edad de la base de firmas en días; -1 si se desconoce).
    async fn status(&self) -> (bool, String, i32) {
        let Some(programa) = self.estado.clamscan.as_deref() else {
            return (false, String::new(), -1);
        };
        let ejecucion = Command::new(programa)
            .arg("--version")
            .stdin(Stdio::null())
            .stderr(Stdio::null())
            .kill_on_drop(true)
            .output();
        let out = match tokio::time::timeout(Duration::from_secs(30), ejecucion).await {
            Ok(Ok(o)) if o.status.success() => o,
            _ => {
                tracing::warn!("«clamscan --version» ha fallado");
                return (false, String::new(), -1);
            }
        };
        let info = salida::parsear_version(&String::from_utf8_lossy(&out.stdout));
        let Some(info) = info else {
            return (false, String::new(), -1);
        };
        let edad = salida::edad_db_dias(Some(&info), ahora_epoch());
        let aviso = salida::aviso_db(true, edad, salida::UMBRAL_DB_DIAS);
        let anterior = self.estado.ultimo_aviso.lock().unwrap().replace(aviso);
        if anterior != Some(aviso) {
            match aviso {
                AvisoDb::Antigua => {
                    tracing::warn!(edad, "la base de firmas de ClamAV está antigua")
                }
                AvisoDb::Desconocida => {
                    tracing::warn!("no se pudo saber la edad de la base de firmas de ClamAV")
                }
                AvisoDb::Ninguno => {}
            }
        }
        (true, info.motor, edad)
    }

    /// Lanza un análisis en segundo plano y devuelve su identificador.
    /// Solo rutas dentro de $HOME o de /tmp; los enlaces simbólicos que salgan de ahí se rechazan.
    async fn scan(
        &self,
        path: &str,
        #[zbus(signal_emitter)] emisor: SignalEmitter<'_>,
    ) -> Result<String, Error> {
        let programa = self.programa()?.to_path_buf();
        let ruta = validar_ruta_real(path).await?;
        let (id, cancelar_rx) = {
            let mut activos = self.estado.activos.lock().unwrap();
            if activos.len() >= MAX_ANALISIS {
                return Err(Error::DemasiadosAnalisis(format!(
                    "Ya hay {MAX_ANALISIS} análisis en curso; espera a que termine alguno"
                )));
            }
            let id = id_analisis(self.estado.siguiente.fetch_add(1, Ordering::Relaxed));
            let (tx, rx) = oneshot::channel();
            activos.insert(id.clone(), tx);
            (id, rx)
        };
        tracing::info!(%id, ruta = %ruta.display(), "análisis iniciado");
        tokio::spawn(tarea_analisis(
            self.estado.clone(),
            programa,
            ruta,
            id.clone(),
            cancelar_rx,
            emisor.to_owned(),
        ));
        Ok(id)
    }

    /// Cancela un análisis en curso.
    async fn cancel(&self, scan_id: &str) -> Result<(), Error> {
        let tx = self.estado.activos.lock().unwrap().remove(scan_id);
        match tx {
            Some(tx) => {
                let _ = tx.send(());
                tracing::info!(id = scan_id, "análisis cancelado");
                Ok(())
            }
            None => Err(Error::AnalisisDesconocido(format!(
                "No hay ningún análisis en curso con el identificador «{scan_id}»"
            ))),
        }
    }

    /// Archivos revisados hasta el momento (cada segundo como máximo).
    #[zbus(signal)]
    async fn progress(emisor: &SignalEmitter<'_>, scan_id: &str, scanned: u64) -> zbus::Result<()>;

    /// Fin del análisis: rutas infectadas y si terminó bien (`false` si se canceló o falló).
    #[zbus(signal)]
    async fn finished(
        emisor: &SignalEmitter<'_>,
        scan_id: &str,
        infected: Vec<String>,
        ok: bool,
    ) -> zbus::Result<()>;
}

async fn tarea_analisis(
    estado: Arc<Estado>,
    programa: PathBuf,
    ruta: PathBuf,
    id: String,
    cancelar: oneshot::Receiver<()>,
    emisor: SignalEmitter<'static>,
) {
    let (tx, mut rx) = mpsc::unbounded_channel();
    let id_prog = id.clone();
    let emisor_prog = emisor.clone();
    let reenviar = tokio::spawn(async move {
        while let Some(n) = rx.recv().await {
            if let Err(e) = Antivirus::progress(&emisor_prog, &id_prog, n).await {
                tracing::warn!(error = %e, "no se pudo emitir Progress");
            }
        }
    });
    let resultado = correr_clamscan(&programa, &ruta, cancelar, tx).await;
    let _ = reenviar.await; // vacía los Progress pendientes antes de Finished
    estado.activos.lock().unwrap().remove(&id);
    let (infectados, ok) = match resultado {
        Ok(r) => {
            for e in &r.acumulado.errores {
                tracing::warn!(id = %id, "{e}");
            }
            let ok = r.ok();
            tracing::info!(id = %id, ok, infectados = r.acumulado.infectados.len(), codigo = ?r.codigo, "análisis terminado");
            (r.acumulado.infectados, ok)
        }
        Err(e) => {
            tracing::error!(id = %id, error = %e, "no se pudo ejecutar clamscan");
            (Vec::new(), false)
        }
    };
    if let Err(e) = Antivirus::finished(&emisor, &id, infectados, ok).await {
        tracing::warn!(error = %e, "no se pudo emitir Finished");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;

    fn dir(n: &str) -> PathBuf {
        let d = std::env::temp_dir().join(format!("bc-av-{}-{n}", std::process::id()));
        let _ = std::fs::remove_dir_all(&d);
        std::fs::create_dir_all(&d).unwrap();
        d
    }

    fn falso(d: &Path, nombre: &str, cuerpo: &str) -> PathBuf {
        let p = d.join(nombre);
        std::fs::write(&p, format!("#!/bin/sh\n{cuerpo}\n")).unwrap();
        std::fs::set_permissions(&p, std::fs::Permissions::from_mode(0o755)).unwrap();
        p
    }

    async fn lanzar(prog: &Path) -> (std::io::Result<Resultado>, Vec<u64>) {
        let (_ctx, crx) = oneshot::channel();
        let (tx, mut rx) = mpsc::unbounded_channel();
        let r = correr_clamscan(prog, Path::new("/tmp/x"), crx, tx).await;
        let mut v = vec![];
        while let Some(n) = rx.recv().await {
            v.push(n);
        }
        (r, v)
    }

    #[test]
    fn argumentos_sin_seguir_enlaces() {
        let a = argumentos_clamscan(Path::new("/home/bc/Descargas"));
        let a: Vec<_> = a.iter().map(|s| s.to_str().unwrap()).collect();
        assert_eq!(a.last(), Some(&"/home/bc/Descargas"));
        assert!(a.contains(&"-r"));
        assert!(a.contains(&"--no-summary"));
        assert!(a.contains(&"--follow-dir-symlinks=0"));
        assert!(a.contains(&"--follow-file-symlinks=0"));
    }

    #[test]
    fn ids() {
        assert_eq!(id_analisis(1), "scan-1");
        assert_ne!(id_analisis(1), id_analisis(2));
    }

    #[test]
    fn path_busqueda() {
        let d = dir("path");
        let p = falso(&d, "clamscan", "exit 0");
        std::fs::write(d.join("noejecutable"), "x").unwrap();
        let ruta = format!("/nonexistent::{}", d.display());
        assert_eq!(buscar_en_path("clamscan", &ruta), Some(p));
        assert_eq!(buscar_en_path("noejecutable", &ruta), None);
        assert_eq!(buscar_en_path("clamscan", ""), None);
        assert_eq!(buscar_en_path("clamscan", "/nonexistent"), None);
    }

    #[tokio::test]
    async fn infectados() {
        let d = dir("inf");
        let p = falso(
            &d,
            "c1",
            "echo '/tmp/x/a: OK'; echo '/tmp/x/v: Eicar FOUND'; exit 1",
        );
        let (r, prog) = lanzar(&p).await;
        let r = r.unwrap();
        assert_eq!(r.acumulado.infectados, vec!["/tmp/x/v"]);
        assert_eq!(r.codigo, Some(1));
        assert!(r.ok());
        assert_eq!(prog.last(), Some(&2));
    }

    #[tokio::test]
    async fn limpio() {
        let d = dir("ok");
        let p = falso(&d, "c0", "echo '/tmp/x/a: OK'; exit 0");
        let (r, _) = lanzar(&p).await;
        let r = r.unwrap();
        assert!(r.acumulado.infectados.is_empty());
        assert!(r.ok());
    }

    #[tokio::test]
    async fn error_de_clamscan() {
        let d = dir("err");
        let p = falso(&d, "c2", "echo 'ERROR: algo'; exit 2");
        let (r, _) = lanzar(&p).await;
        let r = r.unwrap();
        assert_eq!(r.codigo, Some(2));
        assert!(!r.ok());
        assert_eq!(r.acumulado.errores.len(), 1);
    }

    #[tokio::test]
    async fn programa_inexistente() {
        let (r, _) = lanzar(Path::new("/nonexistent/clamscan")).await;
        assert!(r.is_err());
    }

    #[tokio::test]
    async fn cancelacion() {
        let d = dir("can");
        let p = falso(&d, "cs", "echo '/tmp/x/a: OK'; exec sleep 30");
        let (ctx, crx) = oneshot::channel();
        let (tx, _rx) = mpsc::unbounded_channel();
        let ruta = PathBuf::from("/tmp/x");
        let t = tokio::spawn(async move { correr_clamscan(&p, &ruta, crx, tx).await });
        tokio::time::sleep(Duration::from_millis(300)).await;
        ctx.send(()).unwrap();
        let r = tokio::time::timeout(Duration::from_secs(5), t)
            .await
            .expect("debe terminar al cancelar")
            .unwrap()
            .unwrap();
        assert!(r.cancelado);
        assert!(!r.ok());
    }

    #[tokio::test]
    async fn sin_clamscan() {
        let av = Antivirus::con_programa(None);
        assert_eq!(av.status().await, (false, String::new(), -1));
        assert!(matches!(av.programa(), Err(Error::NoDisponible(_))));
    }

    #[tokio::test]
    async fn estado_con_version_falsa() {
        let d = dir("ver");
        let p = falso(
            &d,
            "clamscan",
            "echo 'ClamAV 1.4.1/27500/Thu Jan  1 00:00:00 1970'",
        );
        let av = Antivirus::con_programa(Some(p));
        let (disp, ver, edad) = av.status().await;
        assert!(disp);
        assert_eq!(ver, "1.4.1");
        assert!(edad > 20_000);
    }

    #[tokio::test]
    async fn cancelar_desconocido() {
        let av = Antivirus::con_programa(None);
        assert!(matches!(
            av.cancel("scan-999").await,
            Err(Error::AnalisisDesconocido(_))
        ));
    }
}
