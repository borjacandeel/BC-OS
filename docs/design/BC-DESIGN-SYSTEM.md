# BC OS — Sistema de diseño

Versión 0.1 · Fuente única de verdad visual. Los tokens máquina-legibles están en [`tokens.json`](tokens.json).

Origen: logos oficiales (`assets/branding/`) y captura de referencia (`docs/design/reference/escritorio-referencia-01.webp`, 1586×992). Las medidas marcadas «≈» se han estimado sobre esa captura y deben afinarse al implementar el shell; no están validadas en un sistema en ejecución.

## 1. Principios

1. **Ligero**: pocos efectos, todos baratos en GPU. Sin blur por CPU.
2. **Potente**: densidad de información clara, jerarquía fuerte.
3. **Fluido**: toda transición tiene curva y duración definidas aquí.
4. **Un solo lenguaje**: ninguna aplicación define colores, radios o sombras propios; usa tokens.
5. **Español primero**: textos, fechas (`vie 13 nov  18:11`) y formatos regionales es_ES.

## 2. Color

### 2.1 Marca (de los logos)

| Token | Valor | Uso |
|---|---|---|
| `brand.nightBlue` | `#04111F` | fondo marca, logo sobre claro |
| `brand.white` | `#F5F5F7` | logo/texto sobre oscuro |
| `brand.silver.top` | `#F6F8FC` | degradado plata (0 %) |
| `brand.silver.mid` | `#D5DCE8` | degradado plata (55 %) |
| `brand.silver.bottom` | `#A1ADC0` | degradado plata (100 %) |
| `brand.midnight.center` | `#3A4A66` | radial midnight (centro) |
| `brand.midnight.edge` | `#0B1019` | radial midnight (borde) |

### 2.2 Escritorio (de la referencia)

Fondo: ondas suaves azul índigo → violeta sobre azul noche. Paleta de acento y superficies (≈, muestreadas visualmente):

| Token | Oscuro | Claro | Uso |
|---|---|---|---|
| `accent` | `#2F7BFF` | `#0A64F0` | selección, deslizadores, enlaces, iconos activos |
| `accent.hover` | `#4D8FFF` | `#2F7BFF` | hover |
| `accent.pressed` | `#1F63D6` | `#0850C4` | pulsado |
| `surface.window` | `#16213A` a 82 % | `#F4F6FA` a 86 % | cuerpo de ventana |
| `surface.sidebar` | `#1B2742` a 70 % | `#E8ECF3` a 78 % | barra lateral |
| `surface.panel` | `#101A30` a 78 % | `#FFFFFF` a 80 % | Centro de control, notificaciones, Dock |
| `surface.control` | `#FFFFFF` a 8 % | `#000000` a 6 % | botones, campo de búsqueda, mosaicos |
| `surface.controlHover` | `#FFFFFF` a 14 % | `#000000` a 10 % | hover de controles |
| `border.subtle` | `#FFFFFF` a 12 % | `#000000` a 10 % | contorno de ventana/panel (1 px) |
| `text.primary` | `#F5F5F7` | `#0B1220` | texto principal |
| `text.secondary` | `#F5F5F7` a 62 % | `#0B1220` a 62 % | subtítulos, estados («Conectado») |
| `text.disabled` | `#F5F5F7` a 38 % | `#0B1220` a 38 % | deshabilitado |

### 2.3 Semánticos

| Token | Valor | Uso |
|---|---|---|
| `success` | `#30D158` | confirmaciones, botón maximizar |
| `warning` | `#FFB340` | avisos, botón minimizar |
| `danger` | `#FF5F57` | errores, botón cerrar |
| `info` | `#2F7BFF` | = accent |

Botones de ventana (≈ 22 px de diámetro): cerrar `#FF5F57`, minimizar `#FEBC2E`, maximizar `#28C840`.

Colores de iconos de carpeta: azul `#3B9BFF → #1E7BF0` (degradado vertical).

### 2.4 Modos

- **Oscuro** (predeterminado; es el de la referencia).
- **Claro**.
- **Automático** según hora o preferencia del sistema.
- **Alto contraste**: superficies opacas (100 %), borde 2 px `text.primary`, sin transparencias.

## 3. Tipografía

- Familia UI: **Inter** (sans neutra, soporte completo de español: á é í ó ú ñ ü ¿ ¡). Alternativa del sistema: `Noto Sans`.
- Familia mono: **JetBrains Mono** (Terminal, lema «LIGERO. POTENTE. FLUIDO.» en tracking ancho).
- El logotipo «BC» no es tipografía: usar siempre el SVG.

