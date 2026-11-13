#!/usr/bin/env node
// Build del pack de iconos de BC OS.
//   node scripts/build.mjs [--src dir] [--out dir] [--no-png] [--no-preview]
// Entradas : icons/src/<kind>/<categoría>/*.svg + icons/meta.json
// Salidas  : dist/svg, dist/png/<px>, dist/tinted, dist/sprite.svg, dist/theme/BC (Freedesktop),
//            dist/icns (apps), icons/manifest.json, icons/preview/data.js
import fs from 'node:fs';
import path from 'node:path';
import { optimize } from 'svgo';
import { Resvg } from '@resvg/resvg-js';
import { ROOT, KINDS, CATEGORIES, THEME_NAME, STROKE } from './lib/spec.mjs';
import { listSources, rootAttrs, ctxDir, readJSON } from './lib/util.mjs';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf('--' + n); return i >= 0 ? argv[i + 1] : d; };
const SRC = path.resolve(opt('src', path.join(ROOT, 'src')));
const OUT = path.resolve(opt('out', path.join(ROOT, 'dist')));
const NO_PNG = argv.includes('--no-png');
const NO_PREVIEW = argv.includes('--no-preview');
const MANIFEST = path.resolve(opt('manifest', path.join(ROOT, 'manifest.json')));
const META = readJSON(path.join(ROOT, 'meta.json'), {});
const VERSION = readJSON(path.join(ROOT, 'package.json'), {}).version || '0.0.0';

const w = (p, data) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, data); };
const warn = (m) => console.warn('aviso: ' + m);

// ---------- 1. SVGO ----------
function svgo(str, kind) {
  const res = optimize(str, {
    multipass: true,
    plugins: [
      { name: 'preset-default', params: { overrides: { removeViewBox: false, convertShapeToPath: false, cleanupIds: kind !== 'symbolic' } } },
      'removeDimensions',
    ],
  });
  return res.data;
}

const sources = listSources(SRC);
if (!sources.length) { console.error('sin iconos en ' + SRC); process.exit(1); }
fs.rmSync(OUT, { recursive: true, force: true });

const items = []; // todos los archivos (incluye variantes @hint)
for (const s of sources) {
  const raw = fs.readFileSync(s.file, 'utf8');
  const opt1 = svgo(raw, s.kind);
  if (s.kind === 'symbolic' && !opt1.includes(`stroke-width="${STROKE}"`)) throw new Error(`${s.file}: SVGO perdió stroke-width`);
  if (s.kind === 'symbolic' && !opt1.includes('currentColor')) throw new Error(`${s.file}: SVGO perdió currentColor`);
  items.push({ ...s, svg: opt1 });
  if (!s.hint) w(path.join(OUT, 'svg', s.stem + '.svg'), opt1);
}
const main = items.filter((i) => !i.hint);

// ---------- 2. PNG (resvg) ----------
const tint = (svg, c) => svg.replaceAll('currentColor', c);
function png(svg, size) {
  return new Resvg(svg, { fitTo: { mode: 'width', value: size }, shapeRendering: 2, textRendering: 2 }).render().asPng();
}
const pngCache = new Map();
function pngFor(it, size) {
  const hintItem = items.find((o) => o.hint === size && o.stem === it.stem && o.kind === it.kind && o.category === it.category);
  const svg = tint((hintItem || it).svg, '#000000');
  const key = it.stem + '@' + size;
  if (!pngCache.has(key)) pngCache.set(key, png(svg, size));
  return pngCache.get(key);
}
if (!NO_PNG) {
  for (const it of main) for (const px of KINDS[it.kind].sizes) w(path.join(OUT, 'png', String(px), it.stem + '.png'), pngFor(it, px));
}

// ---------- 3. SVG teñidos para Qt (currentColor -> hex) ----------
for (const it of main.filter((i) => i.kind === 'symbolic')) {
  w(path.join(OUT, 'tinted', 'on-dark', it.stem + '.svg'), tint(it.svg, '#F5F5F7'));
  w(path.join(OUT, 'tinted', 'on-light', it.stem + '.svg'), tint(it.svg, '#0B1220'));
}

// ---------- 4. Sprite ----------
function prefixIds(stem, str) {
  let body = str;
  const ids = [...str.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1]);
  for (const id of ids) {
    const nid = stem + '--' + id;
    body = body.replaceAll(`id="${id}"`, `id="${nid}"`).replaceAll(`url(#${id})`, `url(#${nid})`).replaceAll(`href="#${id}"`, `href="#${nid}"`);
  }
  return body;
}
function symbolOf(it) {
  const svg = it.svg;
  const a = rootAttrs(svg);
  const inner = svg.replace(/^[\s\S]*?<svg\b[^>]*>/, '').replace(/<\/svg>\s*$/, '');
  const body = prefixIds(it.stem, inner);
  const pres = Object.entries(a).filter(([k]) => !['xmlns', 'viewBox', 'width', 'height'].includes(k)).map(([k, v]) => `${k}="${v}"`).join(' ');
  return `<symbol id="${it.stem}" viewBox="${a.viewBox}"${pres ? ' ' + pres : ''}>${body}</symbol>`;
}
w(path.join(OUT, 'sprite.svg'), `<svg xmlns="http://www.w3.org/2000/svg" style="display:none">\n${main.map(symbolOf).join('\n')}\n</svg>\n`);

