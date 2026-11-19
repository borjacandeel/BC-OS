//! BC Hardware Intelligence + política de BC Adaptive Renderer.
//!
//! Sondea el equipo (CPU, RAM, GPU y su controlador, nodo de render, máquina virtual, batería, temperatura y perfil de
//! energía) leyendo `/proc` y `/sys` bajo una raíz configurable (para probar con «máquinas» de prueba en disco), y lo
//! traduce a un único **nivel de calidad gráfica** para todo el sistema con sus **parámetros por efecto**. BC Shell,
//! las apps BC, el login y la integración con el compositor leen el resultado por D-Bus o de la caché en disco.

use std::fmt::Write as _;
use std::path::{Path, PathBuf};

/// Tipo de GPU según su controlador del kernel.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TipoGpu {
    Integrada,
    Dedicada,
    Virtual,
    Software,
}

impl TipoGpu {
    pub fn como_str(self) -> &'static str {
        match self {
            TipoGpu::Integrada => "integrada",
            TipoGpu::Dedicada => "dedicada",
            TipoGpu::Virtual => "virtual",
            TipoGpu::Software => "software",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Gpu {
    /// Identificador PCI del fabricante («0x8086»…) o vacío en SoC/plataforma
    pub vendor_id: String,
    pub fabricante: String,
    /// Módulo del kernel: i915, xe, amdgpu, radeon, nouveau, nvidia, v3d, vc4, virtio_gpu, vmwgfx…
    pub controlador: String,
    pub tipo: TipoGpu,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Perfil {
    pub arquitectura: String,
    pub nucleos: u32,
    /// Extensiones SIMD presentes (sse4_2, avx, avx2, avx512f, neon/asimd)
    pub simd: Vec<String>,
    pub ram_mb: u64,
    pub ram_libre_mb: u64,
    /// Todas las GPU con controlador; la primera es la que se usa para decidir (la de arranque si se sabe)
    pub gpus: Vec<Gpu>,
    /// Hay `/dev/dri/renderD*`: OpenGL/Vulkan por hardware posible
    pub nodo_render: bool,
    pub maquina_virtual: bool,
    /// (porcentaje, enchufado). `None` si no hay batería
    pub bateria: Option<(u8, bool)>,
    /// Temperatura máxima de las zonas térmicas/hwmon en °C
    pub temperatura: Option<f64>,
    /// power-profiles-daemon: power-saver, balanced, performance
    pub perfil_energia: Option<String>,
    pub kernel: String,
}

impl Perfil {
    pub fn gpu_principal(&self) -> Option<&Gpu> {
        self.gpus.first()
    }
    /// Huella que invalida la caché: cambia si cambia el hardware gráfico, su controlador o el kernel
    pub fn huella(&self) -> String {
        let g: Vec<String> = self.gpus.iter().map(|g| format!("{}:{}", g.vendor_id, g.controlador)).collect();
        format!("{}|{}|{}|{}|{}", self.arquitectura, self.nucleos, self.ram_mb / 1024, g.join(","), self.kernel)
    }
}

fn leer(raiz: &Path, rel: &str) -> Option<String> {
    std::fs::read_to_string(raiz.join(rel.trim_start_matches('/'))).ok().map(|s| s.trim().to_string())
}

fn hijos(raiz: &Path, rel: &str) -> Vec<PathBuf> {
    let mut v: Vec<PathBuf> = std::fs::read_dir(raiz.join(rel.trim_start_matches('/')))
        .map(|rd| rd.filter_map(|e| e.ok().map(|e| e.path())).collect())
        .unwrap_or_default();
    v.sort();
    v
}

fn fabricante(vid: &str, controlador: &str) -> &'static str {
    match vid {
        "0x8086" => "Intel",
        "0x1002" | "0x1022" => "AMD",
        "0x10de" => "NVIDIA",
        "0x15ad" => "VMware",
        "0x80ee" => "VirtualBox",
        "0x1af4" | "0x1b36" => "QEMU/virtio",
        "0x1234" => "QEMU (Bochs)",
        _ => match controlador {
            "v3d" | "vc4" => "Broadcom (Raspberry Pi)",
            "panfrost" | "panthor" => "Arm Mali",
            "msm" => "Qualcomm Adreno",
            "asahi" | "apple" => "Apple",
            _ => "desconocido",
        },
    }
}

/// Clasifica una GPU por su controlador del kernel.
pub fn tipo_por_controlador(controlador: &str) -> TipoGpu {
    match controlador {
        "i915" | "xe" | "v3d" | "vc4" | "panfrost" | "panthor" | "msm" | "lima" | "etnaviv" | "asahi" | "mediatek" => {
            TipoGpu::Integrada
        }
        "amdgpu" | "radeon" | "nouveau" | "nvidia" | "nvidia-drm" => TipoGpu::Dedicada,
        "virtio_gpu" | "virtio-gpu" | "vmwgfx" | "vboxvideo" | "qxl" | "bochs" | "bochs-drm" | "cirrus" | "hyperv_drm" => {
            TipoGpu::Virtual
        }
        _ => TipoGpu::Software,
    }
}

/// Sondea el equipo. `raiz` es `/` en un sistema real o una carpeta con la misma estructura en las pruebas.
pub fn sondear(raiz: &Path) -> Perfil {
    let cpuinfo = leer(raiz, "proc/cpuinfo").unwrap_or_default();
    let nucleos = cpuinfo.lines().filter(|l| l.split(':').next().map(str::trim) == Some("processor")).count() as u32;
    let flags: Vec<&str> = cpuinfo
        .lines()
        .find(|l| l.starts_with("flags") || l.starts_with("Features"))
        .and_then(|l| l.split_once(':'))
        .map(|(_, v)| v.split_whitespace().collect())
        .unwrap_or_default();
    let arquitectura = if flags.contains(&"asimd") || cpuinfo.contains("CPU implementer") {
        "aarch64"
    } else if flags.contains(&"lm") || flags.contains(&"sse2") {
        "x86_64"
    } else {
        std::env::consts::ARCH
    }
    .to_string();
    let simd: Vec<String> = ["sse4_2", "avx", "avx2", "avx512f", "asimd", "neon"]
        .iter()
        .filter(|f| flags.contains(f))
        .map(|f| if *f == "asimd" { "neon".to_string() } else { f.to_string() })
        .fold(Vec::new(), |mut v, f| {
            if !v.contains(&f) {
                v.push(f)
            }
            v
        });
    let meminfo = leer(raiz, "proc/meminfo").unwrap_or_default();
    let campo = |n: &str| -> u64 {
        meminfo
            .lines()
            .find_map(|l| l.strip_prefix(n)?.strip_prefix(':'))
            .and_then(|r| r.split_whitespace().next()?.parse().ok())
            .unwrap_or(0)
            / 1024
    };
    let ram_mb = campo("MemTotal");
    let ram_libre_mb = campo("MemAvailable");

    // GPU: /sys/class/drm/cardN/device/{vendor, driver → enlace al módulo}; la de arranque (boot_vga = 1) primero
    let mut gpus: Vec<(bool, Gpu)> = Vec::new();
    for card in hijos(raiz, "sys/class/drm") {
        let nombre = card.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
        if !nombre.starts_with("card") || nombre.contains('-') {
            continue; // card0-HDMI-A-1 son conectores
        }
        let dev = card.join("device");
        let controlador = std::fs::read_link(dev.join("driver"))
            .ok()
            .and_then(|p| p.file_name().map(|n| n.to_string_lossy().into_owned()))
            .or_else(|| std::fs::read_to_string(dev.join("driver_name")).ok().map(|s| s.trim().to_string()))
            .unwrap_or_default();
        if controlador.is_empty() {
            continue;
        }
        let vendor_id = std::fs::read_to_string(dev.join("vendor")).map(|s| s.trim().to_string()).unwrap_or_default();
        let boot = std::fs::read_to_string(dev.join("boot_vga")).map(|s| s.trim() == "1").unwrap_or(false);
        let tipo = tipo_por_controlador(&controlador);
        let g = Gpu { fabricante: fabricante(&vendor_id, &controlador).to_string(), vendor_id, controlador, tipo };
        if !gpus.iter().any(|(_, x)| *x == g) {
            gpus.push((boot, g));
        }
    }
    gpus.sort_by_key(|(boot, g)| (!boot, matches!(g.tipo, TipoGpu::Virtual | TipoGpu::Software)));
    let gpus: Vec<Gpu> = gpus.into_iter().map(|(_, g)| g).collect();
    let nodo_render = hijos(raiz, "dev/dri")
        .iter()
        .any(|p| p.file_name().is_some_and(|n| n.to_string_lossy().starts_with("renderD")));

    let dmi = format!(
        "{} {} {}",
        leer(raiz, "sys/class/dmi/id/sys_vendor").unwrap_or_default(),
        leer(raiz, "sys/class/dmi/id/product_name").unwrap_or_default(),
        leer(raiz, "sys/class/dmi/id/board_vendor").unwrap_or_default()
    )
    .to_lowercase();
    let maquina_virtual = flags.contains(&"hypervisor")
        || gpus.iter().any(|g| g.tipo == TipoGpu::Virtual)
        || ["virtualbox", "innotek", "qemu", "vmware", "parallels", "kvm", "hyper-v", "utm", "apple virtualization"]
            .iter()
            .any(|s| dmi.contains(s));

    let mut bateria = None;
    let mut enchufado = false;
    for ps in hijos(raiz, "sys/class/power_supply") {
        let tipo = std::fs::read_to_string(ps.join("type")).unwrap_or_default();
        if tipo.trim() == "Mains" && std::fs::read_to_string(ps.join("online")).map(|s| s.trim() == "1").unwrap_or(false) {
            enchufado = true;
        }
        if tipo.trim() == "Battery" && bateria.is_none() {
            let cap = std::fs::read_to_string(ps.join("capacity")).ok().and_then(|s| s.trim().parse::<u8>().ok());
            let estado = std::fs::read_to_string(ps.join("status")).unwrap_or_default();
            if let Some(c) = cap {
                bateria = Some((c, estado.trim() == "Charging" || estado.trim() == "Full"));
            }
        }
    }
    if let Some((c, cargando)) = bateria {
        bateria = Some((c, cargando || enchufado));
    }

    let mut temps: Vec<f64> = Vec::new();
    for z in hijos(raiz, "sys/class/thermal") {
        if z.file_name().is_some_and(|n| n.to_string_lossy().starts_with("thermal_zone")) {
            if let Some(t) = std::fs::read_to_string(z.join("temp")).ok().and_then(|s| s.trim().parse::<f64>().ok()) {
                temps.push(t / 1000.0);
            }
        }
    }
    for h in hijos(raiz, "sys/class/hwmon") {
        for f in hijos(raiz, &format!("sys/class/hwmon/{}", h.file_name().unwrap_or_default().to_string_lossy())) {
            let n = f.file_name().unwrap_or_default().to_string_lossy().into_owned();
            if n.starts_with("temp") && n.ends_with("_input") {
                if let Some(t) = std::fs::read_to_string(&f).ok().and_then(|s| s.trim().parse::<f64>().ok()) {
                    temps.push(t / 1000.0);
                }
            }
        }
    }
    let temperatura = temps.into_iter().filter(|t| *t > 0.0 && *t < 150.0).fold(None, |m: Option<f64>, t| {
        Some(m.map_or(t, |m| m.max(t)))
    });
    let perfil_energia = leer(raiz, "var/lib/power-profiles-daemon/state.ini")
        .and_then(|s| s.lines().find_map(|l| l.strip_prefix("Profile=").map(str::to_string)));
    let kernel = leer(raiz, "proc/sys/kernel/osrelease").unwrap_or_default();

    Perfil {
        arquitectura,
        nucleos,
        simd,
        ram_mb,
        ram_libre_mb,
        gpus,
        nodo_render,
        maquina_virtual,
        bateria,
        temperatura,
        perfil_energia,
        kernel,
    }
}

/// Niveles de calidad, de más a menos.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Nivel {
    Minimo = 0,
    Eficiente = 1,
    Equilibrado = 2,
    Alto = 3,
    Ultra = 4,
}

impl Nivel {
    pub const TODOS: [Nivel; 5] = [Nivel::Ultra, Nivel::Alto, Nivel::Equilibrado, Nivel::Eficiente, Nivel::Minimo];
    pub fn como_str(self) -> &'static str {
        match self {
            Nivel::Ultra => "ultra",
            Nivel::Alto => "alto",
            Nivel::Equilibrado => "equilibrado",
            Nivel::Eficiente => "eficiente",
            Nivel::Minimo => "minimo",
        }
    }
    pub fn desde_str(s: &str) -> Option<Nivel> {
        Nivel::TODOS.into_iter().find(|n| n.como_str() == s.trim().to_lowercase())
    }
    fn bajar(self, pasos: u8) -> Nivel {
        let v = (self as u8).saturating_sub(pasos);
        Nivel::TODOS.into_iter().find(|n| *n as u8 == v).unwrap_or(Nivel::Minimo)
    }
}