| Token | Tamaño / interlínea | Peso | Uso |
|---|---|---|---|
| `type.display` | 32 / 38 | 700 | bienvenida, hora de bloqueo |
| `type.title1` | 22 / 28 | 600 | título de sección |
| `type.title2` | 17 / 22 | 600 | cabecera de panel |
| `type.body` | 14 / 20 | 400 | texto general, filas de lista, barra superior (≈ 15 px en la captura) |
| `type.bodyEmphasis` | 14 / 20 | 600 | elemento activo, título de notificación |
| `type.caption` | 12 / 16 | 400 | estados, nombres de archivo, subtítulos |
| `type.mono` | 13 / 18 | 400 | terminal, código |
| `type.tagline` | 13 / 16 | 500 mono, tracking +0.2 em, mayúsculas | lema de marca |

Reglas: máximo 2 pesos por pantalla; texto sobre superficies translúcidas siempre con contraste ≥ 4.5:1 (ver §11).

## 4. Espaciado

Rejilla base **4 px**. Escala: `2, 4, 8, 12, 16, 20, 24, 32, 48, 64`.

| Token | px | Uso |
|---|---|---|
| `space.1` | 4 | separación interna mínima |
| `space.2` | 8 | icono–texto, entre controles pequeños |
| `space.3` | 12 | relleno de filas y botones |
| `space.4` | 16 | relleno de panel, márgenes de ventana |
| `space.6` | 24 | separación entre grupos |
| `space.8` | 32 | márgenes grandes |

Tamaños de referencia (≈): altura barra superior 40 px; fila de barra lateral 40 px; mosaico del Centro de control 108×124 px; tamaño de icono de Dock 70 px con separación 14 px.

## 5. Radios

| Token | px | Uso |
|---|---|---|
| `radius.xs` | 6 | etiquetas, indicadores |
| `radius.sm` | 10 | filas seleccionadas, campo de búsqueda interno |
| `radius.md` | 14 | botones, mosaicos (≈ 16 en captura), icono de app |
| `radius.lg` | 22 | ventanas, paneles (≈ 22–26) |
| `radius.xl` | 28 | Dock |
| `radius.pill` | 999 | campo de búsqueda, controles de deslizador, botones de ventana |

Iconos de aplicación: «squircle» de radio ≈ 22 % del lado.

## 6. Sombras y elevación

| Nivel | Token | Definición | Uso |
|---|---|---|---|
| 0 | `elev.0` | ninguna | contenido |
| 1 | `elev.1` | `0 1 2 rgba(0,0,0,.25)` | botones, mosaicos |
| 2 | `elev.2` | `0 8 24 rgba(0,0,0,.35)` | paneles, notificaciones, Dock |
| 3 | `elev.3` | `0 24 64 rgba(0,0,0,.45)` + borde 1 px `border.subtle` | ventana activa |

Ventana inactiva: `elev.2` y opacidad de contenido 92 %.

## 7. Transparencia y desenfoque

- Las superficies translúcidas (`surface.*`) usan **desenfoque de fondo gaussiano en GPU** con presupuesto fijo: radio 24 px, 1 muestra de fondo por superficie, resolución reducida 1/2. Solo en: Dock, barra superior, Centro de control, notificaciones, barra lateral de ventana.
- El cuerpo de ventana usa opacidad alta (82–86 %) con blur ligero; nunca más de 3 capas con blur apiladas.
- Si el compositor no ofrece aceleración (p. ej. render por software en una VM) **o** el usuario activa «Reducir transparencia» **o** modo alto contraste: se sustituye por color sólido equivalente (`surface.*` al 100 %). Esto es obligatorio, no opcional.
- Sobre el fondo, añadir velo `#04111F` a 20 % para garantizar contraste del texto de barra superior.

## 8. Iconografía

- Estilo: línea/forma rellena redondeada, trazo ≈ 1.75 px a 24 px, esquinas redondeadas, sin degradados excepto en iconos de aplicación.
- Iconos de sistema (barra, lateral, Centro de control): monocromos que heredan `text.primary`; activos en `accent`.
- Iconos de aplicación: squircle con degradado sutil; originales de BC OS (no se usan marcas ni iconos de terceros). Los de la captura son referencia de composición, no se reutilizan.
- Tamaños: 16, 20, 24, 32 (UI); 48, 64, 128, 256 (apps); en Dock 70 base → magnificación hasta 1.6×.
- Formato: SVG; raster solo generado. Un único tema de iconos `bcos`, con variante clara/oscura.
- Logo: usar `BC-logo-blanco.svg` sobre oscuro, `BC-logo-azul-noche.svg` sobre claro, `BC-logo-adaptativo.svg` en web; icono del sistema `BC-icono-midnight`. Margen de respeto = altura de la «B» / 4. No deformar ni recolorear fuera de las variantes entregadas.

