# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado semántico (hitos en `ROADMAP.md`).

## [Sin publicar]

## [0.9.21-beta]
### Cambiado
- Paneles emergentes cargados al abrirse (`Lazy.qml`): apertura de Spotlight y demás de 12–19 ms a 3 ms; −21 MB de memoria.
- Spotlight: una búsqueda por fotograma, sin rehacer la lista si no cambia, sin escalado por software.

## [0.9.20-beta] — BC Rendering Engine
### Añadido
- BC Hardware Intelligence en `bc-hardware-service`: perfil del equipo con raíz configurable, caché con huella,
  monitor único cada 20 s y señal D-Bus `NivelRenderCambiado`; `bc-hardware-service --perfil`.
- BC Adaptive Renderer: niveles Ultra / Alto / Equilibrado / Eficiente / Mínimo con parámetros por efecto y por
  compositor; rebajas por batería, temperatura y fotogramas perdidos con histéresis.
- `RenderEngine` (Qt, singleton QML `Render`) en BC Shell, apps y login: backend vulkan → opengl → software,
  `BC_RENDER_TIER`, `BC_RENDER_BACKEND`, medida de fotogramas.
- Ajustes ▸ Pantallas ▸ Calidad gráfica; `bc-render-apply` (Hyprland/swayfx por IPC).
- Caché en disco del desenfoque del cristal y decodificación del fondo a resolución de pantalla.
- `tools/bench/render-bench.sh`, pruebas `tst_render` y documentación en `docs/rendering-engine/`.
### Cambiado
- Theme, Glass, Genio, AppWindow y SlideIn usan los parámetros del motor en lugar de «¿es por software?».

### Añadido
- Reglas del proyecto (`CLAUDE.md`), lista de tareas (`PENDIENTE.md`) y README con el contexto completo.
- Logos oficiales BC (`assets/branding/`) e imagen de referencia del escritorio (`docs/design/reference/`).
- Sistema de diseño (`docs/design/BC-DESIGN-SYSTEM.md`, `tokens.json`).
- Documentación de arquitectura, hoja de ruta, seguridad, contribución, build, pruebas y ARM64.
- ADR 0001–0003 (base Arch Linux ARM, imagen GPT + systemd-boot, compositor labwc).
- `tools/host-check.sh`: diagnóstico del host del creador.
- Scripts de rootfs (`build/`): chroot aarch64, configuración en español, paquetes base.

### Pendiente
- Primera imagen arrancable verificada (0.1.0).
