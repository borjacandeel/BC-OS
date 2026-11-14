# PENDIENTE — BC OS

Leer SIEMPRE antes de cualquier acción. Actualizar SIEMPRE antes de empezar algo y al terminarlo.

## Reglas de oro
- NO subagentes: trabajar de uno en uno y en secuencia (creador, 21:47). Prevalece sobre cualquier prompt.
- Castellano siempre.
- Skill `0-palabras` siempre.
- Todo se sube siempre a `main` (sin force-push).
- ARM64 únicamente. Base Arch Linux ARM.

## En curso
- [ ] 2026-11-14 (hasta 15:00) **0.3.1**: terminal por defecto alacritty; transparencias (sway opacity, sin picom: es X11); arreglar parpadeo de fondo al arrancar/alternar mosaico (quitar swaybg `output bg`); cursor tipo macOS por defecto; ocultar CMake/Qt Assistant del lanzador; Dock con minimizadas.
- [x] 2026-11-14 **0.3.0-alpha (sway)** HECHO y verificado en QEMU (Ctrl+Intro, Ctrl+B, mosaico/flotante, lanzador por D-Bus, menús). Publicación lanzada. Pendiente: ocultar CMake/Qt Assistant del lanzador, Dock con minimizadas, probar en VirtualBox. Detalle original: compositor sway (mosaico+flotante, botón en barra, Ctrl+Intro=terminal, Ctrl+B=Firefox), BC Shell dividido en panel layer-shell + apps (`--app`), menús globales tipo macOS por app enfocada, Dock vía IPC de sway. ADR 0004. Hecho: SwayControl, LayerHelper, ShellControl, UiState, AppMenus, TopBar, MenuPopup, AppWindow/FilesApp. Falta: Panel.qml, main.cpp por modos, Launcher, CMake, tests, config de sway + `bc-wm-mode`, rootfs, verificación chroot/QEMU, docs, release.
- [x] 2026-11-14 (sesión única, sin subagentes): **0.2.0-alpha** — login greetd + bloqueo PAM + apagado, Centro de control/barra con estado real, notificaciones D-Bus, Archivos (nueva carpeta/renombrar/Papelera), Monitor, Configuración, Tienda (pacman), lanzador .desktop, iconos BC integrados, BC Core de usuario, SSH, red (NM; networkd desactivado), reducción de tamaño. Verificado en QEMU: login bueno/malo, escritorio, bloqueo bueno/malo, cerrar sesión→login, respaldo de autologin, 6 servicios BC Core activos, RAM ~240 MB, root 2,6 GB. ctest 11/11 y CI ARM64 verde. Build de publicación lanzado (image.yml, publicar=true).
- [ ] El creador debe PROBAR 0.2.0-alpha en VirtualBox ARM64 (no verificada ahí). Si el login gráfico fallara: 3 intentos y autologin automático; modo seguro en el menú de arranque.
- [ ] Pendiente conocido: ventanas externas en el Dock (`wlrctl` no está en ALARM: compilarlo o usar protocolo foreign-toplevel); `ext-session-lock` para un bloqueo seguro; tema claro; Música; selector de fondos; `bc-install` debe generar las dos entradas de arranque y el hook plymouth; ISO live; benchmarks rigurosos; instalar/eliminar con polkit en vez de sudo -S; foot/Firefox con configuración propia; la tarea programada de las 03:00 falló (sin acceso al repo en sesiones nuevas) y está desactivada.

## Pendiente (orden)
### Fase 0 — Viabilidad
- [x] Inspeccionar repo (solo README, rama `main` + `claude/bc-os-kcjzgc`).
- [x] Inspeccionar entorno de build: contenedor cloud x86_64 Ubuntu 24.04, 4 CPU, 15 GiB RAM. Emulación aarch64 vía qemu-user + binfmt.
- [x] Logos BC analizados (azul noche `#04111F`, blanco `#F5F5F7`, plata degradado, midnight radial).
- [ ] Host real del creador (Mac Apple Silicon + VirtualBox ARM64): no accesible desde la nube. Script de diagnóstico `tools/host-check.sh` para que lo ejecute el creador.
- [ ] ADRs: estrategia de imagen, compositor, arranque.

### Fase 1 — Base
- [ ] Script reproducible `build/mkimage.sh`: rootfs ALARM → imagen GPT (ESP + ext4) → VDI/VMDK/raw.
- [ ] systemd-boot + initramfs con virtio/ahci/nvme.
- [ ] Locale `es_ES.UTF-8`, teclado `es`, zona `Europe/Madrid`, zram, NetworkManager.
- [ ] Arranque verificado en qemu-system-aarch64 + UEFI (AAVMF).
- [ ] Workflow CI en runner `ubuntu-24.04-arm`.

### Fase 2 — BC Shell
- [ ] Sesión Wayland (labwc) + BC Top Bar + BC Dock + Launcher (Qt6/QML, layer-shell).
- [ ] i18n: es_ES por defecto, en secundario.

### Fase 6 (adelantada) — Reducir tamaño de imagen
- [ ] rootfs ocupa ~4,1 GB: linux-firmware 1,0 GB (innecesario en VM; dejar solo lo mínimo), módulos 205 MB, LLVM 164 MB (mesa), locales 150 MB (dejar es/en), gcc 136 MB (restos de build-deps), /boot 250 MB. Objetivo ≈2,5 GB; luego imagen de 4 GiB. El "6 GiB" es solo capacidad del disco virtual; la descarga (.zip) pesa ~1,2 GB.

### Fase 3+
- [ ] Design system `docs/design/BC-DESIGN-SYSTEM.md` + tokens.
- [ ] Apps: Archivos, Configuración, Monitor, Terminal, Store.
- [ ] BC Core (Rust, D-Bus).
- [ ] Benchmarks, instalador, releases.

## Hecho
- HITO 2: BC Shell corre sobre labwc en la imagen ARM64 (QEMU UEFI + virtio-gpu, render por software). Captura verificada.
- Fase 1 HITO 1: imagen raw GPT ARM64 (`build/mkimage.sh`) arranca en QEMU UEFI hasta `bcos login:` (systemd 7.3.4 ALARM, es_ES, zram, nftables, NetworkManager). Usuario `bc`/`bcos` ; root bloqueado; /home/bc y /root con carpetas en español.
- Docs completas, design system y tokens (subagente docs) en main.
- BC Shell prototipo QML con ctest 3/3 (subagente shell) en main.
- Rootfs ALARM aarch64 descargado, verificado (md5) y actualizado con pacman -Syu en chroot (`/home/user/bcwork/root`).
- Imagen de referencia subida a main.
- README.md con todo el contexto del proyecto.
- Logos oficiales en `assets/branding/`.
- Toolchain instalado en el contenedor: qemu-system-arm, qemu-user-static, AAVMF, Qt 6.4 (host), mtools, dosfstools.