/// Nivel que permite el hardware (sin contar energía ni temperatura).
pub fn nivel_base(p: &Perfil) -> Nivel {
    let pocos_recursos = p.ram_mb > 0 && p.ram_mb < 3500 || p.nucleos > 0 && p.nucleos <= 2;
    match p.gpu_principal() {
        _ if !p.nodo_render => {
            if pocos_recursos {
                Nivel::Minimo
            } else {
                Nivel::Eficiente
            }
        }
        None => Nivel::Eficiente,
        Some(g) => match g.tipo {
            // VirtualBox/VMware/QEMU: la «3D» virtual (o llvmpipe) no da para lente ni capas grandes
            TipoGpu::Virtual | TipoGpu::Software => {
                if pocos_recursos {
                    Nivel::Minimo
                } else {
                    Nivel::Eficiente
                }
            }
            TipoGpu::Integrada => {
                if matches!(g.controlador.as_str(), "v3d" | "vc4" | "lima" | "etnaviv") || p.ram_mb < 6000 {
                    Nivel::Equilibrado // Raspberry Pi y equipos con poca memoria
                } else {
                    Nivel::Alto
                }
            }
            // nouveau sin reloj de la GPU va al mínimo de frecuencias: mejor sin las capas más caras
            TipoGpu::Dedicada if g.controlador == "nouveau" => Nivel::Equilibrado,
            TipoGpu::Dedicada => {
                if p.ram_mb < 6000 {
                    Nivel::Alto
                } else {
                    Nivel::Ultra
                }
            }
        },
    }
}

