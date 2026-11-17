## BC OS @VERSION@ — beta (prerrelease), para probar en máquinas virtuales

Imágenes de disco arrancables (UEFI) para **ARM64** (Mac con Apple Silicon) y **x86_64** (PC Intel/AMD).
También hay **ISO live** (UEFI) con el instalador (`sudo bc-install`).

### Probar en VirtualBox
1. Descomprime `BC-OS-@VERSION@-ARM64.vdi.zip` (Mac Apple Silicon) o `BC-OS-@VERSION@-x86_64.vdi.zip` (PC).
2. VirtualBox → Nueva: Linux / Arch Linux (**ARM 64-bit** o **64-bit**), ≥ 4 GB RAM, 2-4 CPU.
   **Sistema → Habilitar EFI (obligatorio, también en x86_64).** Pantalla: VMSVGA, 128 MB.
3. Disco: usar el `.vdi`. SSH opcional: Red → Avanzado → Reenvío de puertos TCP 2222 → 22 (`ssh -p 2222 bc@127.0.0.1`).
4. Arranca: **BC OS** o **BC OS (modo seguro)**. Login: usuario `bc`, contraseña `bcos` (cámbiala con `passwd`).
5. En la bienvenida elige **Máquina virtual** (se detecta sola).

### Novedades de 0.9.17 (sin publicar aún)
- **yay** instalado (AUR) con git y base-devel; se actualiza con BC OS.
- Ajustes ▸ General ▸ **Actualizaciones**: versión, buscar actualizaciones, lista de paquetes y «Actualizar ahora».
- Escritorio: **Obtener información, Renombrar, Copiar y Pegar**; arrastrar un icono a la **Papelera** del Dock.
- **Zoom** con doble clic en la barra de título o el botón verde (vuelve al tamaño anterior), con animación.
- Recordatorios que caben en el widget («y N más»), menús más redondeados, iconos de apps a mayor resolución.
- **PC con NVIDIA (nouveau)**: vuelve a sway con esquinas por GPU (Hyprland iba a saltos sin control de frecuencias).
- **Resolución nativa a la primera** también con Hyprland (antes podía elegir otra resolución y escala ×1,5–2).
- **Esquinas redondeadas en todas las ventanas siempre de serie** (también en máquinas virtuales, por software).
- **Liquid Glass al máximo de serie** (sin tinte).
- **Tienda**: catálogo al día antes de instalar (antes fallaba con la lista vieja), botón «Obtener/Quitar» según lo
  instalado de verdad, destacadas que existen en ARM y x86.
- **Avisos** sin sombra cortada en los bordes.
- **Nube «poof»** al sacar un icono del Dock; **miniatura flotante** de la captura abajo a la derecha (abre Vista previa).
- **Barras de desplazamiento como macOS**: ocultas, aparecen al desplazar, se ensanchan con el puntero y se arrastran;
  **rebote elástico** al llegar al final en Archivos, Ajustes, Tienda, Notas, Música y más.

### Novedades de 0.9.16
- **Liquid Glass como en liquid-glass-react**: desenfoque ligero (se ve el fondo curvado por la lente), tinte mínimo
  de serie (Ajustes ▸ Aspecto lo sube si quieres más contraste) y anillo especular.

### Novedades de 0.9.15
- **Liquid Glass nuevo** en todo el sistema (Dock, widgets, menús, paneles, barras laterales): refracción con mapa de
  desplazamiento, aberración cromática por canal, saturación al 140 % y anillo especular, portado a C++ de
  liquid-glass-react (MIT); también sin GPU.
- **Dock**: arrastrar iconos como macOS (los demás se apartan; soltar fuera lo quita), «Quitar del Dock» directo y
  ventanas minimizadas con su miniatura real y entrada suave.
- **fish** con prompt de colores e iconos (usuario, carpeta, rama de git y cambios).
- **bc-actualizar** sin conflictos de archivos: todo lo que traen los paquetes de BC se puede actualizar.

### Actualizaciones
- Con `sudo bc-actualizar` (o pulsando el aviso de actualizaciones) llega TODO lo nuevo: escritorio, apps, ajustes,
  fondos, sonidos, sesiones del login y el arranque animado (si cambia, se rehace el initramfs solo). Las novedades del
  escritorio se ven al cerrar sesión o reiniciar. Solo una imagen nueva cambia el instalador de la ISO live.

