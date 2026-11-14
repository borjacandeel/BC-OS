<p align="center">
  <img src="assets/branding/BC-icono-midnight-512.png" width="140" alt="BC OS">
</p>

<h1 align="center">BC OS</h1>

<p align="center"><b>LIGERO. POTENTE. FLUIDO.</b><br>
Sistema operativo Linux ARM64 creado por <b>Borja Candel</b>, en español por defecto.</p>

<p align="center">
  <img alt="Versión" src="https://img.shields.io/badge/versi%C3%B3n-0.3.x--alpha-2F7BFF">
  <img alt="Arquitectura" src="https://img.shields.io/badge/arquitectura-ARM64-04111F">
  <img alt="Base" src="https://img.shields.io/badge/base-Arch%20Linux%20ARM-1793D1">
  <img alt="Idioma" src="https://img.shields.io/badge/idioma-espa%C3%B1ol%20(es__ES)-C60B1E">
  <img alt="Estado" src="https://img.shields.io/badge/estado-alpha%20experimental-FFB340">
</p>

<p align="center">
  <img src="docs/screenshots/bc-os-escritorio.png" alt="BC OS: escritorio (captura de 0.2.0-alpha)" width="880">
  <br><sub>Captura real de BC OS 0.2.0-alpha en QEMU aarch64 (BC Shell sobre labwc, render por software). Es anterior a sway: desde 0.3.0 el compositor es sway; las capturas de más abajo ya son de la serie 0.3.x.</sub>
</p>

