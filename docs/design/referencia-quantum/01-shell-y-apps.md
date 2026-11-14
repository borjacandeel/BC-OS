# Referencia Quantum Linux 01: shell, apps y sesión

Estado: informe de estudio (solo lectura), 2026-11-14. Fuente: repositorio de Quantum Linux (GPL-3.0-or-later) clonado en `/tmp/ql-src`, paquetes `quantum-shell`, `quantum-center`, `quantum-store`, `quantum-files`, `quantum-ayuda`, `quantum-cronos`, `quantum-foton`, `quantum-display`, `quantum-drivers`, `quantum-migrate` y `quantum-desktop`.

## 0. Cómo usar este documento

- Es un **mapa de comportamiento**, no una fuente de código. BC OS recrea las funciones con diseño y código propios (shell Qt6/QML sobre sway, procesos separados, D-Bus `org.bcos.Shell`; ver `ARCHITECTURE.md`).
- No se copia código, textos de interfaz, sonidos, iconos, logos, mascota, fondos ni paletas de marca de Quantum. Los nombres de claves JSON y las cifras de los defectos se listan porque se pidieron como referencia de diseño; BC OS debe usar sus **propios** valores y tokens (`docs/design/tokens.json`, `BC-DESIGN-SYSTEM.md`) y mantener su tema (regla ya anotada en `PENDIENTE.md`).
- `PENDIENTE.md` dice que la **Tienda de Quantum todavía NO** se adopta (decisión del creador): en este informe la Tienda se describe solo para comparar con la actual de BC (pacman + Flathub).
- Lo que BC OS ya tiene según `ARCHITECTURE.md` (estilos BC/Windows/Minimal, Modos, widgets, menús globales, bloqueo, notificaciones, bienvenida de 3 pasos, Tienda, Archivos) se marca «ya existe»; hay que verificarlo contra el código antes de planificar, porque aquí no se ha leído.

## 1. Inventario de funciones

### 1.1 Arquitectura del shell de Quantum

- Es un único proceso **Quickshell** (QML) con una `ShellRoot` que carga todo; una pantalla de carga ligera aparece primero y el resto se carga en segundo plano con carga perezosa; cuando el escritorio está listo la pantalla se desvanece. Al terminar la carga lanza el Centro Quantum en modo inicio de sesión y, si ya hubo bienvenida, comprueba drivers a los 20 s.
- Servicios = singletons QML (`Settings`, `Theme`, `Shell`, `Wm`, `Apps`, `Net`, `Bt`, `Audio`, `Brightness`, `Notifs`, `Updates`, `Weather`, `Sounds`, `Atomic`, `Serp`, `Clipboard`, `Desktop`, `SysInfo`, `Icons`, `Quarki`, `Ai`). Los módulos (`bar`, `dock`, `launcher`…) son ventanas layer-shell que leen esos singletons.
- Control: los atajos de teclado los define el compositor y llaman a un **IPC por nombre** (`shell`, `lock`, `dashboard`, `personalize`, `welcome`, `updates`, `osd`, `island`, `dock`, `atomic`) con funciones (`launcher`, `clipboard`, `controlCenter`, `wifi`, `session`, `dashboard`, `wallpapers`, `personalize`, `nightLight`, `ai`, `snapLayouts`, `lock`, `gameMode`, `appSlot n`, `brightnessUp/Down`, `sound`). Equivale al `org.bcos.Shell` + `bc-ctl` de BC.
- Tres «formas» de shell elegibles (`ui.shell`): Caelestial (barra superior + dock/barra de tareas, la principal), Atomic (la misma forma con paneles de «cristal» que refractan el fondo con un shader; se degrada en PC sin GPU o con < 3,8 GB y avisa una vez) y Serpantium (barra de píldoras arriba, paneles que bajan, tipografía monoespaciada, paleta fija rosada). BC OS no necesita replicar las dos últimas (ver sección 5).
- Rendimiento: bucle de render conmutable a `basic` con < 4 GB de RAM; animaciones del fondo pausadas con pantalla completa, modo juego, batería baja o bloqueo; la medición de sistema solo corre mientras hay un panel que la muestra.
- Detalle recurrente de diseño: los paneles son superficies de pantalla completa transparentes con máscara de entrada solo sobre la tarjeta visible (clic fuera cierra), altura fija para evitar saltos, y entrada con rebote suave y salida rápida.

### 1.2 Módulos del shell

