# BC Rendering Engine — medidas

Las medidas son reales: `tools/bench/render-bench.sh`, 3 repeticiones, y en la tabla va la media.

- **Entorno:** anfitrión x86_64 de 4 núcleos, Qt 6.4, sin pantalla (`offscreen`, 1440×900).
- **Backend:** el software de Qt Quick, como una VM sin 3D (el escenario prioritario).
- **Base:** `bc-baseline-pre-rendering` (`bench-base.csv`).
- **Motor:** la rama `feature/bc-rendering-engine` (`bench-motor.csv`), con `BC_RENDER_DISABLE_CORE=1`, que da nivel «Eficiente».
- **Columnas:** «Fotograma» es el tiempo de render de Qt (registro `qt.scenegraph.time.renderloop`); «Perdidos» son los fotogramas de más de 16,7 ms.

| Escenario | Arranque (ms) | CPU (ms) | RSS (MB) | Fotograma medio (ms) | p95 (ms) | p99 (ms) | Perdidos |
|---|---|---|---|---|---|---|---|
| Arranque en frío | 2432 → **2311** (−5 %) | 1148 → **991** (−14 %) | 201 → **180** (−10 %) | 7,1 → 7,3 | 13,3 → 13,0 | 13,3 → 13,0 | 0 → 0 |
| Arranque con caché | 2423 → **2258** (−7 %) | 1152 → **925** (−20 %) | 201 → **180** (−10 %) | 6,6 → 6,3 | 12,7 → 12,3 | 12,7 → 12,3 | 0 → 0 |
| Genio (ráfaga 40) | 16006 → 15913 | 14595 → 14457 | 201 → 180 | 6,7 → 6,3 | 14,0 → 14,7 | 14,0 → 14,7 | 0 → 0 |
| Dock (ráfaga 40) | 12513 → 12022 | 11324 → **10689** (−6 %) | 201 → 180 | 3,5 → **2,8** (−20 %) | 4,7 → **4,0** | 14,3 → **8,0** (−44 %) | 1,3 → **0** |
| Spotlight (ráfaga 40) | 16270 → 16401 | 14882 → 14940 | 201 → 180 | 1,7 → **1,5** (−12 %) | 4,0 → 4,3 | 13,7 → **10,3** (−25 %) | 0,7 → **0,3** |

**Apertura de un panel emergente** (fotograma en que aparece la capa: Spotlight, Centro de control, menús…), medido
con `qt.scenegraph.time.renderloop`: **12–19 ms → 3 ms** (sincronización de 12–16 ms → 0 ms).

## Lectura

- **Paneles emergentes cargados solo al abrirse** (`Lazy.qml`). Callgrind (`--toggle-collect=syncSceneGraph`)
  mostraba que, cada vez que la capa emergente aparece, Qt vuelve a generar los nodos de todo lo que contiene, también
  lo oculto:
  - el 55 % del tiempo eran rectángulos redondeados (`QQuickRectangle::updatePaintNode` → `drawRoundedRect`);
  - el 39 %, glifos de texto (`QQuickText` → FreeType).

  Ahora solo existe el panel que se abre. Por eso abrir cualquier panel cuesta 3 ms y la memoria baja 21 MB.
- **Arranque con caché:** el fondo desenfocado sale del disco (`~/.cache/bc/glass`).
- **Dock y Spotlight:** en «Eficiente» no hay lente ni segunda capa de sombra, y por software no se escala al animar.
  Spotlight hace una sola búsqueda por fotograma y no rehace la lista si los resultados no cambian.
- **Wall/CPU de las ráfagas:** lo domina la captura de 40 imágenes del propio banco, no la interfaz.

## Sin medir aquí

- GPU real (OpenGL/Vulkan), Hyprland y swayfx: el entorno de desarrollo no tiene GPU.
- VirtualBox y equipos físicos: pendiente de prueba con la ISO 0.9.20-beta.
