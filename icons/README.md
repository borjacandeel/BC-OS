# Iconos de BC OS

Pack de iconos (estilo macOS minimal, originales) para BC OS. Fuente de verdad: [SPEC.md](SPEC.md). Inventario y reparto por lotes: [AUDIT.md](AUDIT.md).

## Estructura

```
icons/
  src/<kind>/<categoría>/*.svg   fuentes (symbolic | color | app)
  meta.json                      etiqueta es_ES y tags por icono
  manifest.json                  generado
  dist/                          generado (svg, png, tinted, sprite, theme/BC, icns)
  preview/index.html             catálogo (abrir en el navegador tras build)
  scripts/build.mjs lint.mjs     herramientas
  scripts/lib/geom.mjs           squircle() y polígonos redondeados para autoría
  templates/app-template.svg     plantilla de icono de app
```

## Uso

```sh
cd icons
npm install          # svgo, resvg, svg-path-bbox
npm run lint         # debe acabar con 0 errores y 0 avisos
npm run build        # genera dist/, manifest.json y preview/data.js
npm run check        # lint + build
xdg-open preview/index.html
```

El catálogo ofrece buscador, tema claro/oscuro, slider de tamaño (16 a 128), rejilla con keylines, vista "claro sobre oscuro", Dock simulado (ampliación x1.6) y una barra de menús con iconos de estado.

Instalar el tema: `cp -r dist/theme/BC /usr/share/icons/` y `gtk-update-icon-cache` si procede.

## Uso en el shell Qt/QML

- UI (symbolic): `dist/tinted/on-dark/<nombre>-symbolic.svg` o `on-light`, con `sourceSize` al tamaño real (16, 20, 24, 32).
- Color/app: `dist/svg/<nombre>.svg` o PNG de `dist/png/<px>/`.
- `currentColor` en QtSvg sale negro: por eso existen los SVG teñidos.

## Contribuir un icono

1. Lee SPEC.md (§3 UI, §4 color, §7 app). Una sola metáfora, mínimo de nodos.
2. Crea el SVG en `src/<kind>/<categoría>/<nombre>.svg` con nombre Freedesktop (`-symbolic` si es UI; `-fill-symbolic` para la variante rellena).
3. Añade su entrada a `meta.json` (clave = nombre base, `es`, `tags`, `category`).
4. `npm run check`. Revisa en la vista previa a 16 px y en claro/oscuro.
5. Commit en castellano a `main`.

Para apps: copia `templates/app-template.svg`, cambia colores del degradado (SPEC §7.4) y el glifo. El cuerpo se genera con `node scripts/lib/geom.mjs squircle 824 185 0.6 100 100`.

## Estado

Lote A (UI): navegación, acciones, estado/barra de menús y diálogos. Muestra de app: `utilities-terminal`. Pendiente: lote B (apps y Dock) y lote C (lugares, MIME, dispositivos). Detalle en AUDIT.md.
