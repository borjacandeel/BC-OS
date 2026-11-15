#!/usr/bin/env python3
"""Genera la colección de fondos «Ondas» de BC OS (arte propio, procedural): mismas capas de ondas con borde de
luz que «Ondas», en otras paletas claras y oscuras, más dos minimalistas. Logo BC centrado (blanco en los oscuros,
grafito en los claros).

Uso: python3 generar-fondos.py logo-blanco.svg carpeta_salida [ancho alto] [nombre…]
Necesita numpy, Pillow y rsvg-convert.
"""
import subprocess, sys, tempfile, os
import numpy as np
from PIL import Image, ImageFilter

# nombre: (claro, fondo arriba, fondo abajo, [colores de capa ×5], luz de borde, estilo)
P = {
    "aurora":    (False, (0.02, 0.08, 0.09), (0.01, 0.03, 0.05),
                  [(0.04, 0.22, 0.24), (0.05, 0.32, 0.30), (0.06, 0.26, 0.38), (0.10, 0.40, 0.34), (0.03, 0.16, 0.22)], (0.55, 1.0, 0.85), "ondas"),
    "atardecer": (False, (0.12, 0.05, 0.10), (0.04, 0.02, 0.06),
                  [(0.30, 0.10, 0.20), (0.48, 0.16, 0.24), (0.62, 0.24, 0.20), (0.52, 0.12, 0.30), (0.22, 0.06, 0.16)], (1.0, 0.72, 0.55), "ondas"),
    "rubi":      (False, (0.08, 0.02, 0.04), (0.03, 0.01, 0.02),
                  [(0.24, 0.04, 0.08), (0.38, 0.06, 0.12), (0.50, 0.08, 0.14), (0.32, 0.05, 0.16), (0.16, 0.03, 0.06)], (1.0, 0.55, 0.60), "ondas"),
    "bosque":    (False, (0.04, 0.07, 0.04), (0.01, 0.03, 0.02),
                  [(0.08, 0.18, 0.10), (0.12, 0.28, 0.14), (0.18, 0.34, 0.16), (0.10, 0.24, 0.18), (0.05, 0.12, 0.07)], (0.80, 1.0, 0.65), "ondas"),
    "carbon":    (False, (0.07, 0.07, 0.08), (0.02, 0.02, 0.03),
                  [(0.12, 0.12, 0.13), (0.17, 0.17, 0.18), (0.22, 0.22, 0.23), (0.15, 0.15, 0.16), (0.09, 0.09, 0.10)], (0.85, 0.87, 0.92), "ondas"),
    "amanecer":  (True, (0.99, 0.90, 0.84), (0.96, 0.80, 0.80),
                  [(0.99, 0.80, 0.70), (0.98, 0.70, 0.66), (0.96, 0.62, 0.66), (0.93, 0.70, 0.78), (0.98, 0.84, 0.82)], (1.0, 1.0, 1.0), "ondas"),
    "lavanda":   (True, (0.93, 0.91, 0.99), (0.86, 0.84, 0.97),
                  [(0.82, 0.78, 0.98), (0.74, 0.70, 0.96), (0.68, 0.66, 0.94), (0.78, 0.72, 0.95), (0.88, 0.86, 0.99)], (1.0, 1.0, 1.0), "ondas"),
    "menta":     (True, (0.90, 0.98, 0.95), (0.82, 0.94, 0.92),
                  [(0.74, 0.93, 0.86), (0.64, 0.89, 0.82), (0.58, 0.84, 0.84), (0.68, 0.90, 0.90), (0.84, 0.96, 0.92)], (1.0, 1.0, 1.0), "ondas"),
    "niebla":    (True, (0.95, 0.96, 0.97), (0.88, 0.90, 0.93),
                  [(0.86, 0.88, 0.92), (0.80, 0.83, 0.88), (0.76, 0.79, 0.85), (0.83, 0.85, 0.90), (0.91, 0.92, 0.95)], (1.0, 1.0, 1.0), "minimal"),
    "noche":     (False, (0.05, 0.06, 0.12), (0.01, 0.01, 0.03),
                  [(0.09, 0.10, 0.22)] * 5, (0.55, 0.60, 1.0), "minimal"),
}