/// Estado dinámico (energía y temperatura) con histéresis: guarda si ya se había rebajado para no oscilar.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Rebaja {
    pub bateria: bool,
    pub calor: u8,
    /// Las apps informan de fotogramas perdidos de forma sostenida (`ReportarFotogramas`)
    pub fotogramas: bool,
}

/// Calcula las rebajas por energía y temperatura. Para subir de nuevo hace falta pasar el umbral con margen
/// (batería ≥ 40 % o enchufado; temperatura 6 °C por debajo).
pub fn rebajas(p: &Perfil, antes: Rebaja) -> Rebaja {
    let bateria = match p.bateria {
        Some((c, false)) => {
            let ahorro = p.perfil_energia.as_deref() == Some("power-saver");
            if antes.bateria {
                c < 40 || ahorro
            } else {
                c < 30 || ahorro
            }
        }
        _ => p.perfil_energia.as_deref() == Some("power-saver"),
    };
    let calor = match p.temperatura {
        Some(t) => {
            let m = if antes.calor > 0 { 6.0 } else { 0.0 };
            if t >= 95.0 - m {
                2
            } else if t >= 85.0 - m {
                1
            } else {
                0
            }
        }
        None => 0,
    };
    Rebaja { bateria, calor, fotogramas: antes.fotogramas }
}

