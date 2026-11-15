# SPEC — Pack de iconos BC OS (macOS minimal)

Fuente de verdad del pack. Versión 0.2.0 (añade §7.7, capas de vidrio «Golden Gate»). La parte ejecutable vive en `icons/scripts/lib/spec.mjs` (constantes) y `icons/scripts/lint.mjs` (reglas): si algo de aquí cambia, cambia también allí. Todo icono nuevo debe pasar `npm run lint` sin errores ni avisos.

Originalidad: se capta la sensación de macOS (proporciones, suavidad, luz) sin copiar glifos de SF Symbols ni iconos de apps de Apple. Cada path es propio. Sin logo ni nombres de Apple.

## 1. Tipos de icono (`kind`) y estructura de carpetas

```
icons/src/<kind>/<categoría>/<nombre>.svg
```

| kind | Uso | viewBox | Color | Tamaños PNG |
|---|---|---|---|---|
| `symbolic` | UI: barra de menús, sidebar, toolbars, diálogos pequeños | `0 0 24 24` | `currentColor` | 16, 20, 24, 32, 48 |
| `color` | Diálogos grandes, carpetas, MIME, dispositivos | `0 0 48 48` | paleta fija (§6) | 16, 24, 32, 48, 64, 128, 256 |
| `app` | Dock, Launchpad, apps | `0 0 1024 1024` | paleta fija (§6, §7) | 16, 32, 64, 128, 256, 512, 1024 |

Categorías (`src/<kind>/<categoría>`), contexto Freedesktop y lote:

| categoría | contexto | etiqueta | lote |
|---|---|---|---|
| `navigation` | Actions | Navegación | A |
| `actions` | Actions | Acciones | A |
| `status` | Status | Barra de menús y estado | A |
| `dialogs` | Status | Diálogos | A (symbolic y color) |
| `apps` | Apps | Apps del sistema | B |
| `places` | Places | Lugares y carpetas | C |
| `mimetypes` | MimeTypes | Archivos y MIME | C |
| `devices` | Devices | Dispositivos | C |

Una categoría puede existir en varios `kind` (p.ej. `places` en `color` y en `symbolic`). Una categoría nueva se añade en `spec.mjs` (`CATEGORIES`) y en esta tabla.

## 2. Naming (Freedesktop Icon Naming Specification)

- Regex: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`. Minúsculas, dígitos y guiones. Sin mayúsculas, espacios ni guiones bajos.
- Se usan los nombres estándar siempre que existan (`go-home`, `edit-copy`, `folder-documents`, `utilities-terminal`...). Si no existe el estándar, se elige un nombre descriptivo con el mismo patrón `contexto-objeto-estado`.
- `symbolic`: el archivo termina en `-symbolic.svg` (`go-home-symbolic.svg`). Los demás `kind` no llevan sufijo.
- Variante rellena (estado activo): `<nombre>-fill-symbolic.svg` (`go-home-fill-symbolic.svg`). Solo en symbolic y solo si existe la regular.
- Variante simplificada para 16 o 32 px: `<stem>@16.svg` / `<stem>@32.svg` (stem completo, junto al icono base). El build la usa solo para ese tamaño PNG. No se publican como SVG propio ni en el sprite.
- Estados numéricos: `battery-level-<0|20|40|60|80|100>[-charging]`, `network-wireless-signal-<none|weak|ok|excellent>` (0, 1, 2, 3 barras), `network-wireless-offline`, `audio-volume-<muted|low|medium|high>`.
- Cada icono base lleva entrada en `icons/meta.json` (§9).
- Texto visible en castellano (`es` en meta.json), nombres de archivo en inglés.

## 3. Iconos symbolic (UI)

### 3.1 Lienzo y rejilla
- Lienzo 24x24. Área viva 20x20 (de 2 a 22 en ambos ejes). Geometría (centro del trazo) dentro de `[2, 22]`; el lint tolera 0.5 por optical balance en arcos y diagonales. Por defecto el trazo queda dentro de `[1.25, 22.75]`.
- Keylines: círculo de Ø20 (centro 12,12, r=10), cuadrado 18x18 (3..21), horizontal 20x16 (2..22 x 4..20), vertical 16x20 (4..20 x 2..22). Un círculo de contenedor usa r=8.5 a 9; un cuadrado, 14 a 17 de lado; los cuadrados pequeños (tiles de grid), 6.
- Coordenadas en múltiplos de 0.5 (0.25 solo en radios internos). Los trazos horizontales y verticales principales caen en enteros o medios.

### 3.2 Trazo
- Raíz: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">`. Sin `width`/`height`.
- Grosor único 1.5 (peso regular). El lint falla con cualquier otro valor salvo `stroke-width="1"` en detalles interiores diminutos (p.ej. el rayo dentro de la batería).
- Terminaciones y uniones redondeadas siempre. Ángulos agudos de punta (flechas, chevrons) a 45°; chevron: 6 de ancho x 12 de alto (brazos a 45°). Cabezas de flecha: brazos de 6.5 a 45°.
- Separación mínima entre trazos paralelos: 3 (centro a centro) para que a 16 px no se fundan; puntos: radio 0.9 a 1.3 (`<circle fill="currentColor" stroke="none">`); nunca trazos de longitud cero.
- Radios de esquina: rect de 14 a 17 de lado rx=2.5 a 3; rect pequeño rx=1.5 a 2; pills rx=altura/2. Esquinas continuas, no usar rx<1.
- Optical balance: círculos 0.25 más grandes que cuadrados equivalentes; los diagonales se acortan 0.5 respecto al eje; wifi y volumen se construyen con arcos concéntricos: wifi centro (12,19), radios 4/8/12, arco de ±45°; volumen centro de ondas (10.5,12), radios 3.5/6.5/9.5, arco de ±42°.
- Opacidad secundaria: 0.3 para partes "apagadas" (barras de wifi sin señal), 0.4 para relleno del nivel de batería cargando. El lint solo admite opacidad en 0.3 a 1.

