#!/usr/bin/env bash
# Genera los PNG del tema Plymouth `bcos` desde los SVG de marca. Reproducible.
# Requiere: rsvg-convert (librsvg2-bin / librsvg) y python3 con PIL.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SVG="$HERE/../../assets/branding/svg"
OUT="$HERE/bcos"
mkdir -p "$OUT"
command -v rsvg-convert >/dev/null || { echo "falta rsvg-convert" >&2; exit 1; }
# Logo blanco y plata (brillo), ancho 360 px (el script lo reescala según pantalla)
rsvg-convert -w 360 "$SVG/BC-logo-blanco.svg" -o "$OUT/logo.png"
rsvg-convert -w 360 "$SVG/BC-logo-plata.svg"  -o "$OUT/logo-plata.png"
python3 - "$OUT" <<'PY'
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
# Halo radial azul muy suave (midnight), alpha decreciente
S = 512
glow = Image.new("RGBA", (S, S))
px = glow.load()
c = (S - 1) / 2
for y in range(S):
    for x in range(S):
        d = (((x - c) ** 2 + (y - c) ** 2) ** 0.5) / c
        a = max(0.0, 1 - d) ** 2
        px[x, y] = (47, 123, 255, int(70 * a))
glow.save(f"{out}/glow.png")
# Barra: pista y relleno (píldora de 4 px), colores de marca
W, H, K = 320, 4, 4
def pill(color, name):
    im = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle([0, 0, W * K - 1, H * K - 1], radius=H * K // 2, fill=color)
    im.resize((W, H), Image.LANCZOS).save(f"{out}/{name}")
pill((255, 255, 255, 38), "bar-track.png")
pill((245, 245, 247, 255), "bar-fill.png")   # como macOS: barra blanca sobre pista gris
# Punto para la entrada de contraseña
d = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
ImageDraw.Draw(d).ellipse([10, 10, 29, 29], fill=(245, 245, 247, 255))
d.resize((10, 10), Image.LANCZOS).save(f"{out}/bullet.png")
PY
echo "Tema generado en $OUT"
