# Escritorio «Golden Gate» de BC OS — estado y decisiones

Encargo del creador (2026-11-15): que el escritorio por defecto de BC OS se vea y se comporte como macOS 27
Golden Gate, sobre la misma base (Arch Linux ARM aarch64, sway, BC Shell Qt6/QML, greetd), con la sesión anterior
disponible en el login como **«BC clásico»**.

## Arquitectura
- **Compositor**: sway (sin cambios). swayfx opcional con GPU (`bc.gpu=1`): radio 20, desenfoque real de capas.
- **BC Shell** (`shell/`): un proceso «panel» con superficies wlr-layer-shell y apps BC (`bc-shell --app …`).
  - Fondo (capa background): `Wallpaper` (solo pruebas), `DesktopIcons`, `DesktopWidgets`.
  - Barra de menús (`MenuBar.qml`), Dock (`DockGG.qml`), semáforos de ventanas externas (`WindowChrome.qml`).
  - Capa emergente: menús (`MenuPopup.qml`), Control Center (`ControlCenterGG.qml`), Centro de notificaciones
    (`NotificationCenter.qml`), Spotlight (`Spotlight.qml`), Aplicaciones (`Launchpad.qml`), pila de Descargas,
    menús contextuales.
  - Superposiciones: Mission Control (`MissionControl.qml`), selector de apps (`AppSwitcher.qml`), efecto genio
    (`Genie.qml`), bloqueo/bienvenida/carga.
  - Material: `Glass.qml` + `GlassProvider` (C++).
  - Datos: `Batteries`, `Reminders`, `WidgetHost`, `QuickTools` (Wi-Fi, Bluetooth, reproducción, búsqueda de
    archivos, calculadora, capturas grim), `SoundPlayer` (`src/desktopdata.*`).
  - **Tokens únicos**: `shell/qml/Theme.qml`, bloque «Tokens de diseño Golden Gate» (medidas de la captura,
    colores claro/oscuro, cristal, tipografía, duraciones y curvas). Para afinar tras la prueba: tocar solo ahí.
- **Sesión**: `bc-session` (con `--classic` → `BC_CLASSIC=1`), `bc-appearance` (claro/oscuro en caliente),
  atajos en `build/overlay/etc/bc/sway/config`, acciones D-Bus `bc-ctl spotlight|mission|switcher|…`.

## Decisiones
1. **No se cambia compositor, toolkit ni gestor de sesión.** sway + Qt ya dan capas, IPC y rendimiento en ARM sin GPU;
   cambiar a KWin/Hyprland rompería el arranque probado y exige GPU (VirtualBox no la tiene).
2. **Liquid Glass sin shaders**: con el renderizador por software de Qt no hay `ShaderEffect`. El fondo se desenfoca
   una vez en C++ (reducción a mitades + ampliación suave ≈ gaussiano, sin ruido) y cada superficie pide su recorte
   redondeado (`image://glass/…`); encima tinte (deslizador), reflejo especular, borde luminoso y sombra.
3. **Tokens en `Theme.qml`** (no en un `Tokens.qml` aparte): Qt 6.4 detecta un ciclo entre dos singletons que importan
   el módulo.
4. **Tipografía**: Inter (OFL) en la interfaz por métricas cercanas a SF Pro (interletrado −0,15);
   CaskaydiaCove Nerd Font queda para terminal y monoespaciada.
5. **Atajos como en macOS**: Ctrl+←/→ cambia de escritorio y Ctrl+↑ abre Mission Control (antes Ctrl+flechas movía el
   foco; ahora el foco va con Súper+flechas). Spotlight Ctrl/Súper+Espacio, Aplicaciones F4, selector Alt/Súper+Tab.
6. **Reloj de la barra en 12 h** («Dom 15 nov 12:19 a.m.») porque así sale en la captura.
7. **Menús globales**: las apps BC tienen menús reales; en apps externas Edición envía las pulsaciones reales con
   `wtype` (no hay protocolo de menú global en Wayland que sway exponga).
8. **Efecto genio** por franjas (28 tiras de la captura grim de la ventana) en lugar de shader.