### 3.3 Variante `fill`
- Misma silueta, el contorno principal con `fill="currentColor"` (el trazo se mantiene y redondea la silueta). Detalles interiores que no se pueden vaciar se omiten (monocromo: no hay "recortes"). Se usa en estados activos de sidebar (home, favoritos, bloqueo...) y control del estado activo.
- Para añadir una fracción rellena sobre un contorno (barra lateral activa) se superpone un path relleno.

### 3.4 Prohibido (lint)
`transform`, `style`, `class`, `id` (en symbolic), `data-*`, metadatos de editor (`sodipodi`, `inkscape`, `<metadata>`), `<style>`, `<filter>`, `<mask>`, `<use>`, `<image>`, `<text>`, `<title>`, colores fijos (`#hex`, `rgb()`), `fill`/`stroke` distintos de `currentColor`/`none`.

### 3.5 Hinting 16 / 32
Todos los symbolic deben verse nítidos a 16. Llevan `@16` obligatorio (el lint avisa si falta): `battery-level-*` (con y sin carga), `audio-volume-low|medium|high`, `network-wireless-signal-*`, `edit-find`, `weather-clear[-fill]`. Si a 16 un icono se empasta (separaciones < 3, más de 3 barras...), se añade `<stem>@16.svg` con la silueta simplificada. Ejemplos candidatos: baterías cargando, wifi. Los `@32` se reservan para iconos `color` y `app`.

### 3.6 Barra de menús (0.2.0)
Iconos de estado a la derecha de la barra, pensados para 16–18 px lógicos:
- `control-center`: interruptor encendido (pastilla llena 18×7, mando hueco r 1.75 por `evenodd`) sobre interruptor apagado (pastilla de contorno 16.5×5.5, mando lleno r 1.25). Separación vertical de 2 entre siluetas.
- `focus-moon[-fill]`: creciente = círculo (12,12) r 8.5 menos círculo (16.5,7.5) r 6.5. Más llena que `weather-clear-night` (dos radios 8) para no confundirse.
- `system-search`: lupa de lente r 7 en (10.5,10.5), mango de 45° hasta (20.5,20.5). `edit-find` sigue siendo la búsqueda dentro de una ventana.
- `menubar-overflow`: doble chevron a la izquierda (dos chevrons de §3.2 separados 5 en X).
- `media-now-playing`: forma de onda de cinco barras verticales separadas 4 (alturas 3, 10, 16, 7, 4).
- `network-wireless-offline`: arcos y punto a .3 y barra diagonal (4.5,4.5)→(19.5,19.5) a plena opacidad. Llevan `@16`: `control-center`, `system-search`, `network-wireless-offline`.

## 4. Iconos color (48x48): diálogos, lugares, MIME, dispositivos

