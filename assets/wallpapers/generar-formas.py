#!/usr/bin/env python3
"""Colección «Formas» de BC OS: 20 fondos minimalistas de estilo macOS (arte propio y procedural, 4K):
dunas, esferas, anillos, cristal líquido, seda, pliegues, brumas de color, horizonte, colinas, arcos, facetas,
órbitas, topografía, pétalos, burbujas, cinta, eclipse… claros y oscuros, con el logo BC en distintos sitios.

Uso: python3 generar-formas.py logo-blanco.svg carpeta_salida [ancho alto] [nombre…]
Necesita numpy, Pillow y rsvg-convert.
"""
import os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageFilter

F = np.float32


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)], F)


class Lienzo:
    def __init__(s, W, H):
        s.W, s.H, s.a = W, H, W / H
        y, x = np.mgrid[0:H, 0:W].astype(F)
        s.x, s.y = x / H, y / H            # coordenadas en alturas (x de 0 a a, y de 0 a 1)
        s.px = 1.0 / H                      # un píxel
        s.img = np.zeros((H, W, 3), F)

    def degradado(s, c0, c1, ang=90):
        t = np.radians(ang)
        d = (s.x / s.a) * np.cos(t) + s.y * np.sin(t)
        d = (d - d.min()) / (d.max() - d.min())
        s.img[:] = c0 * (1 - d[..., None]) + c1 * d[..., None]

    def mezcla(s, mask, col, alpha=1.0):
        m = np.clip(mask, 0, 1)[..., None] * alpha
        s.img = s.img * (1 - m) + np.asarray(col, F) * m

    def suma(s, mask, col, k=1.0):
        s.img = s.img + np.clip(mask, 0, None)[..., None] * np.asarray(col, F) * k

    def borde(s, d, w=1.2):
        """Máscara suave (antialias) a partir de una distancia con signo en alturas: dentro si d < 0."""
        return np.clip(0.5 - d / (w * s.px), 0, 1)

    def manchas(s, puntos):
        """Bruma de color tipo «mesh gradient»: [(x, y, radio, color, peso)] normalizado."""
        acc = np.zeros_like(s.img); wsum = np.zeros(s.img.shape[:2], F)
        for x, y, r, c, w in puntos:
            g = w * np.exp(-(((s.x - x * s.a) ** 2 + (s.y - y) ** 2) / (r * r)))
            acc += g[..., None] * hexc(c); wsum += g
        base = s.img.copy()
        k = np.clip(wsum, 0, 1)[..., None]
        s.img = base * (1 - k) + (acc / np.maximum(wsum, 1e-4)[..., None]) * k


def curva(L, base, amp, freq, fase, armonico=0.3):
    u = L.x / L.a
    return base + amp * np.sin(2 * np.pi * freq * u + fase) + armonico * amp * np.sin(2 * np.pi * 2.3 * freq * u + 1.7 * fase)


# ---------------------------------------------------------------------------------------------------------
def dunas(L, oscuro):
    pal = (["#0B1026", "#141B3D", "#1E2A5A", "#2B3B78", "#3A4F96"] if oscuro else
           ["#F7E4CF", "#F0CDAE", "#E7B28F", "#D99774", "#C47C5E"])
    L.degradado(hexc(pal[0]), hexc(pal[1]), 90)
    for i, (b, a, f, p) in enumerate([(0.42, 0.06, 0.7, 0.3), (0.55, 0.07, 0.9, 2.0), (0.68, 0.06, 0.6, 4.1), (0.82, 0.05, 1.1, 1.2)]):
        c = curva(L, b, a, f, p, 0.25)
        d = c - L.y                                   # < 0 por debajo de la cresta
        col = hexc(pal[min(i + 1, 4)])
        sombra = np.clip((L.y - c) / 0.18, 0, 1)
        lado = 0.5 + 0.5 * np.cos(2 * np.pi * f * L.x / L.a + p)   # cara iluminada y cara en sombra
        tono = col * (1.0 - 0.22 * sombra[..., None]) * (0.9 + 0.12 * lado[..., None])
        m = L.borde(d)
        L.img = L.img * (1 - m[..., None]) + tono * m[..., None]
        L.suma(np.exp(-((L.y - c) / (0.002)) ** 2) * (0.10 if oscuro else 0.18), [1, 1, 1])