/// Nivel efectivo: el del hardware rebajado por energía/temperatura, o el forzado por el usuario
/// (`~/.config/bc/calidad` o `BC_RENDER_TIER`), que nunca sube por encima de lo que el equipo puede.
pub fn nivel(p: &Perfil, r: Rebaja, forzado: Option<Nivel>) -> Nivel {
    let base = nivel_base(p);
    let n = base.bajar(r.bateria as u8 + r.calor + r.fotogramas as u8);
    match forzado {
        // El usuario puede pedir menos que el equipo siempre; más, solo si hay GPU de verdad
        Some(f) if f <= base || (p.nodo_render && p.gpu_principal().is_some_and(|g| matches!(g.tipo, TipoGpu::Integrada | TipoGpu::Dedicada))) => f.min(Nivel::Ultra),
        _ => n,
    }
}

/// Parámetros concretos de cada efecto para un nivel y un compositor («hyprland», «swayfx», «sway» o «x11»).
#[derive(Debug, Clone, PartialEq)]
pub struct Parametros {
    pub nivel: Nivel,
    /// Backend de Qt Quick recomendado: «vulkan», «opengl» o «software»
    pub backend: &'static str,
    pub vidrio_lente: bool,
    pub vidrio_aberracion: bool,
    /// Desenfoque del fondo precalculado (px a 1080p); el del compositor va aparte
    pub vidrio_blur_px: u32,
    /// El compositor desenfoca de verdad lo que hay detrás de las superficies (solo Hyprland)
    pub vidrio_blur_real: bool,
    pub translucidez: bool,
    /// 0 sin sombras, 1 sombra simple, 2 sombra en capas
    pub sombras: u8,
    /// Multiplicador de duraciones (0 = sin animaciones)
    pub animaciones: f32,
    pub genio: bool,
    pub antialias: bool,
    pub texturas_mb: u32,
    pub capas_offscreen: u32,
    pub compositor_blur: (u32, u32),
    pub compositor_sombras: bool,
    pub compositor_animaciones: bool,
    pub radio_esquinas: u32,
}

pub fn parametros(n: Nivel, compositor: &str, gpu_real: bool) -> Parametros {
    let hypr = compositor == "hyprland";
    let fx = compositor == "swayfx" || hypr;
    let (lente, aberr, blur, transl, sombras, anim, genio, tex, capas, cblur) = match n {
        Nivel::Ultra => (true, true, 32, true, 2, 1.0, true, 512, 8, (10, 3)),
        Nivel::Alto => (true, true, 30, true, 2, 1.0, true, 384, 6, (8, 3)),
        Nivel::Equilibrado => (true, false, 26, true, 1, 1.0, true, 256, 4, (6, 2)),
        Nivel::Eficiente => (false, false, 22, true, 1, 0.85, false, 160, 2, (4, 1)),
        Nivel::Minimo => (false, false, 18, false, 0, 0.7, false, 96, 1, (0, 0)),
    };
    Parametros {
        nivel: n,
        backend: if gpu_real { "opengl" } else { "software" },
        vidrio_lente: lente,
        vidrio_aberracion: aberr,
        vidrio_blur_px: blur,
        vidrio_blur_real: hypr && cblur.0 > 0,
        translucidez: transl,
        sombras,
        animaciones: anim,
        genio: genio && gpu_real,
        antialias: n >= Nivel::Equilibrado,
        texturas_mb: tex,
        capas_offscreen: capas,
        compositor_blur: if fx { cblur } else { (0, 0) },
        compositor_sombras: fx && sombras > 0,
        compositor_animaciones: hypr && n >= Nivel::Eficiente,
        radio_esquinas: 12,
    }
}