- Lienzo 48x48, área viva 3 a 45. Cuerpo principal centrado en (24,24), caben en 38x38 (silueta circular R=19, cuadrada hasta 36x36).
- Fondo: degradado lineal vertical (`gradientUnits="userSpaceOnUse"`, y1=4 arriba, y2=44 abajo) de la paleta §6 (tono claro arriba, tono oscuro abajo). Un solo `<linearGradient id>` por icono (ids permitidos en color y app).
- Sombra de contacto: `<ellipse cx="24" cy="42.6" rx="14" ry="2.2" fill="#000000" opacity=".16"/>` (solo si el icono "apoya" en una superficie: diálogos, dispositivos; las carpetas la llevan más ancha rx=17).
- Borde de luz: mismo path del cuerpo con `fill="none" stroke="#FFFFFF" stroke-opacity=".28" stroke-width="1"`.
- Glifo: blanco `#FFFFFF`, trazo 4.4 a 4.6, terminaciones redondeadas (equivale a 1.5 de UI x 3). Puntos r=2.4 a 2.5.
- Formas: info = círculo; aviso = triángulo con vértices redondeados (radio de esquina 5.5); error = octógono redondeado (radio 5); correcto = círculo; pregunta = círculo. Se distinguen por forma y color.
- Documentos MIME (lote C): hoja 30x38 con esquina doblada de 9 (radio 3), etiqueta de tipo (texto convertido en path, nunca `<text>`) o glifo blanco 4.4.
- Carpetas (lote C): silueta original en azul del sistema, degradado `#7CC0FF`→`#3B9BFF`→`#1E7BF0` (pestaña y delantera con tonos distintos), con símbolo grabado del mismo lenguaje que los de UI (trazo 3, `#FFFFFF` opacidad .85 sobre delantera).
- Colores solo de la paleta §6. MIME: el color del glifo identifica el tipo y no usa colores de estado: audio verde, código azul, vídeo violeta, paquete grafito; PDF conserva el rojo por convención universal.
- Octógono de error: lados rectos, esquinas redondeadas con `Q` de radio nominal 6 (color) o 2.2 (symbolic).
- Colores solo de la paleta §6. Se permiten `opacity`, `fill-opacity`, `stroke-opacity`, degradados lineales y radiales.

## 5. Resumen de reglas de formato (todos los kinds)

- SVG limpio, un solo `<svg>` raíz con `xmlns` y `viewBox`. Comentarios solo si llevan `lint-allow`.
- Sin `transform` (se calculan las coordenadas finales), sin `id` salvo gradientes (color/app) y sin metadatos.
- Elementos permitidos: `svg, defs, g, path, circle, ellipse, rect, line, polyline, polygon, linearGradient, radialGradient, stop`.
- Compatibilidad QtSvg (Qt 6.4): nada de filtros, máscaras, `<use>`, `<style>`, `mix-blend-mode`. Sombras = capas con opacidad.
- Excepciones de zona viva: `<!-- lint-allow: bounds <motivo> -->` en el SVG (queda justificado en el propio archivo).

## 6. Paleta (hex)

Tokens base de `docs/design/tokens.json`. Todo color en SVG color/app debe estar en esta lista (`PALETTE` en `spec.mjs`).

Neutros: `#FFFFFF` blanco, `#000000` solo para sombras, `#04111F` azul noche (marca), `#F5F5F7` blanco BC, `#0B1220` texto claro/negro azulado, `#1B2742`.

Semánticos (arriba / token / abajo):

| Rol | Claro | Token | Oscuro |
|---|---|---|---|
| info | `#6AA8FF` | `#2F7BFF` | `#1F63D6` |
| éxito | `#62E487` | `#30D158` | `#1FA84F` |
| aviso | `#FFCB72` | `#FFB340` | `#F29A1F` |
| peligro | `#FF8D85` | `#FF5F57` | `#E8453C` |
| pregunta | `#9BA6FF` | `#6B77F0` | `#4F5BDB` |
| carpeta | `#7CC0FF` | `#3B9BFF` | `#1E7BF0` (más `#1565D0` para sombras internas) |

Los iconos symbolic no llevan color: heredan `currentColor` del tema (`textPrimary`: oscuro `#F5F5F7`, claro `#0B1220`) y el acento del sistema en estados activos (`#2F7BFF` oscuro, `#0A64F0` claro) lo decide el shell.

## 7. Iconos de app (1024x1024)

