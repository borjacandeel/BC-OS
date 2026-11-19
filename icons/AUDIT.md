# AUDIT — inventario de iconos de BC OS

Fase 0. Origen: `shell/qml/` (Icons.qml, Icon.qml, AppIcon.qml, FileGlyph.qml, TopBar, ControlCenter, FilesWindow, NotificationCard), `docs/design/tokens.json`, `docs/design/reference/escritorio-referencia-01.webp`, `assets/branding/`. Nomenclatura: Freedesktop Icon Naming Specification (tema `BC`). Estado a 2026-11-13.

## 1. Estado actual del shell

- `Icons.qml` (singleton): 27 paths antiguos 24x24 dibujados a mano, trazo variable (1.5 a 2.4 según uso), sin variantes ni tamaños.
- `AppIcon.qml`: 8 iconos de Dock dibujados en QML (Archivos, Configuración, Monitor, Terminal, Tienda, Navegador, Música, Papelera).
- `FileGlyph.qml`: carpeta y 3 tipos de documento (código, texto, imagen) dibujados en QML con degradados; hay un cuarto glifo de PDF/doc (llama roja).
- Problemas: trazos incoherentes (1.5 a 2.4), colores fijos (`#2f86ff`, `#e0332f`, `#1b2230`), sin variante `fill`, sin estados (wifi/batería/volumen son un solo glifo), sin tamaños 16/20, sin tema Freedesktop para apps externas.

## 2. Inventario necesario

Leyenda de lote: A = esta entrega, B = apps (squircle 1024) y Dock, C = lugares/MIME/dispositivos.
Convención: `kind` symbolic = 24x24 `currentColor`; color = 48x48 paleta fija; app = 1024 squircle. Ver SPEC.md.

### 2.1 Mapa de los 27 paths antiguos a nombres nuevos

| Icons.qml | Nombre nuevo | Lote |
|---|---|---|
| wifi | `network-wireless-signal-{none,weak,ok,excellent}-symbolic`, `network-wireless-offline-symbolic` | A |
| volume | `audio-volume-{muted,low,medium,high}-symbolic` | A |
| battery | `battery-level-{0,20,40,60,80,100}[-charging]-symbolic` | A |
| toggles | `control-center-symbolic` | A |
| bluetooth | `bluetooth-active-symbolic`, `bluetooth-disabled-symbolic` | A |
| moon | `weather-clear-night-symbolic` (+ `-fill`), `do-not-disturb-symbolic` | A |
| sun | `weather-clear-symbolic` (+ `-fill`), `display-brightness-symbolic` | A |
| bolt | `power-profile-performance-symbolic` (+ `-fill`) | A |
| chevronRight / chevronLeft | `pan-end-symbolic` / `pan-start-symbolic` | A |
| closeX | `window-close-symbolic` | A |
| refresh | `view-refresh-symbolic` | A |
| home | `go-home-symbolic` (+ `-fill`) | A |
| search | `edit-find-symbolic` | A |
| gear | `preferences-system-symbolic` (ajustes, sliders) | A |
| trash (sidebar) | `edit-delete-symbolic` (acción) y `user-trash-symbolic` (lugar) | A / C |
| desktop | `user-desktop-symbolic` | C |
| document | `folder-documents-symbolic` | C |
| download | `folder-download-symbolic` (de momento `browser-download-symbolic`) | C |
| image | `folder-pictures-symbolic` | C |
| music | `folder-music-symbolic` | C |
| folder | `folder-symbolic` y `folder` (color) | C |
| pulse | `utilities-system-monitor-symbolic` | C (glifo de sidebar) |
| prompt | `utilities-terminal-symbolic` | C |
| bag | `system-software-install-symbolic` | C |
| compass | `web-browser-symbolic` | C |

### 2.2 Lote A (hecho): UI

- Navegación (25 archivos; +`view-app-grid`, `window-new` tras la revisión): flechas (go-up/down/previous/next/top/bottom), chevrons (pan-*), go-home (+fill), open-menu, view-more (horizontal y vertical), window-close/minimize/maximize/restore, view-sidebar (+fill), view-grid, view-list.
- Acciones (44 archivos; +`document-open|save|properties` tras la revisión): list-add/remove, object-select, document-edit/new/send, edit-delete (+fill), edit-copy/paste/cut/undo/redo/find/clear, emblem-shared, browser-download, view-refresh/filter/sort-ascending/sort-descending/fullscreen/restore/reveal/conceal, folder-new, zoom-in/out, starred (+fill), bookmark-new (+fill), preferences-system, system-shutdown/log-out/lock-screen (+fill), media-playback-start/pause, media-skip-forward/backward.
- Estado y barra de menús (34): wifi 0-3 y desconectado, batería 6 niveles x (normal, cargando), volumen 4 estados, micrófono (2), bluetooth (2), brillo, sol, luna, no molestar, notificaciones (3), centro de control, energía/bolt, modo avión.
- Diálogos: información, aviso, error, correcto, pregunta, en 2 versiones: color 48 (`dialog-*`) y symbolic 24 (`dialog-*-symbolic`).

### 2.3 Lote B (HECHO): apps, squircle 1024 (16 iconos + variantes @32 y @16 de cada uno; `bc-launcher` = Lanzador en plata, `bc-mission-control` = Mission Control en noche; `multimedia-photo-viewer` = Fotos)

