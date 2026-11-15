#!/usr/bin/env python3
"""Sonidos originales de BC OS (síntesis propia, dominio público / mismo licenciamiento que BC OS).
Uso: python3 generar.py <carpeta_salida>"""
import sys, wave, numpy as np
out = sys.argv[1] if len(sys.argv) > 1 else "."
SR = 44100
def env(n, a=0.004, d=0.25):
    t = np.arange(n) / SR
    return np.minimum(1, t / a) * np.exp(-t / d)
def tone(f, dur, d=0.25, harm=(1, .35, .12), detune=0.0):
    n = int(SR * dur); t = np.arange(n) / SR
    s = sum(h * np.sin(2 * np.pi * f * (k + 1) * t * (1 + detune * k)) for k, h in enumerate(harm))
    return s * env(n, d=d)
def save(name, s, vol=0.5):
    s = s / (np.max(np.abs(s)) + 1e-9) * vol
    pcm = (s * 32767).astype(np.int16)
    with wave.open(f"{out}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
def cat(*parts, gap=0.0):
    g = np.zeros(int(SR * gap)); r = []
    for p in parts: r += [p, g]
    return np.concatenate(r)
# Aviso: dos notas de vidrio ascendentes
save("notify", cat(tone(1318.5, 0.18, 0.09, (1, .2, .05)), tone(1760, 0.45, 0.18, (1, .25, .06)), gap=0.0), 0.42)
# Papelera: barrido de ruido filtrado (papel arrugado) corto
n = int(SR * 0.42); noise = np.random.default_rng(3).normal(0, 1, n)
k = np.ones(18) / 18; crumple = np.convolve(noise, k, "same") * env(n, 0.01, 0.12) * (1 + 0.6 * np.sin(np.arange(n) / SR * 2 * np.pi * 23))
save("trash", crumple, 0.35)
# Bloqueo: clic grave seco
save("lock", tone(196, 0.12, 0.03, (1, .5, .2)), 0.5)
# Volumen: «pop» breve
save("volume", tone(880, 0.07, 0.025, (1, .1)), 0.35)
# Captura: obturador (dos clics)
save("screenshot", cat(tone(2400, 0.03, 0.008, (1,)), tone(1800, 0.05, 0.012, (1,)), gap=0.06), 0.4)
# Error: nota grave doble
save("error", cat(tone(330, 0.12, 0.06), tone(294, 0.2, 0.1), gap=0.02), 0.4)
print("sonidos en", out)
