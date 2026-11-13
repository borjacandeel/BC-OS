# REVIEW — Revisión independiente del pack de iconos BC OS

Fecha 2026-11-13. Revisor externo, solo lectura. Material: 218 SVG de `icons/src`, PNG de `icons/dist/png` (16, 24, 32, 48, 128, 256), hojas de contacto sobre fondo claro y oscuro, contraste con `SPEC.md` y `AUDIT.md` y con el uso real en `shell/qml`.

`npm run check` en `icons/`: pasa (lint 218 archivos, 0 errores, 0 avisos; build 167 iconos, 182 SVG, 36 hints, 17 .icns). El lint es verde pero no cubre varios fallos de abajo (ver P1-12).

Resumen: **P0 = 3, P1 = 13, P2 = 12**.

Criterio: P0 bloquea la integración en el shell o expone un riesgo de parecido con Apple; P1 hay que arreglarlo antes de 0.1.0 estable; P2 es pulido.

---

## P0 — Bloqueantes

### P0-1. `web-browser`: es la brújula de Safari
Círculo blanco con aguja diagonal sobre azul cian. Misma metáfora, composición y casi misma paleta que el icono de Safari. Es el caso de parecido más claro del pack y el SPEC (§8.5) obliga a rediseñar.
Corrección: abandonar la brújula. Globo con meridianos (círculo + elipse vertical + ecuador, trazo 56) o un cursor/ventana con pestaña. Mantener el fondo `cian`, pero ver P1-3 (mismo color que Tienda). Rehacer `@32` y `@16`.

### P0-2. `system-software-install`: la bolsa se lee como candado
El asa semicircular sobre un cuerpo trapezoidal blanco con sonrisa se ve como un candado (a 32 y 16 px es un candado azul sin duda alguna) y la sonrisa recuerda a Amazon; la bolsa de compra además es el icono de Apple Store. Metáfora ambigua y con riesgo doble.
Corrección: cambiar de metáfora. Caja abierta con flecha hacia abajo (paquete que se instala) o un bloque/cubo con flecha. Sin sonrisa. Si se mantiene la bolsa, asa en dos arcos separados del cuerpo y sin sonrisa. Rehacer `@16`/`@32`.

### P0-3. Lienzo de `app`: el squircle claro (papel/plata) se pierde sobre fondos claros
`multimedia-photo-viewer`, `office-calendar`, `bc-launcher`, `user-trash`, `user-trash-full` (6 de 17) llevan fondo blanco o plata con borde de luz `#FFFFFF` a .14: sobre la ventana clara del shell (Archivos, tema claro) el contorno desaparece y solo queda la sombra gris. El Dock y las ventanas en tema claro las funden con el fondo. Se ve en `app128l`.
Corrección: en los fondos papel/plata sustituir (o añadir) un borde inferior oscuro `#000000` a opacidad .10 y stroke-width 3, y bajar el extremo claro del degradado a `#F5F5F7`. Documentarlo como excepción en SPEC §7.4 y aplicarlo en las 3 resoluciones. No exige cambiar el glifo.

---

## P1 — Importantes

### P1-1. Parecido con apps de Apple (rediseñar o diferenciar claramente)
Cada uno copia metáfora y composición reconocibles de un icono de Apple. Corrección común: cambiar silueta del glifo y/o familia de color.
- `office-calendar`: tarjeta blanca, banda roja arriba, número grande negro. Es el Calendario de Apple sin el día de la semana. Corrección: pasar a página con anilla/cabecera de color de marca (azul `#1F63D6`), número en otro peso, o cuadrícula de días en vez de número solitario. Además el "13" va fijo: documentar que lo sustituye el shell, o mostrar cuadrícula neutra.
- `preferences-system-time` (Reloj): esfera negra, aro blanco, manecillas blancas con la de segundos... Es el Reloj de Apple. Corrección: cambiar a reloj sin aro completo (arco + manecillas) o un cronómetro/campana; pasar a otro color (no `noche`, ver P1-3).
- `multimedia-audio-player` (Música): degradado rojo-rosa con corchea blanca = Apple Music. Corrección: auriculares o ecualizador de barras (la metáfora de monitor ya usa pulso: no repetir), cambiar fondo a rojo con menos rosa o a violeta/coral.
- `bc-launcher`: cuadrícula 3x3 de puntos de color sobre plata = Launchpad. Corrección: cuadrícula 3x3 monocroma blanca sobre fondo grafito o azul de marca, o un círculo de "BC".
- `accessories-notes`: banda superior ámbar + líneas = Notas de Apple. Corrección: libreta con espiral lateral, o bloc con esquina doblada; sin banda superior de otro tono.
- `preferences-system`: engranaje blanco sobre grafito = Ajustes del Sistema. El engranaje ya es propio (8 dientes cortos); diferenciar con deslizadores (el símbolo UI ya usa sliders) o con engranaje de 6 dientes sobre grafito/violeta.
- `bc-mission-control`: dos ventanas apiladas sobre noche = Mission Control. Corrección: tres tiles asimétricos (1 grande + 2 pequeños) o estilo "escritorios virtuales" con perspectiva plana, y color propio.
- `accessories-calculator`: pantalla + rejilla de puntos sobre grafito. Aceptable en metáfora; diferenciar con teclas cuadradas y la tecla `=` destacada en color de marca.