### 7.1 Lienzo y forma
- Lienzo 1024x1024. Cuerpo 824x824 centrado: de (100,100) a (924,924). Margen 100 por lado (sombra y respiración).
- Forma: squircle de esquinas continuas, no un rect redondeado. Radio aparente 185, suavizado 0.6 (curva continua que arranca a 296 del vértice). Se genera con `node scripts/lib/geom.mjs squircle 824 185 0.6 100 100` (misma función `squircle()` de `scripts/lib/geom.mjs`). Variar tamaño o radio está prohibido; sin tocar los nodos a mano.
- El lint exige que el path con `fill="url(#bg)"` ocupe exactamente 100,100 a 924,924.

### 7.2 Capas (orden de dibujo, de abajo arriba). Plantilla: `icons/templates/app-template.svg`
1. Sombra difusa: squircle desplazado +28 en Y (`squircle(824,185,0.6,100,128)`), `fill #000000 fill-opacity .07` y `stroke #000000 stroke-opacity .05 stroke-width 36 stroke-linejoin round`.
2. Sombra de contacto: squircle desplazado +12 en Y (`...,100,112`), `fill #000000 fill-opacity .26`.
3. Cuerpo: squircle `fill="url(#bg)"`, degradado lineal vertical `userSpaceOnUse` de (512,100) a (512,924), color superior/inferior según §7.4.
4. Luz superior (una sola fuente): mismo path con `fill="url(#hl)"`, degradado blanco `stop-opacity .22` en y=100 a `0` en y=560.
5. Borde de luz: mismo path `fill="none" stroke="#FFFFFF" stroke-opacity=".14" stroke-width="3"`.
6. Glifo (§7.3).

Nada de texturas, ruido, reflejos duros ni skeuomorfismo. Nunca más de un highlight.

### 7.3 Glifo
- Zona segura: cuadrado de 520x520 centrado (252 a 772). Glifos anchos hasta 560. Todo el glifo en blanco `#FFFFFF` (o `#0B1220`/color de marca sobre fondos "papel").
- Trazos: grosor mínimo 56 en 1024 y 80 en `@16` (lo comprueba el lint; una excepción necesita `<!-- lint-allow: stroke motivo -->`). Grosor general 56 a 64 (equivale al 1.5 de UI x ~37), `stroke-linecap/linejoin="round"`. Secundario: mismo blanco con opacidad .7 (nunca menos de .55). Rellenos: formas llenas con esquinas redondeadas ≥ 24.
- Metáfora clara y única por app, sin texto (los textos, como los números del Calendario, se convierten a path).
- Hinting: a 16 y 32 px se publica `<stem>@16.svg`/`<stem>@32.svg` con el glifo simplificado (menos elementos, trazo mínimo 80 para @16, sin degradados sutiles).

### 7.4 Color de fondo por app (arriba → abajo)
Familia común de saturación/luminosidad: tono claro arriba (L≈72%), oscuro abajo (L≈45%), saturación media-alta. Solo estos pares:

| Color | Arriba | Abajo | Apps |
|---|---|---|---|
| azul | `#5CB0FF` | `#1B6FF0` | Archivos (`system-file-manager`) |
| cian | `#67D3FF` | `#1A8CF2` | Navegador (`web-browser`), Vista previa (`multimedia-photo-viewer`) |
| teal | `#5BE0C8` | `#16A085` | Tienda (`gnome-software`), Instalar software (`system-software-install`) |
| grafito | `#B4BDCC` | `#5E6A80` | Configuración (`preferences-system`), Lanzador (`bc-launcher`) |
| verde | `#6BE591` | `#1FA84F` | Monitor de actividad (`utilities-system-monitor`) |
| noche | `#3A4660` | `#0B1220` | Terminal (`utilities-terminal`) |
| rojo | `#FF8F87` | `#E8453C` | Reloj (`preferences-system-time`) |
| naranja | `#FFA66B` | `#EB5B1E` | (libre; `#EB5B1E` es el color de las teclas de operador de la Calculadora) |
| ámbar | `#FFD27D` | `#F29A1F` | Notas (`accessories-notes`) |
| violeta | `#B49CFF` | `#6B4FE0` | Música (`multimedia-audio-player`) |
| índigo | `#8E9BFF` | `#3A45C4` | Editor (`accessories-text-editor`), Calculadora (`accessories-calculator`) |
| magenta | `#FF8FC2` | `#D6336C` | Mission Control (`bc-mission-control`) |
| papel | `#F5F5F7` | `#E4E9F2` | Calendario (`office-calendar`) |
| plata | `#F5F5F7` | `#C3CCDB` | Papelera (`user-trash`, `user-trash-full`) |
| niebla | `#E6EBF5` | `#A7B3CC` | Aplicaciones (`view-app-grid`, fondo claro) |