def esferas(L, oscuro):
    L.degradado(hexc("#120A2A" if oscuro else "#EDE7FB"), hexc("#2A1250" if oscuro else "#D7CCF5"), 70)
    for cx, cy, r, c1, c2 in [(0.30, 0.62, 0.34, "#6E3CFF", "#1B0B4F"), (0.70, 0.36, 0.22, "#FF5FA2", "#5A1240"),
                              (0.83, 0.78, 0.12, "#4FC3FF", "#0B2F66")]:
        dx, dy = L.x - cx * L.a, L.y - cy
        dist = np.sqrt(dx * dx + dy * dy)
        L.mezcla(np.exp(-np.clip(dist - r, 0, None) / 0.05) * 0.35, [0, 0, 0.05] if oscuro else [0.4, 0.3, 0.6])   # sombra suave
        lx, ly = dx + 0.35 * r, dy + 0.40 * r
        luz = np.clip(1 - np.sqrt(lx * lx + ly * ly) / (1.6 * r), 0, 1) ** 1.6
        col = hexc(c2) * (1 - luz[..., None]) + hexc(c1) * luz[..., None]
        L.img = L.img * (1 - L.borde(dist - r)[..., None]) + col * L.borde(dist - r)[..., None]
        L.suma(np.exp(-((dist - r) / 0.004) ** 2) * np.clip(-dy / r, 0, 1) * 0.25, [1, 1, 1])   # borde de luz arriba
        L.suma(np.exp(-(((dx + 0.42 * r) ** 2 + (dy + 0.48 * r) ** 2) / (0.12 * r) ** 2)) * 0.35, [1, 1, 1])


def anillos(L, oscuro):
    L.degradado(hexc("#03161A" if oscuro else "#E6F6F4"), hexc("#062A30" if oscuro else "#C4E9E6"), 120)
    cx, cy = 1.05 * L.a, 1.10
    r = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
    for i in range(9):
        rr = 0.35 + i * 0.11
        w = 0.03 + 0.004 * i
        banda = L.borde(np.abs(r - rr) - w / 2)
        t = i / 8
        col = hexc("#0FB8A6") * (1 - t) + hexc("#2563EB") * t if oscuro else hexc("#5ACFC2") * (1 - t) + hexc("#7AA2F7") * t
        L.mezcla(banda, col, 0.55 - 0.035 * i)
        L.suma(np.exp(-((r - rr + w / 2) / 0.002) ** 2) * 0.25, [1, 1, 1])


def cristal(L, oscuro):
    L.img[:] = hexc("#0E0E1A" if oscuro else "#F4F1FA")
    L.manchas([(0.25, 0.30, 0.35, "#FF6B3D", 1.0), (0.70, 0.25, 0.30, "#FF2E88", 0.9), (0.55, 0.75, 0.35, "#5B5BFF", 1.0),
               (0.15, 0.85, 0.28, "#00C2FF", 0.8), (0.90, 0.80, 0.25, "#9B5BFF", 0.8)])
    cx, cy, r = 0.5 * L.a, 0.5, 0.30
    dist = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
    m = L.borde(dist - r)
    vidrio = L.img * 0.55 + np.array([1, 1, 1], F) * (0.28 if not oscuro else 0.18)
    L.img = L.img * (1 - m[..., None]) + vidrio * m[..., None]
    L.suma(np.exp(-((dist - r) / 0.003) ** 2) * 0.55, [1, 1, 1])
    L.suma(np.exp(-((dist - r + 0.012) / 0.010) ** 2) * (L.y < cy) * 0.18, [1, 1, 1])