fn esc(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

/// JSON del perfil y del nivel (lo leen BC Shell, bc-render-apply y la caché).
pub fn json(p: &Perfil, r: Rebaja, n: Nivel, par: &Parametros, compositor: &str) -> String {
    let mut s = String::from("{");
    let _ = write!(s, "\"version\":1,\"huella\":\"{}\",", esc(&p.huella()));
    let _ = write!(s, "\"arquitectura\":\"{}\",\"nucleos\":{},\"simd\":[{}],", esc(&p.arquitectura), p.nucleos,
        p.simd.iter().map(|x| format!("\"{x}\"")).collect::<Vec<_>>().join(","));
    let _ = write!(s, "\"ram_mb\":{},\"ram_libre_mb\":{},", p.ram_mb, p.ram_libre_mb);
    let gp: Vec<String> = p
        .gpus
        .iter()
        .map(|g| format!("{{\"fabricante\":\"{}\",\"vendor_id\":\"{}\",\"controlador\":\"{}\",\"tipo\":\"{}\"}}",
            esc(&g.fabricante), esc(&g.vendor_id), esc(&g.controlador), g.tipo.como_str()))
        .collect();
    let _ = write!(s, "\"gpus\":[{}],\"nodo_render\":{},\"maquina_virtual\":{},", gp.join(","), p.nodo_render, p.maquina_virtual);
    match p.bateria {
        Some((c, e)) => {
            let _ = write!(s, "\"bateria\":{c},\"enchufado\":{e},");
        }
        None => s.push_str("\"bateria\":null,\"enchufado\":true,"),
    }
    match p.temperatura {
        Some(t) => {
            let _ = write!(s, "\"temperatura\":{t:.1},");
        }
        None => s.push_str("\"temperatura\":null,"),
    }
    let _ = write!(s, "\"perfil_energia\":\"{}\",\"kernel\":\"{}\",", esc(p.perfil_energia.as_deref().unwrap_or("")), esc(&p.kernel));
    let _ = write!(s, "\"rebaja_fotogramas\":{},", r.fotogramas);
    let _ = write!(s, "\"rebaja_bateria\":{},\"rebaja_calor\":{},\"compositor\":\"{}\",\"nivel_base\":\"{}\",\"nivel\":\"{}\",",
        r.bateria, r.calor, esc(compositor), nivel_base(p).como_str(), n.como_str());
    let _ = write!(
        s,
        "\"parametros\":{{\"backend\":\"{}\",\"vidrio_lente\":{},\"vidrio_aberracion\":{},\"vidrio_blur_px\":{},\
         \"vidrio_blur_real\":{},\"translucidez\":{},\"sombras\":{},\"animaciones\":{:.2},\"genio\":{},\"antialias\":{},\
         \"texturas_mb\":{},\"capas_offscreen\":{},\"compositor_blur_size\":{},\"compositor_blur_passes\":{},\
         \"compositor_sombras\":{},\"compositor_animaciones\":{},\"radio_esquinas\":{}}}}}",
        par.backend, par.vidrio_lente, par.vidrio_aberracion, par.vidrio_blur_px, par.vidrio_blur_real, par.translucidez,
        par.sombras, par.animaciones, par.genio, par.antialias, par.texturas_mb, par.capas_offscreen,
        par.compositor_blur.0, par.compositor_blur.1, par.compositor_sombras, par.compositor_animaciones, par.radio_esquinas
    );
    s
}

/// Nivel forzado por el usuario: `BC_RENDER_TIER` o `~/.config/bc/calidad` («auto» o vacío = automático).
pub fn nivel_forzado(config: Option<&Path>) -> Option<Nivel> {
    if let Ok(v) = std::env::var("BC_RENDER_TIER") {
        if let Some(n) = Nivel::desde_str(&v) {
            return Some(n);
        }
    }
    config.and_then(|c| std::fs::read_to_string(c.join("bc/calidad")).ok()).and_then(|s| Nivel::desde_str(&s))
}

/// Compositor de la sesión: el que anuncia bc-session (`BC_COMPOSITOR`, `BC_FX`) o X11 en la sesión bspwm.
pub fn compositor_actual() -> String {
    if std::env::var("HYPRLAND_INSTANCE_SIGNATURE").is_ok() || std::env::var("BC_COMPOSITOR").as_deref() == Ok("hyprland") {
        return "hyprland".into();
    }
    if std::env::var("XDG_SESSION_TYPE").as_deref() == Ok("x11") {
        return "x11".into();
    }
    if std::env::var("BC_FX").is_ok() {
        return "swayfx".into();
    }
    "sway".into()
}

/// Calcula todo y devuelve (nivel, json).
pub fn evaluar(raiz: &Path, config: Option<&Path>, antes: Rebaja, compositor: &str) -> (Nivel, Rebaja, String) {
    let p = sondear(raiz);
    let r = rebajas(&p, antes);
    let n = nivel(&p, r, nivel_forzado(config));
    let gpu_real = p.nodo_render && p.gpu_principal().is_some_and(|g| matches!(g.tipo, TipoGpu::Integrada | TipoGpu::Dedicada));
    let par = parametros(n, compositor, gpu_real);
    (n, r, json(&p, r, n, &par, compositor))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    /// Monta una «máquina» de prueba en disco con la estructura de /proc y /sys.
    struct Maquina(PathBuf);
    impl Maquina {
        fn nueva(nombre: &str) -> Self {
            let d = std::env::temp_dir().join(format!("bc-render-{}-{nombre}", std::process::id()));
            let _ = fs::remove_dir_all(&d);
            fs::create_dir_all(&d).unwrap();
            Maquina(d)
        }
        fn f(&self, rel: &str, contenido: &str) -> &Self {
            let p = self.0.join(rel);
            fs::create_dir_all(p.parent().unwrap()).unwrap();
            fs::write(p, contenido).unwrap();
            self
        }
        fn cpu(&self, n: u32, flags: &str) -> &Self {
            let mut s = String::new();
            for i in 0..n {
                s += &format!("processor\t: {i}\n{flags}\n\n");
            }
            self.f("proc/cpuinfo", &s)
        }
        fn ram(&self, mb: u64) -> &Self {
            self.f("proc/meminfo", &format!("MemTotal: {} kB\nMemAvailable: {} kB\n", mb * 1024, mb * 512))
        }
        fn gpu(&self, card: &str, vendor: &str, driver: &str, boot: bool) -> &Self {
            let dev = self.0.join(format!("sys/class/drm/{card}/device"));
            fs::create_dir_all(&dev).unwrap();
            fs::write(dev.join("vendor"), vendor).unwrap();
            fs::write(dev.join("boot_vga"), if boot { "1" } else { "0" }).unwrap();
            let drv = self.0.join(format!("sys/bus/pci/drivers/{driver}"));
            fs::create_dir_all(&drv).unwrap();
            let _ = std::os::unix::fs::symlink(&drv, dev.join("driver"));
            self
        }
        fn render(&self) -> &Self {
            self.f("dev/dri/renderD128", "")
        }
        fn dmi(&self, vendor: &str) -> &Self {
            self.f("sys/class/dmi/id/sys_vendor", vendor)
        }
        fn bateria(&self, cap: u8, estado: &str, ac: bool) -> &Self {
            self.f("sys/class/power_supply/BAT0/type", "Battery")
                .f("sys/class/power_supply/BAT0/capacity", &cap.to_string())
                .f("sys/class/power_supply/BAT0/status", estado)
                .f("sys/class/power_supply/AC/type", "Mains")
                .f("sys/class/power_supply/AC/online", if ac { "1" } else { "0" })
        }
        fn temp(&self, c: f64) -> &Self {
            self.f("sys/class/thermal/thermal_zone0/temp", &((c * 1000.0) as i64).to_string())
        }
        fn eval(&self) -> (Nivel, Rebaja, String) {
            evaluar(&self.0, None, Rebaja::default(), "sway")
        }
    }
    impl Drop for Maquina {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }

    const X86: &str = "flags\t\t: fpu sse2 lm sse4_2 avx avx2";
    const ARM: &str = "Features\t: fp asimd evtstrm\nCPU implementer\t: 0x41";

    #[test]
    fn virtualbox_mac_arm_sin_3d() {
        let m = Maquina::nueva("vbox-arm");
        m.cpu(4, ARM).ram(4096).gpu("card0", "0x15ad", "vmwgfx", true).dmi("innotek GmbH");
        let (n, _, j) = m.eval();
        assert_eq!(n, Nivel::Eficiente);
        let p = sondear(&m.0);
        assert!(p.maquina_virtual);
        assert_eq!(p.arquitectura, "aarch64");
        assert_eq!(p.simd, vec!["neon"]);
        assert!(j.contains("\"backend\":\"software\"") && j.contains("\"genio\":false") && j.contains("\"vidrio_lente\":false"));
    }

    #[test]
    fn vm_x86_pequena_minimo() {
        let m = Maquina::nueva("vm-x86");
        m.cpu(2, &format!("{X86} hypervisor")).ram(2048).gpu("card0", "0x80ee", "vboxvideo", true);
        assert_eq!(m.eval().0, Nivel::Minimo);
    }

    #[test]
    fn raspberry_pi() {
        let m = Maquina::nueva("rpi");
        m.cpu(4, ARM).ram(4096).render().gpu("card1", "", "v3d", false).gpu("card0", "", "vc4", false);
        let p = sondear(&m.0);
        assert_eq!(p.gpus[0].fabricante, "Broadcom (Raspberry Pi)");
        assert_eq!(m.eval().0, Nivel::Equilibrado);
    }

    #[test]
    fn portatil_intel() {
        let m = Maquina::nueva("intel");
        m.cpu(8, X86).ram(32000).render().gpu("card0", "0x8086", "i915", true).bateria(80, "Discharging", false).temp(55.0);
        let (n, r, j) = m.eval();
        assert_eq!(n, Nivel::Alto);
        assert_eq!(r, Rebaja::default());
        assert!(j.contains("\"backend\":\"opengl\"") && j.contains("\"genio\":true"));
        let p = sondear(&m.0);
        assert_eq!(p.simd, vec!["sse4_2", "avx", "avx2"]);
        assert_eq!(p.bateria, Some((80, false)));
    }

    #[test]
    fn nvidia_nouveau_equilibrado() {
        let m = Maquina::nueva("nouveau");
        m.cpu(4, X86).ram(8000).render().gpu("card0", "0x10de", "nouveau", true);
        assert_eq!(m.eval().0, Nivel::Equilibrado);
    }

    #[test]
    fn amd_dedicada_ultra_y_arranque_primero() {
        let m = Maquina::nueva("amd");
        m.cpu(12, X86).ram(32000).render().gpu("card1", "0x8086", "i915", false).gpu("card0", "0x1002", "amdgpu", true);
        let p = sondear(&m.0);
        assert_eq!(p.gpus[0].controlador, "amdgpu");
        assert_eq!(m.eval().0, Nivel::Ultra);
    }

    #[test]
    fn bateria_baja_y_calor_con_histeresis() {
        let m = Maquina::nueva("calor");
        m.cpu(8, X86).ram(16000).render().gpu("card0", "0x8086", "i915", true).bateria(20, "Discharging", false).temp(90.0);
        let (n, r, _) = m.eval();
        assert_eq!(r, Rebaja { bateria: true, calor: 1, fotogramas: false });
        assert_eq!(n, Nivel::Eficiente); // Alto − batería − calor
        // A 35 % y 82 °C no se sube todavía (histéresis); a 45 % y 70 °C sí
        m.bateria(35, "Discharging", false).temp(82.0);
        let r2 = rebajas(&sondear(&m.0), r);
        assert_eq!(r2, Rebaja { bateria: true, calor: 1, fotogramas: false });
        m.bateria(45, "Discharging", false).temp(70.0);
        assert_eq!(rebajas(&sondear(&m.0), r2), Rebaja::default());
        // Enchufado no rebaja por batería
        m.bateria(10, "Charging", true).temp(40.0);
        assert_eq!(rebajas(&sondear(&m.0), Rebaja::default()), Rebaja::default());
    }

    #[test]
    fn forzado_no_sube_sin_gpu() {
        let m = Maquina::nueva("forzado");
        m.cpu(4, ARM).ram(4096).gpu("card0", "0x15ad", "vmwgfx", true);
        let p = sondear(&m.0);
        assert_eq!(nivel(&p, Rebaja::default(), Some(Nivel::Ultra)), Nivel::Eficiente);
        assert_eq!(nivel(&p, Rebaja::default(), Some(Nivel::Minimo)), Nivel::Minimo);
    }

    #[test]
    fn parametros_por_compositor() {
        let h = parametros(Nivel::Alto, "hyprland", true);
        assert!(h.vidrio_blur_real && h.compositor_animaciones && h.compositor_blur == (8, 3));
        let s = parametros(Nivel::Alto, "sway", true);
        assert!(!s.vidrio_blur_real && s.compositor_blur == (0, 0) && !s.compositor_sombras);
        let x = parametros(Nivel::Minimo, "x11", false);
        assert!(!x.translucidez && x.sombras == 0 && !x.genio);
        assert_eq!(Nivel::desde_str(" Equilibrado\n"), Some(Nivel::Equilibrado));
    }

    #[test]
    fn huella_cambia_con_el_controlador() {
        let m = Maquina::nueva("huella");
        m.cpu(4, X86).ram(8000).render().gpu("card0", "0x8086", "i915", true);
        let a = sondear(&m.0).huella();
        let _ = fs::remove_file(m.0.join("sys/class/drm/card0/device/driver"));
        m.gpu("card0", "0x8086", "xe", true);
        assert_ne!(a, sondear(&m.0).huella());
    }
}

/// Ruta de la caché del perfil: `$XDG_CACHE_HOME/bc/render-profile.json` o `~/.cache/bc/render-profile.json`.
pub fn ruta_cache() -> Option<PathBuf> {
    std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".cache")))
        .map(|c| c.join("bc/render-profile.json"))
}