### Novedades de 0.9.14
- **Login rehecho como macOS**: tu fondo de pantalla desenfocado, avatar grande, campo de contraseña de vidrio, Reposo /
  Reiniciar / Apagar abajo y el entorno (BC OS o Dotfiles) en una pastilla discreta.
- **El login usa tu resolución, frecuencia y escala** (las de Ajustes ▸ Pantallas del último usuario que las cambió).
- **Esquinas suavizadas** en todo el cristal (barras laterales, paneles, Dock, widgets): ya no se ven pixeladas.
- **Genio** dibujado fila a fila con bordes suavizados y filtrado: sin escalones ni punteado.

### Novedades de 0.9.13
- **Genio de minimizar suave**: franjas de ~3 px en lugar de 32, sin escalones en los bordes del embudo (como macOS).
- **Mover ventanas**: al arrastrarla, la ventana se «levanta» con la sombra más marcada y vuelve con suavidad al soltarla.

### Novedades de 0.9.12
- **Minimizar y cerrar sin parpadeo**: la ventana se oculta cuando el genio (o la captura que se encoge) ya está encima;
  el genio sale al instante (la captura se decodifica una vez, no una por franja) y con más franjas, más suave.
- **Más fluido**: el cristal (Liquid Glass) se recorta en segundo plano con doble búfer; las animaciones de paneles,
  Dock y ventanas ya no esperan al recorte.
- **Mover ventanas**: el cristal de la barra lateral sigue a la ventana con sus esquinas redondeadas (antes se veían
  rectas mientras se arrastraba).
- **Tamaño de la interfaz** en Ajustes ▸ Pantallas: Auto (según los puntos por pulgada reales del monitor, como una
  Retina), 100 %, 125 %, 150 % o 200 %.
- Archivos: la barra de herramientas se adapta a ventanas estrechas (la búsqueda se encoge); Tienda con columnas
  según el ancho; ventanas con barra lateral con un ancho mínimo para que nada se monte.

### Novedades de 0.9.11
- **Resoluciones de MacBook**: Air 13″ (1470 × 956), Pro 14″ (1512 × 982), Air 15″ (1710 × 1112) y Pro 16″
  (1728 × 1117) en Ajustes ▸ Pantallas y en la bienvenida; en máquina virtual se crean al vuelo.
- **Frecuencia elegible** (60, 75, 120, 144 Hz… o «Máxima») en Ajustes ▸ Pantallas; se recuerda en cada inicio,
  también con Hyprland.
- Arreglado: «Aplicaciones» se salía de la pantalla en monitores pequeños (ahora se ajusta sin tapar el Dock).
- `htop` incluido.

### Novedades de 0.9.10
- **Pantalla completa en máquinas virtuales**: al poner la ventana de VirtualBox/UTM en pantalla completa (o cambiar su
  tamaño) el escritorio se adapta a ella aunque se haya elegido una resolución; la elegida se vuelve a aplicar al iniciar.
- **Modo claro**: el resalte de los iconos de la barra de menús se ve sobre fondos claros (antes era blanco sobre blanco).
- Fondo «Nieve» con el logo abajo a la derecha (ya no asoma detrás de los widgets).

### Novedades de 0.9.9
- **Arranque animado** nuevo: orbes de color que flotan, logo que crece con destello y barra fina como macOS.
- **10 fondos «Bosques»** 4K (5 claros y 5 oscuros), los primeros en Ajustes y en la bienvenida.
- **Semáforo y esquinas redondeadas en todas las apps** (Firefox incluido) y redimensionables desde el borde.
- **Hyprland con cualquier GPU real** (dedicada o integrada, también NVIDIA con nouveau); si falla, sway solo.
- **Resolución recordada** en cada inicio; en máquina virtual la bienvenida pregunta cuál quieres.
- **Aviso de actualizaciones** al arrancar: pulsarlo abre la Terminal con la actualización (solo pide la contraseña).
- Genio de macOS en dos fases (también sin GPU), Ajustes ▸ General y Pantallas rehechos, CaskaydiaCove Nerd Font
  en la Terminal, login solo con BC OS y Dotfiles.

### Novedades de 0.9.8
- Multimonitor: barra y Dock en cada pantalla (HDMI/DP como principal), foco al hacer clic como macOS, cristal fluido
  al arrastrar ventanas y arranque «cargar en RAM» para USB lentos.

### Novedades de 0.9.7
- **Actualizaciones firmadas**: el repositorio [bc] se firma con la clave de BC OS y el sistema solo acepta paquetes
  firmados; las novedades llegan solas (aviso + Tienda ▸ Actualizaciones o `sudo bc-actualizar`), sin volver a descargar la imagen.
