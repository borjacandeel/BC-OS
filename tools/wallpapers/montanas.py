#!/usr/bin/env python3
"""Genera «Montañas» (fondo propio de BC OS para el entorno Dotfiles): cielo con degradado, sol bajo y cordilleras en capas.
Uso: montanas.py salida.jpg [ancho alto]"""
import sys
import numpy as np
from PIL import Image, ImageFilter

out = sys.argv[1] if len(sys.argv) > 1 else "montanas.jpg"
W = int(sys.argv[2]) if len(sys.argv) > 3 else 1920
H = int(sys.argv[3]) if len(sys.argv) > 3 else 1080
rng = np.random.default_rng(2026)

def lerp(a, b, t): return a + (b - a) * t

# Cielo: azul profundo arriba -> turquesa -> crema en el horizonte -> rosa tenue
stops = [(0.00, (26, 52, 78)), (0.28, (44, 100, 140)), (0.50, (106, 164, 184)), (0.64, (212, 214, 196)),
         (0.70, (236, 222, 196)), (0.74, (226, 170, 160))]
y = np.linspace(0, 1, H)
sky = np.zeros((H, 3), dtype=np.float32)
for i in range(len(stops) - 1):
    a, ca = stops[i]; b, cb = stops[i + 1]
    m = (y >= a) & (y <= b)
    t = ((y[m] - a) / (b - a))[:, None]
    sky[m] = lerp(np.array(ca), np.array(cb), t)
sky[y > stops[-1][0]] = stops[-1][1]
img = np.repeat(sky[:, None, :], W, axis=1)

# Sol bajo con resplandor
xx, yy = np.meshgrid(np.arange(W), np.arange(H))
cx, cy = W * 0.53, H * 0.69
d = np.sqrt(((xx - cx) / (W * 0.22)) ** 2 + ((yy - cy) / (H * 0.16)) ** 2)
glow = np.clip(1 - d, 0, 1) ** 2.2
img = img * (1 - glow[..., None] * 0.75) + np.array([255, 236, 190]) * glow[..., None] * 0.75

def ridge(base, amp, rough, seed):
    r = np.random.default_rng(seed)
    n = 512
    pts = np.zeros(n)
    step = n // 2; scale = amp
    pts[0] = r.normal(0, scale); pts[-1] = r.normal(0, scale)
    while step >= 1:
        for i in range(step, n, step * 2):
            lo, hi = i - step, min(i + step, n - 1)
            pts[i] = (pts[lo] + pts[hi]) / 2 + r.normal(0, scale)
        scale *= rough; step //= 2
    xs = np.linspace(0, n - 1, W)
    prof = np.interp(xs, np.arange(n), pts)
    return base + prof

layers = [  # (altura base relativa, amplitud, rugosidad, color lejano->cercano)
    (0.72, 38, 0.55, (132, 170, 186)), (0.76, 52, 0.56, (86, 132, 156)), (0.82, 66, 0.57, (48, 92, 120)),
    (0.88, 80, 0.58, (22, 52, 78)), (0.95, 70, 0.60, (6, 14, 30))]
for k, (b, amp, rough, col) in enumerate(layers):
    top = ridge(b * H, amp, rough, 10 + k)
    mask = yy >= top[None, :]
    # bruma: las cordilleras lejanas se funden con el horizonte
    haze = np.clip((yy - top[None, :]) / (H * 0.14), 0, 1)
    c = np.array(col, dtype=np.float32)
    layer = c[None, None, :] * (0.78 + 0.22 * haze[..., None])
    img = np.where(mask[..., None], layer, img)

img += rng.normal(0, 1.1, img.shape)   # grano mínimo contra bandas
im = Image.fromarray(np.clip(img, 0, 255).astype("uint8")).filter(ImageFilter.GaussianBlur(0.6))
im.save(out, quality=90)
print("OK", out, im.size)
