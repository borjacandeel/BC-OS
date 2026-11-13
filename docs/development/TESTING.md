# Pruebas de BC OS

Regla: no se afirma funcionalidad sin prueba ejecutada. Estado actual: sin suite automática todavía; lo siguiente es el plan.

## Niveles

| Nivel | Qué | Herramienta | Estado |
|---|---|---|---|
| 1 | Lint de scripts | `shellcheck`, `bash -n` | pendiente |
| 2 | Rust (BC Core) | `cargo test`, `clippy` | pendiente (sin código aún) |
| 3 | QML/Qt | `qmltestrunner`, `qmllint`, Xvfb / offscreen | pendiente |
| 4 | Imagen | comprobación de tabla GPT, sistemas de archivos, ficheros de arranque | pendiente |
| 5 | Arranque | QEMU aarch64 + UEFI (AAVMF), esperar login por consola serie | pendiente |
| 6 | Localización | verificar que no hay cadenas sin traducir; locale `es_ES.UTF-8` | pendiente |
| 7 | Rendimiento | scripts de benchmark en VM de referencia | pendiente |

## Prueba de arranque (criterio mínimo para publicar)

1. Arrancar la imagen en QEMU `virt` con AAVMF.
2. Verificar mensaje de login de BC OS (`/etc/issue`) por consola serie.
3. Iniciar sesión con el usuario inicial y comprobar cambio de contraseña forzado.
4. `locale` devuelve `es_ES.UTF-8`; `nft list ruleset` muestra la política; `zramctl` muestra zram0.
5. Apagado limpio.

## Benchmarks (`tools/bench/`, futuro)

Medir y registrar: RAM en reposo, CPU en reposo, tiempo de arranque, tiempo hasta sesión, lanzamiento de apps, FPS y consistencia de frame time, uso de disco, nº de procesos. VM de referencia documentada (vCPU, RAM, gráfico). Cada optimización se compara con la medición anterior en `docs/development/` (tabla de resultados).

Objetivos (no garantizados): RAM ≤ 700 MB, CPU ≈ ≤ 2 % en reposo.

## CI

Workflow en runner ARM64 (`ubuntu-24.04-arm`): lint, build Rust/Qt, tests, ensamblado de imagen, prueba de arranque, SHA256. No se publica si falla alguna etapa.