/// Carpeta de configuración del usuario (para `bc/calidad`).
pub fn ruta_config() -> Option<PathBuf> {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".config")))
}

/// Escribe la caché de forma atómica (temporal + rename) solo si cambia.
pub fn guardar_cache(ruta: &Path, json: &str) -> std::io::Result<bool> {
    if std::fs::read_to_string(ruta).ok().as_deref() == Some(json) {
        return Ok(false);
    }
    if let Some(d) = ruta.parent() {
        std::fs::create_dir_all(d)?;
    }
    let tmp = ruta.with_extension("json.tmp");
    std::fs::write(&tmp, json)?;
    std::fs::rename(&tmp, ruta)?;
    Ok(true)
}

/// Estado del servicio: rebajas vigentes, nivel y JSON publicado. Los informes de fotogramas se acumulan en una
/// ventana: tres informes malos seguidos (≥ 8 % perdidos) rebajan un nivel; seis buenos (≤ 1 %) lo devuelven.
#[derive(Debug, Clone)]
pub struct Estado {
    pub raiz: PathBuf,
    pub rebaja: Rebaja,
    pub nivel: Nivel,
    pub json: String,
    malos: u8,
    buenos: u8,
}

impl Estado {
    pub fn nuevo(raiz: PathBuf) -> Self {
        let mut e = Estado { raiz, rebaja: Rebaja::default(), nivel: Nivel::Equilibrado, json: String::new(), malos: 0, buenos: 0 };
        e.reevaluar();
        e
    }
    /// Recalcula; devuelve `true` si el nivel ha cambiado.
    pub fn reevaluar(&mut self) -> bool {
        let (n, r, j) = evaluar(&self.raiz, ruta_config().as_deref(), self.rebaja, &compositor_actual());
        let cambio = n != self.nivel || self.json.is_empty();
        self.nivel = n;
        self.rebaja = r;
        self.json = j;
        if let Some(c) = ruta_cache() {
            if let Err(e) = guardar_cache(&c, &self.json) {
                tracing::warn!(error = %e, "no se pudo guardar la caché del perfil gráfico");
            }
        }
        cambio
    }
    /// Informe de una app: media del tiempo de fotograma y porcentaje de fotogramas perdidos en su última ventana.
    pub fn reportar(&mut self, _media_ms: f64, perdidos_pct: f64) -> bool {
        if perdidos_pct >= 8.0 {
            self.malos = self.malos.saturating_add(1);
            self.buenos = 0;
        } else if perdidos_pct <= 1.0 {
            self.buenos = self.buenos.saturating_add(1);
            self.malos = 0;
        }
        let antes = self.rebaja.fotogramas;
        if self.malos >= 3 {
            self.rebaja.fotogramas = true;
        } else if self.buenos >= 6 {
            self.rebaja.fotogramas = false;
        }
        if antes != self.rebaja.fotogramas {
            self.malos = 0;
            self.buenos = 0;
            return self.reevaluar() || true;
        }
        false
    }
}