| Módulo | Qué hace / cómo se usa / qué muestra |
|---|---|
| **bar** (barra superior) | Flotante (secciones sueltas) o pegada (franja). Izquierda: nombre de la app activa (o marca si no hay). Derecha: bandeja del sistema (StatusNotifier; se oculta el applet de Bluetooth porque duplica el estado), botón de actualizaciones con contador, botón «Reiniciar» pendiente, estado (red, Bluetooth, volumen, icono de juego, batería con %), reloj, notificaciones (icono cambia si hay sin leer o No molestar), apagado. Clic en red abre el Centro de control; clic derecho abre directo la lista Wi-Fi. Con el estilo «una sola barra» no existe y todo va a la barra de tareas. |
| **dock / barra de tareas** | Un solo componente con forma elegible: flotante, pegada o dock. Elementos reordenables: inicio, búsqueda, asistente, apps, clima, uso de CPU/RAM, bandeja, reloj, «mostrar escritorio». Los de antes de «apps» van a la izquierda o centrados con las apps, los de después a la derecha. Apps fijadas + abiertas agrupadas por app; clic enfoca o minimiza si ya está al frente; varias ventanas muestran globo con lista; clic derecho: nueva ventana, fijar/quitar, cerrar (una o todas); se pueden reordenar arrastrando (soltar entre las fijadas la fija). Posición abajo o arriba (arriba obliga al modo «una sola barra»). Autoocultado con franja de 3 px; se esconde con juegos o vídeo a pantalla completa. Opacidad propia (`-1` = según vidrio). Tamaño pequeño/mediano/grande (escala 0,86/1/1,18). Súper+1…9 activa la app de esa posición (abre si está cerrada; con varias ventanas, rota). |
| **launcher** (Súper) | Panel tipo menú Inicio; se abre desde la barra (o desde arriba si la barra está arriba). Buscador tolerante: normaliza tildes y mayúsculas y puntúa por nombre exacto, palabra del nombre, subcadena, tipo genérico/palabras clave y comentario/categorías. Rejilla de apps (icono grande + nombre), Enter abre, Esc cierra; clic derecho: anclar al escritorio o fijar en la barra. Pie: usuario, ajustes, apagado. Mensaje de «no encontré nada». Modo portapapeles (Súper+V): misma ventana, lista de los últimos 80 elementos con vista previa de texto o marca de imagen, Enter copia, «Borrar todo». Anti doble apertura (500 ms por app). Apps `Terminal=true` se lanzan en la terminal. |
| **controlcenter** (Súper+A / Súper+N) | Cabecera con saludo y accesos (ajustes, fondos, bloqueo, apagado); deslizadores de volumen y brillo (brillo solo si hay panel retroiluminado); baldosas: Wi-Fi (con botón a la lista de redes), Bluetooth (abre el gestor), No molestar, modo oscuro, luz nocturna (subtítulo según modo: manual, atardecer u horario), modo juego, mosaico de ventanas, colores del fondo; reproductor MPRIS (título, artista, controles); historial de notificaciones con «Borrar todo» y estado «todo al día». Segunda página: lista de redes (ver `Net`). |
| **dashboard** (Súper+C) | Tarjeta bajo la barra, abre al pulsar el reloj o al dejar el ratón 250 ms en una franja del borde superior; cierra al salir. Dos pestañas con entrada escalonada: Inicio (hora y saludo, calendario de 6 semanas desde lunes, música con carátula que gira) y Rendimiento (anillos de CPU, RAM, disco, temperatura y gráfica de CPU de los últimos 45 s). Se desactiva en pantalla completa y con otro panel abierto. |
| **notifications** | Servidor `org.freedesktop.Notifications` con acciones, marcado, enlaces, imágenes y persistencia. Ventanas emergentes (máx. 5) arriba a la derecha con barra de tiempo que se pausa con el ratón, arrastrar a la derecha descarta, clic ejecuta la acción por defecto, botones de acción, el «icono como imagen» se trata como icono. No molestar suprime emergentes y sonido salvo urgencia crítica. Con la isla activa, las notificaciones salen de la isla. Historial en el Centro de control. |
| **osd** | Píldora que sube con rebote al cambiar volumen o brillo (también por teclas multimedia externas); icono que salta, barra con degradado, se oculta a 1,6 s; ignora los cambios de los primeros 2,5 s (el volumen inicial que informa PipeWire). Con la isla activa, la isla lo muestra. |
| **lock** | Bloqueo con protocolo seguro de Wayland (ext-session-lock) y PAM (solo comprobación de contraseña del usuario). Panel de vidrio con reloj de dígitos que ruedan, foto de perfil hexagonal con órbitas, puntos de contraseña que aparecen, sacudida al fallar, brillo verde/rojo, animación de salida. Tarjetas laterales elegibles y ordenables: clima, ficha del sistema, música, estadísticas, notificaciones (contenido oculto por defecto), calendario. Tras 30 s sin tocar nada el campo «se duerme» y se borra lo escrito (la primera tecla solo lo despierta, para que la tecla que enciende la pantalla no acabe en la contraseña). Fondo: imagen fija con zoom lento, o fondo vivo. Modo vista previa (sin bloquear) desde Personalizar. Entrada IPC `lock` y `lockAsleep` (para el bloqueo automático). |
| **session** (Súper+X, Ctrl+Alt+Supr) | Pantalla completa oscurecida con reloj; cinco botones: bloquear, cerrar sesión, suspender, reiniciar, apagar; navegación con flechas, Enter, Esc; cada botón tiene una frase corta de despedida. |
| **welcome** | Asistente de primer inicio, ver flujo 2.1. |
| **personalize** (Súper+P) | Ventana normal con portada, buscador de opciones y nueve secciones; cambios al instante; «Deshacer» vuelve al estado de apertura. Ver 1.2b. |
| **island** (isla dinámica) | Píldora arriba al centro que se deforma como gelatina (resorte con aplastado según velocidad). Prioridad de contenido: volumen/brillo > modo juego > acción del asistente instalando algo > notificación (5 s) > música. Música pequeña (carátula + título) y grande al pasar el ratón (controles); los colores de la carátula tiñen el resplandor y otros degradados (`musicColors`). |
| **assistant** (Súper+H) | Panel sobre la barra con chat. Órdenes frecuentes resueltas sin IA (abrir apps/carpetas/webs, instalar/desinstalar con tarjeta de confirmación, volumen, brillo, modo oscuro, modo juego, fondo, capturas, actualizar, apagar, abrir «Ayuda y sugerencias», buscar en internet); lo demás va a una **IA local con Ollama** (sin cuentas ni internet); la IA solo puede proponer acciones como botones que la persona pulsa. Si Ollama o un modelo faltan, ofrece instalarlos en una terminal visible. Estados de ánimo y mascota: no se recrea. |
| **gamemode** | Efecto de 2 s al activarlo (oscurece, anillos, rótulo con lo que hace y la pista del contador de FPS); no aparece dentro de un juego en pantalla completa. Efectos reales en 1.4 (`quantum-theme gamemode`). |
| **snap** (Súper+Z o ratón medio segundo sobre maximizar) | Panel de seis diseños de ventana (mitades, 2/3 + 1/3, tres columnas, 1 grande + 2 pequeñas, cuadrícula 2×2, columna central + laterales) expresados en fracciones del área útil. Se elige zona; si el diseño tiene más zonas, ofrece las otras ventanas para completarlo. Colocación mediante un ayudante que habla con el IPC del compositor. |
| **wallpapers** (Súper+W) | Tira flotante sobre la barra: miniaturas de fondos del sistema, de `~/Imágenes/Fondos` y propios (se recuerdan hasta 40; se pueden quitar de la lista sin borrar el archivo), conmutador claro/oscuro, conmutador «colores del fondo», fondo vivo. Admite imágenes, GIF y vídeo (para los animados se saca un fotograma con ffmpeg que sirve de miniatura, de fuente de colores y de fondo en bloqueo/bienvenida). |
| **desktop** (iconos) | Iconos sobre el fondo: contenido de la carpeta Escritorio (según `xdg-user-dir`), accesos `.desktop` con nombre e icono de la app, y la Papelera (llena/vacía). Cuadrícula con casillas recordadas por nombre; clic selecciona, doble clic abre, arrastre cambia de casilla, clic derecho menú; las casillas libres se rellenan de arriba abajo por columnas. |
| **updates** | Aviso «reinicia para terminar de actualizar» (ver flujo 2.2). |
| **Splash / Background** | Pantalla de carga solo en el inicio de sesión (marca de sesión), no al recargar el shell. Cambio de fondo con círculo que crece desde el centro y anillo de luz. Un «secreto» (una figura que cruza el fondo cada 8–20 min) existe; no se recrea. |
| **CursorTrail** | Estela luminosa del ratón, apagada por defecto; se desactiva en modo juego o pantalla completa. Baja prioridad. |
| **serpantium** | Forma alternativa completa (barra, paneles, lanzador, bloqueo). No aplica. |
| **components** | `Glass`, `IconButton`, `Card`, `Txt`, `QSlider`, `Icon` (fuente de iconos Material Symbols Rounded), `ToggleTile`, `PillButton`, `Spin`, `AppIcon`, `LiveWallpaper`: kit de UI propio; BC ya tiene el suyo. |

#### 1.2b Personalizar: secciones y qué controlan

1. **Estilos**: seis predefinidos de un clic (ver 3.4) y «personalizado» cuando se toca cualquier ajuste visual.
2. **Fondo y colores**: fondo, claro/oscuro, acento (lista de siete) o colores del fondo, color del cristal (neutro/acento/propio), paquete de iconos (seis; los no instalados se descargan al elegirlos), vidrio por partes (barra, dock, paneles, ventanas), opacidad de paneles y de ventanas, desenfoque, escala de texto, estela del cursor.
3. **Barra de tareas**: posición, forma, alineación, tamaño, autoocultado, opacidad, elementos visibles y orden (chips arrastrables), isla, barra superior flotante, mostrar nombre de app.
4. **Escritorio**: iconos sí/no.
5. **Ventanas**: esquinas (recta/suave/redonda), animaciones (ninguna/rápida/normal/suave), animación de abrir (zoom/fundido/fuego/giro) y de minimizar (zoom/exprimir/ninguna), botones a la izquierda, ventanas gelatinosas, altura de título (24–48), grosor de borde (0–4), mosaico.
6. **Pantalla de bloqueo**: tarjetas a cada lado, ciudad del clima, mostrar contenido de notificaciones, vista previa, «bloquear ahora».
7. **Sonidos**: ocho estilos con botón de escucha, activar, sonido de inicio, volumen.
8. **Pantalla**: luz nocturna (manual/atardecer/horario con desde-hasta), temperatura en kelvin, brillo por software, contraste, gamma, saturación.
9. **Ratón y touchpad**: velocidad, aceleración, desplazamiento natural, velocidad de scroll, zurdo, tamaño de cursor; touchpad: pulsar para clic, escribir desactiva, método de clic.
Mecánica común: buscador con resultados «opción → sección», filas con ayuda, «Más opciones» plegado, vista previa en vivo en secciones visuales, y una instantánea al abrir para «Deshacer».

### 1.3 Servicios