def seda(L, oscuro):
    L.degradado(hexc("#1A0F14" if oscuro else "#FBEFEA"), hexc("#2E1620" if oscuro else "#F2D8D2"), 100)
    for i in range(7):
        c = curva(L, 0.30 + 0.07 * i, 0.10 - 0.008 * i, 0.55 + 0.05 * i, 0.6 * i, 0.4)
        d = L.y - c
        t = i / 6
        col = (hexc("#E8A07A") * (1 - t) + hexc("#B4547A") * t) if oscuro else (hexc("#F2B9A0") * (1 - t) + hexc("#D98BA4") * t)
        m = L.borde(np.abs(d - 0.025) - 0.025)
        brillo = np.exp(-((d - 0.012) / 0.010) ** 2)
        L.mezcla(m, col * (0.75 + 0.35 * brillo[..., None]), 0.55)


def pliegues(L, oscuro):
    # Papel plegado: planos diagonales cada vez más oscuros con una sombra suave bajo cada pliegue
    tonos = (["#2A2C33", "#25272E", "#202229", "#1B1D23", "#16181D", "#121318"] if oscuro else
             ["#F4F5F8", "#E9EBF0", "#DDE0E8", "#D1D5DF", "#C5CAD6", "#B9BFCD"])
    L.img[:] = hexc(tonos[0])
    u = L.x / L.a
    for i, off in enumerate([0.18, 0.40, 0.62, 0.84, 1.06]):
        linea = off + 0.10 * np.sin(1.3 * u + i) - 0.42 * u
        d = L.y - linea                                  # > 0 por debajo del pliegue
        luz = np.clip(d / 0.25, 0, 1)
        col = hexc(tonos[i + 1]) * (1.02 - 0.05 * luz[..., None])
        L.mezcla(L.borde(-d), col)
        L.suma(np.exp(-np.clip(d, 0, None) / 0.035) * (d > 0) * (0.10 if not oscuro else 0.12), [-1, -1, -1])
        L.suma(np.exp(-(d / 0.0018) ** 2) * (0.25 if not oscuro else 0.10), [1, 1, 1])


def bruma(L, oscuro):
    L.img[:] = hexc("#F7F3FF")
    L.manchas([(0.15, 0.20, 0.40, "#FFD6E8", 1.0), (0.80, 0.15, 0.40, "#CDE4FF", 1.0), (0.50, 0.60, 0.45, "#E5D9FF", 1.0),
               (0.10, 0.90, 0.40, "#D2F5EC", 0.9), (0.90, 0.85, 0.35, "#FFE7CC", 0.9)])


def nebulosa(L, oscuro):
    L.img[:] = hexc("#05040C")
    L.manchas([(0.20, 0.30, 0.30, "#3B0CA8", 1.0), (0.75, 0.20, 0.28, "#C2185B", 0.9), (0.55, 0.70, 0.32, "#0047FF", 1.0),
               (0.90, 0.75, 0.22, "#7C3AED", 0.8), (0.10, 0.85, 0.25, "#0E7490", 0.7)])
    L.img *= 0.85


def horizonte(L, oscuro):
    L.degradado(hexc("#FFB38A" if not oscuro else "#2B0F3A"), hexc("#FF6F7D" if not oscuro else "#0D0820"), 90)
    cx, cy, r = 0.62 * L.a, 0.58, 0.20
    dist = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
    sol = L.borde(dist - r) * (L.y < 0.66)
    L.mezcla(sol, hexc("#FFF1D6" if not oscuro else "#FF8A5C"), 0.95)
    L.suma(np.exp(-np.clip(dist - r, 0, None) / 0.10) * 0.10, hexc("#FFE0B0"))
    mar = L.borde(0.66 - L.y)
    L.mezcla(mar, hexc("#7A4E8C" if not oscuro else "#120A2A"), 1.0)
    for i in range(6):   # reflejos horizontales del sol en el agua
        yy = 0.69 + i * 0.035
        w = 0.17 - i * 0.025
        L.mezcla(L.borde(np.abs(L.y - yy) - 0.004) * L.borde(np.abs(L.x - cx) - w), hexc("#FFD9B0"), 0.35 - 0.04 * i)


