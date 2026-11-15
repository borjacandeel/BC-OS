// Fuente de verdad ejecutable de icons/SPEC.md. Si cambias algo aquí, cambia SPEC.md.
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

export const THEME_NAME = 'BC';
export const STROKE = 1.5;

// kind: symbolic (24, currentColor, trazo) | color (48, paleta fija) | app (1024, squircle)
export const KINDS = {
  symbolic: { viewBox: '0 0 24 24', size: 24, live: [2, 22], suffix: '-symbolic', sizes: [16, 20, 24, 32, 48] },
  color: { viewBox: '0 0 48 48', size: 48, live: [3, 45], suffix: '', sizes: [16, 24, 32, 48, 64, 128, 256] },
  app: { viewBox: '0 0 1024 1024', size: 1024, live: [100, 924], suffix: '', sizes: [16, 32, 64, 128, 256, 512, 1024] },
};

// categoría -> contexto Freedesktop y etiqueta. Cada categoría puede existir en varios kinds
// (src/<kind>/<categoría>/): p.ej. dialogs tiene symbolic y color. Lote: A, B o C.
export const CATEGORIES = {
  navigation: { context: 'Actions', label: 'Navegación', lote: 'A' },
  actions: { context: 'Actions', label: 'Acciones', lote: 'A' },
  status: { context: 'Status', label: 'Barra de menús y estado', lote: 'A' },
  dialogs: { context: 'Status', label: 'Diálogos', lote: 'A' },
  apps: { context: 'Apps', label: 'Apps del sistema', lote: 'B' },
  places: { context: 'Places', label: 'Lugares y carpetas', lote: 'C' },
  mimetypes: { context: 'MimeTypes', label: 'Archivos y MIME', lote: 'C' },
  devices: { context: 'Devices', label: 'Dispositivos', lote: 'C' },
};

// Colores permitidos en kind color/app (hex en mayúsculas). Ver SPEC.md §6.
export const PALETTE = {
  neutral: ['#FFFFFF', '#000000', '#04111F', '#F5F5F7', '#0B1220', '#1B2742'],
  info: ['#6AA8FF', '#2F7BFF', '#1F63D6'],
  success: ['#62E487', '#30D158', '#1FA84F'],
  warning: ['#FFCB72', '#FFB340', '#F29A1F'],
  danger: ['#FF8D85', '#FF5F57', '#E8453C'],
  question: ['#9BA6FF', '#6B77F0', '#4F5BDB'],
  folder: ['#3B9BFF', '#1E7BF0', '#7CC0FF', '#1565D0'],
  apps: [
    // familias de apps (arriba, abajo). Lotes B/C pueden usar solo estos.
    '#5CB0FF', '#1B6FF0', // azul   Archivos, Navegador
    '#B4BDCC', '#5E6A80', // grafito Configuración
    '#6BE591', '#1FA84F', // verde  Monitor, Calculadora(?)
    '#3A4660', '#0B1220', // noche  Terminal
    '#67D3FF', '#1A8CF2', // cian   Tienda
    '#FF8F87', '#E8453C', // rojo   Música, Calendario
    '#FFD27D', '#F29A1F', // ámbar  Notas
    '#B49CFF', '#6B4FE0', // violeta Fotos
    '#FFFFFF', '#E4E9F2', // papel
    '#F5F5F7', '#C3CCDB', // plata
    '#5BE0C8', '#16A085', // teal   Tienda
    '#FFA66B', '#EB5B1E', // naranja Calculadora
    '#8E9BFF', '#3A45C4', // índigo Editor
    '#FF8FC2', '#D6336C', // magenta Mission Control
    '#E6EBF5', '#A7B3CC', // niebla  Aplicaciones (view-app-grid), fondo claro
  ],
};
export const ALLOWED_COLORS = new Set(Object.values(PALETTE).flat().map((c) => c.toUpperCase()));

export const NAME_RE = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