#[cfg(test)]
mod tests_estado {
    use super::*;

    #[test]
    fn informes_de_fotogramas_con_histeresis() {
        let d = std::env::temp_dir().join(format!("bc-render-estado-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&d);
        std::fs::create_dir_all(d.join("proc")).unwrap();
        std::fs::write(d.join("proc/cpuinfo"), "processor\t: 0\nprocessor\t: 1\nprocessor\t: 2\nprocessor\t: 3\nflags\t: sse2 lm\n").unwrap();
        std::fs::write(d.join("proc/meminfo"), "MemTotal: 8000000 kB\n").unwrap();
        std::env::set_var("XDG_CACHE_HOME", d.join("cache"));
        std::env::set_var("XDG_CONFIG_HOME", d.join("config"));
        let mut e = Estado::nuevo(d.clone());
        assert_eq!(e.nivel, Nivel::Eficiente);
        assert!(d.join("cache/bc/render-profile.json").exists());
        assert!(!e.reportar(20.0, 12.0) && !e.reportar(20.0, 12.0));
        assert!(e.reportar(20.0, 12.0));
        assert_eq!(e.nivel, Nivel::Minimo);
        for _ in 0..5 {
            assert!(!e.reportar(5.0, 0.0));
        }
        assert!(e.reportar(5.0, 0.0));
        assert_eq!(e.nivel, Nivel::Eficiente);
        // El usuario fuerza «mínimo» desde Ajustes
        std::fs::create_dir_all(d.join("config/bc")).unwrap();
        std::fs::write(d.join("config/bc/calidad"), "minimo\n").unwrap();
        assert!(e.reevaluar());
        assert!(e.json.contains("\"nivel\":\"minimo\""));
        let _ = std::fs::remove_dir_all(&d);
    }
}