Regla (lint): como máximo dos apps del Dock por familia de color. Un color nuevo se añade aquí y en `PALETTE` (`spec.mjs`).

**Fondos claros (papel, plata y niebla).** El borde de luz blanco no se ve sobre ventanas claras, así que en estos fondos se sustituye por un borde oscuro `#000000` con `stroke-opacity .10` y `stroke-width 6` (en los demás colores sigue siendo `#FFFFFF` .14 / 3). El extremo claro del degradado baja a `#F5F5F7`.

Sobre "papel", "plata" y "niebla" el glifo usa `#0B1220`, `#1F63D6`, `#E8453C` o colores de la paleta semántica.

### 7.5 Papelera del Dock
`user-trash` y `user-trash-full` son excepción: cubo abierto (sin tapa) de vidrio sobre el squircle "plata". Borde (elipse cx 512, cy 336, rx 208, ry 60) y costados en `#1B2742` opaco con trazo 56 (equivale a `#0B1220` a .8 pero sin oscurecer los solapes de las terminaciones); cuerpo `#0B1220` .08 y boca `#0B1220` .16; tres costillas verticales `#0B1220` .55. `-full` dibuja dos papeles (`#1F63D6` y `#6AA8FF`, rectángulos girados -12° y 9°, esquinas 28) entre el arco trasero y el delantero del borde, de modo que se ven a través del vidrio. Es el mismo archivo para Dock y Lugares (el lote C no lo duplica).

### 7.6 Salidas
`dist/png/<tamaño>/<stem>.png`, `dist/icns/<stem>.icns` (tipos `icp4 icp5 icp6 ic07 ic08 ic09 ic10 ic11 ic12 ic13 ic14`, PNG embebido), tema Freedesktop `scalable/apps` + `<N>x<N>/apps`.

### 7.7 Glifo por capas de vidrio («Golden Gate», v0.2)
Opcional para cualquier app y obligatorio en las apps del Dock rediseñadas desde la 0.2.0 (`system-file-manager`, `preferences-system`, `utilities-system-monitor`, `gnome-software`, `utilities-terminal`, `view-app-grid`, papeleras, `accessories-calculator`, `accessories-notes`, `multimedia-photo-viewer`). Mantiene §7.1–7.4: mismo squircle, mismas sombras del cuerpo, una sola luz cenital. El glifo se compone, de abajo arriba, con como mucho estas capas:

1. **Placa de vidrio** (opcional, una): forma secundaria detrás del objeto. `fill="#FFFFFF" fill-opacity=".3"` (.16 sobre fondo "noche", .35 en piezas pequeñas) y borde de vidrio `stroke="#FFFFFF" stroke-opacity=".5" stroke-width="4"` (única excepción al trazo mínimo de §7.3; el lint la reconoce por ancho 4 y opacidad ≤ .6).
2. **Sombra del objeto**: la silueta del objeto principal desplazada **+16 en Y**, `fill="#000000" fill-opacity=".16"` (.3 sobre "noche"). Un solo path (nunca piezas solapadas, que duplicarían la opacidad).
3. **Objeto principal**: blanco con el degradado `gl` (vertical `userSpaceOnUse` de y=252 `#FFFFFF` a y=772 `#E4E9F2`), que da volumen con la misma luz cenital. No es un segundo highlight.
4. **Detalle recortado** (opcional): sobre el objeto blanco, en el color inferior del propio fondo (p.ej. `#1B6FF0`, `#16A085`), como si fuera un hueco. Trazo ≥ 56 o relleno con esquinas ≥ 24. Huecos reales con `fill-rule="evenodd"` (engranajes).
5. **Acentos de color**: solo piezas pequeñas (≤ 5 % del glifo) con colores semánticos de §6 (p.ej. los tres puntos de ventana de Terminal). Excepciones: `accessories-calculator`, cuyas teclas de operador (columna derecha, círculo + píldora de «=») van en `#EB5B1E`; y `view-app-grid`, cuya metáfora son 9 teselas de color (152×152, rx 44, separación 32) con un degradado propio `tl` (`objectBoundingBox`, blanco .32 → 0 a .55) que hace de vidrio de cada tesela.

