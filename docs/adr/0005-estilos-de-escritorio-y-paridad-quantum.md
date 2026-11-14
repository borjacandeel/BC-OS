# ADR 0005 — Estilos de escritorio elegibles y paridad de funciones con Quantum Linux

- Estado: aceptada por el creador (2026-11-14)
- Fecha: 2026-11-14

## Contexto

El creador quiere un sistema completo «como Quantum Linux, pero BC OS». [Quantum Linux](https://github.com/QuantumLinux-arch)
(QuantumLinux-arch, GPL-3.0-or-later) ofrece, entre otras cosas, escritorio con estilo macOS o Windows elegible, modos de uso,
widgets, tienda con Flathub, antivirus, copias antes de actualizar, Android y juegos. BC OS tiene restricciones propias:
**solo ARM64**, base Arch Linux ARM, ligereza, español por defecto y nada de afirmar lo no probado. Steam y Proton no existen
de forma nativa para ARM64.

## Decisión

- Quantum Linux es **referencia de ideas de funciones**, no de código ni de recursos. BC OS **no copia sus logos, fondos,
  capturas, CSS ni textos**; todo el diseño y el código son propios.
- **Estilos de escritorio elegibles** en el panel de BC Shell, sin cambiar de compositor (sway, ADR 0004):
  - **BC** (recomendado): barra superior con menús globales y Dock flotante.
  - **Windows**: barra de tareas inferior con menú Inicio.
  - **Minimal**: solo la barra superior.
  Se elige en el asistente de bienvenida (3 pasos: estilo, colores y fondo, organización de ventanas) o en Configuración
  (`bc-ctl style mac|win|minimal`); el panel lo aplica en caliente por D-Bus (`org.bcos.Shell`).
- Se añaden **Modos** (Relajación, Concentración, Noche), **widgets** de escritorio y **Tienda con Flathub** (`flatpak --user`)
  junto a pacman.
- Resto de funciones, por fases y marcadas como pendientes: antivirus (ClamAV) y Centro BC; copias antes de actualizar
  (Btrfs + Snapper o equivalente) y GRUB/arranque seguro en el instalador; idiomas es/en/pt-BR; ventana de novedades.
- **Experimental y por hacer:** Android con Waydroid (depende del kernel) y juegos x86 con FEX/box64.
  **No se ofrecerán Steam ni Proton nativos** (no existen para ARM64).
- Solo ARM64, sin soporte x86 nativo.

## Consecuencias

- El panel tiene más variantes que probar (3 estilos × mosaico/flotante); se cubren con `ctest` (carga QML) y pruebas en QEMU,
  no en hardware real.
- Más código en el panel (barra de tareas, menú Inicio, widgets) y más estado de usuario (`Settings`, `UiState`).
- Flathub depende de que `flatpak` esté instalado y de la red; en ARM64 el catálogo es menor que en x86.
- La paridad se mide por funciones, no por parecido visual; el aspecto es el del design system de BC OS.
- Se documenta la atribución a Quantum Linux en el README para no inducir a pensar que BC OS es un derivado.

## Alternativas consideradas

1. **Derivar o reutilizar código/recursos de Quantum Linux**: descartado (arquitectura x86, identidad propia de BC OS, riesgo de confusión de marca).
2. **Un solo estilo (macOS)**: descartado; el creador pidió estilo elegible.
3. **Un compositor o shell distinto por estilo**: descartado; coste de mantenimiento y de RAM. Se resuelve en el panel.
4. **Soportar Steam/Proton**: imposible de forma nativa en ARM64; solo vía FEX/box64, experimental.
5. **Flathub sin pacman, o AUR desde el primer día**: pacman sigue siendo el origen principal; AUR queda pendiente por riesgo de seguridad.