Un icono `app` por cada una (categoría `apps`, carpeta `src/app/apps/`). Nombre Freedesktop objetivo, etiqueta es_ES y color de fondo (ver SPEC §7.4):

| Nombre | Etiqueta | Dock hoy |
|---|---|---|
| `system-file-manager` | Archivos | sí |
| `preferences-system` | Configuración | sí |
| `utilities-system-monitor` | Monitor de actividad | sí |
| `utilities-terminal` | Terminal | sí (hecho como muestra de referencia) |
| `system-software-install` | Tienda | sí |
| `web-browser` | Navegador | sí |
| `multimedia-audio-player` | Música | sí |
| `user-trash`, `user-trash-full` | Papelera (vacía/llena) | sí |
| `accessories-text-editor` | Editor | no |
| `accessories-calculator` | Calculadora | no |
| `preferences-system-time` | Reloj | no |
| `office-calendar` | Calendario | no |
| `accessories-notes` | Notas | no |
| `multimedia-photo-viewer` | Fotos | no |

Extras de Dock a considerar: indicador de app abierta (punto, lo dibuja el shell), icono de lanzador/apps (`view-app-grid`, symbolic: HECHO).

### 2.4 Lote C (HECHO): lugares, MIME, dispositivos

Entregado: 10 lugares color (`folder`, `user-home`, `user-desktop`, `folder-documents|download|pictures|music|videos|remote|cloud`) + 16 symbolic de sidebar (regular y `-fill` donde hay silueta cerrada), 9 MIME color, 10 dispositivos color + 9 symbolic, hints `folder@16` y `text-x-generic@16`. Tras la revisión se añadieron `x-office-document`, `x-office-spreadsheet`, `text-html`, `user-trash[-fill]-symbolic`, los `-fill` de lugares y los `@16` de las 9 carpetas/lugares. Pendiente: `folder-open`, `folder-publicshare`, `network-workgroup`; la papelera de app la entrega el lote B.

- Lugares (kind color 48 + symbolic `-fill` para sidebar): `folder`, `user-home`, `user-desktop`, `folder-documents`, `folder-download`, `folder-pictures`, `folder-music`, `folder-videos`, `folder-remote` (red), `folder-cloud` (nube), `folder-publicshare`, `folder-open`, `user-trash` / `user-trash-full` (comparte archivo con lote B), `network-workgroup`.
- MIME (color 48, documento con esquina doblada y etiqueta): `text-x-generic`, `text-x-script` (código), `image-x-generic`, `audio-x-generic`, `video-x-generic`, `package-x-generic` (comprimido), `application-pdf`, `application-x-executable`, `application-octet-stream` (desconocido), `x-office-document`, `x-office-spreadsheet`, `text-html`, `inode-directory` (alias de `folder`).
- Dispositivos (color 48 + symbolic): `drive-harddisk` (interno), `drive-removable-media` (externo), `drive-removable-media-usb`, `video-display` (monitor), `input-keyboard`, `input-mouse`, `printer`, `audio-headphones`, `phone`, `computer`.
- Para FileGlyph.qml: `text-x-script`, `text-x-generic`, `image-x-generic`, `application-pdf`.

### 2.5 Ampliación 2026-11-19 (HECHO): emblemas, discos y Bluetooth por tipo

- Emblemas (categoría nueva `emblems`, color 48 con `@16` + symbolic): `emblem-symbolic-link` (alias), `emblem-readonly` y `emblem-locked` (candado).
- MIME: `application-x-generic` (documento con etiqueta de extensión, `@16`), `application-x-cd-image` (imagen de disco).
- Dispositivos y lugares: `media-optical` (color con `@16` + symbolic), `network-server` (lugares, color con `@16` + symbolic; disco de red). `drive-harddisk`, `drive-removable-media-usb` y `folder-remote` ya existían y cumplen.
- Bluetooth por tipo (symbolic): nuevos `input-gaming` (mando) y `audio-speakers` (altavoz); `audio-headphones`, `input-mouse` e `input-keyboard` ya existían.
- `user-home` (color): el símbolo grabado pasa de casa a silueta de persona.
- Instantáneas: app `bc-restore` (violeta, capas de vidrio) y `document-revert-symbolic` (espejo de `view-refresh` con agujas).
- Revisión de trazo symbolic: todos a 1.5 (solo el rayo de la batería usa 1, excepción de §3.2); `view-app-grid-symbolic` tenía puntos r 1.4 y pasa a 1.3 (§3.2: 0.9–1.3).

## 3. Tamaños necesarios (de tokens)

- UI: 16, 20, 24, 32 (tokens `size.icon.ui`) + 48 para vista grande.
- App/archivo: 16, 32, 48, 64, 128, 256 (tokens `size.icon.app`: 48, 64, 128, 256) + 512 y 1024 para apps. Dock = 70 px (retina 140, usa 128 o 256).
- Hinting dedicado a 16 y 32 mediante `nombre@16.svg` / `nombre@32.svg`.

## 4. Requisitos técnicos detectados

- Qt 6.4 (QtSvg/Image): sin filtros SVG, sin máscaras, sin `<use>`, sin `<style>`. Degradados lineales/radiales y opacidad, sí.
- `currentColor` en QtSvg se pinta en negro: el build emite `dist/tinted/on-dark` (`#F5F5F7`) y `dist/tinted/on-light` (`#0B1220`) listos para `Image`, o se tiñe con efecto de color.
- Textos visibles en castellano (es_ES), identificadores en inglés (Freedesktop).
