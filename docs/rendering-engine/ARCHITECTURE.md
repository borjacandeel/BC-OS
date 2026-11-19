# BC RENDERING ENGINE — arquitectura

> *Adaptive. Native. Efficient.* Un único criterio de calidad gráfica para todo BC OS: panel, apps BC, login,
> instalador y compositor.

## Visión general

```
             /proc, /sys, /dev/dri, power-profiles-daemon
                              │  (raíz configurable: BC_HW_ROOT / pruebas)
                              ▼
┌──────────────── BC Core (Rust) · bc-hardware-service ────────────────┐
│ BC Hardware Intelligence  render::sondear → Perfil                   │
│   CPU/SIMD, RAM, GPU (+controlador, tipo), nodo render, VM,          │
│   batería, temperatura, perfil de energía, huella                    │
│ Política (BC Adaptive Renderer)                                      │
│   nivel_base(Perfil) → rebajas(energía, calor, fotogramas)           │
│   → nivel efectivo (+ preferencia ~/.config/bc/calidad)              │
│   → parametros(nivel, compositor)                                    │
│ Monitor único cada 20 s · caché ~/.cache/bc/render-profile.json      │
│ D-Bus org.bcos.Hardware1: PerfilRender, NivelRender,                 │
│   ReevaluarRender, ReportarFotogramas · señal NivelRenderCambiado    │
└───────────────┬───────────────────────────────────┬──────────────────┘
                │ D-Bus (250 ms máx.) / caché         │ caché / D-Bus
                ▼                                     ▼
┌──── RenderEngine (Qt, cada proceso BC) ────┐   ┌── bc-render-apply ──┐
│ configureBackend(): vulkan→opengl→software │   │ Hyprland: hyprctl   │
│ singleton QML «Render»: nivel + parámetros │   │   eval hl.config    │
│ medida de fotogramas → ReportarFotogramas  │   │ swayfx: swaymsg     │
│ Ajustes ▸ Pantallas ▸ Calidad gráfica      │   │ sway/X11: nada      │
└──────┬─────────────────────────────────────┘   └─────────────────────┘
       ▼
 Theme.d()/dur() × animScale · Glass (lente, sombras) · GlassProvider (radio, caché en disco)
 Genio · escalados de ventanas y paneles (SlideIn, AppWindow)
```

## Decisiones (ADR)

- **ADR-1 — El perfil vive en BC Core.** Se amplía `bc-hardware-service` (`org.bcos.Hardware1`) en lugar de crear un
  servicio paralelo. Un solo monitor de baja frecuencia (20 s) para todo el sistema; los procesos Qt no sondean.
- **ADR-2 — Tres fuentes con orden fijo.** BC Core por D-Bus (como mucho 250 ms al arrancar) → caché en disco →
  valores seguros locales. El login (sin bus de sesión del usuario) y las apps sin BC Core siguen funcionando.
- **ADR-3 — El nivel nunca supera al backend.** Por software (VM sin 3D) el techo es «Eficiente», aunque se fuerce con
  `BC_RENDER_TIER` o en Ajustes. BC Core aplica la misma regla con la GPU detectada.
- **ADR-4 — Sin plugins nuevos de Hyprland.** La integración usa solo IPC (`hyprctl eval`, `swaymsg`). bspwm/X11 no
  se toca.
- **ADR-5 — Materiales sin shaders compilados.** El host de desarrollo no tiene `qsb` (Qt Shader Tools) y el backend
  software de Qt Quick ignora los nodos de geometría propios. El Liquid Glass sigue siendo CPU + imagen (GlassProvider)
  con variantes por nivel (lente, aberración, radio, sombras). Ver «Limitaciones».

## Niveles y parámetros