| Servicio | Función y detalles de diseño |
|---|---|
| **Settings** | Único origen de ajustes: `~/.config/quantum/settings.json` con adaptador tipado, recarga al detectar cambios externos, escritura inmediata, y tras cada cambio visual dispara `quantum-theme apply` con retardo de 250 ms. No escribe hasta haber leído el archivo entero (evita pisar los ajustes del usuario con valores de fábrica durante la carga). Cualquier cambio visual marca el estilo como `custom`, salvo fondo, iconos, fondos propios, iconos de escritorio y las secciones `display/mouse/touchpad/sounds`. Funciones: `set`, `setPath`, `setMany` (una sola escritura), `applyStyle` (mezcla profunda de defectos + estilo), `resetAll`, `snapshot/undo`. Migra una vez la barra fijada de fábrica de una versión anterior. Soporta un archivo de usuario del compositor que se aplica al guardarlo. |
| **Theme** | Lee `colors.json` (esquema Material 3 + `mode`) con vigilancia de archivo; expone superficies, texto, acentos, contenedores, error; tipografía, escala de texto, radios, huecos, duración de animaciones y opacidad de cristal. Ver 3.3. |
| **Shell** | Estado de interfaz: qué panel está abierto, `closeAll`, alternar cada panel, modo juego, página Wi-Fi, colores de música, señales de bloqueo y diseños de ventanas; todos los paneles son mutuamente excluyentes salvo Personalizar. |
| **Wm** | Ventanas abiertas (protocolo de gestión de toplevels), ventana activa, pantalla donde se abren los paneles (la de la ventana activa), agrupación para la barra (fijadas primero, luego abiertas), fijar/reordenar, `toggle` (minimiza si activa), `activateSlot` (Súper+n), «mostrar escritorio» con restauración, cerrar sesión con `loginctl terminate-session`. |
| **Apps** | Lista de entradas `.desktop` visibles, búsqueda tolerante (3.5), lanzamiento con enfriamiento y terminal si procede. |
| **Net** | Gestión Wi-Fi sobre NetworkManager mediante API nativa (sin analizar texto): dispositivo Wi-Fi, redes, intensidad, seguridad, estado cableado/inalámbrico/en línea; flujo: abrir lista inicia escaneo, elegir red; si exige contraseña pide una; mensajes de estado y de error según el motivo del fallo; conectar/desconectar; modo demo por variable de entorno para capturas. |
| **Bt** | Adaptador por defecto, encendido/apagado, dispositivos conectados, etiqueta («No disponible», «Apagado», nombre del conectado, «Encendido»). El emparejado lo hace un agente externo (blueman). |
| **Audio** | PipeWire: sumidero y fuente por defecto, volumen 0–1, silencio y micrófono silenciado; icono según nivel; emite señal también con cambios externos (para el OSD). |
| **Brightness** | `brightnessctl`, clase backlight, disponible solo si hay dispositivo; paso de 5 %. |
| **Notifs** | Ver módulo notifications. |
| **Updates** | Ver flujo 2.2. Comprueba a los 2 min de iniciar y cada 3 h con `checkupdates` (copia aparte de la base de pacman: no toca el sistema ni pide contraseña) y `flatpak remote-ls --updates`; separa «de Quantum» de las de Arch; ordena con las propias primero; notifica una vez por cantidad; vigila un archivo en `/run` que escribe un hook de pacman con los paquetes que exigen reinicio, cada 15 s; traduce nombres a lenguaje llano (kernel, drivers de vídeo, escritorio…). |
| **Weather** | Open-Meteo (gratis, sin cuenta); ubicación aproximada por IP o ciudad escrita; caché de 30 min; solo se consulta al bloquear o al pedirlo; códigos WMO a texto e icono en español. |
| **Sounds** | Reproduce con `pw-play`; ocho paquetes de sonidos con los mismos once eventos (inicio, volumen, activar, desactivar, clic, notificación, bloqueo, desbloqueo, error, captura, vista previa) más uno compartido; antirrebote de 70 ms; vista previa única (tocar otra corta la anterior). |
| **Atomic** | Prepara texturas nítida y desenfocada del fondo para el cristal, sigue la posición del cursor para la «luz» del reflejo y detecta PC débil (sin GPU o poca RAM). No aplica. |
| **Serp** | Estado y paleta fija de la forma Serpantium, y `choose()` para cambiar de forma guardando y restaurando fondo/colores previos. No aplica. |
| **Clipboard** | `cliphist list` (80 más recientes), copiar con `cliphist decode | wl-copy`, `wipe`. El historial lo alimentan dos observadores `wl-paste --watch` (texto e imagen) lanzados con la sesión. |
| **Desktop** | Carpeta Escritorio, lista de archivos con modelo de carpeta, estado de la Papelera, casillas guardadas en `~/.config/quantum/desktop-icons.json`. |
| **SysInfo** | Lee `/proc/stat`, `/proc/meminfo`, `df` y sensores térmicos cada 1,5 s solo si hay usuarios activos; historial de 30 valores. |
| **Icons** | Seis familias de iconos con variante claro/oscuro y color de carpeta según la forma; detecta instalación; instala el paquete al elegirlo y notifica si falla. Cambiar de familia reinicia el shell (Quickshell fija iconos al arrancar). |
| **Quarki / Ai** | Intérprete de órdenes en lenguaje natural sin IA (quita muletillas de cortesía, divide en «y»/«luego» solo si sigue otra orden, mapea nombres coloquiales a categorías de `.desktop`, páginas web como apps) + cliente de modelo local. Instalar/desinstalar usan los mismos orígenes que la Tienda; hay una lista de paquetes protegidos que nunca desinstala. |

### 1.4 quantum-desktop (sesión y utilidades)

- **Sesión** (`quantum-session`): entrada de sesión Wayland «Quantum» (`XDG_CURRENT_DESKTOP=Quantum;wlroots`). Exporta variables (Wayland para Qt/SDL/Firefox/Electron, tema de Qt por qt6ct, cursor); en máquina virtual fuerza cursor por software, GL en GTK y baja los fps de animaciones continuas; borra el marcador de modo juego (no sobrevive a la sesión); actualiza carpetas de usuario localizadas; en cuentas nuevas copia accesos iniciales al escritorio una sola vez (marcador `seed-desktop`); si la configuración generada es más antigua que la plantilla la regenera antes de arrancar, si no arranca ya y regenera en paralelo; después `exec` del compositor.
- **Inicio de la sesión** (autostart del compositor): variables al entorno de D-Bus/systemd, portal XDG, shell, agente polkit (GNOME), inactividad, observadores de portapapeles (con retardo de 8 s), carpetas de usuario, luz nocturna (`quantum-display`), agente de Bluetooth (blueman-applet; sin él BlueZ rechaza emparejar), detector de pendrives de migración, instalación desatendida en modo vivo.
- **Plantilla del compositor** (`wayfire.ini`): 4×1 escritorios virtuales; decoración de servidor propia (título 34 px, borde 1 px, orden de botones, colores desde el tema); animaciones, desenfoque Kawase para terminal y superficies del shell elegidas; ventanas gelatinosas opcional; arrastre a borde acopla (mitad/cuarto/pantalla completa); cuadrícula con Súper+flechas; cambiador Alt+Tab y vista de tareas Súper+Tab; cambio de escritorio Ctrl+Súper+flechas (con ventana: +Mayús); mostrar escritorio Súper+D; pantalla completa Súper+F11 (no F11 sola, para que las apps no se alternen dos veces); mosaico sencillo opcional (Súper+Espacio) con huecos 6/8 px; reglas de ventana (imagen en imagen siempre encima); DPMS a 15 min.
- **Atajos** (sección de comandos; modificador «Súper»):

| Atajo | Acción |
|---|---|
| Súper (solo) | Lanzador |
| Súper+A, Súper+N | Centro de control |
| Súper+C | Panel de hora/rendimiento |
| Súper+V | Historial del portapapeles |
| Súper+W | Selector de fondos |
| Súper+P | Personalizar |
| Súper+H | Asistente |
| Súper+X, Ctrl+Alt+Supr | Menú de sesión |
| Súper+L | Bloquear |
| Súper+G | Modo juego |
| Súper+Z | Diseños de ventanas |
| Súper+1…9 | App n de la barra |
| Súper+Intro, Ctrl+Alt+T | Terminal |
| Súper+E | Archivos |
| Súper+I | Ajustes (Centro, página «ajustes») |
| Ctrl+Mayús+Esc | Monitor del sistema |
| Súper+Mayús+S, Impr | Captura de región |
| Mayús+Impr | Captura de pantalla completa |
| Alt+F4, Súper+Q | Cerrar ventana |
| Teclas multimedia | Volumen (paso 5 %, con tope 100 %), silencio, micrófono, brillo (vía shell para ver OSD), reproducir/pausa/parar/siguiente/anterior (`playerctl`, incluidos play y pausa por separado de auriculares) |

- **`quantum-theme`**: ver 3.3 (motor de temas).
- **`quantum-screenshot region|screen`**: carpeta `Imágenes/Capturas`, nombre con fecha y hora. `region`: selector de zona (`slurp`) → sonido de captura → `grim` → editor de anotación (`swappy`) que guarda en el archivo. `screen`: `grim` de toda la pantalla, copia al portapapeles (`wl-copy`) y notificación con miniatura.
- **`quantum-update`**: abre una terminal propia, lista lo pendiente (las de Quantum marcadas primero, tope de 25 de Arch más «y más»), avisa de que antes se guarda una copia del sistema, ejecuta `pacman -Syu` y luego `flatpak update`, muestra éxito o fallo, avisa si hace falta reiniciar y pide al shell que vuelva a comprobar.
- **`quantum-wf`**: ayudante de IPC del compositor (ventana bajo el ratón, colocar en fracciones del área útil, otras ventanas de la pantalla, enfocar, seguir el cursor).
- **`quantum-displays`**: abre el editor de pantallas y, al cerrar, guarda resolución/posición/escala por monitor para que persistan (también tras modo juego).
- **`quantum-shell-start` / `quantum-shell-restart`**: arranque del shell con el tema de iconos anotado por `quantum-theme`; detección de caída reciente del shell con notificación que ofrece abrir «Ayuda y sugerencias» en modo caída; reinicio del shell sin cerrar ventanas.
- Otros: `hypridle` (9 min baja el brillo al 15 % y lo restaura al volver; 10 min bloquea; antes de suspender bloquea; DPMS a 15 min por el compositor), portales (`wlr` para capturas y grabación, `gtk` para el resto), aplicaciones por defecto por tipo MIME, configuración de terminal con colores generados por el tema.

