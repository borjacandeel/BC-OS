# PENDIENTE — BC OS

Leer SIEMPRE antes de cualquier acción. Actualizar SIEMPRE antes de empezar algo y al terminarlo.

## Reglas de oro
- Castellano siempre.
- Skill `0-palabras` siempre.
- Todo se sube siempre a `main` (sin force-push).
- ARM64 únicamente. Base Arch Linux ARM.

## En curso
- [ ] Fase 1: rootfs ALARM aarch64 actualizado en chroot (qemu-user) — `pacman -Syu`.

## Pendiente (orden)
### Fase 0 — Viabilidad
- [x] Inspeccionar repo (solo README, rama `main` + `claude/bc-os-kcjzgc`).
- [x] Inspeccionar entorno de build: contenedor cloud x86_64 Ubuntu 24.04, 4 CPU, 15 GiB RAM. Emulación aarch64 vía qemu-user + binfmt.
- [x] Logos BC analizados (azul noche `#04111F`, blanco `#F5F5F7`, plata degradado, midnight radial).
- [ ] Host real del creador (Mac Apple Silicon + VirtualBox ARM64): no accesible desde la nube. Script de diagnóstico `tools/host-check.sh` para que lo ejecute el creador.
- [ ] ADRs: estrategia de imagen, compositor, arranque.

### Fase 1 — Base
- [ ] Estructura del repo + documentación obligatoria (README, ROADMAP, ARCHITECTURE, CONTRIBUTING, SECURITY, CHANGELOG, LICENSE, docs/*).
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
- Toolchain instalado en el contenedor: qemu-system-arm, qemu-user-static, AAVMF, Qt 6.4 (host), mtools, dosfstools.