## Estado por componente
| # | Componente | Estado |
|---|---|---|
| 1 | Escritorio: fondo, iconos (~/Escritorio), selección con rectángulo, arrastre con posición guardada, menús contextuales | hecho, compilado; capturas en anfitrión |
| 2 | Widgets: baterías (sysfs + BlueZ), app de terceros (JSON), recordatorios (JSON), arrastrables | hecho; verificado en captura (sin baterías reales en el anfitrión) |
| 3 | Barra de menús: logo BC, app activa en negrita, menús, estado (mosaico, concentración, ES, batería con %, red, Control Center), reloj | hecho; superpuesta a la captura |
| 4 | Menús: menú BC, menú de app, Archivo/Edición/Visualización/Ventana/Ayuda, atajos con símbolos, submenús, marcas | hecho |
| 5 | Dock: ampliación coseno, punto de abierta, rebote, reordenar arrastrando, Mantener/Quitar, apps abiertas no fijadas, minimizadas, pila Descargas, Papelera (vacía/llena), ocultación automática | hecho, compilado; pendiente de prueba real |
| 6 | Menús contextuales: escritorio, iconos, widgets, Dock, Archivos, botón verde | hecho |
| 7 | Ventanas: semáforo con símbolos al pasar, gris en inactivas, pantalla completa, mosaico (mitades/rellenar/centrar), ventanas BC radio 20 | hecho |
| 8 | Mission Control (Spaces, «+», arrastrar ventana a escritorio), escritorios, selector de apps | hecho, compilado; pendiente de prueba real |
| 9 | Gestos de trackpad | **parcial**: `bindgesture` de sway (3/4 dedos) es discreto: se dispara al terminar, **no sigue el dedo** |
| 10 | Multimonitor: barra, Dock y cristal por pantalla, conexión en caliente | **parcial**: widgets y Mission Control solo en la principal |
| 11 | Archivos (Finder): barra lateral (Favoritos/Ubicaciones/Etiquetas), iconos/lista/columnas/galería, ruta, Vista rápida, etiquetas xattr, pestañas, búsqueda | hecho; captura en anfitrión |
| 12 | Spotlight: apps, archivos (find en ~), cálculos (evaluador propio), acciones | hecho |
| 13 | Aplicaciones (rejilla por páginas, búsqueda) desde el 2.º icono del Dock | hecho |
| 14 | Control Center (Wi-Fi, Bluetooth, red, Concentración, mosaico, aspecto, captura, bloqueo, portapapeles, brillo, sonido, reproducción) y Centro de notificaciones (historial real, calendario) | hecho |
| 15 | Ajustes del Sistema: Aspecto (claro/oscuro/auto, Liquid Glass, resalte, movimiento, sonidos), Escritorio y Dock, Fondo, Notificaciones + paneles existentes | hecho (paneles existentes con su lógica real) |
| 16 | Bloqueo e inicio de sesión estilo Golden Gate | hecho |
| 17 | Liquid Glass + deslizador | hecho (refleja el fondo; ver limitaciones) |
| 18 | Sombras, bordes, radios, tipografía, colores | hecho (tokens) |
| 19 | Claro/oscuro en caliente (shell, apps BC, GTK, sway) | hecho; apps Qt ajenas siguen su propio tema |
| 20 | Sonidos originales (aviso, papelera, bloqueo, volumen, captura, error) | hecho |
| — | Animaciones centralizadas en tokens | hecho; duraciones «sin confirmar» |

## Pulido posterior (objetivo del creador: «exacto como un Mac»)
- Interletrado de la barra medido sobre la captura (app en negrita 127 px, reloj 142 px).
- Modo claro revisado en todas las apps (textos y controles adaptativos), interruptores estilo macOS.
- OSD de volumen/brillo como píldora de vidrio arriba a la derecha (desde Tahoe).
- Tema GTK **MacTahoe** (vinceliuice, MIT) claro/oscuro para apps externas; Inter como fuente del sistema; azul de sistema #0A84FF.
- Spotlight con accesos (Aplicaciones, Archivos, Acciones, Portapapeles); avisos que entran desde la derecha.
- Apps de BC con `.desktop` (aparecen en Aplicaciones y Spotlight); una sola «Terminal».
- Con GPU (swayfx): sombras de ventana y desenfoque real detrás del Dock, menús y avisos.
- Verificado en sway real (headless, aarch64): `rect` empieza bajo la barra de título; semáforos y genio usan `rect.y − alto`.