### 1.5 Apps PyQt/QML

| App | Función | Cómo se usa / qué muestra |
|---|---|---|
| **quantum-center** (Centro Quantum) | Ventana PyQt con barra lateral de siete páginas: Inicio, Configura tu PC, Ajustes, Vengo de Windows, Sistema, Comunidad, Créditos. Opción «Mostrar al iniciar sesión» (guardada en su archivo de configuración; no abre si el usuario la desactivó y no hay apps pendientes). Argumentos: modo inicio de sesión, página inicial. En el sistema en vivo muestra un botón de instalación y desactiva lo que necesita sistema instalado. | **Inicio**: tarjeta de bienvenida y cuatro atajos grandes (jugar, instalar apps, personalizar, actualizar). **Configura tu PC**: seis paquetes de apps (juegos, creadores, programación, oficina, música y vídeo, navegadores) cada uno = lista pacman + lista Flatpak, instalados en una terminal visible. **Ajustes**: acceso a Personalizar, teclado (lista de once distribuciones; guarda `keyboard.layout`; Alt+Mayús alterna), fecha y hora (automática por NTP o manual, zona horaria con buscador, arreglo de reloj local para doble arranque con Windows, todo con `timedatectl` sin congelar la ventana), y accesos a editor de pantallas, red, Bluetooth, sonido, apariencia GTK. **Vengo de Windows**: tabla de equivalencias (Explorador → Archivos, Configuración → Centro, Administrador de tareas → monitor, Recortes → captura, historial del portapapeles, vista de tareas, acoplar ventanas, mostrar escritorio, restaurar sistema…) con sus atajos, tarjeta de «Pasar desde Windows» y seis atajos de uso diario. **Sistema**: modo rendimiento (repos optimizados x86-64-v3/v4 + planificador de juegos), actualizar todo, puntos de restauración (lista de Snapper), espejos más rápidos (reflector), liberar caché (`paccache` + Flatpak sin uso), drivers, monitor, ficha del sistema. **Comunidad**: enlaces a documentación y a Ayuda y sugerencias. Al iniciarse puede instalar de Flathub, para el usuario, las apps que el instalador dejó pendientes (cola con progreso; si se cierra la ventana sigue en segundo plano y avisa con notificación). Estilo derivado de `colors.json` y recarga en vivo al regenerarse. |
| **quantum-store** | Tienda en PyQt6 + QML con tres orígenes: repos de Arch (`pacman -Ss/-Si`, instalar con `pkexec pacman -Syu --needed`, quitar con `-Rns` incluyendo paquetes de idioma dependientes), Flathub (API pública v2: búsqueda, colecciones, ficha AppStream con capturas; instalar a nivel sistema; ejecutar con `flatpak run`) y AUR (API RPC v5; instalar con `yay`). Caché HTTP en disco con caducidad (de 30 min a 6 h) y uso de la copia vieja sin internet. | Páginas: Inicio (cuatro destacados tipo cartel, populares, juegos, creación, oficina, tendencias), Juegos, Tus apps (instaladas); búsqueda global con resultados mezclados (coincidencias exactas primero); ficha con versión, instalar/abrir/desinstalar/cancelar, capturas, descripción y **aviso de seguridad** para orígenes no oficiales (AUR). Los trabajos corren con `QProcess`, se muestran con progreso y no se cortan al cerrar la ventana (`quitWhenIdle`). Modo simulación por variable de entorno que solo imprime comandos. Incluye además `quantum-exe`, ventana previa para abrir `.exe/.msi` con Wine en un prefijo propio. |
| **quantum-files** (Archivos) | Explorador tipo Explorador de Windows: pestañas, barra de ruta con migas y edición de ruta, accesos rápidos, Inicio (accesos, discos y dispositivos, recientes), Recientes (lee `recently-used.xbel`), Favoritos, Papelera, discos y USB (montar/expulsar; en Btrfs vale el subvolumen `/`), vista de iconos (3 tamaños) o detalles, orden por nombre/fecha/tipo/tamaño, buscador (por carpeta), panel de detalles (Alt+Intro), menú contextual propio con submenús, «Abrir con» y predeterminado, «Usar como fondo», comprimir ZIP y descomprimir, abrir terminal aquí, copiar/cortar/pegar con trabajos con progreso, pausa y cancelación, borrado definitivo con confirmación, vaciar y restaurar papelera, miniaturas (reducidas al leer; las de vídeo/PDF de la caché del sistema), saludo con nombre de la cuenta. Atajos como los de Windows (F2, Supr, Mayús+Supr, Ctrl+T/W, Alt+←/→/↑, Ctrl+L, Ctrl+F, Ctrl+H, F5, Ctrl+Mayús+N, Ctrl+rueda para zoom). |
| **quantum-ayuda** (Ayuda y sugerencias) | Formulario para reportar un problema o enviar una idea. Recoge datos del equipo y registros recientes, los **sanea** (carpeta personal → `~`, nombre de usuario, nombre del equipo, nombres de redes Wi-Fi, IP, MAC y correos → marcadores), y los envía a un intermediario que los guarda como incidencia en un repositorio privado. Argumentos: `--problema`, `--sugerencia`, `--caida`. | Elige tipo, el área afectada (chips), título (≥ 3 caracteres) y texto (≥ 10), contacto opcional; ve **exactamente qué se envía** (lista con «Ver» y casillas para quitar la ficha del equipo o los registros); aviso de privacidad; enlace a la comunidad. Máx. 5 envíos al día; sin internet el envío queda en cola y se reintenta al abrir la app. En modo caída muestra un mensaje contextual. Modo demo que simula el envío. |
| **quantum-cronos** | «Máquina del tiempo» sobre instantáneas de Snapper (Btrfs): línea de tiempo con el momento actual y puntos clasificados (antes de actualizar, antes de instalar, antes de quitar, estado recién instalado, guardado a mano, antes de un viaje), con etiqueta «Importante», lista de paquetes afectados y fecha relativa. «Guardar este momento» crea un punto a mano. «Viajar» pide confirmación (los documentos y juegos no cambian) y ejecuta un ayudante como root por polkit en pasos: guarda el presente (para deshacer), `snapper undochange N..0`, copia al `/boot` el kernel de ese momento (porque `/boot` es otra partición), regenera initramfs, firma para arranque seguro y actualiza el cargador; al acabar pide reiniciar. Animación de portal con anillos giratorios (hacia atrás al viajar). |
| **quantum-foton** | Biblioteca de juegos unificada: Steam (parser de `.acf/.vdf`, arte local o de CDN, descarta herramientas como Proton), Heroic (Epic, GOG, Amazon), juegos del sistema (`.desktop`), Roblox vía Sober (Flathub, se actualiza antes de abrir), juegos de Windows agregados a mano o en `~/Juegos` (se ejecutan con `umu-run` + Proton-GE, un prefijo por juego; busca portada por nombre), tienda con catálogo propio de juegos gratuitos (Flathub o Steam; `spec` bajo/medio/alto), historial de último juego, instalar Proton-GE, activar modo juego, contador de FPS con MangoHud (configuración propia con colores por rango de FPS, alterna con Mayús derecha+F12). | No aplica en lo esencial (x86). |
| **quantum-display** | Luz nocturna y ajustes de imagen. Un proceso Python decide si la luz nocturna está activa (manual, **atardecer** calculado con la fórmula de NOAA a partir de la ubicación, u horario desde-hasta) con fundido de 2,5 s, y manda «temperatura brillo contraste gamma» por entrada estándar a un pequeño ayudante en C que aplica la rampa de gamma con el protocolo `wlr-gamma-control` (la curva la aplica la GPU: coste nulo). Con todo en valores neutros el ayudante se cierra. La saturación es un plugin del compositor (shader) que solo se carga si ≠ 1 y sin modo juego. | Controlado desde Personalizar → Pantalla (sección `display`). |
| **quantum-drivers** | Detecta GPUs con `lspci`; solo NVIDIA necesita un paquete aparte: elige la generación por id de dispositivo (4 variantes: driver abierto oficial; versiones antiguas del AUR para Maxwell/Pascal, Kepler y Fermi) y la instala con progreso por pasos (quitar drivers que chocan, compilar DKMS firmando con la llave de arranque seguro, regenerar initramfs, quitar `kms` del initramfs para que `nouveau` no se cargue antes, actualizar cargador). Notifica al iniciar sesión (`--check`) y se abre al terminar la bienvenida solo si falta (`--now`); en máquina virtual dice que no hace falta; botones «Instalar», «Más tarde», «Reiniciar ahora». | Lista las tarjetas con su driver en uso. |
| **quantum-migrate** | «Pasar desde Windows»: asistente que busca un pendrive con lo que un programa para Windows (escrito en Rust con interfaz egui) dejó exportado: carpetas personales, cuenta (zona horaria, teclado), contraseñas Wi-Fi, marcadores y perfiles de navegadores (Firefox y Chromium), juegos de Steam (marca Proton), lista de apps con su equivalente en Flathub. Pasos independientes (si uno falla los demás siguen), **nunca pisa nada** (si existe y difiere, el de Windows queda como «nombre (Windows)»), copia con progreso y cancelación, marca lo ya pasado para solo añadir lo nuevo y ofrece borrar las contraseñas Wi-Fi del pendrive. Detector en segundo plano que monta pendrives y abre el asistente si trae datos; «Preparar un pendrive» copia el programa de Windows. | Pantallas: conecta pendrive, encontrado, elegir qué pasar, pasando, acomodando, listo. |

