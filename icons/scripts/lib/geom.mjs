// Utilidades geométricas para autoría de iconos (no se usan en build).
// Uso CLI: node scripts/lib/geom.mjs squircle [tamaño=824] [radio=185] [suavizado=0.6] [x0=100] [y0=100]
import { fileURLToPath } from 'node:url';

export const f = (n) => String(+n.toFixed(2));

/** Polígono regular con vértices redondeados (curvas Q con control en el vértice). */
export function roundedPoly(points, d) {
  const n = points.length;
  let out = '';
  for (let i = 0; i < n; i++) {
    const p = points[i], a = points[(i + n - 1) % n], b = points[(i + 1) % n];
    const ua = unit(p, a), ub = unit(p, b);
    const p1 = [p[0] + ua[0] * d, p[1] + ua[1] * d];
    const p2 = [p[0] + ub[0] * d, p[1] + ub[1] * d];
    out += (i ? 'L' : 'M') + f(p1[0]) + ' ' + f(p1[1]) + 'Q' + f(p[0]) + ' ' + f(p[1]) + ' ' + f(p2[0]) + ' ' + f(p2[1]);
  }
  return out + 'z';
}
const unit = (p, q) => { const dx = q[0] - p[0], dy = q[1] - p[1], l = Math.hypot(dx, dy); return [dx / l, dy / l]; };

export function regPoly(n, cx, cy, R, rotDeg = -90) {
  return Array.from({ length: n }, (_, i) => {
    const a = ((rotDeg + (360 / n) * i) * Math.PI) / 180;
    return [cx + R * Math.cos(a), cy + R * Math.sin(a)];
  });
}

/** Squircle de esquinas continuas (suavizado tipo "figma", 0.6 ≈ Big Sur). */
export function squircle(size = 824, r = 185, s = 0.6, x0 = 100, y0 = 100) {
  const rad = (d) => (d * Math.PI) / 180;
  const p = Math.min((1 + s) * r, size / 2);
  const arcMeasure = 90 * (1 - s);
  const arcLen = Math.sin(rad(arcMeasure / 2)) * r * Math.SQRT2;
  const alpha = (90 - arcMeasure) / 2;
  const p3p4 = r * Math.tan(rad(alpha / 2));
  const beta = 45 * s;
  const c = p3p4 * Math.cos(rad(beta));
  const dd = c * Math.tan(rad(beta));
  const b = (p - arcLen - c - dd) / 3;
  const a = 2 * b;
  const R = f(r);
  const corner = (rot) => {
    // esquina superior derecha en coordenadas relativas, rotada rot*90º
    const seg = [
      ['c', a, 0, a + b, 0, a + b + c, dd],
      ['a', r, r, 0, 0, 1, arcLen, arcLen],
      ['c', dd, c, dd, b + c, dd, a + b + c],
    ];
    return seg.map((s2) => {
      const v = s2.slice(1);
      if (s2[0] === 'a') { const [ra, rb, xr, la, sw, x, y] = v; const [X, Y] = rotv(x, y, rot); return `a${R} ${R} 0 0 1 ${f(X)} ${f(Y)}`; }
      const out = [];
      for (let i = 0; i < v.length; i += 2) { const [X, Y] = rotv(v[i], v[i + 1], rot); out.push(f(X), f(Y)); }
      return 'c' + out.join(' ');
    }).join('');
  };
  const rotv = (x, y, k) => { for (let i = 0; i < k; i++) [x, y] = [-y, x]; return [x, y]; };
  const S = size;
  return (
    `M${f(x0 + S - p)} ${f(y0)}` + corner(0) + `L${f(x0 + S)} ${f(y0 + S - p)}` + corner(1) +
    `L${f(x0 + p)} ${f(y0 + S)}` + corner(2) + `L${f(x0)} ${f(y0 + p)}` + corner(3) + 'z'
  );
}

if (process.argv[1] === fileURLToPath(import.meta.url) && process.argv[2] === 'squircle') {
  const [, , , size, r, s, x0, y0] = process.argv;
  console.log(squircle(+size || 824, +r || 185, s === undefined ? 0.6 : +s, x0 === undefined ? 100 : +x0, y0 === undefined ? 100 : +y0));
}