- **ISO x86_64 arranca en BIOS** (PCs antiguos) además de UEFI; el instalador pone GRUB para BIOS si hace falta.
- Dock: la ampliación entra y sale suave (ya no se queda ampliada) y el menú del clic derecho sale encima del icono.
- Minimizar fluido sin GPU (efecto «Escala»); widgets que ya no desaparecen al cambiar fondo o aspecto.
- Bienvenida rehecha (aspecto, fondos y acento como macOS) y sale nada más entrar.
- Animaciones a la frecuencia más alta del monitor (60, 100, 120, 144 Hz…).
- Temas de fish: `bc-tema Aurora` (Medianoche, Aurora, Atardecer, Lavanda, Grafito, Papel) y rama de git en el prompt.

### Novedades de 0.9.6
- **ISO x86_64 también para PCs antiguos con BIOS** (además de UEFI), en CD o USB (balenaEtcher); el instalador pone GRUB
  para BIOS si el equipo no tiene UEFI.
- **Terminal de BC** como la de macOS (redondeada, translúcida, semáforo y título centrado, claro/oscuro, fluida sin GPU).
- Dock: la ampliación funciona encima de los iconos. Ventanas de BC redimensionables desde el borde y las esquinas.
- Cursor McMojave por hardware; mejor detección de máquina virtual; Liquid Glass con lente y luz en el borde.
- ISO live: entra sola y abre «Instalar BC OS».

### Novedades de 0.9.5 (modo claro)
- **Modo claro en todo**: Bienvenida, Control Center (los módulos no disponibles ya no se vuelven transparentes),
  Centro de notificaciones, pastillas «Editar controles/widgets» y logo; **«Automático»** cambia de verdad a claro
  de 8:00 a 20:00 (antes se quedaba siempre oscuro) y avisa a GTK y a las barras de título.
- **Terminal** con paleta clara u oscura que cambia en caliente con el aspecto (Alacritty y foot).

### Novedades de 0.9.4 (rendimiento)
- **Fluidez en máquinas virtuales**: en VirtualBox/VMware se usa siempre sway ligero (pixman), también con «Aceleración
  3D» (la 3D virtual de VirtualBox es lenta); Hyprland queda para equipos físicos o si se elige en Ajustes ▸ General.
- Las esquinas redondeadas por software (swayfx + llvmpipe) pasan a ser **opcionales** (Ajustes ▸ General): cargaban la CPU.
- Por software, las animaciones ya no escalan ventanas ni paneles (fundido y desplazamiento, mucho más ligeros).
- Arreglos: Calculadora («1..008»), color de la barra de menús según el fondo (texto oscuro sobre fondos claros, como macOS).

### Novedades de 0.9.3
- **Instalador gráfico «Instalar BC OS»** al estilo de macOS: en la **ISO live** se abre solo. Disco (con cifrado
  opcional), cuenta, región, resumen y progreso real; al acabar, «Reiniciar». En Terminal sigue `sudo bc-install`.
- **Animaciones**: avisos que entran y salen deslizándose (y se descartan deslizando), ventanas que crecen al
  expandir/restaurar, emergentes que brotan con un leve muelle.
- **Esquinas redondeadas en todas las ventanas también sin 3D** (VirtualBox ARM): swayfx con OpenGL ES por software,
  solo esquinas; si no arranca, sway clásico. Se desactiva con `bc.fx=0` en el arranque.
- **Iconos tipo macOS en todo el sistema**: Terminal «>_», carpetas especiales azules, tipos de archivo (PDF, ZIP, MP3…),
  apps Qt de terceros con el mismo tema. Terminal de 80×24 con título y saludo como macOS.
- **Ajustes del Sistema** en tarjetas agrupadas como macOS 27, Aspecto con vista previa de Liquid Glass, iconos nuevos.
- **20 fondos 4K nuevos** («Formas»): dunas, esferas, cristal líquido, eclipse, horizonte, seda, órbita…
- Liquid Glass: los emergentes brotan desde su origen con un leve muelle; botón verde con «Mover y redimensionar».
- Arreglados: esquina de la barra lateral de Archivos, corte del vidrio en barras laterales, Spotlight que tapaba el
  Dock, Calculadora en ventanas grandes, página de fondos sin desplazamiento, configuración de foot.

