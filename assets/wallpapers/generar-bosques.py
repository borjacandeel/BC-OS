#!/usr/bin/env python3
"""Colección «Bosques» de BC OS: 10 fondos minimalistas de estilo macOS (arte propio y procedural, 4K).
Capas de pinos con perspectiva atmosférica, niebla, lagos con reflejo, luna y aurora; 5 claros y 5 oscuros,
con el logo BC discreto.

Uso: python3 generar-bosques.py logo-blanco.svg carpeta_salida [ancho alto] [nombre…]
Necesita numpy, Pillow y rsvg-convert (reutiliza el lienzo y el logo de generar-formas.py).
"""
import importlib.util, os, sys
import numpy as np
from PIL import Image, ImageFilter

_spec = importlib.util.spec_from_file_location("formas", os.path.join(os.path.dirname(os.path.abspath(__file__)), "generar-formas.py"))
formas = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(formas)
Lienzo, hexc, logo_img, F = formas.Lienzo, formas.hexc, formas.logo_img, formas.F


def mix(a, b, t):
    return hexc(a) * (1 - t) + hexc(b) * t


def cielo(L, arriba, abajo, curva=1.0):
    t = np.clip(L.y, 0, 1) ** curva
    L.img[:] = hexc(arriba) * (1 - t[..., None]) + hexc(abajo) * t[..., None]


def cresta(L, base, amp, semilla, suave=3):
    """Altura del terreno (en alturas) por columna: suma de senos de fase aleatoria."""
    rng = np.random.default_rng(semilla)
    u = L.x[0] / L.a
    y = np.full_like(u, base)
    for k in range(1, suave + 1):
        y += amp / k * np.sin(2 * np.pi * (k * 0.9 + rng.random()) * u + rng.random() * 6.28)
    return y


def capa(L, col, base, amp, semilla, pinos=0, alto=0.08, ancho=0.022, alpha=1.0, densidad=1.0, suave=3):
    """Una capa del paisaje: colina (cresta) y, encima, pinos de silueta escalonada. Todo con antialias."""
    H, W = L.H, L.W
    suelo = cresta(L, base, amp, semilla, suave)
    m = L.borde(suelo[None, :] - L.y)                       # bajo la cresta
    mask = m.copy()
    if pinos:
        rng = np.random.default_rng(semilla * 7 + 3)
        n = int(pinos * densidad)
        xs = np.sort(rng.random(n)) * L.a
        for xc in xs:
            h = alto * (0.55 + 0.6 * rng.random())
            w = ancho * (0.75 + 0.5 * rng.random()) * h / alto
            ci = int(np.clip(xc * H, 0, W - 1))
            yb = suelo[ci] + 0.004
            y0, y1 = int(max(0, (yb - h) * H) - 2), int(min(H, yb * H) + 2)
            x0, x1 = int(max(0, (xc - w) * H) - 2), int(min(W, (xc + w) * H) + 2)
            if y1 <= y0 or x1 <= x0:
                continue
            yy = L.y[y0:y1, x0:x1]; xx = L.x[y0:y1, x0:x1]
            t = np.clip((yy - (yb - h)) / h, 0, 1)            # 0 en la punta, 1 en la base
            # Silueta de abeto: tres pisos (dientes) y tronco fino
            piso = (t * 3) % 1.0
            semi = w * (0.18 + 0.82 * t) * (0.72 + 0.28 * piso)
            d = np.abs(xx - xc) - semi
            d = np.maximum(d, (yb - h) - yy)
            tronco = np.maximum(np.abs(xx - xc) - w * 0.07, np.maximum(yy - yb - 0.01, (yb - 0.02) - yy))
            d = np.minimum(d, tronco)
            mask[y0:y1, x0:x1] = np.maximum(mask[y0:y1, x0:x1], L.borde(d))
    L.mezcla(mask, col, alpha)
    return suelo


