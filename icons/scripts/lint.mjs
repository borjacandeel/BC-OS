#!/usr/bin/env node
// Lint del pack de iconos. Sale con código 1 si hay errores.
//   node scripts/lint.mjs [--src dir] [--strict]   (--strict: los avisos también fallan)
import fs from 'node:fs';
import path from 'node:path';
import { svgPathBbox } from 'svg-path-bbox';
import { ROOT, KINDS, CATEGORIES, STROKE, NAME_RE, ALLOWED_COLORS } from './lib/spec.mjs';
import { listSources, rootAttrs, readJSON } from './lib/util.mjs';

const argv = process.argv.slice(2);
const i0 = argv.indexOf('--src');
const SRC = path.resolve(i0 >= 0 ? argv[i0 + 1] : path.join(ROOT, 'src'));
const STRICT = argv.includes('--strict');
const META = readJSON(path.join(ROOT, 'meta.json'), {});

let errors = 0, warnings = 0;
const rel = (f) => path.relative(ROOT, f);
const err = (f, m) => { errors++; console.error(`ERROR  ${rel(f)}: ${m}`); };
const warn = (f, m) => { warnings++; console.warn(`aviso  ${rel(f)}: ${m}`); };

const FORBIDDEN_TAGS = ['style', 'filter', 'script', 'image', 'text', 'foreignObject', 'metadata', 'mask', 'pattern', 'use', 'symbol', 'title', 'desc'];
const FORBIDDEN_ATTR = /\b(transform|gradientTransform|patternTransform|style|class|data-[\w-]+|xml:space)\s*=|\b(sodipodi|inkscape|dc|cc|rdf):/;
const num = (v) => parseFloat(v);
const HINT_REQUIRED = [/^battery-level-/, /^audio-volume-(low|medium|high)-/, /^network-wireless-signal-/, /^edit-find-/, /^weather-clear(-fill)?-symbolic/];

function bboxOfElement(tag, a) {
  switch (tag) {
    case 'path': { const [x0, y0, x1, y1] = svgPathBbox(a.d || ''); return [x0, y0, x1, y1]; }
    case 'circle': return [num(a.cx) - num(a.r), num(a.cy) - num(a.r), num(a.cx) + num(a.r), num(a.cy) + num(a.r)];
    case 'ellipse': return [num(a.cx) - num(a.rx), num(a.cy) - num(a.ry), num(a.cx) + num(a.rx), num(a.cy) + num(a.ry)];
    case 'rect': return [num(a.x || 0), num(a.y || 0), num(a.x || 0) + num(a.width), num(a.y || 0) + num(a.height)];
    case 'line': return [Math.min(num(a.x1), num(a.x2)), Math.min(num(a.y1), num(a.y2)), Math.max(num(a.x1), num(a.x2)), Math.max(num(a.y1), num(a.y2))];
    case 'polyline': case 'polygon': {
      const p = (a.points || '').trim().split(/[\s,]+/).map(Number); const xs = p.filter((_, i) => i % 2 === 0), ys = p.filter((_, i) => i % 2 === 1);
      return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
    }
    default: return null;
  }
}

function elements(svg) {
  const out = [];
  for (const m of svg.matchAll(/<([a-zA-Z][\w:-]*)\b([^>]*?)(\/?)>/g)) {
    const attrs = {};
    for (const a of m[2].matchAll(/([\w:-]+)\s*=\s*"([^"]*)"/g)) attrs[a[1]] = a[2];
    out.push({ tag: m[1], attrs });
  }
  return out;
}

const sources = listSources(SRC);
if (!sources.length) { console.error('ERROR  sin iconos en ' + rel(SRC)); process.exit(1); }
const seen = new Map();
const byKey = new Set(sources.map((s) => `${s.kind}|${s.category}|${s.stem}`));