## 2. Flujos de usuario clave

### 2.1 Primer inicio (bienvenida)

1. Primer arranque de sesión tras instalar: pantalla de carga, escritorio, y la bienvenida a pantalla completa con teclado exclusivo (no aparece en sistema vivo). Se reabre desde IPC o Ajustes.
2. Cinco pasos con puntos de progreso, «Saltar» en el primero y «Atrás» en los demás, «Continuar» y «Empezar» al final; flechas eligen, Intro sigue, Esc salta; todo **se aplica al instante detrás** (se ve el efecto real) y se anota `ui.welcomed` al terminar:
   - Paso 1, estilo de escritorio: cuatro opciones (Windows, la propia, macOS, minimal) con vista previa dibujada; la recomendada activa colores desde el fondo.
   - Paso 2, colores y fondo: claro/oscuro, miniaturas de fondos (con insignia «animado»), interruptor «colores de tu fondo» y siete acentos (desactivados mientras los colores del fondo están activos).
   - Paso 3, forma del shell (la alternativa «Serpantium» se elige manteniendo pulsado con transición de barrido).
   - Paso 4, sonidos: ocho estilos con botón de escucha (uno a la vez), u opción «sin sonidos».
   - Paso 5, iconos: seis paquetes con muestra; se aplican y descargan **al terminar** (recarga un segundo el escritorio).
3. Al terminar: si hay NVIDIA sin driver se ofrece instalarlo; si se eligió «Más tarde» antes, recuerda con una notificación (no insiste). El Centro Quantum se abre solo al iniciar sesión mientras la casilla esté marcada.
4. Si el instalador dejó apps por instalar, el Centro las instala en segundo plano (con progreso y notificación al terminar).

### 2.2 Actualizar

1. El servicio comprueba a los 2 min y cada 3 h; si hay novedades notifica una vez por cantidad («hay N actualizaciones, con M de Quantum») y muestra un botón con contador en la barra.
2. Clic en ese botón (o «Actualizar ahora» en el Centro) abre `quantum-update` en terminal: lista, contraseña una vez, `pacman -Syu` y `flatpak update`; antes, un hook de instantáneas (snap-pac + Snapper) guarda un punto de restauración.
3. Un hook de pacman escribe en `/run` los paquetes que piden reinicio (se limpia solo al reiniciar). El shell lo detecta y muestra «Reinicia para terminar de actualizar» con ícono que gira y los nombres en lenguaje llano; «Más tarde» lo vuelve a mostrar a las 2 h y deja un botón «Reiniciar» en la barra.
4. Si algo falla, se indica que el sistema no quedó a medias y se remite al menú de arranque para volver a una copia; Cronos permite volver a un punto con interfaz gráfica.

### 2.3 Instalar apps

- Tienda: buscar o navegar → ficha → «Instalar» (orígenes: Arch, Flathub y AUR con aviso) → progreso con cancelar → «Abrir». Instaladas en «Tus apps».
- Centro → «Configura tu PC»: un clic instala un paquete temático de apps en una terminal visible.
- Asistente: «instala X» → tarjeta con la mejor opción y alternativas → confirmación → progreso (también en la isla).
- Siempre: instalar sincroniza (`-Syu`) porque Arch no admite actualizaciones parciales; quitar elimina los paquetes de idioma dependientes; el asistente no desinstala paquetes de la lista protegida.

### 2.4 Personalizar

Abrir con Súper+P → portada con estilo actual y tarjetas por sección → elegir sección → cambios al instante con vista previa en vivo → «Deshacer» devuelve al estado de apertura. Un estilo de un clic reaplica sobre los defectos de fábrica (por eso siempre se ve igual). Tocar cualquier ajuste visual pasa a estilo «personalizado». Atajos directos: Súper+W (fondos) y Súper+A (claro/oscuro, colores del fondo, luz nocturna, mosaico).

### 2.5 Modo juego (Súper+G o baldosa del Centro de control)

1. Efecto visual de 2 s (no si ya hay un juego a pantalla completa).
2. Crea un marcador de estado; `quantum-theme` regenera la configuración del compositor sin animaciones, ventanas gelatinosas ni desenfoque, y sin el filtro de saturación; el shell pausa fondos animados y estela; la barra muestra un icono de mando; la isla indica el estado.
3. El marcador se borra al empezar una sesión nueva (no sobrevive a reinicios).
4. Complementos de Fotón: contador de FPS con MangoHud (configuración propia, alterna con Mayús derecha+F12) y gestor de planificador de juegos en el «modo rendimiento» (solo x86-64).

### 2.6 Bloqueo

Súper+L, menú de sesión o botón del Centro de control → bloqueo seguro con contraseña PAM. El bloqueo automático lo da la inactividad (9 min baja el brillo, 10 min bloquea, 15 min apaga la pantalla) y bloquear antes de suspender; en esos casos el campo empieza «dormido» para no recoger la tecla que despierta la pantalla. Fallo: sacudida y brillo rojo; éxito: marca verde y salida animada. Se puede previsualizar sin bloquear.

### 2.7 Capturas

Impr o Súper+Mayús+S: selector de zona → sonido → editor de anotación → guarda en `Imágenes/Capturas` con fecha y hora. Mayús+Impr: pantalla completa → archivo + portapapeles + notificación con miniatura. El asistente también las lanza por voz/texto.

### 2.8 Portapapeles

Dos observadores `wl-paste --watch` (texto e imagen) alimentan el historial al iniciar sesión (8 s de retardo); Súper+V abre el lanzador en modo portapapeles; buscar filtra; Intro copia el elemento elegido (decodificado y enviado a `wl-copy`); «Borrar todo» vacía el historial.

### 2.9 «Ayuda y sugerencias»

Entradas: botón en Comunidad del Centro, pie del lanzador, asistente («tengo un problema…», «enviar una idea»), notificación tras caída del shell. Flujo: elegir tipo y área → título y mensaje → ver y recortar lo que se enviará (ficha del equipo y registros saneados) → enviar → confirmación, o cola local si no hay internet. Límite diario de cinco.

## 3. Esquemas

### 3.1 Archivos y rutas

| Ruta | Contenido |
|---|---|
| `/etc/xdg/quantum/settings.json` | defectos del sistema (valores de fábrica del estilo base) |
| `~/.config/quantum/settings.json` | ajustes del usuario (el motor de temas los mezcla en profundidad con los del sistema) |
| `~/.config/quantum/wayfire-user.ini` | reemplazos manuales del compositor, se aplican al guardarlos |
| `~/.config/quantum/desktop-icons.json` | casillas de los iconos del escritorio |
| `~/.local/state/quantum/colors.json` | paleta Material 3 calculada (+ `mode`); el shell y las apps Qt lo vigilan |
| `~/.local/state/quantum/` | configuración generada del compositor, tema de iconos y familia, marcador de modo juego, `stills/` (fotogramas de fondos animados), avisos de una sola vez, cola y registro de envíos de ayuda |
| `/run/quantum/reboot-required` | paquetes que exigen reinicio (lo escribe un hook de pacman) |
| `/usr/share/quantum/palette.json` | paleta Material 3 de respaldo, clara y oscura |

