# BC Rendering Engine — WORKLOG

Rama: `feature/bc-rendering-engine` · Etiqueta de recuperación: `bc-baseline-pre-rendering` (HEAD de main antes de empezar).
Árbol limpio al empezar (nada que guardar con stash).

## Fases
| Fase | Estado |
|---|---|
| 1 Auditoría y línea base | verificado |
| 2 Arquitectura | en curso |
| 3 Módulos | pendiente |
| 4 Integración | pendiente |
| 5 Benchmarks | pendiente |
| 6 Pruebas | pendiente |
| 7 Docs, versión, ISO | pendiente |

## Entorno (comandos que funcionan aquí)
- Anfitrión x86_64 Ubuntu (no Arch), Qt 6.4 del sistema, sin `qsb`/Qt Shader Tools, sin `/usr/bin/time`.
- Shell: `cmake -S shell -B /home/user/bcwork/hb && cmake --build /home/user/bcwork/hb -j8 && (cd /home/user/bcwork/hb && ctest)` → 11 tests.
- BC Core: `cd core && cargo test` → 45 tests (línea base), `cargo clippy`.
- ARM64: chroot Arch Linux ARM en `/home/user/bcwork/root` (qemu-user), `bash /home/user/bcwork/inc.sh` compila BC Shell ahí (Qt 6.12).
- Sesión real: sway headless dentro del chroot (`/home/user/bcwork/headless.sh <script>`), capturas con grim.
- bspwm/X11: Xvfb del anfitrión (`:5`) con `/tmp/.X11-unix` montado en el chroot.
- Banco: `tools/bench/render-bench.sh <bc-shell> <csv> 3` (offscreen, backend software, como VM sin 3D).

## Línea base (main antes de empezar, binario del anfitrión, Qt 6.4 software)
Ver `bench-base.csv`. Arranque ~2,4 s, CPU de arranque ~1,15 s, RSS ~200 MB; render por fotograma (Qt) media 1,6–7,8 ms.

## Inventario de funcionalidades (contrato de no regresión)
Barra de menús con menús globales; Dock (ampliación, rebote, recientes, pilas, papelera, globos, progreso Tienda, arrastrar,
«poof»); widgets de cristal; Control Center editable; Centro de notificaciones; Spotlight; Aplicaciones (F4); Mission
Control; selector de apps; genio (con y sin GPU, desactivado sin GPU desde 0.9.18); cierre animado; Archivos (pestañas,
etiquetas, emblemas, Recientes); Ajustes (Aspecto: cristal, resaltado, estilo de widgets; General: motor gráfico,
actualizaciones con aviso de reinicio; Pantallas); bloqueo/login (pista de contraseña, varios usuarios); claro/oscuro con
fundido; Reducir transparencia; Aumentar contraste; escala de interfaz; multimonitor; Forzar salida; Emoji; Notas con
búsqueda; captura con miniatura; sesiones BC OS (Hyprland/sway/swayfx) y Dotfiles (bspwm + polybar + menús).
Optimizaciones a conservar: sin microcortes en VM (monitor del sistema solo con su widget, KMS clásico en vmwgfx),
cristal solo se recalcula al cambiar el fondo, genio con capa del tamaño justo, sway con pixman en VM, sin lente/genio
sin GPU, desenfoque sin bloques.

## Decisiones (ADR breves)
- ADR-1: El perfil y el nivel se calculan en BC Core (`bc-hardware-service`, interfaz `org.bcos.Hardware1` ampliada),
  no en un servicio nuevo. Los procesos Qt leen D-Bus con tiempo límite corto o la caché en disco.

## Limitaciones externas
(se rellenan con evidencias)
