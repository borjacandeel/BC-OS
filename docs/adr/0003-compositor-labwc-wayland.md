# ADR 0003 — Compositor Wayland: labwc (wlroots) + BC Shell en Qt con layer-shell

- Estado: propuesta aceptada para el prototipo; se revisará con mediciones
- Fecha: 2026-11-13

## Contexto

BC Shell debe ser muy ligero y fluido, en Wayland, reutilizando tecnología de compositor existente (no escribir uno propio antes de que el shell funcione). Objetivo: RAM en reposo ≤ 700 MB en una VM, con posibles limitaciones gráficas en VirtualBox ARM64.

## Opciones

| Opción | A favor | En contra |
|---|---|---|
| **labwc** (wlroots) | muy ligero (C, sin dependencias de Qt/KDE), soporta `wlr-layer-shell`, `foreign-toplevel-management`, temas y reglas; fácil de empaquetar y de parchear; render por software posible vía wlroots/pixman | efectos de ventana (animaciones, blur) limitados: hay que implementarlos en el shell o con parches |
| **KWin** | efectos, animaciones y blur completos, scripts; Qt nativo | mucho más pesado; arrastra KDE Frameworks; control visual total menos directo; más superficie de mantenimiento |
| Sway / otros wlroots | ligeros | enfocados en mosaico; menos adecuado para un escritorio de ventanas flotantes |
| Compositor propio (wlroots) | control total | coste alto; prematuro |

## Decisión

Usar **labwc** como compositor del prototipo y construir **BC Shell** como aplicaciones Qt 6/QML que usan los protocolos `wlr-layer-shell` (barra superior, Dock, lanzador, Centro de control, notificaciones) y `wlr-foreign-toplevel-management` (lista de ventanas, minimizar al Dock, Mission Control). El shell se comunica con el compositor solo por protocolos Wayland estándar, de modo que el compositor pueda cambiarse.

## Consecuencias

- Menor consumo base y arranque más rápido que con KWin (a medir, no asumido).
- Las animaciones de ventana y el desenfoque se resuelven en la capa del shell y con presupuesto controlado (design system §7, §12); si no bastan, opciones: parche a labwc o evaluar un compositor propio sobre wlroots en una fase posterior, o KWin como plan B.
- Cada componente del shell es un proceso independiente: un fallo no tumba el escritorio.
- Render por software como alternativa cuando no haya GPU en el invitado (VirtualBox ARM64): `WLR_RENDERER=pixman`, Qt Quick software backend.
- Riesgo: Mission Control y animaciones de minimizado requieren datos de geometría/miniaturas; se probará con `ext-foreign-toplevel-list` y capturas (`ext-image-copy-capture`). Si el prototipo no cumple, se reabre esta decisión.
