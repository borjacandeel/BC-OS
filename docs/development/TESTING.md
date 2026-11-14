# Pruebas de BC OS

Regla: no se afirma funcionalidad sin prueba ejecutada. Estado actual: hay pruebas automáticas del shell (`ctest`) y pruebas manuales/semiautomáticas de la imagen en QEMU; el resto de niveles de la tabla sigue pendiente.

## Niveles

| Nivel | Qué | Herramienta | Estado |
|---|---|---|---|
| 1 | Lint de scripts | `shellcheck`, `bash -n` | pendiente |
| 2 | Rust (BC Core) | `cargo test`, `clippy` | pendiente (sin código aún) |
| 3 | QML/Qt | `ctest` con `QT_QPA_PLATFORM=offscreen` | hecho (shell) |
| 4 | Imagen | comprobación de tabla GPT, sistemas de archivos, ficheros de arranque | pendiente |
| 5 | Arranque | QEMU aarch64 + UEFI (AAVMF), `tools/qemu/` | manual/semiautomático |
| 6 | Localización | verificar que no hay cadenas sin traducir; locale `es_ES.UTF-8` | pendiente |
| 7 | Rendimiento | scripts de benchmark en VM de referencia | pendiente |

## Prueba de arranque (criterio mínimo para publicar)

1. Arrancar la imagen en QEMU `virt` con AAVMF.
2. Verificar mensaje de login de BC OS (`/etc/issue`) por consola serie.
3. Iniciar sesión con el usuario inicial y comprobar cambio de contraseña forzado.
4. `locale` devuelve `es_ES.UTF-8`; `nft list ruleset` muestra la política; `zramctl` muestra zram0.
5. Apagado limpio.

## Benchmarks (`tools/bench/`, futuro)

Medir y registrar: RAM en reposo, CPU en reposo, tiempo de arranque, tiempo hasta sesión, lanzamiento de apps, FPS y consistencia de frame time, uso de disco, nº de procesos. VM de referencia documentada (vCPU, RAM, gráfico). Cada optimización se compara con la medición anterior en `docs/development/` (tabla de resultados).

Objetivos (no garantizados): RAM ≤ 700 MB, CPU ≈ ≤ 2 % en reposo.

## CI

Workflow en runner ARM64 (`ubuntu-24.04-arm`): lint, build Rust/Qt, tests, ensamblado de imagen, prueba de arranque, SHA256. No se publica si falla alguna etapa.


## Pruebas de BC Shell (`ctest`) en el host

```bash
cmake -S shell -B build-shell -G Ninja && cmake --build build-shell
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ctest --test-dir build-shell --output-on-failure
```

Cubren: carga del QML sin avisos (es/en/movimiento reducido), capturas en 3 tamaños, modelo de archivos y Papelera (especificación
FreeDesktop), lanzador, índice `.desktop`, analizadores de `wpctl`/`nmcli`/`pacman`/`wlrctl`, protocolo IPC de greetd contra un
servidor falso (`tests/fake_greetd.py`, contraseña buena y mala) y el servicio D-Bus de notificaciones (`dbus-run-session`).
La carga QML de `Panel.qml`, los estilos y la bienvenida se comprueban con `bc-shell --check`; las pruebas no sustituyen a ejecutarlo en la imagen.

## Pruebas de la imagen en QEMU

`tools/qemu/start.sh <imagen.img>` arranca la imagen (UEFI, virtio-gpu, SSH en el puerto 2222). Con `tools/qemu/monitor.py`
se envían teclas (`sendkey`) y se hacen capturas (`screendump`). Ejemplo: escribir la contraseña en el greeter y capturar el escritorio.


### Teclas y capturas con el monitor de QEMU

```bash
tools/qemu/start.sh bcos.img /ruta/trabajo        # arranca (snapshot=on: no modifica la imagen); SSH: 127.0.0.1:2222
python3 tools/qemu/monitor.py "sendkey ctrl-ret" "sendkey ctrl-b"       # atajos (Ctrl+Intro, Ctrl+B)
python3 tools/qemu/monitor.py "sendkey meta_l-shift-spc"                 # Súper+Mayús+Espacio: mosaico/flotante
python3 tools/qemu/monitor.py "screendump captura.ppm"                   # captura (convertir a PNG después)
```
`monitor.py` se ejecuta desde el directorio de trabajo donde está `mon.sock`; la salida serie queda en `serial.log`. Orden típica de una
verificación: login (bueno y malo) → escritorio → `Ctrl+Intro` terminal → `Ctrl+B` Firefox → alternar mosaico/flotante → lanzador →
bloqueo → cerrar sesión. Dentro de la sesión, `~/bc-session.log` indica el renderizador usado y si swayfx falló.

### Pruebas con sway headless en el chroot

Sin lanzar la imagen completa se puede probar el shell dentro del rootfs aarch64 (`source build/lib/chroot.sh; bc_binfmt; bc_mount root; bc_chroot root …`):

```bash
WLR_BACKENDS=headless WLR_RENDERER=pixman XDG_RUNTIME_DIR=/tmp/xdg sway -c /etc/bc/sway/config &   # sway sin pantalla
WAYLAND_DISPLAY=wayland-1 QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software bc-shell --panel &
swaymsg -t get_tree; bc-ctl launcher; bc-wm-mode toggle                                          # IPC y D-Bus
```
Útil para comprobar que el panel arranca, registra `org.bcos.Shell` y que `swaymsg` ve las ventanas. Requiere `dbus-run-session` (o un bus de sesión) y
no valida el rendimiento ni el aspecto real. Los nombres exactos de los sockets Wayland pueden variar: se comprueba con `ls $XDG_RUNTIME_DIR`.

### Qué NO está verificado

VirtualBox ARM64 desde 0.2.0, hardware real, swayfx con GPU real (con llvmpipe va lento y con fallos de dibujo), Waydroid, FEX/box64 y Flathub en condiciones reales de red. No se afirma su funcionamiento.