Regla de convivencia: los archivos generados (CSS de GTK, `settings.ini`, colores del terminal) llevan una marca; si el usuario los edita a mano y la marca desaparece, el motor **no los toca**.

### 3.2 Árbol de `settings.json` (claves, valores, defecto)

`appearance`
- `mode`: `dark` | `light` (defecto `dark`).
- `dynamicColors`: bool (`false`); si es `true`, la paleta sale del fondo.
- `accent`: hex `#RRGGBB` (defecto de marca; BC pondrá el suyo).
- `wallpaper`: ruta | `quantum:live` (fondo generativo propio; BC usará su identificador).
- `customWallpapers`: lista de rutas (máx. 40).
- `desktopIcons`: bool (`true`).
- `glassTint`: `""` | `accent` | hex.
- `iconTheme`: `papirus` | `tela` | `fluent` | `whitesur` | `colloid` | `candy` (`papirus`).
- `panelOpacity`: real (`0.86`); `blur`: bool (`true`); `textScale`: real (`1.0`); `cursorTrail`: bool (`false`).
- `glass`: `{ bar, dock, panels: true; windows: false }`; `windowOpacity`: real 0,6–1 (`0.9`, solo si `glass.windows`).

`windows`
- `tiling` bool `false`; `corners` `sharp|soft|round` (`soft`); `animations` `none|fast|normal|smooth` (`normal`); `openAnimation` `zoom|fade|fire|spin` (`zoom`); `minimizeAnimation` `zoom|squeezimize|none` (`squeezimize` en el shell, `zoom` en el archivo de sistema: incoherencia a evitar); `buttonsLeft` bool `false`; `wobbly` bool `false`; `titleHeight` int 24–48 (`34`); `borderSize` int 0–4 (`1`).

`layout`
- `style`: `split` (barra arriba + dock) | `single` (una barra abajo).
- `topBar`: `{ floating: true, showApp: true, island: true }`.

`dock`
- `pinned`: lista de ids `.desktop` (cuatro por defecto: archivos, navegador, terminal, centro).
- `floating` true; `align` `center|left`; `size` `small|medium|large`; `autohide` false; `position` `bottom|top`; `shape` `auto|floating|attached|dock`; `opacity` real (`-1` = según vidrio).
- `showSearch`, `showStart`, `showTray`, `showUpdates`, `showAssistant` (en Quantum `showQuarki`), `showClock` = true; `showDesktop`, `showSysmon`, `showWeather` = false.
- `order`: lista de ids de elemento: `start, search, assistant, apps, weather, sysmon, tray, clock, desktop`; lo posterior a `apps` va a la derecha; los que falten en la lista guardada se añaden al final.

`clock`: `format24h` true, `showDate` true, `showSeconds` false.
`lock`: `left` (`weather, fetch, media`), `right` (`stats, notifs`), `showNotifContent` false, `city` `""` (automática). Claves de tarjeta disponibles: `weather, fetch, media, stats, notifs, calendar`.
`keyboard`: `layout` `""` (automático desde el sistema) | códigos xkb separados por coma, `variant`, `options` (`grp:alt_shift_toggle`).
`notifications`: `{ dnd: false }`.
`display`: `nightLight` false; `nightMode` `manual|sunset|schedule`; `nightFrom` `"21:00"`, `nightTo` `"07:00"`; `temperature` 4000 K (6500 = neutro); `brightness` 0,3–1 (`1.0`); `contrast` 0,5–1,5; `gamma` 0,5–2; `saturation` 0–2.
`mouse`: `speed` −1…1 (0), `accel` true, `natural` false, `scrollSpeed` 1.0, `leftHanded` false, `cursorSize` 24.
`touchpad`: `speed` 0, `tapToClick` true, `natural` true, `disableWhileTyping` true, `scrollSpeed` 1.0, `clickMethod` `clickfinger|button-areas`.
`sounds`: `pack` (ocho ids), `enabled` true, `startup` true, `volume` 0,6.
`ai`: `{ model: "" }` (`""` = el primero instalado).
`ui`: `welcomed` false, `shell` `caelestial|atomic|serpantium`, `style` (id de estilo o `custom`), `page` (última sección abierta de Personalizar), `advanced`, `filesPinned` (migración única), `serpApps`, `before` (copia de fondo/colores para volver desde otra forma).

Observaciones de diseño aprovechables: el esquema es **por secciones** (no plano), tiene valores por defecto **duplicados** (sistema y código) que conviene unificar en un solo lugar en BC, y distingue «ajustes que definen un estilo» de «ajustes de dispositivo o estado de interfaz» (los segundos no cambian `ui.style`).

### 3.3 Tema: tokens y pipeline

**Paleta** (`colors.json`): claves Material 3 (todas con prefijo `on_` para el texto sobre cada rol): `surface`, `surface_container_{lowest,low,"",high,highest}`, `surface_bright/dim`, `on_surface`, `on_surface_variant`, `outline`, `outline_variant`, `primary`, `on_primary`, `primary_container`, `on_primary_container`, `secondary(_container)`, `tertiary(_container)`, `error(_container)`, `inverse_*`, `*_fixed(_dim)`, `scrim`, `shadow`, `source_color`; más `mode`. El shell mapea a sus propios nombres: `surface`, `surfaceLow/Container/High/Highest`, `fg`, `fgMuted`, `outline`, `outlineVariant`, `primary`, `primaryFg`, `primaryContainer(Fg)`, `secondaryContainer(Fg)`, `tertiary`, `error`, `errorFg`, `scrim`. Cada color tiene un valor de respaldo por si falta el archivo.

**Otros tokens**
- Tipografía: una sans de interfaz, una monoespaciada para código y terminal, y una fuente de iconos (Material Symbols Rounded, Apache 2.0, descargada al compilar el paquete). Escala de texto: 12/14/17/22 px × `textScale`.
- Radios por «esquinas»: recta 6/10/14, suave 10/16/24, redonda 14/20/28 (pequeño/medio/grande). Hueco 10.
- Animación: duraciones base 120/200/340 ms × multiplicador por modo (0, 0,7, 1, 1,4). Con `none` todo aparece quieto.
- Escala de la barra: 0,86/1/1,18.
- Vidrio: opacidad = `panelOpacity` si esa parte tiene vidrio, si no 0,97; la base puede teñirse con acento (22 % oscuro / 16 % claro).
- Degradado de marca de tres colores para detalles (línea superior de paneles, OSD, isla). Con música, esos tres se sustituyen por los de la carátula.

**Cómo se generan los colores (motor `quantum-theme apply`)**
1. Mezcla en profundidad `settings.json` del usuario sobre los del sistema.
2. Calcula la paleta según modo y orígenes, por este orden:
   - `dynamicColors` + existe `matugen` + el fondo es un archivo → `matugen image <fondo> --json hex --dry-run -m <modo> -t scheme-vibrant --prefer saturation` (de un vídeo/GIF usa el fotograma fijo).
   - Si no, acento distinto del de marca → `matugen color hex <acento> -t scheme-tonal-spot`; sin matugen, **gira el tono** de la paleta de respaldo en la diferencia de tonos (conservando los de error).
   - Si no, paleta de respaldo clara u oscura.
3. Escribe en una sola pasada: `colors.json` (con `mode`), configuración del compositor (plugins, animaciones, decoración, teclado, ratón/touchpad, salidas, desenfoque para superficies del shell por nombre de espacio de nombres), copia del fondo para la pantalla de inicio de sesión, colores del terminal (y señal para recargar), CSS de GTK3/4 con colores `@define-color` para libadwaita, `gsettings` (esquema de color, tema GTK, iconos, fuentes, cursor, orden de botones), paleta de qt6ct, y el nombre del tema de iconos (que el shell lee al arrancar; cambiar de **familia** reinicia el shell).
4. `gamemode on|off` crea/borra un marcador y regenera sin plugins de animación, gelatina y desenfoque.
5. Otros subcomandos: `set CLAVE VALOR`, `get CLAVE`, `wallpaper RUTA`, `save-outputs`.
Fallos de `matugen` caen a la paleta fija con aviso, nunca rompen el escritorio.

### 3.4 Estilos de escritorio (valores parciales sobre los defectos)

