## BC OS @VERSION@ (ARM64) — beta (prerrelease), para probar en máquinas virtuales

Imagen de disco arrancable (UEFI, ARM64). **Aún no hay ISO**: el instalador (`sudo bc-install`) viene dentro de la imagen.

### Probar en VirtualBox (Mac Apple Silicon)
1. Descomprime `BC-OS-@VERSION@-ARM64.vdi.zip`.
2. VirtualBox → Nueva: Linux / Arch Linux (ARM 64-bit), ≥ 2 GB RAM, 2 CPU. **Sistema → Habilitar EFI.** Gráficos: VMSVGA.
3. Disco: usar el `.vdi`. Red → Avanzado → Reenvío de puertos: TCP 2222 → 22 si quieres SSH (`ssh -p 2222 bc@127.0.0.1`).
4. Arranca: menú de 5 s con **BC OS** (animación de arranque con el logo, por defecto) y **BC OS (modo seguro, sin animación)**.
5. Aparece el **panel de login**. Usuario `bc`, contraseña `bcos` (**solo alpha**; cámbiala con `passwd`).

### Novedades de 0.4.1
- **La pantalla se adapta sola** al tamaño de la ventana de VirtualBox/QEMU o al monitor (`bc-display`; vigila los cambios de pantalla). En Configuración: `bc-display list` / `bc-display set 1920x1080`.
- **Iconos Qogir** (vinceliuice, GPL-3.0) para aplicaciones y tipos de archivo; interfaz con el pack BC. Paleta **Medianoche refinado**, más sobria.
- Animaciones: ventanas emergentes con entrada deslizante, notificaciones que entran por la derecha, rebote del Dock al abrir una app, cierre animado de las apps, transiciones en la bienvenida y **OSD** de volumen y brillo.
- **Súper+V**: historial del portapapeles. **Bloqueo y apagado de pantalla por inactividad** (10 y 15 min). Aviso de actualizaciones disponibles.
- Se quita del menú de arranque la entrada «efectos» (fallaba en VirtualBox); sigue disponible a mano añadiendo `bc.gpu=1` en el editor de arranque (solo con GPU real).

### Novedades de 0.4.0: «como Quantum, pero BC OS»
- **Asistente de bienvenida** en el primer inicio (3 pasos): estilo de escritorio, fondo y color de acento, y organización de ventanas (flotantes o mosaico, widgets, Modos). Se reabre desde Configuración.
- **Tres estilos de escritorio** elegibles al instante: **BC** (barra superior + Dock), **Windows** (barra de tareas + menú Inicio con búsqueda) y **Minimal** (solo la barra).
- **Widgets** en el escritorio (reloj, calendario, uso del equipo) y **Modos** en el Centro de control: Relajación, Concentración (No molestar) y Noche (tinte cálido).
- **Fondos propios** (Medianoche, Océano, Grafito, Plata) y **color de acento** configurable con los colores base de BC OS.
- **Tienda con Flathub** (apps Flatpak en tu usuario, sin contraseña) además de los repositorios de Arch Linux ARM.
- **Servicio de antivirus** (`bc-antivirus-service`, ClamAV por D-Bus) y `clamav` en la imagen; aún sin interfaz gráfica.
- Alacritty translúcido por defecto, cursor tipo macOS y animación de minimizar (apps de BC).
- **fish** como shell por defecto, con sugerencias automáticas, colores de BC, `zoxide` (cd inteligente), `fzf` (Ctrl+R/Ctrl+T), `eza` y `bat`.
- Capturas con `Impr`, `Súper+Mayús+S` (área) y `Alt+Impr` (ventana), al portapapeles y a Imágenes; ajustes de rendimiento (sysctl) y `fastfetch` con el logo de BC.
- Revisión de seguridad y robustez: la Tienda ya no se queda colgada con contraseña errónea, opciones validadas, nada se abre sobre la pantalla bloqueada, superficies a pantalla completa bien dimensionadas.
- Referencia de ideas: Quantum Linux (GPL-3.0-or-later). BC OS no copia sus logos, fondos ni capturas; ver README.