### P1-2. Confusión entre símbolos UI (casi idénticos)
- `document-send-symbolic`, `go-top-symbolic`, `browser-download-symbolic`, `go-bottom-symbolic`: cuatro variantes del mismo "flecha + barra". A 16 px no se distinguen. Corrección: `document-send` = flecha saliendo de una bandeja abierta (U con flecha arriba), `browser-download` = flecha dentro de bandeja; `go-top/go-bottom` = flecha con barra solo en el extremo y sin bandeja.
- `edit-clear-symbolic` (x en círculo) y `dialog-error-symbolic` (x en círculo): idénticos. Corrección: `edit-clear` como x en pastilla/ cuña de borrador (`⌫` propio) y `dialog-error` como octógono (SPEC §4 lo pide).
- `user-desktop-symbolic`, `computer-symbolic`, `video-display-symbolic` y sus `-fill`: tres monitores con peana, casi iguales. Corrección: `computer` = portátil o torre; `video-display` = monitor sin peana ancha con ranura; `user-desktop` = monitor con barra inferior (dock) o rectángulo con línea de escritorio.
- `bookmark-new-fill`, `starred-fill` y `folder-music`: aceptables, pero `bookmark-new-symbolic` vs `view-sidebar` a 16 px se parecen en peso. Menor, ver P2.
- `power-profile-performance-symbolic` (rayo) y el rayo dentro de `battery-*-charging`: mismo signo para dos significados. Corrección: rayo de carga más pequeño y con trazo 1 (ya previsto en SPEC §3.2); el perfil de rendimiento, un indicador/velocímetro.

### P1-3. Paleta de apps: colores repetidos y 3 fondos oscuros iguales
Tres azules/cianes en el Dock (Archivos azul, Tienda cian, Navegador cian), tres fondos oscuros (Terminal, Reloj, Mission Control), dos grafitos (Configuración, Calculadora), tres papel/plata. A 32 y 16 px el color es lo único distintivo y aquí no distingue. Se ve claro en `app32d` y `app16l`.
Corrección: Tienda a otro tono (naranja `#FFD27D→#F29A1F` ya está en Notas: usar teal/turquesa `#5BE0C8→#16A085`, añadiéndolo a la paleta y a SPEC §7.4) o violeta; Reloj a `rojo`/`ámbar`; Mission Control a `violeta` o `azul` oscuro; Calculadora a `ámbar` o `naranja`. Regla: como máximo dos apps del Dock por familia.

### P1-4. Grosor de glifo en apps incumple SPEC §7.3
El SPEC fija trazo mínimo 56 en glifos de app. Hay trazos de 40 (`accessories-notes`, `multimedia-photo-viewer`, `user-trash`, `user-trash-full`), 44 (`system-software-install`), 48 (`bc-mission-control`, trashes) y 24 (`web-browser`, `user-trash-full`, detalles). Además en el mismo pack el grosor principal va de 56 a 88 (engranaje) y 64 (otros): un icono "ligero" junto a uno "pesado" en el Dock. Corrección: fijar 56 como grosor general, 64 máximo; las excepciones documentadas en el propio SVG con `lint-allow`.

### P1-5. Sin hints `@16` en iconos symbolic
`find` encuentra 19 `@16` (17 apps + `folder`, `text-x-generic`) y ninguno en symbolic, aunque SPEC §3.5 nombra baterías cargando y wifi como candidatos. Se ve en `sym16`: los 12 estados de batería son una mancha (0, 20 y 40 % indistinguibles, el relleno y el contorno se funden), el rayo de carga es un punto, `audio-volume-low/medium/high` apenas se distinguen, el rayo del Sol queda en puntos sueltos y la lupa pierde el mango.
Corrección: `@16` para `battery-level-*` (relleno sin hueco, marcas de nivel en 3 pasos 0/33/66/100, rayo con trazo 1.5 mínimo), `audio-volume-*`, `weather-clear*`, `edit-find`, `network-wireless-*`, `airplane-mode`, `audio-input-microphone`, `printer`, `input-keyboard`.