def niebla(L, y, grosor, col, k):
    g = np.exp(-((L.y - y) / grosor) ** 2)
    L.mezcla(g, col, k)


def resplandor(L, cx, cy, r, col, k):
    d = np.sqrt((L.x - cx * L.a) ** 2 + (L.y - cy) ** 2)
    L.suma(np.exp(-(d / r) ** 2), hexc(col), k)


def disco(L, cx, cy, r, col):
    d = np.sqrt((L.x - cx * L.a) ** 2 + (L.y - cy) ** 2)
    L.mezcla(L.borde(d - r), hexc(col))


def estrellas(L, n, semilla, k=0.9):
    rng = np.random.default_rng(semilla)
    for _ in range(n):
        x, y = rng.random() * L.a, rng.random() * 0.55
        r = (0.6 + rng.random() * 1.1) * L.px
        x0, y0 = int(x * L.H) - 3, int(y * L.H) - 3
        if x0 < 0 or y0 < 0 or x0 + 7 > L.W:
            continue
        d = np.sqrt((L.x[y0:y0 + 7, x0:x0 + 7] - x) ** 2 + (L.y[y0:y0 + 7, x0:x0 + 7] - y) ** 2)
        g = np.clip(1 - d / r, 0, 1)[..., None] * k * (0.4 + 0.6 * rng.random())
        L.img[y0:y0 + 7, x0:x0 + 7] += g


def capas(L, colores, base0, paso, pinos, semilla, alto0=0.05, crece=1.35, amp=0.025, nieblas=None):
    """Capas de lejos (claras, pequeñas) a cerca (oscuras, grandes); niebla entre ellas."""
    for i, c in enumerate(colores):
        capa(L, hexc(c), base0 + i * paso, amp * (1 + 0.4 * i), semilla + i, pinos=pinos,
             alto=alto0 * crece ** i, ancho=0.016 * crece ** i, densidad=max(0.35, 1 - 0.15 * i))
        if nieblas and i < len(colores) - 1:
            niebla(L, base0 + i * paso + 0.03, 0.05, hexc(nieblas), 0.35)


def reflejo(L, y_agua, tinte, k=0.55):
    """Lago: refleja lo de encima de y_agua, con leve ondulación y tinte."""
    H = L.H
    yw = int(y_agua * H)
    arriba = L.img[:yw].copy()
    alto = H - yw
    src = arriba[::-1][:alto]
    if src.shape[0] < alto:
        src = np.concatenate([src, np.repeat(src[-1:], alto - src.shape[0], 0)])
    filas = np.arange(alto)
    desp = (np.sin(filas / (H * 0.004)) * (1 + filas / alto * 3)).astype(int)
    out = np.empty_like(src)
    for i in range(alto):
        out[i] = np.roll(src[i], desp[i], axis=0)
    t = (filas / max(1, alto))[:, None, None]
    L.img[yw:] = out * (1 - k) + hexc(tinte) * k * (0.6 + 0.4 * t) + out * 0
    L.img[yw:yw + 2] = L.img[yw:yw + 2] * 0.85 + 0.15


# ---- Claros ------------------------------------------------------------------------------------
def niebla_matinal(L):
    cielo(L, "#E9EEF3", "#F7F4EE", 0.8)
    resplandor(L, 0.72, 0.30, 0.22, "#FFF6E3", 0.08)
    capas(L, ["#C9D3DC", "#AEBBC7", "#8E9DAC", "#6D7D8D", "#4D5C6B"], 0.54, 0.085, 30, 11, nieblas="#F2F4F6")


def pinar_alba(L):
    cielo(L, "#F6E1D7", "#F9EEE6", 1.2)
    disco(L, 0.30, 0.36, 0.05, "#FFF1E4")
    resplandor(L, 0.30, 0.36, 0.16, "#FFD9C2", 0.10)
    capas(L, ["#E3C6C2", "#CFA9AB", "#B48D96", "#8F6F80", "#6A5468"], 0.56, 0.08, 26, 21, nieblas="#F8E9E2")