def colinas(L, oscuro):
    pal = ["#DDEFF6", "#B6DCE6", "#8CC5C9", "#5FA7A8", "#3C8586", "#24605F"]
    L.degradado(hexc("#F4FAFC"), hexc(pal[0]), 90)
    for i, (b, a, f, p) in enumerate([(0.45, 0.05, 0.8, 0.5), (0.55, 0.06, 0.6, 2.2), (0.66, 0.05, 1.0, 3.4),
                                      (0.76, 0.05, 0.7, 5.0), (0.87, 0.04, 0.9, 1.1)]):
        c = curva(L, b, a, f, p, 0.2)
        niebla = np.clip((L.y - c) / 0.25, 0, 1)
        col = hexc(pal[i + 1]) * (1 - 0.25 * niebla[..., None]) + 0.06
        L.mezcla(L.borde(c - L.y), col)


def arcos(L, oscuro):
    L.img[:] = hexc("#0B0B10")
    cols = ["#C2554D", "#C98A4B", "#C9B25A", "#5E9E77", "#4F7FC4", "#8E6BC0"]   # tonos apagados, no arcoíris chillón
    cx, cy = 0.5 * L.a, 1.25
    r = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
    for i, c in enumerate(cols):
        rr = 0.62 + i * 0.075
        m = L.borde(np.abs(r - rr) - 0.03)
        sombra = np.clip((r - rr + 0.03) / 0.06, 0, 1)            # cada banda con volumen: clara arriba, más oscura abajo
        col = hexc(c) * (0.85 - 0.30 * sombra[..., None])
        L.mezcla(m, col, 0.85)
        L.suma(np.exp(-((r - rr + 0.03) / 0.003) ** 2) * 0.35 * L.borde(np.abs(r - rr) - 0.05), [1, 1, 1])
    L.mezcla(L.borde(r - 0.58), hexc("#0B0B10"))


def cuarzo(L, oscuro):
    rng = np.random.default_rng(11)
    pts = rng.random((26, 2)) * np.array([L.a, 1.0])
    d1 = np.full(L.x.shape, 9, F); d2 = np.full(L.x.shape, 9, F); idx = np.zeros(L.x.shape, np.int32)
    for i, (px, py) in enumerate(pts):
        d = np.sqrt((L.x - px) ** 2 + (L.y - py) ** 2)
        nuevo = d < d1
        d2 = np.where(nuevo, d1, np.minimum(d2, d)); idx = np.where(nuevo, i, idx); d1 = np.minimum(d1, d)
    base0, base1 = (hexc("#0D1B2A"), hexc("#1B3A5C")) if oscuro else (hexc("#E8EEF8"), hexc("#C9D6EE"))
    t = (pts[idx][..., 0] / L.a * 0.6 + pts[idx][..., 1] * 0.4)
    L.img = base0 * (1 - t[..., None]) + base1 * t[..., None]
    L.img += (rng.random(26)[idx] * 0.06 - 0.03)[..., None]
    L.suma(np.exp(-((d2 - d1) / 0.0025) ** 2) * (0.22 if oscuro else 0.35), [1, 1, 1])


def orbita(L, oscuro):
    L.degradado(hexc("#05070F"), hexc("#0E1630"), 60)
    cx, cy = 0.5 * L.a, 0.55
    for i in range(7):
        rx, ry, ang = 0.25 + i * 0.09, 0.10 + i * 0.045, np.radians(-14)
        xr = (L.x - cx) * np.cos(ang) - (L.y - cy) * np.sin(ang)
        yr = (L.x - cx) * np.sin(ang) + (L.y - cy) * np.cos(ang)
        e = np.sqrt((xr / rx) ** 2 + (yr / ry) ** 2) - 1
        L.suma(np.exp(-(e * ry / 0.0016) ** 2) * (0.35 - 0.03 * i), hexc("#8FB4FF"))
        t = 1.3 + i * 0.9                              # un punto brillante en cada órbita
        px, py = rx * np.cos(t), ry * np.sin(t)
        X, Y = cx + px * np.cos(-ang) - py * np.sin(-ang), cy + px * np.sin(-ang) + py * np.cos(-ang)
        dd = np.sqrt((L.x - X) ** 2 + (L.y - Y) ** 2)
        L.suma(np.exp(-(dd / 0.006) ** 2) * 1.2 + np.exp(-dd / 0.03) * 0.15, hexc("#CFE0FF"))


