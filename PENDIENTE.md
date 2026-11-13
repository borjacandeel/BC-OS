# PENDIENTE — BC OS

Leer SIEMPRE antes de cualquier acción. Actualizar SIEMPRE antes de empezar algo y al terminarlo.

## Reglas de oro
- Castellano siempre.
- Skill `0-palabras` siempre.
- Todo se sube siempre a `main` (sin force-push).
- ARM64 únicamente. Base Arch Linux ARM.

## En curso
- [ ] TAREA PROGRAMADA: sábado 2026-11-14 03:00 (Madrid), trigger `trig_013KkEZCuJr82FMndmg84bFq` (sesión nueva sin repo adjunto; clona con add_repo). Objetivo: BC OS funcional, todo inicia solo, prerelease listo para probar en VM. Publicación sin MCP: escribir versión en `build/PUBLICAR` (dispara image.yml).
- [x] `shell-real-1` hecho (main 4a996f9): responsive 1024x640+, Dock lanza `foot` real y marca apps en ejecución (/proc), Archivos con directorio real (modelo C++), ctest 7/7. Sin probar con ratón ni en VirtualBox. Falta: Centro de control real, Configuración/Monitor/Tienda/Navegador/Música/Papelera (solo 'En desarrollo'), magnificación del Dock verificada.
- [ ] Agente en curso (21:15): `arranque-animado` (Plymouth con logo BC). Verificar que no rompe el arranque antes de publicar.
- [x] HITO 3 (creador, 21:08): 0.1.2-alpha arranca en VirtualBox ARM64 con BC Shell. Feedback: "casi no va nada, es como una imagen, faltan muchas cosas".
- [ ] PRIORIDAD: BC Shell REAL. Orden: (1) layout responsive a cualquier resolución, (2) Dock lanza apps reales (foot/terminal, archivos), (3) Archivos lista el directorio real (FolderListModel), (4) Centro de control/barra con estado real (wpctl, nmcli, batería vía BC Core D-Bus), (5) gestión de ventanas (iconos de Dock con apps abiertas), (6) integrar iconos `icons/` (paso 5), (7) animaciones.
- [x] Instalador `build/installer/bc-install` (subagente): probado en QEMU, sin cifrado y con LUKS2, arranca. Sin probar: asistente interactivo (solo bash -n), VirtualBox. Integrado en imagen (/usr/bin/bc-install) y paquetes cryptsetup/dosfstools/rsync/libnewt añadidos → saldrá en 0.1.3-alpha.
- [ ] ISO live con instalador: pendiente (squashfs + hook initramfs + xorriso EFI). Hoy se instala desde la imagen en marcha: `sudo bc-install`.
- [ ] Build 0.1.2-alpha FALLÓ en Actions: `rm -rf $R` tras mkimage recorrió /sys y /dev aún montados (bind) → mount busy, borró /dev/null del runner. Fix: bc_umount con respaldo lazy y `rm -rf --one-file-system`. Relanzar build.
- [x] DECISIÓN del creador (2026-11-13): se mantiene **labwc (Wayland), estilo macOS, súper ligero y animado**. NO bspwm/Hyprland. Nota técnica: labwc no anima ventanas por sí mismo; animaciones de Dock/menús/paneles las hace BC Shell (QML); animación de ventanas (abrir/cerrar/minimizar) queda como investigación (p. ej. fork con scenefx o compositor propio sobre wlroots, ADR nueva), siempre con respaldo por software para VirtualBox.
- [ ] SSH por defecto (pedido del creador): openssh instalado y `sshd` activado SIEMPRE en la imagen; nftables abre 22/tcp; `PermitRootLogin no`. Solo alpha: contraseña `bcos` pública → riesgo si la VM está en red puenteada (el instalador/primer arranque debe forzar cambio o usar clave). VirtualBox NAT: reenvío de puertos host 2222 → invitado 22. Rebuild 0.1.2-alpha con SSH.
- [ ] BUG VirtualBox: CAUSA confirmada con capturas del creador: labwc cae con "VMware: No 3D enabled / EGL_NOT_INITIALIZED / unable to create renderer" (vmwgfx sin 3D) → sesión tty1 muere → getty en bucle → pantalla negra. Fix en `bc-session`: WLR_RENDERER=pixman siempre + QT_QUICK_BACKEND=software + shell cae a bash con log. Build 0.1.2-alpha lanzado en Actions (publicar=true). PENDIENTE: que el creador la pruebe; si labwc con pixman falla en vmwgfx, ver WLR_DRM_DEVICES / backend headless o fbdev.
- [ ] Release `v0.1.1-alpha` publicada (mitigación fsck) pero su texto dice 0.1.0 (plantilla fija); corregido en workflow para próximas. El creador debe PROBARLA en VirtualBox y reportar. Editar el texto de la release a mano (la sesión no puede editar releases).
- [ ] ICONOS paso 5 (integración, PRÓXIMA SESIÓN): sustituir `shell/qml/Icons.qml`/`Icon.qml`/`AppIcon.qml`/`FileGlyph.qml` por loader sobre `icons/dist/tinted/on-dark|on-light` (currentColor es negro en QtSvg), instalar tema `BC` en la imagen (`/usr/share/icons/BC`), añadir `qt6-svg` (ya en base.txt), compilar, `ctest` y captura sin iconos rotos. Fuente: `icons/AUDIT.md` (mapa Icons.qml → tema). Estado: lotes A/B/C hechos, revisión `icons/REVIEW.md` hecha, correcciones P0/P1 hechas (183 iconos, lint 0 errores; quedan P2 y @16 de PDF/ejecutable/dispositivos, ver icons/REVIEW.md).
- [ ] BUG VirtualBox (reportado por el creador con capturas): systemd-boot y kernel OK, pero "Failed to start File System Check on /dev/disk/by-label/bc-root" → emergency (root bloqueado). NO reproducido en QEMU (ni con reloj 2020). Mitigación 0.1.1-alpha: `fsck.mode=skip` + ext4 con journal. Pendiente causa raíz (pedir al creador `journalctl`/prueba con rd.debug) y probar con VirtualBox ARM64.
- [ ] Pack de iconos completo (macOS minimal) con subagente permanente `icon-designer` → `icons/` + integración en `shell/` (Icons.qml/AppIcon.qml). Pasos: agente, contexto, diseño, revisión independiente, implementación. Subir a main.
- [x] Iconos revisión REVIEW.md: P0 y P1 corregidos (estado en `icons/REVIEW.md`); pendientes P1-9, P1-6 resto y P2.
- [x] Release alpha PUBLICADA vía Actions: https://github.com/borjacandeel/BC-OS/releases/tag/v0.1.0-alpha (zip VDI 1.24 GB + SHA256SUMS). Pendiente: que el creador la pruebe en VirtualBox ARM64.
- [ ] CI shell: arreglados módulos QML; faltaba plugin SVG (qt6-svg) → verificar run verde.
- [x] Iconos LOTE A (icon-designer): AUDIT.md, SPEC.md, build/lint/preview en `icons/` (`npm run check`), 102 iconos UI (navegación, acciones, estado, diálogos) + muestra de app `utilities-terminal`. Integración en `shell/` la hace el agente principal (mapa de nombres en `icons/AUDIT.md` §2.1).
- [x] Iconos LOTE B (icon-designer): 16 apps squircle 1024 en `icons/src/app/apps` con @32/@16, lint 0 errores.
- [x] Iconos LOTE C (icon-designer): lugares, MIME y dispositivos (54 SVG color/symbolic, @16 de carpeta y texto), lint 0 errores.
- [x] Layout de BC Shell responsive (escala u=0,6..1,25, `--size WxH`, probado 1024x640/1280x800/1920x1080). Dock lanza `foot` real (BC_TERMINAL) con indicador por /proc; Archivos lista el directorio real (modelo C++ `FileBrowser`, doble click, atrás/adelante/arriba, breadcrumb, búsqueda). ctest 7/7. Falta: apps Configuración/Monitor/Tienda/Navegador/Música/Papelera ("En desarrollo"), Centro de control con estado real, magnificación solo animada por QML (no probada con ratón real), barra superior sin escalar.
- [ ] LÍMITE HOY (ampliado por el creador): trabajar hasta las 21:30 (Europe/Madrid, 2026-11-13). A esa hora: terminar lo que esté en marcha, subir a main y parar. Sin tareas nuevas.
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