def lago_claro(L):
    cielo(L, "#DCE8F0", "#F3F6F7", 0.9)
    capa(L, hexc("#B8C8D6"), 0.50, 0.07, 31, suave=2)
    capa(L, hexc("#97AFC0"), 0.56, 0.03, 32, pinos=40, alto=0.06, ancho=0.018)
    capa(L, hexc("#6F8A9D"), 0.62, 0.012, 33, pinos=34, alto=0.08, ancho=0.022)
    reflejo(L, 0.64, "#E3ECF1", 0.45)


def nieve(L):
    cielo(L, "#EEF2F6", "#FBFCFD", 1.0)
    capa(L, hexc("#E4E9EF"), 0.60, 0.05, 41)
    capa(L, hexc("#F1F4F7"), 0.70, 0.04, 42)
    capa(L, hexc("#FFFFFF"), 0.80, 0.03, 43)
    rng = np.random.default_rng(44)
    for i, (y, h) in enumerate([(0.70, 0.07), (0.79, 0.10), (0.88, 0.13)]):
        L2 = hexc(["#9AA7B5", "#6E7D8D", "#47535F"][i])
        capa_pinos_sueltos(L, L2, y, h, 5 + i * 3, 45 + i)


def capa_pinos_sueltos(L, col, y, h, n, semilla):
    rng = np.random.default_rng(semilla)
    for _ in range(n):
        xc = (0.08 + rng.random() * 0.84) * L.a
        hh = h * (0.6 + 0.5 * rng.random()); w = hh * 0.28
        y0, y1 = int((y - hh) * L.H) - 2, int(y * L.H) + 2
        x0, x1 = int((xc - w) * L.H) - 2, int((xc + w) * L.H) + 2
        yy = L.y[y0:y1, x0:x1]; xx = L.x[y0:y1, x0:x1]
        t = np.clip((yy - (y - hh)) / hh, 0, 1); piso = (t * 3) % 1.0
        d = np.maximum(np.abs(xx - xc) - w * (0.18 + 0.82 * t) * (0.72 + 0.28 * piso), (y - hh) - yy)
        d = np.maximum(d, yy - y)
        m = L.borde(d)[..., None]
        L.img[y0:y1, x0:x1] = L.img[y0:y1, x0:x1] * (1 - m) + col * m


def salvia(L):
    cielo(L, "#E8EEE6", "#F6F5EE", 1.0)
    resplandor(L, 0.65, 0.25, 0.2, "#FFFBEA", 0.08)
    capas(L, ["#CBD8C6", "#AEC2A9", "#8EA98A", "#6F8C6C", "#506C50"], 0.52, 0.095, 22, 51, amp=0.04, nieblas="#EEF2EA")


# ---- Oscuros -----------------------------------------------------------------------------------
def bosque_noche(L):
    cielo(L, "#0A1020", "#1B2742", 1.0)
    estrellas(L, 380, 61)
    disco(L, 0.74, 0.22, 0.035, "#EEF0F5")
    resplandor(L, 0.74, 0.22, 0.16, "#7F92C2", 0.28)
    capas(L, ["#26324F", "#1D2842", "#151E34", "#0E1526", "#080D19"], 0.54, 0.09, 28, 62, nieblas="#2A3655")


def aurora(L):
    cielo(L, "#061214", "#0E2427", 1.0)
    estrellas(L, 260, 71, 0.7)
    u = L.x / L.a
    for k, (c, y, a) in enumerate([("#38E3A9", 0.24, 0.42), ("#3BB9E0", 0.30, 0.22), ("#7E6BE8", 0.19, 0.18)]):
        yc = y + 0.05 * np.sin(2 * np.pi * (1.1 + 0.3 * k) * u + k)
        g = np.exp(-((L.y - yc) / 0.035) ** 2) * (0.65 + 0.35 * np.sin(2 * np.pi * 1.6 * u + k) ** 2) * np.clip((L.y - yc + 0.09) / 0.09, 0, 1)
        L.suma(g * a, hexc(c))
    capas(L, ["#123033", "#0D2628", "#091D1F", "#061416", "#030B0C"], 0.58, 0.085, 30, 72)


