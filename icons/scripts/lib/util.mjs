import fs from 'node:fs';
import path from 'node:path';
import { KINDS, CATEGORIES } from './spec.mjs';

/** Recorre icons/src/<kind>/<categoría>/<archivo>.svg y devuelve entradas normalizadas. */
export function listSources(srcDir) {
  const out = [];
  if (!fs.existsSync(srcDir)) return out;
  for (const kind of fs.readdirSync(srcDir).sort()) {
    const kd = path.join(srcDir, kind);
    if (!fs.statSync(kd).isDirectory()) continue;
    for (const cat of fs.readdirSync(kd).sort()) {
      const cd = path.join(kd, cat);
      if (!fs.statSync(cd).isDirectory()) continue;
      for (const file of fs.readdirSync(cd).sort()) {
        if (!file.endsWith('.svg')) continue;
        out.push({ kind, category: cat, file: path.join(cd, file), ...parseName(file.slice(0, -4), kind) });
      }
    }
  }
  return out;
}

/**
 * Nombre -> {stem, base, fill, hint}.
 *  stem  = nombre de archivo sin @hint (id del símbolo, p.ej. go-home-fill-symbolic)
 *  base  = nombre Freedesktop sin -symbolic ni -fill (clave de meta.json)
 *  hint  = 16 | 32 si es variante simplificada para ese tamaño
 */
export function parseName(name, kind) {
  let stem = name, hint = null;
  const m = /@(16|32)$/.exec(stem);
  if (m) { hint = +m[1]; stem = stem.slice(0, -m[0].length); }
  let base = stem;
  if (kind === 'symbolic' && base.endsWith('-symbolic')) base = base.slice(0, -9);
  const fill = /-fill$/.test(base);
  if (fill) base = base.slice(0, -5);
  return { stem, base, fill, hint };
}

export function rootAttrs(svg) {
  const m = /<svg\b([^>]*)>/.exec(svg);
  const attrs = {};
  if (!m) return attrs;
  for (const a of m[1].matchAll(/([\w:-]+)\s*=\s*"([^"]*)"/g)) attrs[a[1]] = a[2];
  return attrs;
}

export function ctxDir(category) {
  return (CATEGORIES[category]?.context || 'Apps').toLowerCase();
}

export function kindOf(kind) {
  return KINDS[kind];
}

export function readJSON(p, fallback) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return fallback; }
}
