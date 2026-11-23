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

## 0.9.23 frente a 0.9.19 (2026-11-23)

Mismo banco (`tools/bench/render-bench.sh`, ahora también con Centro de control, Notificaciones, Mission Control y
10 s de reposo), software de Qt Quick, 1440×900, 3 repeticiones. Datos: `bench-0.9.19.csv` y `bench-0.9.23.csv`.
Gráfico y capturas lado a lado: `comparacion/`.

| Qué | 0.9.19 | 0.9.23 | Mejora |
|---|---|---|---|
| Fotogramas perdidos (>16,7 ms) en las ráfagas | 2,7 | 0 | −100 % |
| Abrir Spotlight, Centro o un menú | 15,5 ms | 3 ms | −81 % |
| Dock: p99 | 12 ms | 5,3 ms | −56 % |
| Notificaciones: p99 | 12,7 ms | 6 ms | −53 % |
| Centro de control: p99 | 12,3 ms | 7,7 ms | −37 % |
| Arranque con caché: fotograma medio | 6,9 ms | 4,9 ms | −29 % |
| Notificaciones: fotograma medio | 2,4 ms | 1,8 ms | −25 % |
| CPU en reposo (10 s) | 687 ms | 532 ms | −23 % |
| Dock: fotograma medio | 3,2 ms | 2,5 ms | −22 % |
| CPU al arrancar (con caché) | 1021 ms | 801 ms | −22 % |
| Spotlight: p99 | 14,3 ms | 11,7 ms | −18 % |
| Mission Control: fotograma medio | 1,8 ms | 1,5 ms | −17 % |
| Tiempo de arranque (con caché) | 2322 ms | 2047 ms | −12 % |
| Memoria | 201 MB | 180 MB | −10 % |
| Genio por software: fotograma medio | 5,5 ms | 6,2 ms | +14 % (con GPU va en la GPU; sin medir aquí) |
| Arranque en frío: fotograma medio | 5,9 ms | 6,6 ms | +11 % (3 fotogramas: ruido) |