## Segunda ronda (2026-11-15, «réplica exacta»)
- Fuentes: apple.com/es/os/macos (Liquid Glass «de cristalino a completamente tintado», barras de herramientas unificadas,
  barras laterales de borde a borde, iconos de menú rediseñados, app Siri) y prensa (menús casi sin iconos, flecha nativa
  para iconos ocultos de la barra, barras laterales con iconos en color, radio de ventana único).
- Iconos: el creador prefiere los MacOS-Like anteriores; se restauraron (los de icon-designer quedan en el historial de git).
- Apps nuevas o rehechas: Monitor de Actividad (procesos reales), Tienda (App Store), Calculadora, Notas, Vista previa,
  Calendario, Recordatorios, Música (mpv), Ajustes (Wi-Fi, Bluetooth, Pantallas, Teclado, Fecha y hora, cuenta).
- Vibrancy: barras laterales de vidrio en todas las apps (la app sigue su posición con sway).
- Widgets editables (galería), Calendario y Reloj; Spotlight por secciones; vista Aplicaciones con categorías;
  flecha de iconos ocultos; Terminal con aspecto del de macOS; Archivos ▸ Recientes.
- Ghostty desactivado (fallo de Zig en CI): Terminal = Alacritty.

## Tercera ronda (2026-11-15 tarde)
- Animaciones de salida: la capa emergente se mantiene 260 ms al cerrar para que menús, Spotlight, Aplicaciones (se agranda
  y desvanece), pila y galería se desvanezcan; cerrar ventanas externas con captura que se encoge y desvanece.
- Control Center editable («Editar controles…»: quitar con «−», añadir Turno de noche, Calculadora, Nota rápida, Ajustes;
  se guarda en `centroControles`).
- Archivos ▸ Recientes: agrupado por Hoy/Ayer/7 días/30 días, miniaturas reales, xbel + archivos modificados en 30 días.
- Multimonitor: cada superficie recorta el cristal del fondo de su pantalla (caché por tamaño).
- Cristal claro con suelo de tinte 0,55 (texto oscuro legible sobre fondos oscuros); barras de herramientas sin línea con
  fundido del contenido («scroll edge effect»).

## Sin confirmar frente a Golden Gate
- Todas las duraciones y curvas (Apple no las publica): menús 120 ms, Control Center 240 ms, genio 500 ms,
  Mission Control 330 ms, cambio de escritorio 420 ms, Dock 90 ms, rebote 180+520 ms ×2.
- Radio de ventana 20 (fuentes secundarias: «≈20 pt, menos que Tahoe»), radio de menú 12, semáforo 12 px.
- Barra de título unificada de 52 px en apps BC; colores exactos de barra lateral activa/inactiva.
- Ampliación del Dock al 75 % y alcance de 150 px.

## Limitaciones técnicas
- El cristal muestra el **fondo** desenfocado, no las ventanas de detrás (solo el compositor puede: swayfx + GPU).
- Cerrar ventanas externas se anima con una captura grim que se encoge y se desvanece (semáforo, Súper/Ctrl+Q); abrirlas no se anima.
- Gestos discretos (ver 9). Selector de apps: se confirma al soltar Alt si la tecla llega, o tras 1,1 s.
- Iconos de app: tema MacOS-Like (GPL-3.0), squircle, sin capas de vidrio dinámicas ni modo tintado.

## Recursos de terceros
- Iconos MacOS-Like (Scrimas, GPL-3.0), sobre MacTahoe (vinceliuice, GPL-3.0). Cursores McMojave (vinceliuice, GPL-3.0).
- Inter (OFL-1.1). CaskaydiaCove Nerd Font (OFL-1.1). Fondo «Ondas» y sonidos: propios (`assets/`).

## Volver a la sesión anterior
En la pantalla de inicio de sesión, elegir **«BC clásico»** (misma sesión sway con `BC_CLASSIC=1`).
También se puede fijar en Ajustes ▸ General ▸ «Entorno al iniciar sesión».