| Id | Descripción | Diferencias respecto del base |
|---|---|---|
| 1 quantum | estilo base | ninguna |
| 2 clásico | tipo Windows 10 | `layout.style=single`; dock pegado, alineado a la izquierda; esquinas rectas; animaciones rápidas; acento azul; opacidad de panel 0,95 |
| 3 moderno | tipo Windows 11 | `single`; dock pegado, centrado; esquinas suaves; acento azul; opacidad 0,9 |
| 4 muelle | tipo macOS | `split`; barra superior pegada con nombre de app; dock flotante, centrado, tamaño grande, sin búsqueda; esquinas redondas; botones a la izquierda; animaciones suaves; acento rosado |
| 5 gamer | oscuro e intenso | oscuro; acento rojo; opacidad 0,95; sin desenfoque; dock pequeño; esquinas rectas; animaciones rápidas; apertura «fuego» |
| 6 minimal | claro y limpio | modo claro; acento índigo; opacidad 0,92; barra superior pegada sin nombre de app; dock con autoocultado y sin búsqueda; esquinas redondas; animaciones suaves; apertura con fundido |

Aplicar un estilo = `deepMerge(defectos, estilo)` + `ui.style=<id>`, de modo que **siempre se ve igual** independientemente del estado anterior (el fondo se conserva salvo que el estilo traiga uno). La bienvenida reutiliza los mismos valores. Equivalencia con BC OS (ADR 0005): BC ≈ quantum, Windows ≈ clásico/moderno, Minimal ≈ minimal, y falta «macOS puro» (muelle) como variante.

### 3.5 Algoritmos pequeños útiles

- **Búsqueda de apps** (puntuación ascendente = mejor): 0 nombre empieza por la consulta; 1 alguna palabra del nombre empieza; 2 contiene; 3 coincide tipo genérico o palabras clave; 4 comentario o categorías; desempate alfabético en es-ES; todo normalizado sin tildes y en minúsculas.
- **Agrupación de la barra**: primero ids fijados (resueltos a entrada `.desktop` por id o heurística por `app_id`), luego ventanas abiertas agrupadas por entrada; recalcular solo cuando cambia el estado real (evita parpadeo).
- **Rejilla de iconos de escritorio**: casilla recordada si está libre; si no, la siguiente libre de arriba abajo por columnas; la Papelera siempre primera.
- **Atardecer**: fórmula astronómica de NOAA con latitud y longitud aproximadas (de la IP o de la zona horaria); en horario normal, intervalo con paso por medianoche.
- **Saneado de registros**: ordenar sustituciones por longitud descendente y luego expresiones para IP, MAC y correo.

## 4. Qué recrear en BC OS (priorizado)

Convenciones: esfuerzo S (≤ 1 día), M (varios días), L (semanas o con decisiones de arquitectura). «ARM64» indica riesgo o dependencia en aarch64. Todo lo marcado «?» es **pregunta abierta**, no dato.

### P0: coherencia con el trabajo en curso (bienvenida y tema)

| # | Qué | Esf. | Dependencias / ARM64 |
|---|---|---|---|
| 1 | **Motor de tema propio**: tokens Material-3-like, modo claro/oscuro, acento elegible y **«colores del fondo»**. Pipeline: ajustes → paleta → archivo de estado que vigila el panel y las apps; también GTK/Qt/terminal (alacritty) y el esquema de color de Firefox si procede. Respaldo sin generador externo (giro de tono de la paleta BC). | M | Generador de paleta: `matugen` (Rust) ¿está en Arch Linux ARM?; si no, **implementarlo en `bc-core`** (extracción de colores del fondo + escalas tonales) con el crate `material-colors` o propio. Pregunta abierta, ver 6. |
| 2 | **Esquema de ajustes unificado** con secciones, valores por defecto en un único lugar, vigilancia de cambios externos, escritura atómica, retardo de aplicación y bloqueo de escritura hasta leer. Recoger «estilo = ajustes parciales sobre defectos» y la distinción estilo/dispositivo. | M | `bc-settings-service` ya existe (TOML/dconf): decidir si adopta este árbol. |
| 3 | **Bienvenida ampliada a 5 pasos** (estilo, colores y fondo, forma del shell, sonidos, iconos) con vista previa dibujada y efecto inmediato; reabrible; opción de estilo macOS. Ya existe de 3 pasos. | M | Fondos y sonidos **propios** (sin reutilizar los de Quantum). |
| 4 | **Personalizar con buscador, vista previa y «Deshacer»** (instantánea al abrir). | M | Depende de 2. |

### P1: funciones de sistema de uso diario

| # | Qué | Esf. | Dependencias / ARM64 |
|---|---|---|---|
| 5 | **Actualizaciones visibles**: servicio de comprobación (arranque + cada 3 h), conteo en barra, notificación, separación «de BC»/«de Arch», `checkupdates` + Flathub, hook de pacman de «reinicio necesario» y aviso con «Más tarde» (2 h). | S–M | `pacman-contrib`, `flatpak`. Encaja con `bc-update-service`; el canal OTA propio es del informe de repositorio. |
| 6 | **Portapapeles con historial** (Súper+V, imágenes incluidas, borrar todo). | S | `cliphist` y `wl-clipboard` (Go y C; aarch64 sin problemas conocidos, verificar paquete) o implementación propia en el panel. |
| 7 | **Capturas**: región (selector + anotación), pantalla completa (archivo + portapapeles + notificación), carpeta con fecha. BC ya tiene `bc-screenshot`: comparar. | S | `grim`, `slurp`, editor de anotación (`swappy` o propio). |
| 8 | **OSD** de volumen y brillo, con arranque silencioso. | S | `wpctl`, `brightnessctl`. |
| 9 | **Centro de control** completo: sliders, baldosas (Wi-Fi con lista, Bluetooth, No molestar, oscuro, luz nocturna, modo juego, mosaico, colores del fondo), MPRIS, historial. Ya existe: auditar baldosas. | S–M | NetworkManager, BlueZ, MPRIS. |
| 10 | **Bloqueo**: tarjetas elegibles, campo que «se duerme» a los 30 s, vista previa, sacudida al fallar. Prioridad alta: pasar a `ext-session-lock-v1` (limitación conocida en `ARCHITECTURE.md`). | M (tarjetas) / L (protocolo seguro) | sway lo soporta; Qt6 necesita el módulo de bloqueo de sesión (`qt6-wayland` con `QtWaylandClient` + protocolo propio, o `swaylock` como respaldo): ¿existe soporte en Qt 6 de ALARM? Pregunta abierta. |
| 11 | **Inactividad**: atenuar brillo, bloquear, apagar pantalla, bloquear antes de suspender. | S | `swayidle` (en extra) o `hypridle` ¿empaquetado en ALARM? |
| 12 | **Luz nocturna y ajustes de imagen** (manual/atardecer/horario, temperatura, brillo, contraste, gamma). | S (con `wlsunset`) / M (propio) | `wlsunset` usa `wlr-gamma-control` (sway lo soporta); en máquina virtual puede no haber rampa de gamma. La saturación necesita un shader de compositor: no disponible en sway. |
| 13 | **Ajustes de ratón/touchpad/teclado/fecha-hora/zona** con `swaymsg input` y `timedatectl`. | S–M | Ninguna. |
| 14 | **Modo juego** reducido: apaga transparencias/efectos de swayfx, silencia notificaciones, pausa fondos y widgets animados, y aplica un perfil de rendimiento. | S | Su utilidad en ARM64 es menor sin juegos x86 (ver fase 7 de `PENDIENTE.md`). |

### P2: experiencia del shell

| # | Qué | Esf. | Dependencias |
|---|---|---|---|
| 15 | **Isla dinámica** (volumen, notificaciones, música) y **dashboard** (hora, calendario, música, rendimiento con anillos) sobre el panel BC. | M | MPRIS; mediciones propias en `bc-performance-service`. |
| 16 | **Selector de fondos** (tira) con claro/oscuro y «colores del fondo»; fondos animados (vídeo/GIF) con fotograma fijo; pausa por pantalla completa/batería/bloqueo. | M | `ffmpeg`; reproducción QtMultimedia (el renderizado por software de BC OS puede hacerla inviable: medir). |
| 17 | **Diseños de ventana** (Súper+Z) para modo flotante usando `swaymsg`; en mosaico ya lo cubre sway. | M | IPC de sway (ya hay `SwayControl`). |
| 18 | **Barra de tareas más rica** (reordenar arrastrando, globo con lista de ventanas, Súper+1…9 con rotación, mostrar escritorio, autoocultado, opacidad propia, elementos ordenables). | M | Ya existe en parte. |
| 19 | **Sonidos del sistema** con paquetes propios y vista previa (11 eventos + antirrebote). | M | Producción de audio **propia** (no se reutilizan los de Quantum); `pw-play`. |
| 20 | **Iconos en el escritorio** con casillas recordadas y menú contextual (con Papelera). | M | Papelera de usuario (`gio trash`). |
| 21 | **Clima** (Open-Meteo, ciudad o IP) para bloqueo/dashboard/barra. | S | Red; es una consulta que revela ubicación aproximada: documentarlo y hacer que sea opcional. |

