# BC Rendering Engine — medidas

Las medidas son reales: `tools/bench/render-bench.sh`, 3 repeticiones, y en la tabla va la media.

- **Entorno:** anfitrión x86_64 de 4 núcleos, Qt 6.4, sin pantalla (`offscreen`, 1440×900).
- **Backend:** el software de Qt Quick, como una VM sin 3D (el escenario prioritario).
- **Base:** `bc-baseline-pre-rendering` (`bench-base.csv`).
- **Motor:** la rama `feature/bc-rendering-engine` (`bench-motor.csv`), con `BC_RENDER_DISABLE_CORE=1`, que da nivel «Eficiente».
- **Columnas:** «Fotograma» es el tiempo de render de Qt (registro `qt.scenegraph.time.renderloop`); «Perdidos» son los fotogramas de más de 16,7 ms.

| Escenario | Arranque (ms) | CPU (ms) | RSS (MB) | Fotogramas | Fotograma medio (ms) | p95 (ms) | Perdidos |
|---|---|---|---|---|---|---|---|
| Arranque en frío | 2432 → 2431 | 1148 → 1155 | 201 → 196 | 3,3 → 3,0 | 7,1 → 7,2 | 13,3 → 12,7 | 0 → 0 |
| Arranque con caché | 2423 → **2309** | 1152 → **1016** | 201 → 197 | 3,7 → 3,7 | 6,6 → 6,8 | 12,7 → 14,0 | 0 → 0,3 |
| Genio (ráfaga 40) | 16006 → 15778 | 14595 → 14374 | 201 → 196 | 6,0 → 5,3 | 6,7 → 7,0 | 14,0 → 13,7 | 0 → 0 |
| Dock (ráfaga 40) | 12513 → 12100 | 11324 → **10851** | 201 → 197 | 120 → 120 | 3,5 → **3,0** | 4,7 → **4,0** | 1,3 → 1,3 |
| Spotlight (ráfaga 40) | 16270 → 15970 | 14882 → 14583 | 201 → 196 | 58 → 42 | 1,7 → 1,9 | 4,0 → 7,3 | 0,7 → 0,7 |

## Lectura

- **Arranque con caché:** el fondo desenfocado sale del disco (`~/.cache/bc/glass`). Arranca un 5 % antes y gasta un 12 % menos de CPU.
- **Memoria:** unos 5 MB menos en todos los escenarios, porque el fondo se decodifica a tamaño de pantalla.
- **Dock:** el fotograma medio baja un 14 % y el p95, de 4,7 a 4,0 ms. Es el efecto de quitar la lente y la segunda capa de sombra en «Eficiente».
- **Spotlight:** hay menos fotogramas porque en «Eficiente» la animación dura ×0,85. El p95 sube porque la misma transición se reparte en menos fotogramas. Los perdidos no cambian.
- **Genio:** en todos los niveles por software se sustituye por minimizar sin efecto, igual que antes. Las cifras son las del panel durante la ráfaga.

## Sin medir aquí

- GPU real (OpenGL/Vulkan), Hyprland y swayfx: el entorno de desarrollo no tiene GPU.
- VirtualBox y equipos físicos: pendiente de prueba con la ISO 0.9.20-beta.