def lago_noche(L):
    cielo(L, "#0B0F1E", "#24223F", 0.9)
    estrellas(L, 300, 81)
    resplandor(L, 0.5, 0.62, 0.35, "#5C4E8C", 0.25)
    capa(L, hexc("#2B2A4A"), 0.50, 0.07, 82, suave=2)
    capa(L, hexc("#1C1C36"), 0.56, 0.03, 83, pinos=40, alto=0.06, ancho=0.018)
    capa(L, hexc("#111227"), 0.62, 0.012, 84, pinos=34, alto=0.08, ancho=0.022)
    reflejo(L, 0.64, "#14152A", 0.5)


def bruma_verde(L):
    cielo(L, "#0E1A16", "#22342C", 1.1)
    resplandor(L, 0.5, 0.35, 0.4, "#46705C", 0.25)
    capas(L, ["#2C4639", "#223A2F", "#192D24", "#11211A", "#0A1511"], 0.50, 0.1, 26, 91, amp=0.035, nieblas="#33503F")


def luna(L):
    cielo(L, "#141018", "#2B1E2A", 1.0)
    estrellas(L, 200, 101, 0.6)
    disco(L, 0.5, 0.42, 0.13, "#F1E6DA")
    resplandor(L, 0.5, 0.42, 0.32, "#B4806C", 0.3)
    capa(L, hexc("#1E1520"), 0.70, 0.03, 102, pinos=26, alto=0.12, ancho=0.03)
    capa(L, hexc("#0E0A10"), 0.80, 0.02, 103, pinos=18, alto=0.18, ancho=0.042)


# nombre: (función, logo)
COLECCION = {
    "bosque-niebla": (niebla_matinal, ("abajo-der", 0.04)),
    "pinar-alba":    (pinar_alba, ("abajo-der", 0.04)),
    "lago-claro":    (lago_claro, ("centro-bajo", 0.045)),
    "nieve":         (nieve, ("arriba-izq", 0.04)),
    "salvia":        (salvia, ("abajo-der", 0.04)),
    "bosque-noche":  (bosque_noche, ("abajo-der", 0.04)),
    "aurora-boreal": (aurora, ("abajo-der", 0.04)),
    "lago-noche":    (lago_noche, ("centro-bajo", 0.045)),
    "bruma-verde":   (bruma_verde, ("abajo-der", 0.04)),
    "luna":          (luna, ("centro-bajo", 0.045)),
}


def render(nombre, svg, out, W, H):
    fn, (pos, tam) = COLECCION[nombre]
    L = Lienzo(W, H)
    fn(L)
    claro = float(L.img.mean()) > 0.5
    rng = np.random.default_rng(1)
    L.img += rng.normal(0, 0.004, L.img.shape).astype(F)
    pic = Image.fromarray((np.clip(L.img, 0, 1) * 255 + 0.5).astype(np.uint8)).convert("RGBA")
    logo = logo_img(svg, int(W * tam), claro)
    m = int(W * 0.04)
    x, y = {"centro-bajo": ((W - logo.width) // 2, int(H * 0.86) - logo.height // 2),
            "abajo-der": (W - m - logo.width, H - m - logo.height),
            "arriba-izq": (m, int(H * 0.09))}[pos]
    pic.alpha_composite(logo, (x, y))
    pic.convert("RGB").save(out, quality=92, optimize=True, progressive=True, subsampling=0)
    print(out, flush=True)


if __name__ == "__main__":
    svg, outdir = sys.argv[1], sys.argv[2]
    W, H = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (3840, 2160)
    for n in sys.argv[5:] or list(COLECCION):
        render(n, svg, os.path.join(outdir, n + ".jpg"), W, H)