`@32` conserva las capas 1, 3 y 4 sin borde de vidrio ni sombra del objeto (trazos 64); `@16` deja solo el objeto principal (trazo ≥ 80, sin degradados de glifo ni detalles). Autoría reproducible: `node scripts/authoring/golden-gate.mjs` (coordenadas del glifo escritas a mano; squircle de `geom.mjs`).

Variantes oscura y tintada: aún no forman parte del formato (ver propuesta en `REVIEW.md`, «Propuesta 0.3»).

## 8. Proceso de diseño de un icono

1. Elegir la metáfora más reconocible (una sola).
2. Dibujar a mano con el mínimo de nodos, simetría exacta, coordenadas limpias (0.5 para symbolic).
3. Colocar el archivo en `src/<kind>/<categoría>/`, añadir entrada a `meta.json`.
4. `npm run lint` y `npm run build`; abrir `preview/index.html` (claro/oscuro, slider a 16 px, overlay de rejilla).
5. Si recuerda a un icono de Apple, rediseñarlo.

## 9. Formato de `icons/meta.json`

```json
{
  "go-home": { "es": "Inicio", "tags": ["casa", "home"], "category": "navigation" }
}
```
La clave es el nombre base (sin `-symbolic` ni `-fill`). Si el mismo nombre existe en dos categorías (p.ej. `preferences-system`: symbolic en `actions` y app en `apps`), `category` es la principal y `also` lista las demás. `es` es la etiqueta visible en castellano (es_ES); `tags` mezcla castellano e inglés para el buscador; `category` debe coincidir con la carpeta.

## 10. Formato de `icons/manifest.json` (generado por `build`)

```json
{
  "name": "BC", "version": "0.1.0", "stroke": 1.5,
  "kinds": { "symbolic": { "viewBox": "0 0 24 24", "sizes": [16,20,24,32,48] }, "color": {}, "app": {} },
  "categories": [ { "id": "navigation", "label": "Navegación", "context": "Actions", "lote": "A", "count": 21 } ],
  "icons": [
    {
      "name": "go-home", "label": "Inicio", "category": "navigation", "context": "Actions",
      "kind": "symbolic", "viewBox": "0 0 24 24",
      "variants": { "regular": "go-home-symbolic", "fill": "go-home-fill-symbolic" },
      "tags": ["casa", "home"], "sizes": [16,20,24,32,48],
      "hints": [16], "file": "dist/svg/go-home-symbolic.svg"
    }
  ]
}
```
`variants` apunta a stems (nombre de archivo sin `.svg`) y `hints` solo aparece si hay `@16`/`@32`. Una entrada por `(kind, categoría, nombre)`; por eso `dialog-warning` aparece dos veces (symbolic y color).

## 11. Pipeline de build (`npm run build`, ver README)

1. SVGO 3 (multipass, `viewBox` conservado, `currentColor` conservado, formas sin convertir a path).
2. `dist/svg/<stem>.svg` optimizados.
3. `dist/png/<px>/<stem>.png` con resvg (`@resvg/resvg-js`). Symbolic en negro puro con alfa.
4. `dist/tinted/on-dark|on-light/<stem>.svg` (symbolic con `currentColor` sustituido por `#F5F5F7` / `#0B1220`) para QtSvg.
5. `dist/sprite.svg` (`<symbol id="<stem>">`, gradientes con ids únicos por símbolo).
6. `dist/theme/BC/` con `index.theme` (`Inherits=hicolor`), `symbolic/<ctx>/`, `scalable/<ctx>/`, `<N>x<N>/<ctx>/`.
7. `dist/icns/` para apps.
8. `manifest.json`, `preview/data.js`.

## 12. Uso desde el shell Qt/QML (para la integración)

- Symbolic: usar `dist/tinted/on-dark` o `on-light` según tema (o `Image` + colorización). `sourceSize` = tamaño lógico x devicePixelRatio. Tamaños: 16, 20, 24, 32.
- Color y app: `dist/svg/<stem>.svg` con `sourceSize` o PNG `dist/png/<px>/`. El Dock (70 px) usa 128 o 256.
- Aplicaciones externas: instalar `dist/theme/BC` en `/usr/share/icons/BC` y fijar `gtk-icon-theme-name=BC` / `QT_QPA_PLATFORMTHEME` con `iconTheme=BC`.