| Parámetro | Ultra | Alto | Equilibrado | Eficiente | Mínimo |
|---|---|---|---|---|---|
| Lente del cristal | sí | sí | sí | no | no |
| Aberración cromática | sí | sí | no | no | no |
| Desenfoque precalculado (px a 1080p) | 32 | 30 | 26 | 22 | 18 |
| Translucidez | sí | sí | sí | sí | no |
| Sombras (capas) | 2 | 2 | 1 | 1 | 0 |
| Duración de animaciones | ×1 | ×1 | ×1 | ×0,85 | ×0,7 |
| Genio (solo con GPU) | sí | sí | sí | no | no |
| Antialias | sí | sí | sí | no | no |
| Texturas (MB) / capas offscreen | 512/8 | 384/6 | 256/4 | 160/2 | 96/1 |
| Compositor: desenfoque tamaño×pasadas | 10×3 | 8×3 | 6×2 | 4×1 | — |

**Nivel del hardware** (`nivel_base`):

- GPU dedicada: Ultra (Alto con menos de 6 GB).
- nouveau: Equilibrado.
- Integrada: Alto (Equilibrado en Raspberry Pi o con menos de 6 GB).
- Virtual o por software: Eficiente (Mínimo con 2 núcleos o menos o con menos de 3,5 GB).
- Sin nodo de render: igual que por software.

**Rebajas con histéresis:**

| Motivo | Baja | Vuelve |
|---|---|---|
| Batería sin cargador | por debajo del 30 % (o con power-saver), 1 nivel | desde el 40 % |
| Temperatura | desde 85 °C, 1 nivel; desde 95 °C, 2 niveles | 6 °C por debajo |
| Fotogramas | 3 ventanas seguidas de 180 fotogramas con ≥ 8 % por encima de 16,7 ms, 1 nivel | 6 ventanas con ≤ 1 % |

## Backend de Qt Quick por proceso

`RenderEngine::configureBackend()` se llama antes de crear `QGuiApplication` (bc-shell en modo panel y app, y
bc-greeter). La petición se toma, por orden, de:

1. `BC_RENDER_BACKEND`;
2. `QT_QUICK_BACKEND=software` de la sesión;
3. `parametros.backend` del perfil en caché;
4. automático.

Después se aplica la cadena de reserva:

- **vulkan:** solo si hay nodo de render y un ICD de Vulkan;
- **opengl:** solo si hay nodo de render y una plataforma real (no offscreen);
- **software:** en el resto de casos.

## Gestión de recursos

- **Decodificación a resolución de pantalla.** `GlassProvider::loadCover` usa `QImageReader::setScaledSize`, así que
  un JPEG de 6K no se decodifica entero.
- **Desenfoque cacheado en disco.** El resultado reducido del desenfoque se guarda en
  `~/.cache/bc/glass/<sha1>.png`, con unos pocos KB por pantalla y nivel. La clave lleva ruta, fecha, pantalla y
  radio. En los siguientes arranques solo se amplía.
- **Caché en memoria** de hasta 4 fondos (multimonitor), como antes.

## Variables y archivos

| Nombre | Efecto |
|---|---|
| `BC_RENDER_TIER` | Fuerza un nivel (también lo lee BC Core) |
| `BC_RENDER_BACKEND` | vulkan, opengl o software (con reserva) |
| `BC_RENDER_DISABLE_CORE=1` | No consultar BC Core (pruebas, banco) |
| `BC_HW_ROOT` | Raíz alternativa para `bc-hardware-service --perfil` |
| `~/.config/bc/calidad` | Preferencia de Ajustes (`auto` si no existe) |
| `~/.cache/bc/render-profile.json` | Perfil y parámetros (versión 1) |

## Limitaciones conocidas

- Sin `qsb` en el entorno de desarrollo, no hay materiales con shaders RHI. El backend software no admite
  `QSGGeometryNode` propios, así que BC Geometry (SDF/AA analítico en GPU) no se ha implementado. Queda pendiente
  para cuando el sistema de compilación tenga `qt6-shadertools`.
- La medida de fotogramas cuenta el coste de sincronizar y dibujar de Qt Quick. No incluye lo que tarda el compositor
  en presentar.