def topografia(L, oscuro):
    rng = np.random.default_rng(5)
    f = np.zeros(L.x.shape, F)                      # campo suave en coma flotante (sin escalones de 8 bits)
    for _ in range(9):
        cx, cy, s, amp = rng.random() * L.a, rng.random(), 0.18 + rng.random() * 0.35, rng.random() * 2 - 1
        f += amp * np.exp(-(((L.x - cx) ** 2 + (L.y - cy) ** 2) / (s * s)))
    f = (f - f.min()) / (f.max() - f.min())
    gy, gx = np.gradient(f)
    g = np.sqrt(gx * gx + gy * gy) * L.H + 1e-4
    k = 14
    fr = np.abs(((f * k) % 1.0) - 0.5) * 2               # 1 en la línea de nivel
    dist = (1 - fr) / (k * g) * L.H                     # distancia aproximada en píxeles
    linea = np.clip(1.4 - dist, 0, 1)
    if oscuro:
        L.degradado(hexc("#0A1210"), hexc("#13231F"), 90); L.suma(linea * 0.30, hexc("#7FE0C0"))
    else:
        L.degradado(hexc("#F6F4EE"), hexc("#EAE6DA"), 90); L.suma(linea * 0.22, [-0.55, -0.50, -0.40])


def petalos(L, oscuro):
    L.img[:] = hexc("#0A0612" if oscuro else "#FBF7FF")
    cx, cy = 0.5 * L.a, 0.5
    cols = ["#FF375F", "#FF9F0A", "#FFD60A", "#30D158", "#64D2FF", "#0A84FF", "#5E5CE6", "#BF5AF2"]
    for i, c in enumerate(cols):
        ang = 2 * np.pi * i / len(cols)
        px, py = cx + 0.17 * np.cos(ang), cy + 0.17 * np.sin(ang)
        dx, dy = L.x - px, L.y - py
        xr = dx * np.cos(-ang) - dy * np.sin(-ang); yr = dx * np.sin(-ang) + dy * np.cos(-ang)
        e = np.sqrt((xr / 0.20) ** 2 + (yr / 0.085) ** 2) - 1
        if oscuro: L.suma(L.borde(e * 0.085) * (1 - 0.5 * np.clip(-e, 0, 1)), hexc(c), 0.30)   # pétalos de luz que se suman
        else: L.mezcla(L.borde(e * 0.085), hexc(c), 0.35)


def burbujas(L, oscuro):
    L.degradado(hexc("#081A2E" if oscuro else "#E4F1FF"), hexc("#10304F" if oscuro else "#C8E0FA"), 110)
    rng = np.random.default_rng(3)
    for _ in range(22):
        cx, cy, r = rng.random() * L.a, rng.random(), 0.03 + rng.random() ** 2 * 0.16
        dist = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
        L.mezcla(L.borde(dist - r), [1, 1, 1], 0.05 + 0.05 * rng.random())
        L.suma(np.exp(-((dist - r) / 0.0025) ** 2) * 0.25, [1, 1, 1])


def cinta(L, oscuro):
    L.img[:] = hexc("#F5F5F7" if not oscuro else "#0E0E12")
    for i in range(16):
        t = i / 15
        c = curva(L, 0.30 + 0.30 * t, 0.16, 0.45, 1.0 + 0.25 * t, 0.15)
        col = hexc("#0A84FF") * (1 - t) + hexc("#BF5AF2") * t
        L.mezcla(L.borde(np.abs(L.y - c) - 0.010), col, 0.55 if not oscuro else 0.6)


def eclipse(L, oscuro):
    L.img[:] = hexc("#030305")
    cx, cy, r = 0.5 * L.a, 0.5, 0.24
    dist = np.sqrt((L.x - cx) ** 2 + (L.y - cy) ** 2)
    corona = np.exp(-np.clip(dist - r, 0, None) / 0.05) * 0.9 + np.exp(-np.clip(dist - r, 0, None) / 0.18) * 0.25
    ang = np.arctan2(L.y - cy, L.x - cx)
    L.suma(corona * (0.75 + 0.25 * np.cos(ang + 0.8))[...], hexc("#FF9A5A"))
    L.suma(np.exp(-((dist - r) / 0.0035) ** 2) * 1.2, hexc("#FFE6C7"))
    L.mezcla(L.borde(dist - r + 0.002), hexc("#030305"))


