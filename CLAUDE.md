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
- [ ] Investigar a fondo macOS 27 Golden Gate (apple.com/es/os/macos y fuentes públicas) y anotar medidas/rasgos en ESTADO.md.
- [ ] Iconos: el creador pide «iguales que los de Golden Gate». NO se copian los de Apple (son obras protegidas):
      se diseñan propios con la misma rejilla/forma/capas (squircle, vidrio por capas, claro/oscuro/tintado) vía `icon-designer`
      (regla 6) — requiere permiso explícito para ese subagente (regla 7).
- [ ] Apps BC al nivel de las de macOS: Archivos (Finder), Ajustes del Sistema (todos los paneles), Monitor de Actividad,
      Tienda (App Store), Terminal, Vista previa/visor de imágenes, Notas, Calculadora, Calendario, Música.
- [ ] Animaciones: abrir/cerrar ventanas BC, hojas, menús, Control Center, Mission Control, Launchpad/Aplicaciones, Spotlight.
- [ ] Transparencias y materiales por componente (barra lateral, barra de herramientas, menús, popovers) en claro y oscuro.
- [ ] Barra de menús: iconos de estado propios exactos en forma/tamaño (Wi-Fi, batería, Control Center, Concentración, Spotlight).
- [ ] Verificar en QEMU cada parte con capturas antes de dar nada por hecho.
- [ ] README actualizado con capturas (subagente pedido por el creador, 2026-11-15).
