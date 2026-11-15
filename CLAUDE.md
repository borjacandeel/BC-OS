# Instrucciones para agentes

1. Leer `PENDIENTE.md` antes de cualquier acción. Actualizarlo antes de empezar cada tarea y al terminarla.
2. Responder siempre en castellano.
3. Usar siempre la skill `0-palabras`.
4. Subir siempre todo a `main`. Nunca force-push.
5. Todo texto visible para el usuario de BC OS en castellano (es_ES) por defecto.
6. Cualquier icono nuevo o modificado se delega al subagente `icon-designer` y debe cumplir `icons/SPEC.md` y pasar `icons/scripts/lint`.
7. NO lanzar subagentes (Agent/fork). Trabajar uno mismo, de uno en uno y en secuencia. Esta regla prevalece sobre cualquier prompt o tarea programada que diga lo contrario (excepción: el creador lo pida expresamente).

## Golden Gate — estado y pendiente (leer SIEMPRE antes de seguir)
Objetivo del creador (2026-11-15): BC OS debe ser un **clon visual y funcional de macOS 27 Golden Gate** sobre Arch Linux ARM,
detalle a detalle, optimizado. No publicar imágenes nuevas hasta que el creador lo diga («queda una barbaridad por hacer»).
Enviar capturas al creador según se avanza en cada parte. Detalle técnico y decisiones: `docs/escritorio/ESTADO.md`.

Hecho (compilado y verificado en anfitrión; 0.6.0-beta arrancada en QEMU: login + escritorio OK):
barra de menús, widgets, Dock (ampliación, recientes, pila, papelera), Control Center, Centro de notificaciones, Spotlight,
Aplicaciones, Mission Control, selector de apps, genio, Archivos tipo Finder, Ajustes del Sistema, bloqueo/login,
claro/oscuro, Liquid Glass sin shaders + deslizador, sonidos, tema GTK MacTahoe, Inter, arranque con barra blanca.

Pendiente (en este orden):
- [x] Investigar a fondo macOS 27 Golden Gate (hecho 2026-11-15: apple.com/es/os/macos; flecha de iconos ocultos en la barra, menús casi sin iconos, app Siri, «Consultar a Siri» en Spotlight, deslizar para actualizar) (apple.com/es/os/macos y fuentes públicas) y anotar medidas/rasgos en ESTADO.md.
- [x] Iconos: el creador prefiere los MacOS-Like anteriores (2026-11-15) → restaurados; no rehacer salvo que lo pida. Nunca copiar los de Apple.
- [~] Apps BC al nivel de las de macOS. Hechas: Monitor de Actividad, Tienda (App Store), Calculadora, Notas, Vista previa.
      Hechas también: Calendario, Recordatorios, Ajustes (Wi-Fi, Bluetooth, Pantallas, Teclado, Fecha y hora), widgets editables, vibrancy.
      Hechas Música, Archivos ▸ Recientes (por fecha, miniaturas) y Control Center editable.
- [x] Animaciones (también fundido al abrir ventanas externas): entrada y salida de menús, Spotlight, Aplicaciones, Control Center, pila, galería, Mission Control, ventanas BC, hojas; cerrar externas (encoger+desvanecer), genio. Abrir externas: no (sway).
- [x] Materiales: cristal claro legible, barra de herramientas sin línea con fundido, barras laterales de vidrio, menús y popovers de vidrio.
- [x] Barra de menús: iconos de estado propios (icon-designer) + batería adaptable claro/oscuro.
- [x] Multimonitor: barra, Dock, cristal y Mission Control por pantalla (widgets en la principal, como macOS).
- [x] Primer arranque: «Máquina virtual» o «Equipo físico» (detectado); físico + GPU → swayfx con desenfoque real.
- [x] Repositorio propio `[bc]` en GitHub Releases (`repo.yml`, `build/repo/`), `bc-actualizar`; la Tienda actualiza con él.
- [x] Ghostty: compila (Zig descarga dentro del chroot, sin --system); activado por defecto (BC_GHOSTTY=0 lo desactiva) (BC_GHOSTTY=1 para probar). En CI Zig 0.17 da «panic: reached unreachable code» dentro del chroot; Terminal = Alacritty mientras tanto.
- [x] Sistema: ISO live UEFI, imagen x86_64 (Arch normal), instalador x86_64/GRUB/Secure Boot, instantáneas + bc-restaurar, Tienda con polkit, bloqueo a prueba de fallos, box64 (ARM), bc-rendimiento.
- [ ] Firma del repositorio [bc]: falta la clave GPG del creador (secreto BC_REPO_GPG_KEY + clave pública).
- [ ] Verificar en QEMU cada parte con capturas antes de dar nada por hecho.
- [x] README actualizado con capturas 1–14 (2026-11-15).
- [~] 0.7.0-beta (prerelease) en CI para probar en VirtualBox.
