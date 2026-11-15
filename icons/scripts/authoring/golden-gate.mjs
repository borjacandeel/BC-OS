#!/usr/bin/env node
// Autoría de los iconos de app «Golden Gate» (SPEC §7.8: glifo por capas de vidrio).
// No forma parte del build: escribe SVG limpios en src/. Las coordenadas de cada glifo
// están escritas a mano aquí; el squircle sale de lib/geom.mjs (SPEC §7.1).
//   node scripts/authoring/golden-gate.mjs
import fs from 'node:fs';
import path from 'node:path';
import { squircle, f } from '../lib/geom.mjs';
import { ROOT } from '../lib/spec.mjs';

const APPS = path.join(ROOT, 'src', 'app', 'apps');
const PLACES = path.join(ROOT, 'src', 'color', 'places');

const BODY = squircle(824, 185, 0.6, 100, 100);
const SH28 = squircle(824, 185, 0.6, 100, 128);
const SH12 = squircle(824, 185, 0.6, 100, 112);

// ---------- piezas comunes ----------
const W = '#FFFFFF';
const GLASS = (op = '.3') => `fill="${W}" fill-opacity="${op}" stroke="${W}" stroke-opacity=".5" stroke-width="4"`;
const OBJ = 'fill="url(#gl)"';
const SHADOW = (op = '.16') => `fill="#000000" fill-opacity="${op}"`;
const STROKE = (w, c = W, op) => `fill="none" stroke="${c}"${op ? ` stroke-opacity="${op}"` : ''} stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"`;

