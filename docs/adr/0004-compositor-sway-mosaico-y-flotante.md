# ADR 0004 — Compositor sway (mosaico y flotante) y BC Shell como procesos con layer-shell

- Estado: aceptada por el creador (2026-11-14); sustituye a la ADR 0003 (labwc)
- Fecha: 2026-11-14

## Contexto

El creador pide un botón para alternar entre **mosaico (tiling, estilo bspwm)** y **flotante**, atajos de teclado globales
(`Ctrl+Intro` terminal, `Ctrl+B` Firefox…) y menús estilo macOS en todas las aplicaciones. labwc no tiene motor de mosaico ni
IPC para controlar ventanas desde fuera, y el Dock necesita listar/minimizar/enfocar ventanas externas.

## Decisión

- Compositor: **sway** (wlroots). Hace mosaico y flotante, tiene IPC (`swaymsg`), atajos por configuración y funciona sin 3D con
  `WLR_RENDERER=pixman`. Mantiene los objetivos de ligereza y la compatibilidad con VirtualBox.
- **BC Shell se divide en procesos**:
  - *Panel* (`bc-shell --panel`): barra superior, Dock, escritorio, Centro de control, notificaciones, lanzador, menús, diálogos
    de energía, bloqueo y splash, cada uno como **superficie `wlr-layer-shell`** (layer-shell-qt).
  - *Aplicaciones* (`bc-shell --app files|monitor|settings|store`): ventanas normales `xdg-toplevel`, una por proceso
    (un fallo en una app no tumba el escritorio). En mosaico se organizan como cualquier ventana.
- El panel habla con sway por IPC (`swaymsg`) para listar ventanas, enfocar, minimizar (scratchpad) y cambiar de modo.
- Modo mosaico/flotante: `bc-wm-mode` reescribe `~/.config/bc/sway-mode.conf` y recarga sway; botón en la barra y atajo
  `Súper+Mayús+Espacio`.
- Menú global estilo macOS en la barra superior según la app enfocada; las apps de BC exponen acciones por D-Bus
  (`org.bcos.App.<nombre>.Invoke`).
- El greeter (greetd) sigue usando cage.

## Consecuencias

- Se pierde la restricción «solo labwc»; sway añade ~10 MB al sistema.
- El bloqueo de pantalla usa una capa `overlay` con teclado exclusivo (más fuerte que antes, aún sin `ext-session-lock`).
- Las animaciones de ventana dependen del compositor (sway no anima): se animan los componentes propios del shell.
- El Dock y los menús pueden mostrar ventanas externas reales (Firefox, Terminal…).
