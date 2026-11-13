# Hoja de ruta de BC OS

Los números de versión son hitos de planificación, no promesas. Estado real en `PENDIENTE.md`.

| Versión | Hito | Contenido principal | Estado |
|---|---|---|---|
| 0.1.0 | Fundación | rootfs ARM64, imagen arrancable, locale español, documentación | en curso |
| 0.2.0 | Prototipo BC Shell | sesión Wayland, barra superior, Dock, lanzador | pendiente |
| 0.3.0 | Componentes de escritorio | Mission Control, Centro de control, notificaciones, design system aplicado | pendiente |
| 0.4.0 | Aplicaciones nativas | Archivos, Configuración, Monitor, Terminal, Store | pendiente |
| 0.5.0 | Sistema integrado | BC Core, red, audio, hardware, seguridad, actualizaciones | pendiente |
| 0.8.0 | Beta | instalador, optimización, beta pública | pendiente |
| 1.0.0 | Primera estable | criterios de calidad y rendimiento cumplidos y medidos | pendiente |

## Fases

0. **Viabilidad** — repo, entorno, estrategia de imagen, decisiones (ADR).
1. **Base** — sistema mínimo ARM64 que arranca en QEMU y, después, en VirtualBox ARM64.
2. **BC Shell** — sesión gráfica y componentes básicos.
3. **Identidad visual** — design system, modo claro/oscuro, animaciones.
4. **Aplicaciones** — apps nativas.
5. **Integración** — servicios Rust, red, audio, seguridad, actualizaciones.
6. **Optimización** — benchmarks, perfilado, renderizado.
7. **Instalador** — imagen instalable, particionado, cifrado opcional, recuperación.
8. **Beta pública** — documentación, Releases, checksums, problemas conocidos.

## Hitos técnicos

1. Linux ARM64 real arrancando en VirtualBox.
2. BC Shell ejecutándose sobre él.
3. Imagen BC OS descargable y reproducible desde GitHub Releases.

## Criterios para publicar

- Imagen probada en arranque y login.
- SHA256 publicado.
- Notas de versión e instrucciones de instalación.
- Problemas conocidos documentados.
- Nunca se publica como estable algo inacabado.
