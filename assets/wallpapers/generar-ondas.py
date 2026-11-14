#!/usr/bin/env python3
"""Genera el fondo por defecto de BC OS «Ondas»: ondas nocturnas azul‑violeta
con bordes de luz y el logo BC minimal en el centro. Arte propio (procedural).

Uso: python3 generar-ondas.py logo-blanco.svg salida.jpg [ancho alto]
Necesita numpy, Pillow y rsvg-convert.
"""
import subprocess, sys, tempfile, os
import numpy as np
from PIL import Image, ImageFilter

logo_svg, out = sys.argv[1], sys.argv[2]
W, H = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (3840, 2160)

y, x = np.mgrid[0:H, 0:W].astype(np.float32)
u, v = x / W, y / H

# Fondo: noche profunda, más clara arriba a la derecha
bg = np.stack([
    0.035 + 0.05 * (1 - v) * u,
    0.040 + 0.03 * (1 - v),
    0.090 + 0.10 * (1 - v) * (0.4 + 0.6 * u),
], -1)
img = bg.copy()

# Capas de ondas (de atrás hacia delante): base, amplitud, frecuencia, fase, color, luz del borde
layers = [
    (0.30, 0.10, 1.6, 0.0, (0.10, 0.10, 0.30), 0.35),
    (0.42, 0.11, 1.3, 1.7, (0.16, 0.12, 0.42), 0.55),
    (0.55, 0.09, 1.9, 3.1, (0.10, 0.16, 0.48), 0.70),
    (0.67, 0.10, 1.4, 4.6, (0.22, 0.14, 0.55), 0.85),
    (0.80, 0.08, 2.1, 0.9, (0.08, 0.12, 0.36), 1.00),
]
for base, amp, freq, ph, col, glow in layers:
    curve = (base + amp * np.sin(2 * np.pi * freq * u + ph)
             + 0.35 * amp * np.sin(2 * np.pi * 2.7 * freq * u + 1.3 * ph)) * H
    d = y - curve                      # >0 debajo de la cresta
    inside = np.clip(d / 3.0, 0, 1)[..., None]
    depth = np.clip(d / (0.45 * H), 0, 1)[..., None]
    c = np.array(col, np.float32)
    fill = c * (1.0 - 0.65 * depth) + 0.04 * (1 - depth)
    img = img * (1 - inside) + fill * inside
    # borde de luz fino + halo suave sobre la cresta
    edge = np.exp(-(d / (0.0016 * H)) ** 2) * glow
    halo = np.exp(-np.clip(d, 0, None) / (0.035 * H)) * (d > 0) * 0.22 * glow
    light = np.array([0.62, 0.66, 1.0], np.float32)
    img += (edge + halo)[..., None] * light * (0.55 + 0.45 * u[..., None])

# Viñeta y grano suave para evitar bandas
r = np.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2)
img *= (1 - 0.35 * np.clip(r - 0.25, 0, 1))[..., None]
img += np.random.default_rng(7).normal(0, 0.004, img.shape).astype(np.float32)
pic = Image.fromarray((np.clip(img, 0, 1) ** (1 / 1.1) * 255).astype(np.uint8))
pic = pic.filter(ImageFilter.GaussianBlur(0.6))

# Logo BC minimal centrado (≈7 % del ancho, blanco translúcido)
lw = int(W * 0.07)
with tempfile.TemporaryDirectory() as t:
    p = os.path.join(t, "logo.png")
    subprocess.run(["rsvg-convert", "-w", str(lw), "-o", p, logo_svg], check=True)
    logo = Image.open(p).convert("RGBA")
a = np.array(logo, np.float32)
a[..., 3] *= 0.82
logo = Image.fromarray(a.astype(np.uint8))
shadow = Image.new("RGBA", logo.size, (0, 0, 20, 0))
shadow.putalpha(logo.getchannel("A").point(lambda s: int(s * 0.5)))
shadow = shadow.filter(ImageFilter.GaussianBlur(W // 400))
pos = ((W - logo.width) // 2, (H - logo.height) // 2)
pic = pic.convert("RGBA")
pic.alpha_composite(shadow, (pos[0], pos[1] + W // 800))
pic.alpha_composite(logo, pos)
pic.convert("RGB").save(out, quality=92, optimize=True, progressive=True)
print(out, W, H)
