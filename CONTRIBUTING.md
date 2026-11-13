# Contribuir a BC OS

Gracias por querer ayudar. Resumen de reglas:

## Idioma

- Documentación, commits, issues y PR: **castellano**.
- Identificadores de código: inglés.
- Todo texto visible en la interfaz: español (es_ES) por defecto, a través del sistema de localización (`qsTr`/Linguist/gettext). Sin cadenas fijas.

## Flujo

1. Lee `PENDIENTE.md` y `ARCHITECTURE.md`.
2. Ramas: `main` es la fuente de verdad; se trabaja en ramas cortas `feat/…`, `fix/…`, `docs/…` y se integran a `main` mediante PR (o commits directos del mantenedor).
3. Commits pequeños, con mensaje en castellano que explique el porqué. Nunca `--force` sobre `main`.
4. Nunca subas credenciales, claves privadas, tokens o secretos.
5. Actualiza `PENDIENTE.md` y `CHANGELOG.md` cuando corresponda.

## Estándares

- Rust: `cargo fmt`, `cargo clippy -- -D warnings`, `cargo test`.
- C/C++: C++20, `clang-format`, sin dependencias innecesarias.
- QML: solo tokens de `docs/design/tokens.json`; sin colores, radios ni sombras propios.
- Bash: `set -euo pipefail`, `shellcheck` limpio.
- Python: solo para tests y utilidades; `ruff`.
- Solo ARM64 (aarch64) como objetivo inicial.
- Sin Electron en componentes del núcleo.
- No afirmar funcionalidad no probada; documentar limitaciones.

## Pruebas

Ver `docs/development/TESTING.md`. Todo cambio funcional debe incluir pruebas o justificar su ausencia.

## Seguridad

Vulnerabilidades: seguir `SECURITY.md` (no abrir issues públicos).

## Licencia

Al contribuir aceptas que tu aportación se licencia bajo GPL-3.0-or-later. Marca y logos de BC OS reservados (ver `LICENSE`).