### P1-6. Iconos color ilegibles a 16 px
Solo existe `@16` de `folder` y `text-x-generic`. Las demás carpetas (documents, download, pictures, music, videos, remote, cloud, home, desktop) a 16 son el mismo bloque azul sin glifo; los MIME con etiqueta (`application-pdf` "PDF", `application-x-executable`, `text-x-script`, `application-octet-stream`) quedan en una mancha. Ver `col16d`.
Corrección: `@16` para los 9 `folder-*`/`user-*` (glifo grande sin degradado, un solo símbolo de 6 px), `application-pdf` (banda roja sin texto), `text-x-script` y `application-x-executable`; dispositivos `phone`, `printer`, `drive-*` con silueta simplificada.

### P1-7. Falta `-fill` en la mayor parte de lugares symbolic
Solo `folder`, `folder-cloud`, `folder-documents`, `user-desktop` y `user-home` tienen `-fill`. `folder-download`, `folder-music`, `folder-pictures`, `folder-videos`, `folder-remote` no, aunque `FilesWindow.qml` usa los seis para su sidebar activa. Resultado: estado activo inconsistente. Corrección: añadir `-fill` para los cinco y para `user-trash`.

### P1-8. `dialog-*` color: la forma no distingue
SPEC §4 pide información = círculo, aviso = triángulo, error = octógono, correcto = círculo, pregunta = círculo. El octógono de `dialog-error` tiene radio de esquina tan grande que se ve un círculo: info, correcto, pregunta y error son cuatro círculos y se distinguen solo por color (problema de accesibilidad, daltonismo rojo/verde). Corrección: octógono real (radio 3 a 4 en las esquinas); info y pregunta pueden compartir círculo si el glifo es muy distinto, pero correcto vs error debe diferir por forma.

### P1-9. Mezcla de trazos en iconos `color`
Los glifos de los iconos color usan 1, 1.5, 1.6, 1.8, 2, 2.4, 3, 3.2, 3.4, 4, 4.4 y 4.6 (conteo en `src/color`). SPEC §4 fija 4.4 a 4.6 para el glifo blanco y 3 para el grabado de carpetas. Las carpetas usan 3 y los MIME entre 1.6 y 4. Se nota en `col48`: PDF y ejecutable más finos que las carpetas. Corrección: normalizar a 3 (grabados) y 4.4 (glifos de diálogo); detalles de dispositivo, 1.5 mínimo.

### P1-10. Paleta fuera de espíritu en `color`
Aunque pasa lint, `package-x-generic` lleva naranja/ámbar de aviso, `audio-x-generic` rojo de peligro, `video-x-generic` violeta de pregunta y `application-pdf` rojo: los colores semánticos de estado se usan como colores de categoría. Un MIME rojo se confunde con error. Corrección: tonos neutros por tipo (grafito para ejecutable, azul para código, verde para audio) o fijar un tipo→color propio en SPEC §6 con tonos desaturados.

### P1-11. Baja diferenciación a 16 px en pares de apps
`user-trash` vs `user-trash-full` (a 16 solo cambia un detalle de 2 px), `system-file-manager` vs `system-software-install` (ambos azul con silueta blanca), `bc-launcher` vs `bc-mission-control` vs `accessories-calculator` (rejillas). Corrección: en `user-trash-full@16` papeles que sobresalen 3 px y color del cubo más oscuro; en Files una pestaña de carpeta más marcada.

### P1-12. El lint no detecta lo anterior
Pasa sin avisos con trazos de app <56, colores repetidos, iconos symbolic sin `@16` y octógono redondeado. Corrección: añadir a `scripts/lint.mjs` (1) mínimo 56 en `stroke-width` de glifos de app salvo `lint-allow`, (2) aviso de `@16` cuando una symbolic tenga >2 elementos paralelos o fill parcial, (3) comprobar paridad de gradientes del par (`bg`) con la tabla de §7.4 y un máximo de apps por familia, (4) umbral de radio mínimo en octógono de error.

