# PENDIENTE — BC OS

Leer SIEMPRE antes de cualquier acción. Actualizar SIEMPRE antes de empezar algo y al terminarlo.

## Reglas de oro
- Castellano siempre.
- Skill `0-palabras` siempre.
- Todo se sube siempre a `main` (sin force-push).
- ARM64 únicamente. Base Arch Linux ARM.

## En curso
- [ ] Subagente `instalador` escribiendo `build/installer/bc-install` (probado vía losetup + QEMU). Después: ISO live (squashfs + hook initramfs + xorriso EFI).
- [ ] PRIORIDAD (creador): ISO/imagen de instalación con instalador (particionado, montaje, GRUB/systemd-boot, usuario, locale, cifrado opcional) y probar en VirtualBox ARM64. Hoy: imagen raw "live-disk" arrancable; instalador sin hacer. Entregable provisional: pre-release en GitHub (requiere autorización del creador) + `VBoxManage convertfromraw`.
- [ ] Fase 2: pila gráfica en la imagen (labwc, Qt6 runtime, seatd, fuentes Inter) + autostart de BC Shell + autologin/greeter.
- [ ] Integrar `shell/` (captura en `shell/docs/captura-es.png`) y `core/` en la imagen.
- [ ] Subagente `bc-core-ci` (core/ Rust + workflows) en curso.

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

### Fase 3+
- [ ] Design system `docs/design/BC-DESIGN-SYSTEM.md` + tokens.
- [ ] Apps: Archivos, Configuración, Monitor, Terminal, Store.
- [ ] BC Core (Rust, D-Bus).
- [ ] Benchmarks, instalador, releases.

## Hecho
- Fase 1 HITO 1: imagen raw GPT ARM64 (`build/mkimage.sh`) arranca en QEMU UEFI hasta `bcos login:` (systemd 7.3.4 ALARM, es_ES, zram, nftables, NetworkManager). Usuario `bc`/`bcos` ; root bloqueado; /home/bc y /root con carpetas en español.
- Docs completas, design system y tokens (subagente docs) en main.
- BC Shell prototipo QML con ctest 3/3 (subagente shell) en main.
- Rootfs ALARM aarch64 descargado, verificado (md5) y actualizado con pacman -Syu en chroot (`/home/user/bcwork/root`).
- Imagen de referencia subida a main.
- README.md con todo el contexto del proyecto.
- Logos oficiales en `assets/branding/`.
- Toolchain instalado en el contenedor: qemu-system-arm, qemu-user-static, AAVMF, Qt 6.4 (host), mtools, dosfstools.
