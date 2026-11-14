# Hoja de ruta de BC OS

Los números de versión son hitos de planificación, no promesas. Estado real en `PENDIENTE.md`.

| Versión | Hito | Contenido principal | Estado |
|---|---|---|---|
| 0.1.x | Fundación | rootfs ARM64, imagen arrancable, locale español, docs; arranca en VirtualBox ARM64 (0.1.2/0.1.3) | hecho |
| 0.2.0 | Escritorio funcional | login greetd, bloqueo, Centro de control, notificaciones, Archivos, Monitor, Configuración, Tienda, BC Core | hecho (QEMU) |
| 0.3.x | sway y personalización | sway flotante/mosaico, atajos, panel + apps, menús globales, Alacritty, cursor macOS, swaybg, minimizar animado, swayfx experimental; estilos BC/Windows/Minimal, Modos, widgets, Flathub, bienvenida | en curso |
| 0.4.0 | Seguridad y pulido | `ext-session-lock`, tema claro, ventanas externas completas en el Dock, polkit en la Tienda | planificado |
| 0.5.0 | Paridad de funciones (inspiración Quantum Linux) | antivirus (ClamAV) y Centro BC, copias antes de actualizar, idiomas es/en/pt-BR | planificado |
| 0.8.0 | Beta | ISO con instalador (GRUB/arranque seguro), optimización, beta pública | planificado |
| 0.x experimental | Compatibilidad | Android con Waydroid, juegos x86 con FEX/box64 (sin Steam/Proton nativos: no hay ARM64) | por hacer, experimental |
| 1.0.0 | Primera estable | criterios de calidad y rendimiento cumplidos y medidos | planificado |

Los hitos 0.4+ son planificación, no promesas. Referencia de funciones: Quantum Linux (solo ideas; ver ADR 0005).

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