### P1-13. Inventario: iconos que faltan para lo que usa el shell
Revisado `shell/qml` (TopBar, Dock, FilesWindow, ControlCenter, NotificationCard, FileGlyph, AppIcon, Icons). Cubiertos: wifi, volumen, batería, toggles, bluetooth, moon, sun, bolt, chevrons, closeX, refresh, home, desktop, document, download, image, music, search, folder, los 8 de Dock, carpeta y 3 MIME de FileGlyph. Faltan o están a medias:
- `user-trash-symbolic` (y `-fill`): `FilesWindow.qml` línea 103 usa `Icons.trash` en sidebar. AUDIT lo mapea a lote C pero no existe en `src/symbolic/places` (solo `edit-delete`, que es la acción de borrar, no el lugar).
- `folder-pictures-fill`, `folder-music-fill`, `folder-download-fill`, `folder-videos-fill`, `folder-remote-fill` (P1-7).
- `x-office-document` y `x-office-spreadsheet` (color): FileGlyph tiene 4 tipos, pero AUDIT §2.4 prevé estos y no están entregados.
- `folder-open` (color) y `folder-publicshare`: pendientes del propio AUDIT §2.4 y no hechos.
- `text-html`, `network-workgroup`: pendientes.
- `power-profile-balanced-symbolic` y `power-profile-power-saver-symbolic`: el Centro de control tiene la tarjeta de energía con solo el rayo.
- `network-wired-symbolic`: no hay cable aunque hay estados wifi.
- `view-app-grid-symbolic`: AUDIT §2.3 lo cita como extra de Dock/lanzador; no existe (`bc-launcher` es solo de app).
- `system-search-symbolic` (barra del lanzador), `window-new-symbolic`, `document-open-symbolic`, `document-save-symbolic`, `document-properties-symbolic`: toolbar de Archivos.
- `drive-removable-media-symbolic` y `drive-harddisk-solidstate`: hay color `drive-removable-media` pero no su variante symbolic ni la de disco óptico.
- `dialog-password-symbolic` y `dialog-password` (color), `camera-photo-symbolic`, `video-camera-symbolic`, `accessibility-symbolic` y `system-users-symbolic`: ausentes aunque la Configuración las necesitará.

---

## P2 — Menores

- P2-1. `network-wireless-signal-*`: el arco de `opacity .3` más lejano es muy tenue a 16 px sobre fondo oscuro; subir a .35 o usar punteado fino.
- P2-2. `battery-level-*`: el relleno interior `rect` sin trazo deja un hueco de 1 unidad con el contorno; a 24 px parece que el nivel "flota". Alinear relleno a trazo con 1.5 de margen exacto.
- P2-3. Símbolos con geometría idéntica a SF Symbols (no obliga a rediseñar, pero se recomienda tocar ángulos): `view-sidebar` (rectángulo + línea vertical), `control-center` (dos interruptores apilados), `network-wireless-*` (arcos + punto), `battery-*` (cápsula con terminal y rayo), `audio-volume-*` (altavoz + ondas), `airplane-mode`, `edit-find` (lupa), `lock-screen`. Variar: `view-sidebar` con línea a 8.5 y esquinas rx 2.5, `control-center` con un interruptor y un deslizador, `network` con arcos con extremos cuadrados.
- P2-4. `preferences-system-symbolic`: dos sliders; coincide con `view-filter-symbolic` (tres líneas) por estilo. A 16 px confusos; marcar los puntos como círculo relleno en `preferences`.
- P2-5. `bookmark-new` vs `starred`: bordes y pesos distintos a 24 px pero a 16 casi idénticos en versión rellena. Ensanchar la cinta del marcador.
- P2-6. `weather-clear-night-symbolic` y `do-not-disturb-symbolic` son la misma luna; el Centro de control usa `moon` para ambos. Añadir distintivo (luna con barra o "Zz").
- P2-7. `input-mouse` y `phone` symbolic: pastillas largas con detalle interior de 1 px que a 16 desaparece. Quitar el detalle interior o engrosarlo.
- P2-8. Carpetas (`color/places`): todas comparten el mismo azul; solo cambia el glifo. Aceptable en estética macOS minimal, pero `folder-remote` (globo) y `folder-cloud` convendría diferenciarlos por tono (ligeramente más frío) para el listado de lugares.
- P2-9. `drive-harddisk` y `drive-removable-media` (color): siluetas grises con círculo, ambiguas (parecen proyector o router). Rehacer con proporciones de disco (bloque bajo con LED) frente a pendrive (ya hay `-usb`).
- P2-10. Sombras de contacto en `color` y `app`: el squircle del app lleva dos capas (+12 y +28) con .26 y .07; con el Dock dibujando su propia sombra puede duplicarse. Documentar que el Dock no añade sombra o publicar una variante sin ella para el lanzador.
- P2-11. Mezcla de glifo lleno y contorno en apps: Archivos, Configuración, Tienda, Papelera llenos; Monitor, Terminal, Navegador, Reloj de contorno. Elegir una familia de peso dominante (contorno grueso) para toda la fila.
- P2-12. Documentación desfasada: AUDIT §2.2 dice 21 navegación y 37 acciones; hay 23 y 41. SPEC cita `view-app-grid` en lote B y no está. Actualizar los contadores y el estado de los pendientes.

