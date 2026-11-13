# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado semántico (hitos en `ROADMAP.md`).

## [Sin publicar]

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