function app({ top, bottom, light = false, glyph, defs = '', gl = true, shadows = true }) {
  const g = (id, y1, y2, a, b) => `<linearGradient id="${id}" x1="512" y1="${y1}" x2="512" y2="${y2}" gradientUnits="userSpaceOnUse">${a}${b}</linearGradient>`;
  const st = (o, c, op) => `<stop offset="${o}" stop-color="${c}"${op !== undefined ? ` stop-opacity="${op}"` : ''}/>`;
  const rim = light
    ? `<path d="${BODY}" fill="none" stroke="#000000" stroke-opacity=".10" stroke-width="6"/>`
    : `<path d="${BODY}" fill="none" stroke="#FFFFFF" stroke-opacity=".14" stroke-width="3"/>`;
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><defs>` +
    g('bg', 100, 924, st(0, top), st(1, bottom)) +
    g('hl', 100, 560, st(0, W, '.22'), st(1, W, '0')) +
    (gl ? g('gl', 252, 772, st(0, W), st(1, '#E4E9F2')) : '') +
    defs +
    `</defs>` +
    (shadows
      ? `<path d="${SH28}" fill="#000000" fill-opacity=".07" stroke="#000000" stroke-opacity=".05" stroke-width="36" stroke-linejoin="round"/>` +
        `<path d="${SH12}" fill="#000000" fill-opacity=".26"/>`
      : '') +
    `<path d="${BODY}" fill="url(#bg)"/><path d="${BODY}" fill="url(#hl)"/>` +
    rim +
    glyph +
    `</svg>\n`
  );
}

/** Polígono con esquinas redondeadas (Q con control en el vértice); d por vértice. */
function rpoly(pts, d) {
  const n = pts.length;
  const u = (p, q) => { const dx = q[0] - p[0], dy = q[1] - p[1], l = Math.hypot(dx, dy); return [dx / l, dy / l]; };
  let s = '';
  for (let i = 0; i < n; i++) {
    const p = pts[i], a = pts[(i + n - 1) % n], b = pts[(i + 1) % n], di = Array.isArray(d) ? d[i] : d;
    const ua = u(p, a), ub = u(p, b);
    s += (i ? 'L' : 'M') + f(p[0] + ua[0] * di) + ' ' + f(p[1] + ua[1] * di) + 'Q' + f(p[0]) + ' ' + f(p[1]) + ' ' + f(p[0] + ub[0] * di) + ' ' + f(p[1] + ub[1] * di);
  }
  return s + 'Z';
}
const circle = (cx, cy, r) => `M${f(cx - r)} ${f(cy)}A${r} ${r} 0 1 0 ${f(cx + r)} ${f(cy)}A${r} ${r} 0 1 0 ${f(cx - r)} ${f(cy)}Z`;
const rot = (cx, cy, x, y, deg) => { const a = (deg * Math.PI) / 180, dx = x - cx, dy = y - cy; return [cx + dx * Math.cos(a) - dy * Math.sin(a), cy + dx * Math.sin(a) + dy * Math.cos(a)]; };
const rrectRot = (cx, cy, w, h, deg, d) => rpoly([[-w / 2, -h / 2], [w / 2, -h / 2], [w / 2, h / 2], [-w / 2, h / 2]].map(([x, y]) => rot(cx, cy, cx + x, cy + y, deg)), d);

// Carpeta de pestaña (silueta propia): x,y = esquina superior izquierda de la pestaña.
function folder(x, y, w, h) {
  const t = 52, tw = Math.round(w * 0.4), R = 64, r = 36;
  return `M${x} ${y + r}A${r} ${r} 0 0 1 ${x + r} ${y}H${x + tw - 40}C${x + tw - 18} ${y} ${x + tw - 6} ${y + 10} ${x + tw + 8} ${y + 26}L${x + tw + 14} ${y + 33}C${x + tw + 26} ${y + 47} ${x + tw + 36} ${y + t} ${x + tw + 56} ${y + t}H${x + w - R}A${R} ${R} 0 0 1 ${x + w} ${y + t + R}V${y + h - R}A${R} ${R} 0 0 1 ${x + w - R} ${y + h}H${x + R}A${R} ${R} 0 0 1 ${x} ${y + h - R}Z`;
}

// Engranaje: n dientes trapezoidales redondeados + agujero central (evenodd).
function gear(cx, cy, R, r, n, hole, d) {
  const pts = [];
  const step = 360 / n, tip = step * 0.17, base = step * 0.29;
  for (let i = 0; i < n; i++) {
    const a = -90 + step * i;
    for (const [ang, rad] of [[a - base, r], [a - tip, R], [a + tip, R], [a + base, r]]) {
      const t = (ang * Math.PI) / 180; pts.push([cx + rad * Math.cos(t), cy + rad * Math.sin(t)]);
    }
  }
  return rpoly(pts, d) + (hole ? circle(cx, cy, hole) : '');
}

const out = {};

// ===== Archivos: dos carpetas; la de atrás de vidrio, la delantera con bolsillo =====
{
  const back = folder(332, 282, 440, 380), front = folder(252, 362, 440, 380), frontSh = folder(252, 378, 440, 380);
  const pocket = 'M252 510A64 64 0 0 1 316 446H628A64 64 0 0 1 692 510V678A64 64 0 0 1 628 742H316A64 64 0 0 1 252 678Z';
  const base = { top: '#5CB0FF', bottom: '#1B6FF0' };
  out['system-file-manager'] = app({ ...base, glyph:
    `<path d="${back}" ${GLASS()}/>` +
    `<path d="${frontSh}" ${SHADOW()}/>` +
    `<path d="${front}" fill="${W}" fill-opacity=".82"/>` +
    `<path d="${pocket}" ${OBJ}/>` });
  out['system-file-manager@32'] = app({ ...base, gl: false, glyph:
    `<path d="${back}" fill="${W}" fill-opacity=".4"/><path d="${front}" fill="${W}" fill-opacity=".82"/><path d="${pocket}" fill="${W}"/>` });
  out['system-file-manager@16'] = app({ ...base, gl: false, glyph:
    `<path d="${folder(232, 292, 560, 460)}" fill="${W}"/>` });
}

// ===== Ajustes del Sistema: engranaje grande + engranaje pequeño de vidrio =====
{
  const base = { top: '#B4BDCC', bottom: '#5E6A80' };
  const big = gear(470, 554, 216, 176, 8, 72, 16), bigSh = gear(470, 570, 216, 176, 8, 72, 16);
  const small = gear(660, 346, 110, 88, 6, 34, 12);
  out['preferences-system'] = app({ ...base, glyph:
    `<path d="${small}" ${GLASS('.35')} fill-rule="evenodd"/>` +
    `<path d="${bigSh}" ${SHADOW()} fill-rule="evenodd"/>` +
    `<path d="${big}" ${OBJ} fill-rule="evenodd"/>` });
  out['preferences-system@32'] = app({ ...base, gl: false, glyph:
    `<path d="${small}" fill="${W}" fill-opacity=".45" fill-rule="evenodd"/><path d="${big}" fill="${W}" fill-rule="evenodd"/>` });
  out['preferences-system@16'] = app({ ...base, gl: false, glyph:
    `<path d="${gear(512, 512, 290, 230, 8, 96, 22)}" fill="${W}" fill-rule="evenodd"/>` });
}

// ===== Monitor de Actividad: gráfica de área sobre tarjeta de vidrio =====
{
  const base = { top: '#6BE591', bottom: '#1FA84F' };
  const pts = [[320, 604], [404, 520], [476, 576], [564, 404], [640, 500], [704, 452]];
  const line = (dy = 0) => 'M' + pts.map(([x, y]) => `${x} ${y + dy}`).join('L');
  const ar = `<linearGradient id="ar" x1="512" y1="404" x2="512" y2="676" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="${W}" stop-opacity=".55"/><stop offset="1" stop-color="${W}" stop-opacity="0"/></linearGradient>`;
  out['utilities-system-monitor'] = app({ ...base, gl: false, defs: ar, glyph:
    `<rect x="252" y="292" width="520" height="440" rx="72" ${GLASS()}/>` +
    `<path d="${line()}V676H320Z" fill="url(#ar)"/>` +
    `<path d="${line(16)}" ${STROKE(56, '#000000', '.16')}/>` +
    `<path d="${line()}" ${STROKE(56)}/>` });
  out['utilities-system-monitor@32'] = app({ ...base, gl: false, glyph:
    `<rect x="252" y="292" width="520" height="440" rx="72" fill="${W}" fill-opacity=".3"/><path d="${line()}" ${STROKE(64)}/>` });
  out['utilities-system-monitor@16'] = app({ ...base, gl: false, glyph:
    `<path d="M272 600L408 472L520 568L656 376L752 472" ${STROKE(96)}/>` });
}

// ===== Tienda (gnome-software): bolsa de compra con la marca BC =====
{
  const base = { top: '#5BE0C8', bottom: '#16A085' };
  const bag = (dy = 0) => rpoly([[316, 380 + dy], [708, 380 + dy], [732, 772 + dy], [292, 772 + dy]], [36, 36, 64, 64]);
  const handle = 'M424 452V352A88 88 0 0 1 600 352V452';
  const holes = '<circle cx="424" cy="452" r="22" fill="#16A085"/><circle cx="600" cy="452" r="22" fill="#16A085"/>';
  const B = 'M390 532H440A37.5 37.5 0 0 1 440 607H448A37.5 37.5 0 0 1 448 682H384A24 24 0 0 1 360 658V556A24 24 0 0 1 384 532Z';
  const C = 'M634 560H584L537 607L584 654H634';
  out['gnome-software'] = app({ ...base, glyph:
    `<path d="${handle}" ${STROKE(56, W, '.7')}/>` +
    `<path d="${bag(16)}" ${SHADOW()}/>` +
    `<path d="${bag()}" ${OBJ}/>` + holes +
    `<path d="${B}" fill="#16A085"/><path d="${C}" ${STROKE(56, '#16A085')}/>` });
  out['gnome-software@32'] = app({ ...base, gl: false, glyph:
    `<path d="${handle}" ${STROKE(64, W, '.7')}/><path d="${bag()}" fill="${W}"/>` + holes + `<path d="${B}" fill="#16A085"/><path d="${C}" ${STROKE(64, '#16A085')}/>` });
  out['gnome-software@16'] = app({ ...base, gl: false, glyph:
    `<path d="M408 440V344A104 104 0 0 1 616 344V440" ${STROKE(88, W, '.7')}/>` +
    `<path d="${rpoly([[300, 380], [724, 380], [756, 792], [268, 792]], [44, 44, 72, 72])}" fill="${W}"/>` +
    '<circle cx="408" cy="452" r="32" fill="#16A085"/><circle cx="616" cy="452" r="32" fill="#16A085"/>' });
}

// ===== Terminal: ventana de vidrio oscura con >_ =====
{
  const base = { top: '#3A4660', bottom: '#0B1220' };
  const dots = `<circle cx="316" cy="348" r="20" fill="#FF5F57"/><circle cx="376" cy="348" r="20" fill="#FFB340"/><circle cx="436" cy="348" r="20" fill="#30D158"/>`;
  const prompt = (dy = 0, op1, op2 = '.7', w = 64) =>
    `<path d="M340 ${470 + dy}L416 ${546 + dy}L340 ${622 + dy}" ${STROKE(w, op1 ? '#000000' : W, op1)}/>` +
    `<path d="M476 ${622 + dy}H620" ${STROKE(w, op1 ? '#000000' : W, op1 || op2)}/>`;
  out['utilities-terminal'] = app({ ...base, gl: false, glyph:
    `<rect x="252" y="292" width="520" height="440" rx="64" ${GLASS('.16')}/>` + dots + prompt(16, '.3') + prompt() });
  out['utilities-terminal@32'] = app({ ...base, gl: false, glyph:
    `<rect x="252" y="292" width="520" height="440" rx="64" fill="${W}" fill-opacity=".16"/>` + prompt(0, undefined, '.7', 72) });
  out['utilities-terminal@16'] = app({ ...base, gl: false, glyph:
    `<path d="M300 380L432 512L300 644" ${STROKE(96)}/><path d="M512 644H724" ${STROKE(96, W, '.7')}/>` });
}

// ===== Aplicaciones (view-app-grid): rejilla 3x3 de teselas de color sobre «niebla» =====
{
  const base = { top: '#E6EBF5', bottom: '#A7B3CC', light: true };
  const cols = [['#2F7BFF', '#30D158', '#FFB340'], ['#6B4FE0', '#04111F', '#FF5F57'], ['#16A085', '#D6336C', '#EB5B1E']];
  const xs = [252, 436, 620];
  const tl = `<linearGradient id="tl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${W}" stop-opacity=".32"/><stop offset=".55" stop-color="${W}" stop-opacity="0"/></linearGradient>`;
  let sh = '', tiles = '', glass = '';
  for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) {
    sh += `<rect x="${xs[c]}" y="${xs[r] + 12}" width="152" height="152" rx="44" ${SHADOW('.14')}/>`;
    tiles += `<rect x="${xs[c]}" y="${xs[r]}" width="152" height="152" rx="44" fill="${cols[r][c]}"/>`;
    glass += `<rect x="${xs[c]}" y="${xs[r]}" width="152" height="152" rx="44" fill="url(#tl)"/>`;
  }
  out['view-app-grid'] = app({ ...base, gl: false, defs: tl, glyph: sh + tiles + glass });
  let t32 = '';
  for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) t32 += `<rect x="${xs[c] - 8}" y="${xs[r] - 8}" width="168" height="168" rx="44" fill="${cols[r][c]}"/>`;
  out['view-app-grid@32'] = app({ ...base, gl: false, glyph: t32 });
  const x16 = [232, 432, 632];
  let t16 = '';
  for (let r = 0; r < 3; r++) for (let c = 0; c < 3; c++) t16 += `<rect x="${x16[c]}" y="${x16[r]}" width="160" height="160" rx="40" fill="${cols[r][c]}"/>`;
  out['view-app-grid@16'] = app({ ...base, gl: false, glyph: t16 });
}

// ===== Papelera: cubo de vidrio con costillas, abierto (sin tapa) =====
{
  const base = { top: '#F5F5F7', bottom: '#C3CCDB', light: true };
  const cy = 336, rx = 208, ry = 60, L = 512 - rx, Rr = 512 + rx;
  const sides = `M${L} ${cy}L346 700C350 726 368 740 398 744C470 752 554 752 626 744C656 740 674 726 678 700L${Rr} ${cy}`;
  const body = `${sides}A${rx} ${ry} 0 0 1 ${L} ${cy}Z`;
  const backArc = `M${L} ${cy}A${rx} ${ry} 0 0 1 ${Rr} ${cy}`;
  const frontArc = `M${L} ${cy}A${rx} ${ry} 0 0 0 ${Rr} ${cy}`;
  const mouth = `M${L} ${cy}A${rx} ${ry} 0 0 1 ${Rr} ${cy}A${rx} ${ry} 0 0 1 ${L} ${cy}Z`;
  const INK = '#1B2742';
  const ribs = `<path d="M424 448L434 664M512 452V672M600 448L590 664" ${STROKE(56, '#0B1220', '.55')}/>`;
  const glassBody = `<path d="${body}" fill="#0B1220" fill-opacity=".08"/><path d="${mouth}" fill="#0B1220" fill-opacity=".16"/>`;
  const papers =
    `<path d="${rrectRot(588, 300, 140, 184, 9, 28)}" fill="#6AA8FF"/>` +
    `<path d="${rrectRot(446, 312, 156, 196, -12, 28)}" fill="#1F63D6"/>`;
  const empty = (w, withRibs = true) => `<path d="${backArc}" ${STROKE(w, INK)}/>` + `<path d="${sides}" ${STROKE(w, INK)}/>` + `<path d="${frontArc}" ${STROKE(w, INK)}/>` + (withRibs ? ribs : '');
  out['user-trash'] = app({ ...base, gl: false, glyph: glassBody + empty(56) });
  out['user-trash@32'] = app({ ...base, gl: false, glyph: glassBody + empty(64) });
  out['user-trash@16'] = app({ ...base, gl: false, glyph: `<path d="${body}" fill="#0B1220" fill-opacity=".16"/>` + empty(88, false) });
  // llena: papeles entre el borde trasero y el delantero (se ven a través del vidrio)
  const full = (w, withRibs = true) => `<path d="${mouth}" fill="#0B1220" fill-opacity=".16"/><path d="${backArc}" ${STROKE(w, INK)}/>` + papers +
    `<path d="${body}" fill="#0B1220" fill-opacity=".08"/><path d="${sides}" ${STROKE(w, INK)}/><path d="${frontArc}" ${STROKE(w, INK)}/>` + (withRibs ? ribs : '');
  out['user-trash-full'] = app({ ...base, gl: false, glyph: full(56) });
  out['user-trash-full@32'] = app({ ...base, gl: false, glyph: full(64) });
  out['user-trash-full@16'] = app({ ...base, gl: false, glyph:
    `<path d="${backArc}" ${STROKE(88, INK)}/><path d="${rrectRot(450, 296, 180, 220, -12, 32)}" fill="#1F63D6"/><path d="${rrectRot(596, 286, 160, 200, 9, 32)}" fill="#6AA8FF"/>` +
    `<path d="${body}" fill="#0B1220" fill-opacity=".16"/><path d="${sides}" ${STROKE(88, INK)}/><path d="${frontArc}" ${STROKE(88, INK)}/>` });
}

for (const [k, v] of Object.entries(out)) fs.writeFileSync(path.join(APPS, k + '.svg'), v);

// ===== Pila de Descargas (color 48, lugares): hojas en abanico + tarjeta azul con flecha =====
{
  const r48 = (cx, cy, w, h, deg) => rrectRot(cx, cy, w, h, deg, 3);
  const defs = `<defs><linearGradient id="f" x1="24" y1="4" x2="24" y2="44" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7CC0FF"/><stop offset="1" stop-color="#1E7BF0"/></linearGradient></defs>`;
  const sheet = (d, c) => `<path d="${d}" fill="${c}" stroke="#1B2742" stroke-opacity=".18" stroke-width="1"/>`;
  const card = 'M11 11a3 3 0 0 1 3-3h20a3 3 0 0 1 3 3v26a3 3 0 0 1-3 3H14a3 3 0 0 1-3-3z';
  const arrow = '<path d="M24 15.5v12M19 22.5l5 5 5-5M18.5 33h11" fill="none" stroke="#FFFFFF" stroke-opacity=".9" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>';
  const svg = (inner) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">${defs}<ellipse cx="24" cy="42.6" rx="14" ry="2.2" fill="#000000" opacity=".16"/>${inner}</svg>\n`;
  fs.writeFileSync(path.join(PLACES, 'folder-download-stack.svg'), svg(
    sheet(r48(22, 23.5, 26, 32, -11), '#E4E9F2') + sheet(r48(26, 23.5, 26, 32, 8), '#FFFFFF') +
    `<path d="${card}" fill="url(#f)"/><path d="${card}" fill="none" stroke="#FFFFFF" stroke-opacity=".28" stroke-width="1"/>` + arrow));
  fs.writeFileSync(path.join(PLACES, 'folder-download-stack@16.svg'), svg(
    sheet(r48(26.5, 23.5, 26, 32, 9), '#FFFFFF') + `<path d="${card}" fill="url(#f)"/>` +
    '<path d="M24 14.5v14M18 22.5l6 6 6-6" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'));
}
console.log('golden-gate:', Object.keys(out).length, 'SVG de app + folder-download-stack');