### Novedades de 0.3.2
- **Animación de minimizar** en las apps de BC (la ventana se encoge hacia el Dock y se despliega al volver).
- **Esquinas redondeadas en todas las ventanas** con swayfx: entrada de arranque **«BC OS (experimental: efectos con GPU real)»**. Verificado en QEMU: redondea ventanas y Dock, pero con render por software (llvmpipe) va lento y con fallos de dibujo, por eso NO es el modo por defecto. Las ventanas de BC y el Dock ya son redondeados en el modo normal; las de terceros (Alacritty, Firefox) solo con efectos. Desenfoque y sombras: opcionales en `~/.config/bc/sway-user.conf`.

### Novedades de 0.3.1
- Terminal por defecto **Alacritty** (translúcida, con respaldo a foot); ventanas de BC con transparencia suave.
- **Cursor tipo macOS** por defecto (tema libre apple_cursor de ful1e5, GPL-3.0).
- **Fondo sin parpadeos** al arrancar y al alternar mosaico/flotante (el fondo lo pinta sway; ya no se recarga la configuración en caliente).
- Dock con ventanas minimizadas; lanzador sin herramientas de desarrollo; instalador al día (dos entradas de arranque, Plymouth).
- Nota: no hay `picom` (es solo para X11); el desenfoque de fondo no está disponible en sway estándar.

### Novedades de 0.3.0: sway, mosaico y atajos
- **Compositor sway**: ventanas **flotantes** (por defecto, como macOS) o en **mosaico** (como bspwm). Botón en la barra superior o `Súper+Mayús+Espacio`.
- Atajos: **Ctrl+Intro** terminal, **Ctrl+B** Firefox, Ctrl+Espacio lanzador, Súper+E Archivos, Súper+Q cerrar, Súper+F pantalla completa, Súper+M minimizar. Lista completa: `/etc/bc/atajos.txt` (Súper+F1).
- **Menús globales tipo macOS** en la barra: nombre de la app enfocada y sus menús (Archivo, Editar, Ver, Ventana, Ayuda); las apps de BC reciben las acciones por D-Bus.
- **Dock con ventanas reales** (puntos de apps abiertas, enfocar al pulsar).
- BC Shell ahora es un panel (layer-shell) más apps en procesos aparte.

### Qué incluye
- **Login gráfico** (greetd + pantalla propia), **bloqueo** (Ctrl+Súper+Q o menú del logo BC), cerrar sesión, reiniciar, apagar y suspender con confirmación.
- **BC Shell**: barra superior y Centro de control con estado real (audio, red, batería, brillo, Bluetooth, No molestar), notificaciones del sistema,
  lanzador con búsqueda (Ctrl+Espacio o icono del Dock), **Archivos** (carpetas reales, nueva carpeta, renombrar, Papelera), **Monitor del sistema**,
  **Configuración**, **Tienda** (pacman), Terminal (`foot`) y Navegador (Firefox).
- Pack de **iconos BC**, fondo BC, animaciones en ventanas, Dock, menús y login (movimiento reducido en Configuración).
- Servicios **BC Core** (Rust, D-Bus) como servicios de usuario, SSH activado y cortafuegos.
- Si el login gráfico fallara 3 veces seguidas, el sistema arranca con **autologin** de `bc` para no quedarte fuera.

### Verificado (QEMU aarch64 UEFI + pruebas automáticas)
- Arranque → login (contraseña buena y mala) → escritorio → bloqueo (PAM) → cerrar sesión → vuelta al login; respaldo de autologin.
- Estado real de red y audio en la sesión; Tienda abierta; firefox y foot instalados.
- `ctest` del shell (carga QML es/en, protocolo greetd, notificaciones D-Bus, Papelera, lanzador, analizadores).

### No verificado / problemas conocidos
- **Esta versión puede no estar probada en VirtualBox ARM64** (las anteriores 0.1.2 y 0.1.3 sí arrancaron).
- Sin hardware real probado con sway. Tema claro, Música, Android (Waydroid) y juegos x86 (FEX/box64) aún no existen.
- El servicio de antivirus no tiene interfaz; Flathub necesita red y se verifica poco.
- El bloqueo es una superposición: no usa `ext-session-lock`, otra ventana podría recibir teclado. Contraseña por defecto pública.
- Música sin implementar; sin tema claro; Wi-Fi/Bluetooth solo probados por sus analizadores (sin hardware en la VM).
- Render por software (VirtualBox no tiene 3D): rendimiento no medido con precisión. RAM en reposo observada: ~250 MB usados tras iniciar sesión (QEMU, 2 GB).

SHA256 del zip en `SHA256SUMS`.