## 9. Componentes

| Componente | Especificación |
|---|---|
| **Botón** | altura 32, relleno horizontal 12, `radius.md`, `surface.control`; primario: fondo `accent`, texto blanco |
| **Botón de icono** | 32×32 (barra de ventana: flechas atrás/adelante en cápsula), `radius.md` |
| **Campo de búsqueda** | altura 36, `radius.pill`, `surface.control`, lupa 16 px a la izquierda, marcador «Buscar» en `text.secondary` |
| **Fila de lista / lateral** | altura 40, relleno 12, `radius.sm`; seleccionada: fondo `accent`, texto blanco; hover: `surface.controlHover` |
| **Mosaico (Centro de control)** | 108×124, `radius.md`, `surface.control`; icono 32 px arriba, título `bodyEmphasis` + estado `caption`; activo: icono en `accent` |
| **Deslizador** | pista 4 px `surface.controlHover`, relleno `accent`, tirador 20 px blanco con `elev.1`; fila con icono + etiqueta + chevrón a la derecha |
| **Interruptor** | 42×24, `radius.pill`; encendido `accent` |
| **Migas de pan** | icono casa + segmentos separados por chevrón `›`, último en `text.primary` |
| **Notificación** | 320×80, `radius.lg`, `surface.panel`, icono 32 + título + cuerpo + botón cerrar ✕ |
| **Menú / popover** | `surface.panel`, `radius.md`, `elev.2`, filas de 32 |
| **Diálogo** | 420 ancho mín., `radius.lg`, botones alineados a la derecha, acción primaria a la derecha |
| **Tooltip** | `surface.panel`, `caption`, retardo 600 ms |
| **Insignia** | 18 px, `danger`, `caption` blanca |
| **Foco de teclado** | anillo 2 px `accent`, desfase 2 px, siempre visible al navegar con teclado |

Estados de interacción: normal → hover (+6 % blanco) → pulsado (−8 % luminosidad) → deshabilitado (38 % opacidad) → foco (anillo).

## 10. Disposición del escritorio

### 10.1 Barra superior (BC Barra superior)

- Altura 40 px, `surface.panel` con blur, ancho completo, borde inferior 1 px `border.subtle`.
- Izquierda: logo «BC» (monograma blanco) + menús de la aplicación activa en español: **Archivos, Editar, Ver, Ir, Ventana, Ayuda** (ejemplo de la referencia).
- Derecha: Wi‑Fi, Sonido, Batería, botón del Centro de control, fecha y hora `vie 13 nov  18:11` (formato es_ES, 24 h).

### 10.2 Dock (BC Dock)

- Flotante, centrado, a 12 px del borde inferior; `radius.xl`, `surface.panel`, `elev.2`.
- Iconos 70 px, separación 14 px; indicador de app abierta: punto 5 px `text.primary` bajo el icono.
- Magnificación: hasta 1.6× con curva gaussiana sobre 3 iconos vecinos; respeta movimiento reducido (sin magnificación, solo resalte).
- Orden de la referencia: Archivos, Configuración, Monitor, Terminal, Tienda, Navegador, Música, Papelera.

### 10.3 Ventana

- `radius.lg`, `elev.3`, borde 1 px `border.subtle`, `surface.window`.
- Barra de título integrada 52 px: semáforos (cerrar/minimizar/maximizar, 22 px, separación 8 px) a la izquierda, navegación, ruta y búsqueda en la misma fila.
- Barra lateral 240 px (`surface.sidebar`), contenido a la derecha.
- Redimensión por todos los bordes (zona 6 px); mínimo 480×320.

### 10.4 Centro de control

- Panel 380 px ancho, `radius.lg`, anclado bajo el botón de la barra superior, margen 16 px.
- Fila superior de 3 mosaicos: **Wi‑Fi (Conectado)**, **Bluetooth (Activado)**, **No molestar (Desactivado)**.
- Debajo: deslizadores **Sonido** y **Brillo**, y fila **Energía** con chevrón.

### 10.5 Notificaciones

- Tarjeta bajo la barra superior, arriba a la derecha, auto‑cierre 5 s (persistente si es crítica). Ejemplo: «Actualizaciones — BC OS está al día».

### 10.6 Fondo y marca

