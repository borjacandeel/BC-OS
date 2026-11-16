<p align="center">
  <img src="assets/branding/BC-icono-midnight-512.png" width="140" alt="BC OS">
</p>

<h1 align="center">BC OS</h1>

<p align="center"><b>LIGERO. POTENTE. FLUIDO.</b><br>
Sistema operativo Linux (ARM64 y x86_64) creado por <b>Borja Candel</b>, en español por defecto.</p>

<p align="center">
  <img alt="Versión" src="https://img.shields.io/badge/versi%C3%B3n-0.9.0--beta%20(prerelease)-2F7BFF">
  <img alt="Arquitectura" src="https://img.shields.io/badge/arquitectura-ARM64%20%7C%20x86__64-04111F">
  <img alt="Base" src="https://img.shields.io/badge/base-Arch%20Linux%20%2F%20ARM-1793D1">
  <img alt="Idioma" src="https://img.shields.io/badge/idioma-espa%C3%B1ol%20(es__ES)-C60B1E">
  <img alt="Estado" src="https://img.shields.io/badge/estado-beta%20experimental-FFB340">
</p>

BC OS es un Linux ligero y en español para **ARM64** (sobre **Arch Linux ARM**) y **x86_64** (sobre **Arch Linux**), con compositor **Hyprland** (con aceleración 3D) o **sway** (sin ella) y un escritorio propio, **BC Shell** (Qt 6 / QML). Desde la serie 0.6 su escritorio por defecto es **«Golden Gate»**: una réplica del aspecto y del comportamiento de macOS 27 Golden Gate, hecha con código y recursos propios o libres (no usa recursos de Apple). Se prueba en máquinas virtuales (VirtualBox en Mac Apple Silicon o PC, QEMU) y se adapta a equipos físicos con GPU.

<p align="center">
  <img src="docs/escritorio/capturas/1-escritorio.jpg" alt="Escritorio Golden Gate de BC OS: barra de menús transparente, widgets de vidrio a la izquierda, fondo de ondas con el logo BC y Dock de vidrio" width="880">
  <br><sub>Escritorio Golden Gate: barra de menús, widgets de vidrio, iconos en el escritorio, aviso y Dock. Captura del shell en el anfitrión de desarrollo.</sub>
</p>