---

## Notas de método
- Alineación a keylines y área viva: no se detectaron incumplimientos en symbolic (el lint ya lo bloquea); el problema está en el peso y en los hints, no en la rejilla.
- No se han modificado iconos ni `dist/`. No se ha tocado `PENDIENTE.md` (la actualiza el agente principal).

---

## Estado tras la corrección (2026-11-13, icon-designer)

`npm run check`: lint 271 archivos, 0 errores, 0 avisos; build 183 iconos, 204 SVG, 67 hints.

**Resuelto**
- P0-1: `web-browser` rediseñado como globo con meridianos y ecuador (sin aguja ni brújula), @32/@16 incluidos.
- P0-2: `system-software-install` ahora es caja con flecha de entrada, sin asa ni sonrisa; fondo teal.
- P0-3: fondos papel/plata con borde oscuro `#000000` .10 (ancho 6) en las 3 resoluciones; extremo claro `#F5F5F7`. Documentado en SPEC §7.4.
- P1-1: rediseñados calendario (anillas + cuadrícula, azul de marca), reloj (cronómetro), música (auriculares), lanzador (3x3 blanco sobre grafito), notas (libreta con agujeros, sin banda), configuración (engranaje de 6 dientes), mission control (tres tiles asimétricos), calculadora (teclas cuadradas y `=` destacada).
- P1-2: `document-send`/`browser-download` (bandeja), `edit-clear` (cuña de borrar), `user-desktop` (monitor con barra de dock), `power-profile-performance` (velocímetro).
- P1-3: paleta de apps con 14 familias y máximo 2 apps por familia (teal, naranja, índigo y magenta nuevos).
- P1-4: trazo de glifo >= 56 (>= 80 en @16) en todas las apps.
- P1-5: `@16` para `battery-level-*` (12), `audio-volume-low|medium|high`, `network-wireless-signal-*`, `edit-find`, `weather-clear[-fill]`.
- P1-6 (parcial): `@16` de las 9 carpetas y lugares con glifo grande.
- P1-7: `-fill` de `folder-download|music|pictures|videos|remote` y `user-trash`.
- P1-8: octógono de error con lados rectos (color y symbolic).
- P1-10: MIME sin colores de estado (audio verde, script azul, paquete grafito); PDF conserva rojo por convención.
- P1-11 (parcial): papelera llena con papeles azules que sobresalen; Archivos y Tienda se separan por color (azul/teal).
- P1-12 (parcial): el lint comprueba trazo mínimo de app, máximo 2 apps por familia y `@16` obligatorio en los symbolic críticos.
- P1-13 (parcial): añadidos `user-trash-symbolic`, `power-profile-balanced|power-saver`, `network-wired`, `view-app-grid`, `document-open|save|properties`, `window-new`, `drive-removable-media`, `dialog-password`, `camera-photo`, `system-users` (symbolic) y `x-office-document`, `x-office-spreadsheet`, `text-html` (color).
- P2-12: contadores de AUDIT actualizados.

**No resuelto (con motivo)**
- P1-6 resto: `@16` de `application-pdf`, `text-x-script`, `application-x-executable`, `drive-*`, `phone`, `printer` color. Requiere rediseñar la etiqueta por tipo, no un ajuste.
- P1-9: normalizar trazos de glifos color a 3 / 4.4. Toca unos 40 SVG color; se hará junto a la revisión de MIME.
- P1-2 `computer`/`video-display`: solo se separó `user-desktop`; portátil y monitor con peana ya difieren entre sí.
- P1-8 resto: info, correcto y pregunta siguen siendo círculos; se distinguen por glifo y color (el error ya difiere por forma).
- P1-12 (2) y (4): no hay chequeo de elementos paralelos ni umbral numérico del octógono.
- P1-13 resto: `folder-open`, `folder-publicshare`, `network-workgroup`, `system-search` (el shell mapea a `edit-find`), `drive-harddisk-solidstate`, `video-camera`, `accessibility`, `dialog-password` color.
- `@16` de `airplane-mode`, micrófono, impresora y teclado: ya cumplen la separación mínima de 3; sin hint hasta que el shell lo pida.
- P2-1 a P2-11: sin tocar (pulido).