// ---------- 5. Tema Freedesktop ----------
const THEME = path.join(OUT, 'theme', THEME_NAME);
const dirs = new Map(); // dir -> {Size, Context, Type, Min, Max}
for (const it of main) {
  const cx = ctxDir(it.category);
  const ctxName = CATEGORIES[it.category]?.context || 'Apps';
  if (it.kind === 'symbolic') {
    fs.mkdirSync(path.join(THEME, 'symbolic', cx), { recursive: true });
    fs.copyFileSync(path.join(OUT, 'svg', it.stem + '.svg'), path.join(THEME, 'symbolic', cx, it.stem + '.svg'));
    dirs.set(`symbolic/${cx}`, { Size: 16, Context: ctxName, Type: 'Scalable', MinSize: 8, MaxSize: 512 });
  } else {
    fs.mkdirSync(path.join(THEME, 'scalable', cx), { recursive: true });
    fs.copyFileSync(path.join(OUT, 'svg', it.stem + '.svg'), path.join(THEME, 'scalable', cx, it.stem + '.svg'));
    dirs.set(`scalable/${cx}`, { Size: 128, Context: ctxName, Type: 'Scalable', MinSize: 16, MaxSize: 1024 });
    if (!NO_PNG) for (const px of KINDS[it.kind].sizes) {
      w(path.join(THEME, `${px}x${px}`, cx, it.stem + '.png'), pngFor(it, px));
      dirs.set(`${px}x${px}/${cx}`, { Size: px, Context: ctxName, Type: 'Fixed' });
    }
  }
}
const order = [...dirs.keys()].sort((a, b) => (parseInt(a) || 0) - (parseInt(b) || 0) || a.localeCompare(b));
w(path.join(THEME, 'index.theme'),
  `[Icon Theme]\nName=${THEME_NAME}\nName[es]=${THEME_NAME}\nComment=Iconos de BC OS (macOS minimal)\nComment[es]=Iconos de BC OS (estilo macOS minimal)\nInherits=hicolor\nExample=folder\nDirectories=${order.join(',')}\n\n` +
  order.map((d) => `[${d}]\n` + Object.entries(dirs.get(d)).map(([k, v]) => `${k}=${v}`).join('\n') + '\n').join('\n'));

// ---------- 6. .icns (solo apps) ----------
const ICNS = { 16: ['icp4'], 32: ['icp5', 'ic11'], 64: ['icp6', 'ic12'], 128: ['ic07'], 256: ['ic08', 'ic13'], 512: ['ic09', 'ic14'], 1024: ['ic10'] };
export function buildIcns(pngBySize) {
  const chunks = [];
  for (const [px, types] of Object.entries(ICNS)) for (const t of types) {
    const data = pngBySize[px]; if (!data) continue;
    const h = Buffer.alloc(8); h.write(t, 0, 'ascii'); h.writeUInt32BE(data.length + 8, 4);
    chunks.push(h, data);
  }
  const body = Buffer.concat(chunks);
  const head = Buffer.alloc(8); head.write('icns', 0, 'ascii'); head.writeUInt32BE(body.length + 8, 4);
  return Buffer.concat([head, body]);
}
let icnsCount = 0;
if (!NO_PNG) for (const it of main.filter((i) => i.kind === 'app')) {
  const by = {}; for (const px of KINDS.app.sizes) by[px] = pngFor(it, px);
  w(path.join(OUT, 'icns', it.stem + '.icns'), buildIcns(by)); icnsCount++;
}

// ---------- 7. manifest.json ----------
const groups = new Map();
for (const it of main) {
  const k = it.kind + '|' + it.category + '|' + it.base;
  if (!groups.has(k)) groups.set(k, { it, files: {} });
  groups.get(k).files[it.fill ? 'fill' : 'regular'] = it.stem;
}
const icons = [...groups.values()].map(({ it, files }) => {
  const m = META[it.base];
  if (!m) warn(`sin entrada en meta.json: ${it.base}`);
  const hints = items.filter((o) => o.hint && o.base === it.base && o.kind === it.kind).map((o) => o.hint).sort((a, b) => a - b);
  return {
    name: it.base,
    label: m?.es || it.base,
    category: it.category,
    context: CATEGORIES[it.category]?.context || null,
    kind: it.kind,
    viewBox: KINDS[it.kind].viewBox,
    variants: files,
    tags: [...new Set(m?.tags || [])],
    sizes: KINDS[it.kind].sizes,
    ...(hints.length ? { hints } : {}),
    file: `dist/svg/${(files.regular || files.fill)}.svg`,
  };
}).sort((a, b) => a.category.localeCompare(b.category) || a.kind.localeCompare(b.kind) || a.name.localeCompare(b.name, "en", { numeric: true }));

const manifest = {
  name: THEME_NAME,
  version: VERSION,
  stroke: STROKE,
  kinds: Object.fromEntries(Object.entries(KINDS).map(([k, v]) => [k, { viewBox: v.viewBox, sizes: v.sizes }])),
  categories: Object.entries(CATEGORIES).map(([id, c]) => ({ id, label: c.label, context: c.context, lote: c.lote, count: icons.filter((i) => i.category === id).length })),
  icons,
};
if (OUT === path.join(ROOT, 'dist')) w(MANIFEST, JSON.stringify(manifest, null, 2) + '\n');
else w(path.join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');

// ---------- 8. datos para la vista previa ----------
if (!NO_PREVIEW && OUT === path.join(ROOT, 'dist')) {
  const svgs = Object.fromEntries(main.map((i) => [i.stem, prefixIds(i.stem, i.svg)]));
  w(path.join(ROOT, 'preview', 'data.js'), `// Generado por scripts/build.mjs. No editar.\nwindow.BC_ICONS = ${JSON.stringify({ manifest, svgs })};\n`);
}

const nFiles = main.length;
console.log(`BC icons: ${icons.length} iconos, ${nFiles} SVG (${items.length - nFiles} hints), ${icnsCount} .icns -> ${path.relative(process.cwd(), OUT) || '.'}`);