### Novedades de 0.9.0
- **Hyprland** por defecto si hay aceleración 3D: animaciones fluidas tipo macOS (muelle al abrir, cierre que encoge,
  Spaces deslizantes), esquinas continuas, sombras y **desenfoque real**. Sin 3D, sway por software automáticamente.
  En Mac: **UTM** con pantalla `virtio-gpu-gl-pci` para tener 3D (VirtualBox ARM no lo tiene).
- Arreglado el **bucle de login** en VirtualBox. Alacritty con marco de ventana.

### Novedades de 0.8.0
- **Imagen x86_64** además de ARM64 (en x86_64 incluye las Guest Additions de VirtualBox).
- **Primer arranque: máquina virtual o equipo físico** (detectado). En equipo físico con GPU: swayfx con esquinas,
  sombras y **desenfoque real** detrás de las ventanas. Cambiable en Ajustes ▸ General.
- **Repositorio propio `[bc]`** en GitHub: Tienda ▸ Actualizaciones o `sudo bc-actualizar`.
- Animaciones de macOS: cerrar y abrir ventanas, menús, Spotlight, Aplicaciones, Control Center; Control Center
  **editable**; Archivos ▸ **Recientes**; **10 fondos nuevos**; Mission Control y cristal por pantalla; modo claro legible;
  iconos MacOS-Like de antes.

### Novedades de 0.6.0: escritorio «Golden Gate»
- Escritorio por defecto rehecho al estilo de **macOS 27 Golden Gate**: barra de menús transparente, widgets de vidrio a la izquierda (baterías, uso del equipo o widget de otra app, recordatorios), Dock de vidrio con ampliación, pila de Descargas y Papelera, **Liquid Glass** con deslizador, modo **claro/oscuro** en caliente, fuente Inter.
- **Spotlight** (Ctrl/Súper+Espacio), **Aplicaciones** (F4 o el 2.º icono del Dock), **Mission Control** (Ctrl+↑ / F3, Ctrl+←/→ escritorios), **selector de apps** (Alt+Tab), **Control Center** y **Centro de notificaciones** (clic en la hora), minimizar al Dock con **efecto genio**, iconos en el escritorio.
- **Archivos** como Finder (iconos, lista, columnas, galería, Vista rápida con Espacio, etiquetas, pestañas) y **Ajustes del Sistema** nuevos. Terminal **Ghostty** (si su compilación falla, Alacritty). Sonidos propios.
- Estado y decisiones: `docs/escritorio/ESTADO.md`.

### Novedades de 0.5.0: entorno «Dotfiles (bspwm)»
- En el **login** (y en Configuración, y en la bienvenida) puedes elegir entre **BC OS** (sway) y **Dotfiles (bspwm)**, un entorno de mosaico X11 basado en `borjacandeel/dotfiles-2026`: **bspwm + sxhkd + polybar + picom + rofi + dunst**, con tus atajos (Súper+Intro, Súper+D, Ctrl+flechas, Ctrl+B Firefox…; lista en `/etc/bc/atajos-dotfiles.txt`, Súper+F1), fondo «Montañas», barra minimal (escritorios numerados, pista del reproductor, reloj) y la pantalla que se adapta a la ventana de la máquina virtual.
- Verificado en QEMU aarch64: el login muestra el selector, Xorg arranca, polybar y el fondo aparecen, Ctrl+Intro abre la terminal y rofi funciona con iconos. **Sin probar en VirtualBox** (Xorg allí puede comportarse distinto: si queda en negro, vuelve a elegir «BC OS» en el login y envíame `~/bc-session.log`).
- Configuración de Dotfiles en `~/.config/` (se copia solo la primera vez); `bc-dotfiles-setup --reset` restaura los originales.

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
- **Hardware real**: la ISO x86_64 arranca en un PC con BIOS y NVIDIA (GT 710); Hyprland con nouveau en ese equipo
  aún sin probar (si falla al arrancar, la sesión pasa sola a sway).
- Semáforo y esquinas de las apps de terceros: comprobado en Firefox; el resto de apps GTK/Qt sin probar una a una.
- Arranque animado (Plymouth) simulado, no visto aún en una máquina real.
- Android (Waydroid) y juegos x86 (FEX) aún no existen; el antivirus no tiene interfaz.
- El bloqueo es una superposición: no usa `ext-session-lock`. Contraseña por defecto pública: cámbiala con `passwd`.
- Wi-Fi/Bluetooth solo probados por sus analizadores (sin hardware en la VM).

SHA256 del zip en `SHA256SUMS`.