# nombre: (función, oscuro, logo)   logo = (posición, tamaño relativo al ancho)
COLECCION = {
    "dunas":       (dunas, False, ("centro", 0.065)),
    "dunas-noche": (dunas, True, ("centro", 0.065)),
    "esferas":     (esferas, True, ("abajo-izq", 0.045)),
    "esferas-luz": (esferas, False, ("abajo-izq", 0.045)),
    "anillos":     (anillos, True, ("centro", 0.06)),
    "cristal":     (cristal, True, ("centro", 0.075)),
    "seda":        (seda, False, ("arriba-der", 0.045)),
    "pliegues":    (pliegues, False, ("arriba-izq", 0.045)),
    "bruma":       (bruma, False, ("centro", 0.065)),
    "nebulosa":    (nebulosa, True, ("centro", 0.065)),
    "horizonte":   (horizonte, False, ("abajo-der", 0.045)),
    "colinas":     (colinas, False, ("arriba-izq", 0.045)),
    "arcos":       (arcos, True, ("centro-bajo", 0.06)),
    "cuarzo":      (cuarzo, True, ("centro", 0.06)),
    "orbita":      (orbita, True, ("centro", 0.055)),
    "topografia":  (topografia, True, ("abajo-der", 0.045)),
    "petalos":     (petalos, True, ("abajo-der", 0.045)),
    "burbujas":    (burbujas, True, ("centro", 0.06)),
    "cinta":       (cinta, False, ("abajo-izq", 0.045)),
    "eclipse":     (eclipse, True, ("centro", 0.055)),
}


def logo_img(svg, w, claro):
    with tempfile.TemporaryDirectory() as tmp:
        p = os.path.join(tmp, "logo.png")
        subprocess.run(["rsvg-convert", "-w", str(w), "-o", p, svg], check=True)
        logo = Image.open(p).convert("RGBA")
    a = np.array(logo, F)
    if claro:
        a[..., :3] = np.array([0.20, 0.21, 0.26]) * 255
        a[..., 3] *= 0.72
    else:
        a[..., 3] *= 0.85
    return Image.fromarray(a.astype(np.uint8))


def render(nombre, svg, out, W, H):
    fn, oscuro, (pos, tam) = COLECCION[nombre]
    L = Lienzo(W, H)
    fn(L, oscuro)
    claro = float(L.img.mean()) > 0.5
    rng = np.random.default_rng(1)
    L.img += rng.normal(0, 0.0045, L.img.shape).astype(F)      # tramado: sin bandas en los degradados
    pic = Image.fromarray((np.clip(L.img, 0, 1) * 255 + 0.5).astype(np.uint8)).convert("RGBA")
    logo = logo_img(svg, int(W * tam), claro)
    m = int(W * 0.045)
    x, y = {"centro": ((W - logo.width) // 2, (H - logo.height) // 2),
            "centro-bajo": ((W - logo.width) // 2, int(H * 0.80) - logo.height // 2),
            "abajo-izq": (m, H - m - logo.height), "abajo-der": (W - m - logo.width, H - m - logo.height),
            "arriba-izq": (m, int(H * 0.09)), "arriba-der": (W - m - logo.width, int(H * 0.09))}[pos]
    sombra = Image.new("RGBA", logo.size, (0, 0, 20, 0) if not claro else (255, 255, 255, 0))
    sombra.putalpha(logo.getchannel("A").point(lambda s: int(s * 0.45)))
    pic.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(max(1, W // 400))), (x, y + max(1, W // 900)))
    pic.alpha_composite(logo, (x, y))
    pic.convert("RGB").save(out, quality=92, optimize=True, progressive=True, subsampling=0)
    print(out, flush=True)


if __name__ == "__main__":
    svg, outdir = sys.argv[1], sys.argv[2]
    W, H = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (3840, 2160)
    for n in sys.argv[5:] or list(COLECCION):
        render(n, svg, os.path.join(outdir, n + ".jpg"), W, H)