def render(name, logo_svg, out, W, H):
    light, top, bot, cols, glowc, style = P[name]
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    u, v = x / W, y / H
    t, b = np.array(top, np.float32), np.array(bot, np.float32)
    img = t * (1 - v[..., None]) + b * v[..., None]
    img += (0.04 if not light else 0.02) * ((1 - v) * u)[..., None]
    lightc = np.array(glowc, np.float32)
    if style == "ondas":
        layers = [(0.30, 0.10, 1.6, 0.0, 0.35), (0.42, 0.11, 1.3, 1.7, 0.55), (0.55, 0.09, 1.9, 3.1, 0.70),
                  (0.67, 0.10, 1.4, 4.6, 0.85), (0.80, 0.08, 2.1, 0.9, 1.00)]
        for (base, amp, freq, ph, glow), col in zip(layers, cols):
            curve = (base + amp * np.sin(2 * np.pi * freq * u + ph) + 0.35 * amp * np.sin(2 * np.pi * 2.7 * freq * u + 1.3 * ph)) * H
            d = y - curve
            inside = np.clip(d / 3.0, 0, 1)[..., None]
            depth = np.clip(d / (0.45 * H), 0, 1)[..., None]
            c = np.array(col, np.float32)
            fill = c * (1.0 - (0.65 if not light else 0.18) * depth) + (0.04 if not light else 0.03) * (1 - depth)
            img = img * (1 - inside) + fill * inside
            edge = np.exp(-(d / (0.0016 * H)) ** 2) * glow
            halo = np.exp(-np.clip(d, 0, None) / (0.035 * H)) * (d > 0) * 0.22 * glow
            k = 0.55 if not light else 0.35
            if light:   # en claro el borde es una línea blanca suave que aclara
                img = img + (edge * 0.8 + halo * 0.6)[..., None] * (1 - img) * k * 2
            else:
                img += (edge + halo)[..., None] * lightc * (k + 0.45 * u[..., None])
    else:
        # Minimal: degradado limpio y dos líneas de luz muy finas
        for base, amp, freq, ph, w in [(0.62, 0.07, 1.1, 0.6, 1.0), (0.70, 0.05, 1.4, 2.4, 0.55)]:
            curve = (base + amp * np.sin(2 * np.pi * freq * u + ph)) * H
            d = y - curve
            edge = np.exp(-(d / (0.0012 * H)) ** 2) * w
            halo = np.exp(-np.abs(d) / (0.05 * H)) * 0.10 * w
            if light: img = img - (edge * 0.45 + halo * 0.5)[..., None] * np.array([0.30, 0.26, 0.18], np.float32)
            else: img += (edge * 0.8 + halo)[..., None] * lightc * 0.6
    r = np.sqrt((u - 0.5) ** 2 + (v - 0.5) ** 2)
    img *= (1 - (0.35 if not light else 0.08) * np.clip(r - 0.25, 0, 1))[..., None]
    img += np.random.default_rng(7).normal(0, 0.004, img.shape).astype(np.float32)
    pic = Image.fromarray((np.clip(img, 0, 1) ** (1 / 1.1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))
    lw = int(W * 0.07)
    with tempfile.TemporaryDirectory() as tmp:
        p = os.path.join(tmp, "logo.png")
        subprocess.run(["rsvg-convert", "-w", str(lw), "-o", p, logo_svg], check=True)
        logo = Image.open(p).convert("RGBA")
    a = np.array(logo, np.float32)
    if light:
        a[..., :3] = np.array([0.20, 0.21, 0.26]) * 255   # logo grafito en los claros
        a[..., 3] *= 0.70
    else:
        a[..., 3] *= 0.82
    logo = Image.fromarray(a.astype(np.uint8))
    shadow = Image.new("RGBA", logo.size, (0, 0, 20, 0) if not light else (255, 255, 255, 0))
    shadow.putalpha(logo.getchannel("A").point(lambda s: int(s * (0.5 if not light else 0.6))))
    shadow = shadow.filter(ImageFilter.GaussianBlur(W // 400))
    pos = ((W - logo.width) // 2, (H - logo.height) // 2)
    pic = pic.convert("RGBA")
    pic.alpha_composite(shadow, (pos[0], pos[1] + W // 800))
    pic.alpha_composite(logo, pos)
    pic.convert("RGB").save(out, quality=90, optimize=True, progressive=True)
    print(out)

if __name__ == "__main__":
    logo_svg, outdir = sys.argv[1], sys.argv[2]
    W, H = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (3840, 2160)
    names = sys.argv[5:] or list(P)
    for n in names: render(n, logo_svg, os.path.join(outdir, n + ".jpg"), W, H)
