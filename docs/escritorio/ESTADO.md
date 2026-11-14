# Escritorio «Golden Gate» de BC OS — estado y decisiones

Objetivo (encargo del creador, 2026-11-15): que el escritorio por defecto de BC OS se vea y se comporte como
macOS 27 Golden Gate, sobre la misma base (Arch Linux ARM, sway, BC Shell Qt6/QML), con la sesión anterior
disponible en el login como **«BC clásico»**.

## Auditoría (punto de partida)
- Compositor: **sway** (wlroots). Render por software (pixman) en VirtualBox/QEMU; swayfx opcional con GPU (`bc.gpu=1`).
- Shell: **BC Shell** (Qt 6 / QML). Panel = superficies wlr-layer-shell (fondo, barra, Dock, emergentes);
  apps BC = procesos `bc-shell --app …`. Control por D-Bus `org.bcos.Shell` (`bc-ctl`). Ventanas vía IPC de sway.
- Sesión: greetd + `bc-greeter` → `bc-session` → `bc-wm-mode` monta la config de sway.
- Reutilizable: todo (SwayControl, SystemStatus, Notificaciones, FileBrowser, AppIndex, LayerWindow…).

## Decisiones
1. **No se cambia compositor, toolkit ni gestor de sesión.** Justificación: sway + Qt ya dan superficies por capas,
   IPC y rendimiento en ARM; cambiar a KWin/Hyprland rompería el arranque probado y exige GPU.
2. **Liquid Glass sin shaders**: en VirtualBox Qt usa el renderizador por software (sin `ShaderEffect`). El fondo se
   desenfoca una vez en C++ (`GlassProvider`, reducción/ampliación suave ≈ gaussiano) y cada superficie pide su recorte
   ya redondeado (`image://glass/…`). Encima: tinte (deslizador), reflejo especular, borde luminoso y sombra (`Glass.qml`).
   Limitación: el cristal refleja el **fondo**, no las ventanas que tenga detrás (un cliente Wayland no puede leer
   otras superficies; solo el compositor: swayfx `blur` con GPU).
3. **Tokens únicos en `shell/qml/Theme.qml`** (medidas de la captura, colores claro/oscuro, cristal, duraciones y curvas).
   Iba a ser `Tokens.qml`, pero Qt 6.4 detecta un ciclo entre dos singletons que importan el módulo: se fusionó en Theme.
4. **Tipografía**: Inter (OFL) en la interfaz por métricas cercanas a SF Pro; CaskaydiaCove Nerd Font en terminal y
   monoespaciada (antes era la fuente de todo el sistema: cambia por fidelidad con la captura).
5. Recursos: logo BC en lugar del de Apple; iconos MacOS-Like (GPL-3.0) y cursores McMojave (GPL-3.0); fondo «Ondas» propio.

## Estado por componente
| # | Componente | Estado |
|---|---|---|
| — | Tokens, ajustes en caliente (aspecto, cristal, Dock, widgets, sonidos) | hecho, compilado |
| 17 | Material Liquid Glass + deslizador | en curso |
| 2 | Widgets: baterías (sysfs + BlueZ), recordatorios (JSON), widgets de otras apps (JSON) | backend hecho |
| 3 | Barra superior | pendiente |
| 5 | Dock | pendiente |

## Volver a la sesión anterior
En la pantalla de inicio de sesión, elegir **«BC clásico»** (misma sesión sway con `BC_CLASSIC=1`: barra, Dock y
widgets anteriores).