- Fondo predeterminado: ondas índigo/violeta sobre `brand.nightBlue`. Marca de agua opcional abajo‑izquierda: logo + «LIGERO. POTENTE. FLUIDO.» (`type.tagline`).
- Los fondos se generan como recursos originales de BC OS (no se redistribuye la captura de referencia).

## 11. Accesibilidad

- Contraste mínimo: texto normal 4.5:1, texto grande e iconos 3:1 (WCAG 2.2 AA). Medir sobre el peor caso de fondo translúcido y, si no se cumple, subir la opacidad de la superficie.
- **Reducir movimiento**: duraciones a 0–80 ms, sin magnificación de Dock, sin parallax, fundidos en lugar de desplazamientos.
- **Reducir transparencia**: ver §7.
- **Alto contraste**: ver §2.4.
- Escalado de texto 80–200 %; todos los componentes usan `rem`/unidades escalables.
- Navegación completa por teclado, foco visible, orden lógico; atajos documentados en Configuración → Teclado.
- Etiquetas accesibles en español para lectores de pantalla (AT‑SPI).
- Objetivo táctil/clic ≥ 32 px.
- Nunca transmitir información solo con color.

## 12. Animación

Principios: respuesta inmediata (< 100 ms al input), física suave, solo animar `transform` y `opacity` (baratas en GPU); nada de relayout por fotograma.

### 12.1 Curvas

| Token | Curva | Uso |
|---|---|---|
| `ease.standard` | `cubic-bezier(0.2, 0, 0, 1)` | movimiento general |
| `ease.enter` | `cubic-bezier(0, 0, 0, 1)` | aparecer |
| `ease.exit` | `cubic-bezier(0.3, 0, 1, 1)` | desaparecer |
| `ease.spring` | muelle, amortiguamiento 0.82, rigidez 260 | Dock, mosaicos |

### 12.2 Duraciones

| Token | ms |
|---|---|
| `dur.instant` | 80 |
| `dur.fast` | 140 |
| `dur.base` | 220 |
| `dur.slow` | 320 |
| `dur.overview` | 380 |

### 12.3 Catálogo

| Evento | Animación |
|---|---|
| Abrir ventana | escala 0.94→1 + opacidad, `dur.base`, `ease.enter` |
| Cerrar ventana | escala 1→0.96 + opacidad, `dur.fast`, `ease.exit` |
| Minimizar | encoger hacia el icono del Dock, `dur.slow`, `ease.standard` |
| Maximizar | interpolar geometría, `dur.base` |
| Dock | magnificación con `ease.spring`; rebote al lanzar app |
| Mission Control | ventanas a miniaturas, `dur.overview` |
| Cambio de escritorio | desplazamiento horizontal, `dur.slow` |
| Centro de control / menús / popovers | escala 0.96→1 desde el ancla + opacidad, `dur.fast` |
| Notificación | entrada desde arriba, 24 px, `dur.base` |
| Navegación en Archivos | fundido cruzado, `dur.fast` |

Objetivo de fotogramas: 60 FPS (120 FPS si el hardware y compositor lo permiten). Es un objetivo; debe medirse (ver `docs/development/TESTING.md`).

## 13. Aplicaciones

Todas las apps nativas (Qt 6/QML) importan el módulo QML compartido `BC.Design` generado desde `tokens.json`; no se permite estilo propio.

| App | Notas de diseño |
|---|---|
| **Archivos** | barra lateral (Inicio, Escritorio, Documentos, Descargas, Imágenes, Música, Papelera), migas de pan, búsqueda, vista cuadrícula/lista, iconos de carpeta azules |
| **Configuración** | lista lateral de paneles (Pantalla, Apariencia, Red, Sonido, Energía, Teclado, Ratón, Usuarios, Seguridad, Actualizaciones), contenido en tarjetas |
| **Monitor** | gráficos de línea con `accent`, cuadrícula `border.subtle`; paleta categórica validada para daltonismo |
| **Terminal** | fondo `#0B1019` a 90 %, `type.mono`, paleta ANSI propia de 16 colores |
| **Tienda** | cuadrícula de apps, ficha con capturas, botón primario «Instalar» |

## 14. Reglas de implementación

1. Generar `BC.Design` (QML) y constantes Rust/CSS desde `tokens.json`; no copiar valores a mano.
2. Cualquier valor nuevo se añade primero a `tokens.json` y a este documento.
3. Revisión visual obligatoria en claro, oscuro y alto contraste antes de integrar una app.
4. Capturas de regresión visual por pantalla clave (futuro, `docs/development/TESTING.md`).