> **Estado honesto:** alpha experimental, versión actual **0.3.x-alpha** (0.3.0 sway, 0.3.1 pulido, 0.3.2 animación de minimizar y swayfx experimental). Es un escritorio funcional (login, bloqueo, Archivos con Papelera, Monitor, Configuración, Tienda, notificaciones, mosaico/flotante, estilos de escritorio…) **verificado en QEMU aarch64**. **Las versiones 0.1.2 y 0.1.3 arrancaron en VirtualBox ARM64; de la 0.2.0 en adelante aún no se han probado ahí, ni en hardware real.** **No hay ISO todavía** (el instalador `bc-install` va dentro de la imagen). Ver [problemas conocidos](#problemas-conocidos).

---

## Descargar y probar

Última imagen: [**Releases**](https://github.com/borjacandeel/BC-OS/releases) (prerelease). Cada release incluye `BC-OS-<versión>-ARM64.vdi.zip` y `SHA256SUMS`.

1. Descomprime el `.zip` → `.vdi`. Comprueba `shasum -a 256`.
2. VirtualBox (Mac Apple Silicon) → **Nueva**: Linux / Arch Linux (ARM 64-bit), ≥ 2 GB RAM, 2 CPU.
3. **Sistema → Habilitar EFI**. Disco: usar el `.vdi` existente. Gráficos: VMSVGA.
4. Arranca: menú de 5 s (animación de arranque por defecto o modo seguro) → **panel de login**. Usuario `bc`, contraseña `bcos` (**solo alpha**).

También se prueba sin VirtualBox con QEMU (`qemu-system-aarch64 -M virt` + UEFI AAVMF); ver [`docs/development/BUILD.md`](docs/development/BUILD.md).

## Versiones

| Versión | Estado | Qué trae |
|---|---|---|
| `0.1.0-alpha` | publicada | Primera imagen ARM64: arranca en QEMU; en VirtualBox falla el `fsck` del root (ver abajo). |
| `0.1.1-alpha` | publicada | Mitigación del `fsck`; en VirtualBox arrancaba a pantalla negra (labwc sin 3D). |
| `0.1.2-alpha` | publicada | **Arranca en VirtualBox ARM64** con BC Shell (render por software) y SSH activado. El shell es una maqueta. |
| `0.1.3-alpha` | publicada | Shell con Dock y Archivos reales, iconos BC, fondo BC, instalador `bc-install` y animación de arranque con el logo. **Arranca en VirtualBox ARM64, también con la animación (confirmado por el creador).** |
| `0.2.0-alpha` | publicada | **Escritorio funcional**: login (greetd), bloqueo, apagado, Centro de control real, notificaciones, Archivos + Papelera, Monitor, Configuración, Tienda, lanzador, iconos y fondo BC, BC Core y SSH. Verificada en QEMU. |
| `0.3.0-alpha` | publicada | **sway**: botón mosaico/flotante en la barra (`Súper+Mayús+Espacio`), `Ctrl+Intro` terminal, `Ctrl+B` Firefox, menús globales tipo macOS por app, Dock con ventanas reales. BC Shell dividido en panel + apps. |
| `0.3.1-alpha` | publicada | Terminal Alacritty (respaldo foot), cursor tipo macOS, fondo sin parpadeos (`swaybg`), transparencias, Dock con minimizadas. |
| `0.3.2-alpha` | publicada | Animación de minimizar y entrada de arranque **experimental** con swayfx (solo GPU real). Estilos de escritorio (BC/Windows/Minimal), Modos, widgets, Tienda con Flathub y asistente de bienvenida de 3 pasos (en desarrollo dentro de la serie 0.3.x; ver `PENDIENTE.md`). |
| `0.4.0` → `1.0.0` | planificadas | Ventanas externas más completas, bloqueo seguro (`ext-session-lock`), tema claro, ISO con instalador, beta y primera estable. Son hitos, no promesas. |

> Las funciones de estilos, Modos, widgets, Flathub y bienvenida están implementadas en el código y se han probado con `ctest` y en QEMU, pero su inclusión exacta por versión publicada se confirma en las [notas de cada release](https://github.com/borjacandeel/BC-OS/releases).

## Capturas

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/bc-os-mosaico.png" alt="Modo mosaico"><br><sub><b>Mosaico</b> (sway): terminal y Firefox en mosaico; el botón de la barra alterna con el modo flotante.</sub></td>
    <td width="50%"><img src="docs/screenshots/bc-os-lanzador-sway.png" alt="Lanzador"><br><sub><b>Lanzador</b> (Ctrl+Espacio) con menús globales por app en la barra.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/bc-os-login.png" alt="Panel de login"><br><sub><b>Login</b> (greetd + greeter propio sobre cage): reloj, avatar, contraseña con animación de error y botones de energía.</sub></td>
    <td width="50%"><img src="docs/screenshots/bc-os-bloqueo.png" alt="Pantalla de bloqueo"><br><sub><b>Bloqueo</b> (Ctrl+Súper+Q): misma estética, verifica con PAM.</sub></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/bc-os-tienda.png" alt="Tienda"><br><sub><b>Tienda</b> sobre pacman, abierta dentro de la sesión.</sub></td>
    <td><img src="docs/screenshots/arranque-bc-1-logo-progreso.png" alt="Animación de arranque"><br><sub><b>Arranque</b>: logo BC con barra de progreso (Plymouth).</sub></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/icon-pack-catalogo.png" alt="Catálogo de iconos"><br><sub><b>Pack de iconos BC</b> (catálogo).</sub></td>
    <td><img src="docs/design/reference/escritorio-referencia-01.webp" alt="Referencia visual"><br><sub><b>Referencia visual</b> del creador: el objetivo de diseño, no una captura del sistema.</sub></td>
  </tr>
</table>

## Problemas conocidos

- **VirtualBox:** `0.1.0` y `0.1.1` fallaban (`fsck`; labwc sin 3D). `0.1.2`/`0.1.3` arrancan con render por software. **Desde `0.2.0` (y toda la serie 0.3.x con sway) no se ha probado en VirtualBox** (sí en QEMU). Sin hardware real probado.
- **swayfx** (esquinas redondeadas, entrada de arranque «experimental») solo tiene sentido con GPU real; con render por software (llvmpipe) va lento y con fallos de dibujo. No es el modo por defecto.
- Android (Waydroid), juegos x86 (FEX/box64), antivirus, copias antes de actualizar e idiomas adicionales **no existen todavía**.
- El **bloqueo** es una superposición, no usa `ext-session-lock-v1`: otra ventana podría recibir teclado. Pendiente.
- Contraseña por defecto pública (`bc` / `bcos`) y SSH activo: solo para pruebas en máquinas virtuales.
- Sin tema claro, sin app de Música, sin ISO. Wi-Fi y Bluetooth sin probar con hardware real.
- Rendimiento no medido con rigor; observado: ~250 MB de RAM usados tras iniciar sesión (QEMU, 2 GB).

---

## Qué es BC OS

Un Linux ARM64 **ligero, fluido y en español**, con un escritorio propio (**BC Shell**) de estética minimal inspirada en macOS pero con identidad original (logos en [`assets/branding/`](assets/branding/)). No usa código, marcas ni recursos de Apple.

| Pieza | Elección |
|---|---|
| Base | Arch Linux ARM (aarch64), kernel Linux estándar, systemd, pacman |
| Gráficos | Wayland · compositor **sway** (wlroots; mosaico y flotante) · Mesa; respaldo por software · swayfx experimental (arranque con `bc.gpu=1`, solo GPU real) |
| Shell | **BC Shell**: Qt 6 / QML, dividido en panel `layer-shell` (`bc-shell --panel`) + apps (`--app files\|monitor\|settings\|store`) |
| Control | D-Bus `org.bcos.Shell` · `bc-ctl` · `bc-wm-mode` · atajos en `/etc/bc/atajos.txt` |
| Terminal | `bc-terminal`: Alacritty con respaldo a foot |
| Servicios | **BC Core**: Rust + D-Bus (`bc-daemon`, settings, update, security, hardware, performance) |
| Sistema | PipeWire · NetworkManager · zram · nftables · arranque UEFI con systemd-boot |
| Idioma | `es_ES` por defecto, inglés secundario (Qt Linguist) |
| Imagen | GPT: ESP FAT32 + ext4, construida en CI ARM64 nativo |

Decisiones y motivos: [`ARCHITECTURE.md`](ARCHITECTURE.md) y [`docs/adr/`](docs/adr/).

## Estado por componente

| Componente | Estado |
|---|---|
| Imagen ARM64 (UEFI, systemd-boot, animación de arranque) | ✅ QEMU · ✅ VirtualBox (0.1.2/0.1.3) · 🟡 0.2.0 sin probar en VirtualBox |
| Login (greetd + greeter QML), bloqueo, apagado/reinicio/suspender/cerrar sesión | ✅ verificado en QEMU (incluye respaldo de autologin) |
| sway: flotante / mosaico (botón en la barra, `Súper+Mayús+Espacio`), atajos, menús globales por app | ✅ verificado en QEMU |
| BC Shell: barra, Dock, Centro de control, notificaciones, lanzador | ✅ estado real (audio, red, batería, brillo, Bluetooth, No molestar) |
| Estilos de escritorio (BC / Windows con barra de tareas y menú Inicio / Minimal), Modos (Relajación, Concentración, Noche), widgets | 🟡 implementados; probados con `ctest` y en QEMU |
| Asistente de bienvenida (3 pasos: estilo, colores y fondo, organización de ventanas) | 🟡 implementado; se reabre desde Configuración |
| Fondo (`swaybg`), cursor tipo macOS, terminal Alacritty/foot | ✅ verificado en QEMU |
| swayfx (efectos con GPU real) | 🟡 experimental; lento con llvmpipe; sin probar con GPU real |
| Archivos (nueva carpeta, renombrar, Papelera) · Monitor · Configuración | ✅ funcionales |
| Tienda: pacman y Flathub (`flatpak --user`) | ✅ pacman verificado; 🟡 Flathub según disponibilidad de `flatpak`; instalar con pacman usa `sudo` con tu contraseña |
| BC Core (6 servicios D-Bus de usuario) | ✅ construidos e instalados; arrancan con la sesión |
| Pack de iconos BC (186) integrado en el shell e instalado como tema | ✅ |
| Instalador (`bc-install`) | 🟡 probado en QEMU (con y sin LUKS); dentro de la imagen |
| ISO con instalador | ⛔ pendiente |
| Bloqueo seguro (`ext-session-lock`), tema claro, Música | ⛔ pendiente |
| Benchmarks / optimización | 🟡 primeras medidas; sin rigor |

## Paridad de funciones con Quantum Linux (inspiración, no copia)

El creador quiere para BC OS un conjunto de funciones comparable al de [Quantum Linux](https://github.com/QuantumLinux-arch) (QuantumLinux-arch, GPL-3.0-or-later), **usado solo como referencia de ideas**. BC OS **no copia sus logos, fondos, capturas ni CSS**: todo el diseño y el código son propios (decisión en [ADR 0005](docs/adr/0005-estilos-de-escritorio-y-paridad-quantum.md)). Se respetan además las restricciones de BC OS: **solo ARM64** y **sin Steam/Proton nativos** (no existen para ARM64).

| Función | Estado |
|---|---|
| Estilo de escritorio elegible (BC / Windows / Minimal) | 🟡 implementado |
| Modos (Relajación, Concentración, Noche) y widgets | 🟡 implementado |
| Tienda con Flathub (Flatpak de usuario) | 🟡 implementado; AUR pendiente |
| Asistente de bienvenida | 🟡 3 pasos (el plan original contempla más) |
| Antivirus (ClamAV) y «Centro BC» | ⛔ por hacer |
| Copias antes de actualizar (Btrfs + Snapper o equivalente), GRUB/arranque seguro en el instalador | ⛔ por hacer |
| Android con Waydroid | ⛔ por hacer, **experimental**, depende del kernel |
| Juegos x86 con FEX / box64 | ⛔ por hacer, **experimental** |
| Idiomas es / en / pt-BR, ventana de novedades tras actualizar | ⛔ por hacer |

## Objetivos (a medir, no garantizados)

RAM en reposo ≤ 700 MB · CPU en reposo ≈ ≤ 2 % · 60 FPS (120 donde se pueda) · arranque rápido. Se medirán sobre una VM de referencia documentada antes de afirmar nada.

## Hoja de ruta

`0` Viabilidad ✅ → `1` Base ✅ (arranca) → `2` BC Shell 🟡 → `3` Identidad visual 🟡 → `4` Apps → `5` Integración → `6` Optimización → `7` Instalador → `8` Beta pública. Detalle en [`ROADMAP.md`](ROADMAP.md) y trabajo vivo en [`PENDIENTE.md`](PENDIENTE.md).

## Estructura del repositorio

```
assets/branding/    logos e iconos oficiales BC
build/              pipeline de imagen (build-all, mkimage, rootfs, overlay)
core/               BC Core (Rust)
shell/              BC Shell (Qt 6 / QML)
icons/              pack de iconos (SPEC, fuentes SVG, build, lint, catálogo)
docs/               diseño, desarrollo, ADRs, capturas
tools/              diagnóstico de host, utilidades
.github/workflows/  CI en runners ARM64 (ci.yml, image.yml)
```

## Construir

```bash
sudo build/build-all.sh 0.3.2-alpha      # rootfs + shell + core + swayfx + configuración (host ARM64 o x86_64 con qemu-user)
```

En GitHub: **Actions → Imagen ARM64 → Run workflow** (opción *publicar* crea un prerelease). Guía completa: [`docs/development/BUILD.md`](docs/development/BUILD.md), pruebas: [`TESTING.md`](docs/development/TESTING.md), ARM64/VirtualBox: [`ARM64.md`](docs/development/ARM64.md).

## Atribuciones

- **Cursor:** tema «macOS» del proyecto [apple_cursor](https://github.com/ful1e5/apple_cursor) de ful1e5 (v2.0.1), licencia **GPL-3.0**, descargado y verificado durante la construcción de la imagen; el aviso se instala con el sistema.
- **Quantum Linux** (QuantumLinux-arch, GPL-3.0-or-later): referencia de ideas de funciones; no se reutilizan sus recursos gráficos ni textos.
- **swayfx** (WillPower3309, licencia MIT) y **sway / wlroots**: se compilan o instalan desde su origen; no se modifican.
- Pack de iconos y logos BC: propios, bajo la licencia del repositorio con marca reservada.

## Iconos y créditos de terceros

- **Qogir** (vinceliuice, GPL-3.0): iconos de aplicaciones y tipos de archivo (subconjunto en `icons/qogir/`, sin modificar). La interfaz del shell usa el pack BC propio (`icons/`).
- Cursor tipo macOS: `apple_cursor` de ful1e5 (GPL-3.0). swayfx (MIT), Alacritty, fish, sway y el resto: ver sus licencias en el sistema.

## Principios

Español primero · solo ARM64 · nada de afirmar lo no probado · seguridad intacta · optimizar midiendo · builds reproducibles · sin credenciales en el repo. Normas en [`CONTRIBUTING.md`](CONTRIBUTING.md) y [`SECURITY.md`](SECURITY.md). Reglas para agentes: [`CLAUDE.md`](CLAUDE.md).

---

<p align="center">© Borja Candel · Licencia GPL-3.0-or-later con marca y logos reservados (ver <a href="LICENSE"><code>LICENSE</code></a>)</p>
