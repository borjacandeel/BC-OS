## Novedades de BC OS @VERSION@

Llegan también a los equipos instalados con `sudo bc-actualizar` (después, reinicia).

**Fluidez (tirones en gráficas Intel)**
- La gráfica Intel ya no baja a ~300 MHz entre fotogramas: su frecuencia mínima sube a 500 MHz (servicio `bc-gpu-freq`). Es el arreglo que recomienda la wiki de Hyprland para los tirones y las caídas a 20–40 fps en gráficas Intel integradas.
- Sombras de las ventanas más ligeras en gráficas integradas (14 px en vez de 26), que era lo que más costaba. Con gráfica dedicada siguen grandes.
- Hyprland sin triple búfer automático: iba más fluido en la Intel HD 620.
- Sin animaciones dobles: Hyprland ya no funde los menús, Spotlight, Mission Control, avisos y demás capas que el escritorio anima por su cuenta.
- **Causa principal de los tirones, corregida:** en reposo, el escritorio a pantalla completa, la barra y el Dock se redibujaban enteros varias veces por segundo. Cada aviso del compositor, aunque no cambiara nada, hacía que Qt redibujara toda la superficie. Ahora esos avisos repetidos se descartan.
  - Medido en un compositor Wayland real: de ~2 redibujados por segundo por superficie a ninguno.
  - Spotlight, el Centro de control y los menús se siguen dibujando igual.
- El panel ya no reenvía a Hyprland la configuración entera de sus capas al abrir un menú. Cada envío hacía que se redibujaran el escritorio, la barra y el Dock.
- Sway (máquinas virtuales): consultas al compositor por su socket, sin lanzar `swaymsg`.
- El panel ya no lanza procesos desde el hilo que dibuja:
  - consulta a Hyprland por su socket;
  - volumen, red, Bluetooth, brillo y música, en un hilo aparte;
  - el widget de baterías ya no bloquea la interfaz hasta 1,5 s cada minuto.
- Los ajustes y los recordatorios solo se recargan si cambian de verdad.
- Nueva orden `bc-diagnostico-fps`: muestra cuántas veces por segundo dibuja cada parte del escritorio y si es el compositor quien lo provoca.

**Detalles de macOS**
- El Dock rebota el icono de una app que pide atención (mensaje nuevo, descarga terminada…).
- Cursor de texto del color de acento con parpadeo suave en todos los campos.
- Ajustes del Sistema: la página nueva entra con un leve deslizamiento.
- Menús con los atajos en el orden de macOS (⌃⌥⇧⌘) y ⎋ para Esc.

**Arreglos**
- Animaciones revisadas fotograma a fotograma:
  - el Centro de notificaciones ya no cruza media pantalla al abrirse: entra desde la derecha;
  - la barra de capturas (⌘⇧5) tampoco cruza la pantalla;
  - el portapapeles y el lanzador ya no aparecen de golpe;
  - las animaciones de entrada siguen el nivel gráfico del equipo.
- El portapapeles tiene cristal como el resto de paneles.
- El aviso emergente ya no queda encimado al Centro de control.
- El widget de música del Centro de control vuelve a mostrar lo que suena.
- Al actualizar, los equipos con systemd-boot pasan una vez al GRUB de BC OS con su tema (UEFI x86_64 sin Secure Boot). Para evitarlo: `sudo touch /etc/bc/sin-grub`.
- `bc-actualizar` aplica sus novedades en la misma actualización, no en la siguiente.