### P3: apps y mantenimiento

| # | Qué | Esf. | Dependencias / ARM64 |
|---|---|---|---|
| 22 | **Ayuda y sugerencias**: formulario con tipo/área, vista exacta de lo que se envía con casillas, saneado de registros, cola sin internet, límite diario. Destino por decidir (p. ej. incidencia en el repositorio público de BC con enlace precargado, o correo). Ofrecerlo tras una caída del shell. | M | Decidir canal y privacidad; no se necesita intermediario si el destino son incidencias públicas con enlace precargado. |
| 23 | **Centro BC** con páginas Inicio, Apps por temas, Ajustes, «Vengo de Windows/macOS» (tabla de equivalencias y atajos), Sistema, Comunidad. «Configura tu PC» = paquetes temáticos pacman+Flatpak **filtrados a lo que existe en aarch64**. | M | Comprobar cada paquete en ALARM y cada app en Flathub aarch64 (`flatpak remote-ls --arch=aarch64`). |
| 24 | **Archivos**: pestañas, migas editables, discos y USB (montar/expulsar), recientes, favoritos, papelera con restaurar, comprimir/descomprimir, trabajos con progreso y cancelación, menú contextual con «Abrir con» y «Usar como fondo», miniaturas. Ya existe `FilesApp`: auditar carencias. | M–L | `udisks2`, `gio`, `xdg-user-dirs`. |
| 25 | **Tienda**: ya existe (pacman + Flathub). Aprendizajes aprovechables (sin adoptar la tienda de Quantum): caché HTTP con caducidad y modo sin conexión, ficha con capturas desde AppStream, trabajos que no se cortan al cerrar la ventana, `-Syu` al instalar, quitar paquetes de idioma dependientes, lista de paquetes protegidos, aviso para orígenes no oficiales (AUR). | M | Filtrar por arquitectura; muchos paquetes AUR no declaran `aarch64`. |
| 26 | **Puntos de restauración + «Cronos»**: línea de tiempo y «viajar». | L | **Decisión de sistema de archivos**: BC usa raíz ext4 (ADR 0002); las instantáneas del tipo Snapper necesitan Btrfs (o LVM/otra herramienta). Además `/boot` (ESP con systemd-boot, kernel `Image`) no viaja con la copia: hay que guardar y restaurar kernel+initramfs. Ver fase 5 de `PENDIENTE.md`. |
| 27 | **Asistente en lenguaje natural** (órdenes locales con confirmación para acciones delicadas; lista de paquetes protegidos). IA local opcional. | L | Ollama en aarch64 funciona solo en CPU: coste alto en máquinas virtuales. Dejar para el final. |
| 28 | **Pasar desde Windows** (Windows en ARM64 existe en Macs con virtualización y en portátiles con Snapdragon). Compilar el exportador para `aarch64-pc-windows`. | L | Baja prioridad. |
| 29 | **Información de hardware** en lugar de «Drivers»: listar GPU y driver en uso, avisos de VM. | S | `lspci`, `systemd-detect-virt`. |

## 5. Lo que NO aplica a BC OS

- **x86_64 y su ecosistema**: modo rendimiento con repos CachyOS (x86-64-v3/v4) y planificador `scx`; Steam con Proton; Proton-GE, `umu-run`, Heroic, Lutris, Bottles; `lib32-*`; el catálogo de juegos de Foton (Steam/Flathub x86). Los juegos x86 en BC pasarían por FEX/box64, experimental (fase 7 de `PENDIENTE.md`).
- **Wine** y `quantum-exe` para `.exe/.msi`: solo con emulación x86; descartado salvo que se haga la fase 7.
- **NVIDIA** (`quantum-drivers`): sin sentido en aarch64 de BC; se sustituye por información de hardware.
- **Wayfire y sus plugins**: animaciones de ventana, gelatina, desenfoque Kawase, cuadrícula, `expo`, cambio de escritorio virtual, mosaico sencillo, filtro de saturación (shader propio), decoración de servidor propia, IPC propio. En sway/swayfx existe desenfoque y esquinas redondeadas (swayfx, experimental), pero **no hay animaciones de apertura/minimizar ni vista general**; ¿hay animaciones en swayfx 0.6.1? pregunta abierta.
- **GRUB, `snap-pac`, `grub-mkconfig` y arranque seguro con MOK**: BC arranca con systemd-boot (ADR 0002).
- **Servidor de bloqueo con `pam_unix` plano**: BC ya tiene `/etc/pam.d/bc-lock`.
- **Formas Atomic y Serpantium** (cristal con refracción, forma de píldoras, paleta fija y fuente monoespaciada): sin interés; la «forma del shell» de BC son sus variantes de mosaico/flotante, widgets y Modos.
- **Marca**: mascota y asistente con personalidad, frases de despedida, secretos y guiños, «Créditos», logos, fondos incluidos, sonidos y paletas de marca, el estilo de títulos del instalador. Nada de esto se reutiliza.
- **Discord/Comunidad de Quantum**, intermediario de reportes y repositorio privado: BC definirá su propio canal.
- **Instalación desatendida con respuestas de Windows**, instalador Calamares (informe aparte).
- **Quickshell como dependencia**: BC OS ya tiene shell propio en Qt6/QML (`bc-shell`) con procesos separados (ADR 0004). No hace falta adoptar Quickshell; ver pregunta abierta sobre su disponibilidad solo si se quisiera.

## 6. Preguntas abiertas (no asumidas)

1. ¿Está **Quickshell** empaquetado para Arch Linux ARM (aarch64)? No se asume. Aun así no es necesario: BC usa su propio `bc-shell`.
2. ¿Están en los repositorios de Arch Linux ARM o son compilables en aarch64: `matugen`, `cliphist`, `hypridle`/`swayidle`, `wlsunset`, `swappy`, `grim`, `slurp`, `brightnessctl`, `power-profiles-daemon`, `blueman`? Comprobar con `pacman -Si` en el chroot de construcción; los que falten se compilan en `build/` o se sustituyen.
3. ¿Qué se usa como generador de colores desde el fondo en BC si `matugen` no está? Opciones: crate Rust (`material-colors`) en `bc-core` o implementación propia (cuantización + escalas tonales).
4. ¿Hay protocolo `ext-session-lock-v1` utilizable desde Qt 6 en la versión de ALARM? Si no, ¿bloquear con un cliente mínimo en C/Rust (estilo `swaylock`) con la interfaz del panel superpuesta?
5. ¿Qué sistema de instantáneas con raíz ext4 (ADR 0002)? Btrfs obligaría a revisar el pipeline de imagen; alternativas: copias con `rsync` a una partición de recuperación, o LVM.
6. ¿La reproducción de **fondos animados** es viable con render por software (`QT_QUICK_BACKEND=software`)? Medir antes de ofrecerlo en la bienvenida.
7. ¿swayfx 0.6.1 permite el efecto «vidrio» con GPU de máquina virtual o solo con `bc.gpu=1`? Condiciona el paso «efecto vidrio» de Personalizar.
8. ¿Qué paquetes de «Configura tu PC» existen para aarch64 (LibreOffice, VLC, Obsidian, Spotify y OBS tienen builds ARM dispares en Flathub)? Verificar uno a uno.
9. ¿Se mantiene la **ventana de novedades tras actualizar** (fase 9 de `PENDIENTE.md`)? En Quantum, tras una actualización, el shell se recarga y no repite pantalla de carga; no se ha encontrado una ventana de novedades en estos paquetes.
10. ¿Destino de «Ayuda y sugerencias»? Es decisión del creador (privacidad, moderación).

## 7. Notas de calidad detectadas en la referencia (para no repetirlas)

- Defectos duplicados entre `/etc/xdg/quantum/settings.json` y el código del shell, con valores ya divergentes (animación de minimizar).
- Dependencia de comandos con argumentos por cadena (`sh -c`) para listar fondos y generar fotogramas: en BC usar procesos con argumentos separados y bibliotecas.
- Las escrituras a `settings.json` desde varios procesos (shell, motor de temas, Centro, quantum-migrate) pueden pisarse: usar un único servicio de ajustes (D-Bus) como único escritor.
- El Centro y varias apps escriben estilos con CSS de Qt; en BC conviene un único módulo de tema compartido por todas las apps QML.
