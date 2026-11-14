# Arquitectura de BC OS

Estado: serie 0.3.x-alpha. Se marca explícitamente qué está **verificado** y qué es **planificado**.

## 1. Capas

```
┌───────────────────────────────────────────────────────────────┐
│ Apps de BC (Qt 6/QML, xdg-toplevel, un proceso cada una):      │
│ `bc-shell --app files|monitor|settings|store`  [implementadas] │
│ Terminal (bc-terminal: Alacritty, respaldo foot), Firefox      │
├───────────────────────────────────────────────────────────────┤
│ Panel de BC Shell (`bc-shell --panel`, wlr-layer-shell):       │
│ barra superior con menús globales, Dock / barra de tareas y    │
│ menú Inicio (según estilo), lanzador, Centro de control,       │
│ notificaciones, widgets, bloqueo, bienvenida   [implementado]  │
│ Servicio D-Bus org.bcos.Shell (+ org.bcos.App.<app>)           │
├───────────────────────────────────────────────────────────────┤
│ Compositor Wayland: sway (wlroots) + swaybg (fondo);           │
│ swayfx opcional con GPU real (bc.gpu=1)       [experimental]   │
├───────────────────────────────────────────────────────────────┤
│ BC Core (Rust, D-Bus de usuario): bc-daemon, settings, update, │
│ security, hardware, performance                [instalado]     │
├───────────────────────────────────────────────────────────────┤
│ Base: Arch Linux ARM aarch64, linux-aarch64, systemd,          │
│ PipeWire, NetworkManager, nftables, zram, pacman (+ flatpak    │
│ de usuario para Flathub)                                       │
├───────────────────────────────────────────────────────────────┤
│ Arranque: UEFI → systemd-boot → kernel Image + initramfs →     │
│ Plymouth → greetd                                              │
└───────────────────────────────────────────────────────────────┘
```

Verificado en QEMU aarch64: arranque, login, sway (flotante y mosaico), panel, apps y atajos. Sin probar en VirtualBox desde 0.2.0 ni en hardware real.

### Panel y apps

El shell son procesos separados (ADR 0004): un fallo en una app no tumba el escritorio.

- **Panel** (`bc-shell --panel`): cada elemento (barra, Dock, escritorio, Centro de control, lanzador, menús, notificaciones, bloqueo…) es una superficie layer-shell (`layer-shell-qt`).
- **Apps** (`bc-shell --app files|monitor|settings|store`): ventanas normales; sway las coloca en flotante o mosaico.
- **Estilos de escritorio** (ADR 0005): BC (barra superior + Dock flotante), Windows (barra de tareas + menú Inicio), Minimal (solo barra superior). Se eligen en el asistente de bienvenida o en Configuración (`bc-ctl style mac|win|minimal`).
- **Modos** (Relajación, Concentración, Noche) y **widgets** de escritorio los gestiona el panel.
- **Menús globales**: la barra muestra los menús de la app enfocada; las apps de BC reciben las acciones por D-Bus `org.bcos.App.<nombre>.Invoke`.

### Control por D-Bus y línea de órdenes

| Pieza | Función |
|---|---|
| `org.bcos.Shell` (`/org/bcos/Shell`) | métodos del panel: lanzador, centro, bloqueo, bienvenida, estilo, opciones, energía |
| `bc-ctl` | envoltorio de `busctl --user` sobre `org.bcos.Shell` (lo usan los atajos de sway) |
| `bc-wm-mode toggle\|tiling\|floating\|init\|status` | alterna mosaico/flotante y genera la configuración final de sway |
| `/etc/bc/atajos.txt` | lista de atajos (Súper+F1) |

## 2. Decisiones clave

Detalle en `docs/adr/`:

| ADR | Decisión |
|---|---|
| 0001 | Base Arch Linux ARM (aarch64), pacman, kernel de distribución |
| 0002 | Imagen raw GPT: ESP FAT32 512 MiB (systemd-boot, kernel `Image`, initramfs) + raíz ext4; construida sin montajes loop |
| 0003 | Compositor Wayland labwc/wlroots + shell Qt con layer-shell, en lugar de KWin (compositor sustituido por 0004) |
| 0004 | sway (mosaico + flotante) y BC Shell dividido en panel layer-shell + apps |
| 0005 | Estilos de escritorio elegibles (BC/Windows/Minimal) y paridad de funciones con Quantum Linux como inspiración |

## 3. Pipeline de construcción

1. Descargar y verificar (MD5 publicado) el rootfs de Arch Linux ARM aarch64.
2. En un host x86_64 se ejecuta el rootfs mediante `qemu-user-static` + `binfmt_misc` + `chroot`; en un host aarch64 se usa chroot nativo.
3. `pacman -Syu` y paquetes de `build/packages/base.txt`.
3b. `build-shell.sh` compila BC Shell en el rootfs; `build-core.sh` compila BC Core; `build-swayfx.sh` compila swayfx 0.6.1 en `/opt/swayfx` (el clon se hace en el anfitrión). `build-all.sh` los encadena.
4. Configuración (`build/configure-rootfs.sh`): identidad, locale `es_ES.UTF-8`, teclado `es`, zona `Europe/Madrid`, skel en español, usuarios, servicios, zram, nftables, initramfs.
5. Ensamblado de imagen sin loop mounts (`mke2fs -d`, `mtools`, `sfdisk`).
6. Verificación de arranque en QEMU aarch64 con UEFI (AAVMF) antes de cualquier publicación.
7. Suma SHA256 y publicación en GitHub Releases (solo con imagen probada).