> **Estado honesto:** beta experimental. La **0.9.0-beta** sale para ARM64 y x86_64 (disco VDI e ISO live) con **Hyprland** por defecto si hay 3D; la 0.6.0-beta arrancó en QEMU aarch64 con login y escritorio correctos. Muchas piezas están compiladas y vistas en capturas, pero **pendientes de prueba real**. Ver [estado y pendientes](#estado-honesto-de-golden-gate).

---

## Escritorio Golden Gate

Qué incluye (detalle técnico y decisiones en [`docs/escritorio/ESTADO.md`](docs/escritorio/ESTADO.md)):

- **Barra de menús transparente**: logo BC, app activa en negrita, menús globales (Archivo, Edición, Visualización, Ventana, Ayuda), iconos de estado y reloj.
- **Widgets de vidrio** a la izquierda: baterías, uso del equipo (o widget de otra app) y recordatorios; arrastrables.
- **Dock de vidrio**: ampliación, punto de app abierta, rebote, apps **recientes**, **pila** de Descargas, **Papelera** (vacía/llena), minimizadas y ocultación automática.
- **Liquid Glass** con **deslizador** de intensidad (sin shaders; ver limitaciones).
- Modo **claro / oscuro** en caliente (shell, apps BC, GTK y sway).
- **Spotlight**: apps, archivos, cálculos y acciones.
- **Aplicaciones**: rejilla por páginas con búsqueda.
- **Mission Control** con escritorios («+», arrastrar ventanas entre escritorios) y **selector de apps**.
- Minimizar al Dock con **efecto genio**.
- **Control Center** (Wi-Fi, Bluetooth, red, Concentración, mosaico, aspecto, captura, bloqueo, portapapeles, brillo, sonido, reproducción) y **Centro de notificaciones** (historial y calendario).
- **Archivos** tipo Finder: barra lateral con Favoritos/Ubicaciones/Etiquetas, vistas de iconos/lista/columnas/galería, Vista rápida, etiquetas, pestañas y búsqueda.
- **Ajustes del Sistema** nuevos: Aspecto, Escritorio y Dock, Fondo, Notificaciones y los paneles anteriores.
- **Bloqueo e inicio de sesión** estilo Golden Gate.
- **Sonidos propios** (aviso, papelera, bloqueo, volumen, captura, error).
- Además: tema GTK MacTahoe para apps externas, fuente Inter, iconos MacOS-Like, cursor McMojave, terminal Ghostty (Alacritty si su compilación falla) y arranque con barra blanca.

### Capturas

<table>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/1-escritorio.jpg" alt="Escritorio con widgets de vidrio, iconos y Dock"><br><sub><b>Escritorio</b>: widgets de vidrio, iconos del escritorio, aviso y Dock.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/2-control-center.jpg" alt="Control Center abierto arriba a la derecha"><br><sub><b>Control Center</b>: Wi-Fi, Bluetooth, red, Concentración, mosaico, accesos rápidos, pantalla, sonido y reproducción.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/3-aplicaciones.jpg" alt="Rejilla de Aplicaciones con buscador sobre el fondo desenfocado"><br><sub><b>Aplicaciones</b> (F4): rejilla con búsqueda sobre el fondo desenfocado.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/4-ventanas.jpg" alt="Ventanas de Archivos y Ajustes del Sistema con semáforos"><br><sub><b>Ventanas</b>: Archivos tipo Finder y Ajustes del Sistema (Aspecto).</sub></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="docs/escritorio/capturas/5-bloqueo.jpg" alt="Pantalla de bloqueo con fecha, hora grande y campo de contraseña" width="50%"><br><sub><b>Bloqueo</b> (Ctrl+Súper+Q): fecha, hora y contraseña sobre el fondo.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/6-monitor.jpg" alt="Monitor de Actividad"><br><sub><b>Monitor de Actividad</b>: procesos reales, CPU y memoria.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/7-tienda.jpg" alt="Tienda"><br><sub><b>Tienda</b>: instalar apps con estilo App Store.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/8-apps-nuevas.jpg" alt="Calculadora, Notas y Vista previa"><br><sub><b>Calculadora, Notas y Vista previa</b>: apps BC nuevas.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/9-ajustes-dock.jpg" alt="Ajustes ▸ Escritorio y Dock"><br><sub><b>Ajustes ▸ Escritorio y Dock</b>: tamaño, ampliación, esquinas activas.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/10-calendario-recordatorios.jpg" alt="Calendario y Recordatorios"><br><sub><b>Calendario y Recordatorios</b>: vista de mes y listas.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/11-vibrancy.jpg" alt="Vibrancy"><br><sub><b>Vibrancy</b>: barras laterales de vidrio.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/12-widgets.jpg" alt="Widgets"><br><sub><b>Widgets</b>: galería editable, calendario y reloj.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/13-musica.jpg" alt="Música"><br><sub><b>Música</b>: biblioteca local con mpv.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/14-spotlight.jpg" alt="Spotlight"><br><sub><b>Spotlight</b>: resultados por secciones.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/18-modo-claro.jpg" alt="Modo claro"><br><sub><b>Modo claro</b>: widgets y avisos de vidrio claro, legibles sobre fondos oscuros.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/escritorio/capturas/15-control-center-editable.jpg" alt="Control Center editable"><br><sub><b>Control Center editable</b>: «Editar controles…», quitar con «−» y añadir Turno de noche, Calculadora, Nota rápida, Ajustes.</sub></td>
    <td width="50%"><img src="docs/escritorio/capturas/16-recientes.jpg" alt="Archivos Recientes"><br><sub><b>Archivos ▸ Recientes</b>: agrupado por fecha, con miniaturas reales.</sub></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="docs/escritorio/capturas/17-bienvenida-equipo.jpg" alt="Bienvenida: máquina virtual o equipo físico" width="70%"><br><sub><b>Primer arranque</b>: máquina virtual (ligero) o equipo físico (GPU, desenfoque real); se detecta solo.</sub></td>
  </tr>
</table>

<sub>Capturas del shell renderizado en el anfitrión de desarrollo (por eso aparece el usuario <code>root</code>), no dentro de la máquina virtual.</sub>

### Fondos de pantalla

Colección propia «Ondas» con el logo BC en el centro, en tonos oscuros, claros y minimalistas (4K, generados con
`assets/wallpapers/generar-fondos.py`). Se eligen en **Ajustes ▸ Fondo de pantalla** o en la bienvenida.

<table>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/ondas.jpg" alt="Fondo Ondas"><br><sub><b>Ondas</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/aurora.jpg" alt="Fondo Aurora"><br><sub><b>Aurora</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/atardecer.jpg" alt="Fondo Atardecer"><br><sub><b>Atardecer</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/rubi.jpg" alt="Fondo Rubí"><br><sub><b>Rubí</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/bosque.jpg" alt="Fondo Bosque"><br><sub><b>Bosque</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/carbon.jpg" alt="Fondo Carbón"><br><sub><b>Carbón</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/noche.jpg" alt="Fondo Noche"><br><sub><b>Noche</b> · minimal oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/amanecer.jpg" alt="Fondo Amanecer"><br><sub><b>Amanecer</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/lavanda.jpg" alt="Fondo Lavanda"><br><sub><b>Lavanda</b> · claro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/menta.jpg" alt="Fondo Menta"><br><sub><b>Menta</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/niebla.jpg" alt="Fondo Niebla"><br><sub><b>Niebla</b> · minimal claro</sub></td>
  </tr>
</table>

Colección «Formas» (20 fondos 4K de formas minimalistas al estilo macOS, con el logo BC en distintos sitios; generados con
`assets/wallpapers/generar-formas.py`):

<table>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/dunas.jpg" alt="Fondo Dunas"><br><sub><b>Dunas</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/dunas-noche.jpg" alt="Fondo Dunas de noche"><br><sub><b>Dunas de noche</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/esferas.jpg" alt="Fondo Esferas"><br><sub><b>Esferas</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/esferas-luz.jpg" alt="Fondo Esferas"><br><sub><b>Esferas</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/anillos.jpg" alt="Fondo Anillos"><br><sub><b>Anillos</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/cristal.jpg" alt="Fondo Cristal líquido"><br><sub><b>Cristal líquido</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/seda.jpg" alt="Fondo Seda"><br><sub><b>Seda</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/pliegues.jpg" alt="Fondo Pliegues"><br><sub><b>Pliegues</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/bruma.jpg" alt="Fondo Bruma"><br><sub><b>Bruma</b> · claro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/nebulosa.jpg" alt="Fondo Nebulosa"><br><sub><b>Nebulosa</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/horizonte.jpg" alt="Fondo Horizonte"><br><sub><b>Horizonte</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/colinas.jpg" alt="Fondo Colinas"><br><sub><b>Colinas</b> · claro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/arcos.jpg" alt="Fondo Arcos"><br><sub><b>Arcos</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/cuarzo.jpg" alt="Fondo Cuarzo"><br><sub><b>Cuarzo</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/orbita.jpg" alt="Fondo Órbita"><br><sub><b>Órbita</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/topografia.jpg" alt="Fondo Topografía"><br><sub><b>Topografía</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/petalos.jpg" alt="Fondo Pétalos"><br><sub><b>Pétalos</b> · oscuro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/burbujas.jpg" alt="Fondo Burbujas"><br><sub><b>Burbujas</b> · oscuro</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="docs/escritorio/fondos/cinta.jpg" alt="Fondo Cinta"><br><sub><b>Cinta</b> · claro</sub></td>
    <td width="33%"><img src="docs/escritorio/fondos/eclipse.jpg" alt="Fondo Eclipse"><br><sub><b>Eclipse</b> · oscuro</sub></td>
  </tr>
</table>

### Atajos principales

| Atajo | Acción |
|---|---|
| `Ctrl+Espacio` / `Súper+Espacio` | Spotlight |
| `F4` (o `Súper+A`) | Aplicaciones |
| `Ctrl+↑` / `F3` | Mission Control |
| `Ctrl+←` / `Ctrl+→` | Escritorio anterior / siguiente |
| `Alt+Tab` (o `Súper+Tab`) | Selector de apps (con Mayús, hacia atrás) |
| `Súper+M` | Minimizar al Dock (`Súper+Mayús+M`: restaurar) |
| `Ctrl+Súper+Q` | Bloquear pantalla |
| `Ctrl+Intro` · `Ctrl+B` · `Súper+E` | Terminal · Firefox · Archivos |
| `Súper+F1` | Lista completa de atajos |

Lista completa: [`build/overlay/etc/bc/atajos.txt`](build/overlay/etc/bc/atajos.txt) (en el sistema, `/etc/bc/atajos.txt`). Personalización en `~/.config/bc/sway-user.conf`.

### Sesiones en el login

| Sesión | Qué es |
|---|---|
| **BC OS** | El escritorio **Golden Gate** (por defecto). |
| **BC clásico** | El escritorio anterior de BC Shell (misma sesión sway con `BC_CLASSIC=1`). Úsala si algo de Golden Gate falla. |
| **Dotfiles (bspwm)** | Entorno de mosaico X11 (bspwm, sxhkd, polybar, picom, rofi, dunst) basado en `borjacandeel/dotfiles-2026`. |

La sesión por defecto también se puede fijar en **Ajustes ▸ General ▸ «Entorno al iniciar sesión»**.

## Estado honesto de Golden Gate

**Verificado:**
- 0.6.0-beta arrancada en **QEMU aarch64**: login y escritorio correctos.
- Componentes compilados y revisados en el anfitrión con capturas (las de arriba). Comprobado en sway real (headless, aarch64) el posicionamiento de semáforos y del genio.

**Hecho en 0.8.0-beta** (compilado y visto en capturas; **pendiente de prueba en VirtualBox**):
- Animaciones de macOS (abrir/cerrar ventanas, genio, menús, Spotlight, Aplicaciones, Control Center, Mission Control).
- Materiales de vidrio en claro y oscuro, Control Center editable, Archivos ▸ Recientes, multimonitor, 10 fondos nuevos.
- Imagen **x86_64** (Arch Linux) además de ARM64, **ISO live UEFI**, instalador con GRUB y arranque seguro opcionales.
- Repositorio propio `[bc]`, instantáneas antes de actualizar (`bc-restaurar`), Tienda sin contraseña (polkit),
  bloqueo a prueba de fallos, **Ghostty**, box64 (programas x86_64 en ARM) y `bc-rendimiento`.

**Pendiente:** firma GPG del repositorio, idiomas, Android y probar todo en máquinas virtuales con y sin 3D.

**Limitaciones conocidas:**
- Cristal (Liquid Glass): con Hyprland desenfoca de verdad lo que hay detrás; con sway por software refleja el **fondo** desenfocado.
- Gestos: con Hyprland el cambio de escritorio sigue al dedo; con sway son discretos (se disparan al terminar).
- Ventanas de apps externas: con Hyprland, animaciones del compositor; con sway, cierre con captura que se encoge y apertura con fundido.
- Multimonitor: barra, Dock, cristal y Mission Control por pantalla; los widgets, en la principal.
- Iconos de apps: tema MacOS-Like (elegido por el creador).
- Duraciones, curvas y algunas medidas son estimaciones (Apple no las publica); ver «Sin confirmar» en [`ESTADO.md`](docs/escritorio/ESTADO.md).
- Generales: el bloqueo de BC es una capa del panel (si el panel cae, entra swaylock con `ext-session-lock`); sin hardware real probado; contraseña por defecto pública y SSH activo (solo para máquinas virtuales).

---

## Descargar y probar

Imágenes publicadas: [**Releases**](https://github.com/borjacandeel/BC-OS/releases) (prerelease). Cada release incluye `BC-OS-<versión>-ARM64.vdi.zip`, `BC-OS-<versión>-x86_64.vdi.zip`, las ISO live y `SHA256SUMS`. Última: **0.8.0-beta**.

1. Descomprime el `.zip` → `.vdi`. Comprueba `shasum -a 256`.
2. VirtualBox → **Nueva**: Linux / Arch Linux (**ARM 64-bit** en Mac Apple Silicon o **64-bit** en PC), ≥ 4 GB RAM, 2-4 CPU.
3. **Sistema → Habilitar EFI**. Disco: usar el `.vdi` existente. Gráficos: VMSVGA.
4. Opcional: Red → Avanzado → Reenvío de puertos TCP 2222 → 22 para SSH (`ssh -p 2222 bc@127.0.0.1`).
5. Arranca: menú de 5 s (arranque normal o modo seguro) → **panel de login**. Usuario **`bc`**, contraseña **`bcos`** (**solo alpha/beta de prueba**; cámbiala con `passwd`).

También se prueba sin VirtualBox con QEMU (`qemu-system-aarch64 -M virt` + UEFI AAVMF); ver [`docs/development/BUILD.md`](docs/development/BUILD.md). También hay **ISO live** (arranca en RAM, con el instalador `sudo bc-install`). En la bienvenida elige **Máquina virtual**.

## Versiones

| Versión | Estado | Qué trae |
|---|---|---|
| `0.1.0` – `0.1.3-alpha` | publicadas | Primeras imágenes ARM64. **0.1.2 y 0.1.3 arrancan en VirtualBox ARM64** (render por software); 0.1.3 trae Dock y Archivos reales, iconos y fondo BC, `bc-install` y animación de arranque. |
| `0.2.0-alpha` | publicada | Escritorio funcional: login (greetd), bloqueo, apagado, Centro de control, notificaciones, Archivos + Papelera, Monitor, Configuración, Tienda, BC Core y SSH. Verificada en QEMU. |
| `0.3.x-alpha` | publicadas | **sway** (mosaico/flotante), menús globales por app, Dock con ventanas reales, Alacritty, animación de minimizar y swayfx experimental. |
| `0.4.0-beta` / `0.4.1-beta` | publicadas (prerrelease) | Asistente de bienvenida, estilos, widgets, Modos, Flathub, fish, servicio de antivirus; resolución adaptable (`bc-display`), iconos Qogir, portapapeles (Súper+V). |
| `0.5.0-beta` | prerrelease, en pruebas | Entorno **Dotfiles (bspwm)** elegible en el login. Verificado en QEMU; sin probar en VirtualBox. |
| `0.9.0-beta` | prerelease | **Hyprland** por defecto con 3D (animaciones fluidas tipo macOS, desenfoque real), sway por software si no; arreglo del bucle de login en VirtualBox; Alacritty con marco. |
| `0.8.0-beta` | prerelease | **x86_64** + ISO live, primer arranque VM/equipo físico, repositorio `[bc]`, instantáneas, Tienda sin contraseña, Ghostty, box64, instalador con GRUB/Secure Boot, Control Center editable, Recientes, 10 fondos, animaciones. |
| `0.7.0-beta` | prerelease | Apps nuevas (Monitor, Tienda, Calculadora, Notas, Vista previa, Calendario, Recordatorios, Música), vibrancy, widgets editables, animaciones de cerrar/minimizar. |
| `0.6.0-beta` | prerelease | Escritorio **Golden Gate** por defecto; «BC clásico» en el login. Arranca en QEMU con login y escritorio correctos. |
| → `1.0.0` | planificada | Prueba completa en VirtualBox y hardware, firma GPG del repositorio y primera estable. Es un hito, no una promesa. |

Detalle de cada versión en [`build/RELEASE-NOTES.md`](build/RELEASE-NOTES.md) y en las [notas de cada release](https://github.com/borjacandeel/BC-OS/releases). Capturas de versiones anteriores (BC clásico, login antiguo, Tienda, arranque) en [`docs/screenshots/`](docs/screenshots/).

## Actualizaciones: repositorio propio `[bc]`

BC OS se actualiza desde su propio repositorio pacman, publicado en GitHub Releases
([`repo-aarch64`](https://github.com/borjacandeel/BC-OS/releases/tag/repo-aarch64) y [`repo-x86_64`](https://github.com/borjacandeel/BC-OS/releases/tag/repo-x86_64)) por `.github/workflows/repo.yml` en cada cambio:
`bc-shell`, `bc-core`, `bc-escritorio` y el metapaquete `bc-os`. En el sistema: **Tienda ▸ Actualizaciones** o
`sudo bc-actualizar`. Detalles en [`build/repo/LEEME.md`](build/repo/LEEME.md).

## Descargas: ARM64 y x86_64, disco o ISO live

Cada versión trae, para **ARM64** (Mac Apple Silicon, Raspberry Pi…) y **x86_64** (PC; Arch Linux normal):
`BC-OS-<versión>-<arq>.vdi.zip` (disco para VirtualBox) y `BC-OS-<versión>-<arq>.iso` (live UEFI, con el instalador).
En VirtualBox hay que **activar EFI**. Instalar: `sudo bc-install` (opciones `--bootloader grub` y `--secure-boot`).

## Sistema

- **Instantáneas**: antes de cada instalación o actualización se guarda el estado de los paquetes y `/etc`;
  `bc-restaurar` (o Ajustes ▸ General) vuelve atrás.
- **Tienda sin contraseña** para administradores con sesión activa (polkit, ayudante restringido `bc-paquetes`).
- **Bloqueo a prueba de fallos**: si el panel se cae con la pantalla bloqueada, swaylock la protege al instante.
- **Programas x86_64 en ARM** con box64 (se abren solos). **`bc-rendimiento`**: informe de arranque, memoria y CPU.

## Animaciones fluidas: Hyprland

Con aceleración 3D (equipo real, **UTM** en Mac con pantalla `virtio-gpu-gl-pci`, VirtualBox x86 con «Habilitar
aceleración 3D», QEMU con virgl) BC OS arranca **Hyprland** con animaciones tipo macOS: apertura con muelle, cierre
que encoge y desvanece, Spaces que se deslizan, menús con zoom, esquinas continuas, sombras y **desenfoque real**
detrás del vidrio. Gestos de 3 dedos que siguen al dedo. Sin 3D (p. ej. VirtualBox en Mac ARM) entra **sway** por
software automáticamente; si Hyprland fallara, también. Configuración: `/etc/bc/hypr/hyprland.lua` (personalizable en
`~/.config/bc/hypr-user.lua`); forzar uno u otro: `~/.config/bc/compositor` (`hyprland` o `sway`).

## Primer arranque: máquina virtual o equipo físico

La bienvenida pregunta dónde se ejecuta BC OS (y lo detecta solo). **Máquina virtual** (VirtualBox, UTM, QEMU):
dibujo por software, ligero. **Equipo físico**: GPU con esquinas, sombras y desenfoque real detrás de las ventanas.

## Arquitectura

| Pieza | Elección |
|---|---|
| Base | Arch Linux ARM (aarch64), kernel Linux estándar, systemd, pacman |
| Gráficos | Wayland · compositor **sway** (mosaico y flotante) · respaldo por software · swayfx opcional con GPU real (`bc.gpu=1`: radios y desenfoque real) |
| Shell | **BC Shell**: Qt 6 / QML; proceso «panel» con superficies `layer-shell` (barra, Dock, widgets, Spotlight, Mission Control…) + apps BC (`bc-shell --app …`) |
| Login | greetd + pantalla propia; sesiones BC OS, BC clásico y Dotfiles (bspwm) |
| Control | D-Bus `org.bcos.Shell` · `bc-ctl` (`spotlight`, `mission`, `switcher`…) · `bc-session` · `bc-appearance` |
| Aspecto | Tokens únicos en `shell/qml/Theme.qml` · Inter · MacTahoe (GTK) · MacOS-Like (iconos) · McMojave (cursor) |
| Servicios | **BC Core**: Rust + D-Bus (`bc-daemon`, settings, update, security, hardware, performance) |
| Sistema | PipeWire · NetworkManager · zram · nftables · arranque UEFI con systemd-boot |
| Imagen | GPT: ESP FAT32 + ext4, construida en CI ARM64 nativo |

Decisiones y motivos: [`ARCHITECTURE.md`](ARCHITECTURE.md), [`docs/adr/`](docs/adr/) y [`docs/escritorio/ESTADO.md`](docs/escritorio/ESTADO.md).

## Estructura del repositorio

```
assets/             logos BC, fondos y sonidos propios
build/              pipeline de imagen (build-all, mkimage, rootfs, overlay)
core/               BC Core (Rust)
shell/              BC Shell (Qt 6 / QML)
icons/              pack de iconos BC y temas de terceros
docs/               escritorio Golden Gate, diseño, desarrollo, ADRs, capturas
tools/              diagnóstico de host, utilidades
.github/workflows/  CI en runners ARM64 (ci.yml, image.yml)
```

## Construir

```bash
sudo build/build-all.sh 0.6.0-beta      # rootfs + shell + core + configuración (host ARM64 o x86_64 con qemu-user)
```

En GitHub: **Actions → Imagen ARM64 → Run workflow** (opción *publicar* crea un prerelease). Guía completa: [`docs/development/BUILD.md`](docs/development/BUILD.md), pruebas: [`TESTING.md`](docs/development/TESTING.md), ARM64/VirtualBox: [`ARM64.md`](docs/development/ARM64.md). Trabajo vivo: [`PENDIENTE.md`](PENDIENTE.md).

## Créditos y licencias de terceros

BC OS **no copia recursos de Apple** (iconos, fondos, sonidos, fuentes ni código): el fondo «Ondas», los sonidos, los logos y el pack de iconos BC son propios, y lo demás procede de proyectos libres:

| Recurso | Autor | Licencia |
|---|---|---|
| Iconos **MacOS-Like** (tema por defecto, sobre MacTahoe) | Scrimas | GPL-3.0 |
| Cursores **McMojave** | vinceliuice | GPL-3.0 |
| Tema GTK **MacTahoe** (claro/oscuro) | vinceliuice | MIT |
| Fuente **Inter** (interfaz) | Proyecto Inter | OFL-1.1 |
| **CaskaydiaCove Nerd Font** (terminal y monoespaciada) | Nerd Fonts | OFL-1.1 |
| Iconos **Qogir** (respaldo) | vinceliuice | GPL-3.0 |
| **sway / wlroots**, **swayfx** | sus autores | MIT |

**Quantum Linux** (GPL-3.0-or-later) sirvió como referencia de ideas para funciones de la serie 0.4; no se reutilizan sus recursos. El resto de paquetes del sistema conserva sus licencias, instaladas con él.

## Principios

Español primero · solo ARM64 · nada de afirmar lo no probado · seguridad intacta · optimizar midiendo · builds reproducibles · sin credenciales en el repo. Normas en [`CONTRIBUTING.md`](CONTRIBUTING.md) y [`SECURITY.md`](SECURITY.md). Reglas para agentes: [`CLAUDE.md`](CLAUDE.md).

---

<p align="center">© Borja Candel · Licencia GPL-3.0-or-later con marca y logos reservados (ver <a href="LICENSE"><code>LICENSE</code></a>)</p>