for (const s of sources) {
  const f = s.file;
  const svg = fs.readFileSync(f, 'utf8');
  const K = KINDS[s.kind];

  // --- estructura de carpetas y naming ---
  if (!K) { err(f, `kind desconocido «${s.kind}» (symbolic|color|app)`); continue; }
  if (!CATEGORIES[s.category]) err(f, `categoría desconocida «${s.category}»`);
  if (!NAME_RE.test(s.stem)) err(f, `nombre inválido «${s.stem}»: minúsculas, dígitos y guiones (Freedesktop)`);
  if (s.kind === 'symbolic' && !s.stem.endsWith('-symbolic')) err(f, 'los iconos symbolic deben terminar en -symbolic');
  if (s.kind !== 'symbolic' && s.stem.endsWith('-symbolic')) err(f, '-symbolic solo en kind symbolic');
  if (s.kind !== 'symbolic' && s.fill) err(f, 'variantes -fill solo en kind symbolic');
  if (s.hint && !byKey.has(`${s.kind}|${s.category}|${s.stem}`)) err(f, `variante @${s.hint} sin icono base`);
  if (s.fill && !byKey.has(`${s.kind}|${s.category}|${s.stem.replace('-fill', '')}`)) err(f, 'variante -fill sin variante regular');
  if (s.hint && s.hint !== 16 && s.hint !== 32) err(f, 'solo se admiten @16 y @32');
  const key = `${s.stem}@${s.hint || ''}`;
  if (seen.has(key)) err(f, `nombre duplicado con ${rel(seen.get(key))}`); else seen.set(key, f);
  if (!s.hint && !META[s.base]) err(f, `falta «${s.base}» en icons/meta.json (etiqueta es_ES y tags)`);
  if (META[s.base] && !s.hint && ![META[s.base].category, ...(META[s.base].also || [])].includes(s.category)) err(f, `meta.json dice categoría «${META[s.base].category}»`);

  // --- estructura SVG ---
  if (!/^<svg\b/.test(svg.trim())) { err(f, 'no empieza por <svg>'); continue; }
  if (!svg.includes('xmlns="http://www.w3.org/2000/svg"')) err(f, 'falta xmlns');
  const root = rootAttrs(svg);
  if (root.viewBox !== K.viewBox) err(f, `viewBox «${root.viewBox}», debe ser «${K.viewBox}»`);
  if ('width' in root || 'height' in root) err(f, 'width/height en la raíz (usa solo viewBox)');
  if (FORBIDDEN_ATTR.test(svg)) err(f, 'atributo prohibido (transform/style/class/data-*/metadatos de editor)');
  if (/<!--/.test(svg) && !/lint-allow/.test(svg)) warn(f, 'comentarios en el SVG');
  const els = elements(svg);
  for (const e of els) if (FORBIDDEN_TAGS.includes(e.tag)) err(f, `etiqueta <${e.tag}> no permitida (compatibilidad QtSvg)`);
  if (s.kind === 'symbolic') for (const e of els) if (e.attrs.id) err(f, 'ids no permitidos en symbolic');
  const ids = new Set(els.map((e) => e.attrs.id).filter(Boolean));
  for (const m of svg.matchAll(/url\(#([^)]+)\)/g)) if (!ids.has(m[1])) err(f, `url(#${m[1]}) sin definir`);
  for (const m of svg.matchAll(/\b(width|height)="0"/g)) warn(f, 'dimensión 0 ' + m[0]);

  // --- trazo y colores ---
  const draw = els.filter((e) => ['path', 'circle', 'ellipse', 'rect', 'line', 'polyline', 'polygon'].includes(e.tag));
  if (!draw.length) err(f, 'sin geometría');
  if (s.kind === 'symbolic') {
    if (root.fill !== 'none' || root.stroke !== 'currentColor') err(f, 'raíz debe llevar fill="none" stroke="currentColor"');
    if (num(root['stroke-width']) !== STROKE) err(f, `stroke-width raíz «${root['stroke-width']}», spec ${STROKE}`);
    if (root['stroke-linecap'] !== 'round' || root['stroke-linejoin'] !== 'round') err(f, 'raíz debe llevar stroke-linecap/linejoin="round"');
    for (const e of draw) {
      const a = e.attrs;
      if ('stroke-width' in a && num(a['stroke-width']) !== STROKE && !(a.stroke === 'none') && num(a['stroke-width']) !== 1) err(f, `<${e.tag}> stroke-width «${a['stroke-width']}» (spec ${STROKE}; 1 solo en detalles internos pequeños)`);
      for (const p of ['fill', 'stroke']) if (p in a && !['none', 'currentColor'].includes(a[p])) err(f, `<${e.tag}> ${p}="${a[p]}": en UI solo currentColor/none`);
      if ('opacity' in a || 'fill-opacity' in a) { const o = num(a.opacity ?? a['fill-opacity']); if (!(o >= 0.3 && o <= 1)) err(f, 'opacidad fuera de 0.3–1'); }
    }
    if (/#[0-9a-fA-F]{3,8}\b|rgb\(/.test(svg)) err(f, 'color fijo en icono de UI (usa currentColor)');
  } else {
    const colors = [...svg.matchAll(/(?:fill|stroke|stop-color)="(#[0-9a-fA-F]{3,8})"/g)].map((m) => m[1].toUpperCase());
    for (const c of colors) if (!ALLOWED_COLORS.has(c)) err(f, `color ${c} fuera de la paleta (SPEC §6)`);
    if (svg.includes('currentColor')) err(f, 'currentColor no permitido en iconos de color');
    if (/stroke-width="(?!0)/.test(svg) && !draw.some((e) => e.attrs.stroke)) warn(f, 'stroke-width sin stroke');
  }

  // --- REVIEW P1-4: trazo mínimo de los glifos de app (SPEC §7.3) ---
  if (s.kind === 'app' && !/lint-allow:\s*stroke/.test(svg)) {
    const min = s.hint === 16 ? 80 : 56;
    for (const e of draw) {
      const a = e.attrs;
      if (!('stroke-width' in a) || !a.stroke || a.stroke === 'none') continue;
      if (a.stroke === '#000000' || (a.stroke === '#FFFFFF' && a['stroke-opacity'] === '.14')) continue; // sombras y borde de luz
      if (a.stroke === '#FFFFFF' && num(a['stroke-width']) === 4 && num(a['stroke-opacity']) <= 0.6) continue; // borde de vidrio (SPEC §7.7)
      if (num(a['stroke-width']) < min) err(f, `<${e.tag}> stroke-width ${a['stroke-width']} < ${min} (SPEC §7.3; <!-- lint-allow: stroke motivo --> si es deliberado)`);
    }
  }
  // --- REVIEW P1-5: hints @16 obligatorios en symbolic críticos (SPEC §3.5) ---
  if (s.kind === 'symbolic' && !s.hint && HINT_REQUIRED.some((re) => re.test(s.stem)) && !byKey.has(`${s.kind}|${s.category}|${s.stem}@16`) && !sources.some((o) => o.hint === 16 && o.kind === s.kind && o.stem === s.stem)) warn(f, 'falta la variante @16 (SPEC §3.5)');

  // --- zona viva (geometría; el trazo añade STROKE/2) ---
  const justified = /lint-allow:\s*bounds/.test(svg);
  const [lo, hi] = K.live;
  const slack = s.kind === 'symbolic' ? 0.5 : 0; // tolerancia óptica en UI (arcos/diagonales)
  for (const e of draw) {
    let bb;
    try { bb = bboxOfElement(e.tag, e.attrs); } catch (x) { err(f, `geometría ilegible en <${e.tag}>: ${x.message}`); continue; }
    if (!bb || bb.some((v) => !Number.isFinite(v))) { err(f, `geometría inválida en <${e.tag}>`); continue; }
    if (s.kind === 'app') {
      // En app: nada fuera del lienzo; sombras pueden salir del cuerpo (100–924) pero no del lienzo.
      if (bb[0] < 0 || bb[1] < 0 || bb[2] > K.size || bb[3] > K.size) err(f, `<${e.tag}> sale del lienzo ${K.size}`);
      continue;
    }
    if (bb[0] < lo - slack || bb[1] < lo - slack || bb[2] > hi + slack || bb[3] > hi + slack) {
      if (!justified) err(f, `<${e.tag}> fuera del área viva [${lo},${hi}]: ${bb.map((v) => +v.toFixed(2)).join(', ')} (añade <!-- lint-allow: bounds motivo --> si es deliberado)`);
    }
  }
  if (s.kind === 'app') {
    // El cuerpo debe ser el squircle 824 centrado: se comprueba la bbox del path con degradado de fondo.
    const bodyPath = els.find((e) => e.tag === 'path' && /url\(#bg\)/.test(e.attrs.fill || ''));
    if (!bodyPath) err(f, 'falta el cuerpo con fill="url(#bg)"');
    else {
      const [x0, y0, x1, y1] = svgPathBbox(bodyPath.attrs.d);
      if ([x0, y0].some((v) => Math.abs(v - 100) > 1) || [x1, y1].some((v) => Math.abs(v - 924) > 1)) err(f, `cuerpo ${[x0, y0, x1, y1].map((v) => +v.toFixed(1))} debe ocupar 100,100–924,924`);
    }
  }
}

// REVIEW P1-3/P1-12: como máximo 2 apps del Dock por familia de fondo (SPEC §7.4)
{
  const fam = new Map();
  for (const s of sources.filter((x) => x.kind === 'app' && !x.hint)) {
    const m = fs.readFileSync(s.file, 'utf8').match(/<linearGradient id="bg"[^>]*><stop offset="0" stop-color="(#\w+)"\/><stop offset="1" stop-color="(#\w+)"/);
    if (!m) continue;
    const k = m[1] + m[2]; fam.set(k, [...(fam.get(k) || []), s.base]);
  }
  for (const [k, v] of fam) if (v.length > 2 && !v.every((n) => /^(papel|plata)$/.test(n))) { errors++; console.error(`ERROR  familia de color ${k}: ${v.length} apps (${v.join(', ')}); máximo 2`); }
}
// meta.json sin icono
const bases = new Set(sources.map((s) => s.base));
if (i0 < 0) for (const k of Object.keys(META)) if (!bases.has(k)) { warnings++; console.warn(`aviso  meta.json: «${k}» no tiene SVG`); }

const total = sources.length;
console.log(`lint: ${total} archivos, ${errors} errores, ${warnings} avisos`);
process.exit(errors || (STRICT && warnings) ? 1 : 0);