Entradas de arranque (`build/overlay/boot/loader/entries/`): **BC OS** (animación), **BC OS (modo seguro, sin animación)** y **BC OS (experimental: efectos con GPU real)** (`bc.gpu=1`, swayfx).

## 3b. Sesión de usuario: login, escritorio, bloqueo y apagado

```
systemd-boot → kernel → Plymouth (logo BC) → greetd
  greetd → cage (kiosco Wayland, render por software) → bc-greeter (QML, IPC greetd + PAM)
  login correcto → greetd arranca `bc-session --greetd`
     → `bc-wm-mode init` genera `$XDG_RUNTIME_DIR/bc-sway.conf` (sistema + teclado + efectos + fondo swaybg + modo + usuario)
     → sway (o `/opt/swayfx/bin/sway` si el kernel arranca con `bc.gpu=1` y hay GPU; si falla, sway normal) → `bc-shell --panel`
  sin `bc.gpu=1`: `WLR_RENDERER=pixman` y `QT_QUICK_BACKEND=software` (render por software)
  primer inicio de sesión → asistente de bienvenida (3 pasos); se reabre con `bc-ctl welcome`
  cerrar sesión (`swaymsg exit`) → vuelve a greetd/bc-greeter
```

- **Respaldo:** `bc-greeter-session` cuenta los arranques del greeter (`/run/bc-greeter/count`); tras 3 fallos seguidos marca
  `/run/bc-greeter/failed` y `bc-login-fallback.path` arranca el autologin de `getty@tty1` (que detiene greetd por `Conflicts=`).
- **Bloqueo:** `Ctrl+Súper+Q` o menú del logo BC. Es una superposición de pantalla completa que verifica con PAM (`/etc/pam.d/bc-lock`).
  **Limitación:** no usa `ext-session-lock-v1`, así que no impide por sí sola que otra ventana reciba teclado; está en la lista de pendientes.
- **Apagar / reiniciar / suspender / cerrar sesión:** diálogo de confirmación con cuenta atrás; ejecuta `systemctl` o `swaymsg exit`.
- **Estado del sistema** (`SystemStatus`): `wpctl` (audio), `nmcli` (red), `/sys/class/power_supply` (batería), `brightnessctl`, `bluetoothctl`.
- **Notificaciones:** `bc-shell` implementa `org.freedesktop.Notifications` en el bus de sesión; respeta No molestar.
- **Tienda:** interfaz sobre `pacman` (instalar y quitar usan `sudo -S` con la contraseña del usuario, solo en memoria) y, si `flatpak` está disponible, sobre Flathub con `flatpak --user`.

## 4. Servicios BC Core

| Servicio | Responsabilidad | Privilegio |
|---|---|---|
| `bc-daemon` | coordinación, registro de servicios, bus | usuario |
| `bc-settings-service` | ajustes persistentes (dconf/archivo TOML), validación | usuario |
| `bc-update-service` | consulta y aplicación de actualizaciones vía pacman con firmas | root mínimo, vía polkit |
| `bc-security-service` | estado de cortafuegos, cifrado, políticas | root mínimo, vía polkit |
| `bc-hardware-service` | detección de pantallas, batería, sensores | usuario (udev/sysfs lectura) |
| `bc-performance-service` | métricas de CPU/RAM/GPU, perfiles | usuario |

Principios: IPC por D-Bus (zbus), un fallo no tumba el escritorio, logs estructurados al journal, sin servicios root innecesarios.

## 5. Localización

Español (es_ES) por defecto; inglés secundario. QML con `qsTr()` + Qt Linguist (`.ts`); Rust con catálogos gettext/Fluent. Texto visible siempre por el sistema compartido. Sin cadenas literales en la UI.

## 6. Seguridad

Ver `SECURITY.md`. Cortafuegos nftables con política de entrada restrictiva, root bloqueado por defecto, `sudo` por grupo `wheel`, contraseña inicial de usuario caducada en el primer acceso, firmas de pacman activas.

## 7. Rendimiento

Objetivos: RAM en reposo ≤ 700 MB, CPU ≈ ≤ 2 %. Son metas; se medirán con scripts en `tools/` en una VM de referencia documentada antes de afirmarlas.

## 8. Límites conocidos

- VirtualBox en Apple Silicon: la aceleración gráfica del invitado ARM64 no está validada; se debe prever render por software. Ver `docs/development/ARM64.md`.
- El entorno de construcción actual no es el Mac del creador; la compatibilidad con VirtualBox ARM64 está **pendiente de probar** por el creador.
