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
# Orbes de color difusos (azul y violeta) que se mueven despacio tras el logo
for name, col in (("orbe-azul.png", (47, 123, 255)), ("orbe-violeta.png", (139, 92, 246)), ("orbe-cian.png", (34, 211, 238))):
    S = 384; o = Image.new("RGBA", (S, S)); q = o.load(); c = (S - 1) / 2
    for y in range(S):
        for x in range(S):
            d = (((x - c) ** 2 + (y - c) ** 2) ** 0.5) / c
            q[x, y] = col + (int(120 * max(0.0, 1 - d) ** 2.2),)
    o.save(f"{out}/{name}")
# Destello que recorre el logo (24 fotogramas): franja diagonal de luz recortada por la silueta del logo
logo = Image.open(f"{out}/logo.png").convert("RGBA")
Wl, Hl = logo.size
alpha = logo.getchannel("A")
for i in range(24):
    band = Image.new("L", (Wl, Hl), 0); bp = band.load()
    pos = -0.35 + 1.7 * i / 23
    for y in range(Hl):
        for x in range(Wl):
            u = x / Wl + 0.35 * (y / Hl) - pos
            bp[x, y] = int(255 * max(0.0, 1 - abs(u) / 0.12) ** 1.5)
    from PIL import ImageChops
    m = ImageChops.multiply(band, alpha)
    fr = Image.new("RGBA", (Wl, Hl), (255, 255, 255, 0)); fr.putalpha(m)
    fr.save(f"{out}/brillo-{i:02d}.png")
# Punto para la entrada de contraseña
d = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
ImageDraw.Draw(d).ellipse([10, 10, 29, 29], fill=(245, 245, 247, 255))
d.resize((10, 10), Image.LANCZOS).save(f"{out}/bullet.png")
PY
echo "Tema generado en $OUT"
