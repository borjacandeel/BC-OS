## Novedades de BC OS @VERSION@

**Fluidez**
- El efecto genio al minimizar lo dibuja la GPU con una malla deformada, en vez de la CPU píxel a píxel.
- Hyprland en gráficas integradas: el cristal desenfoca solo el fondo de pantalla (calculado una vez), sombras más ligeras y capas con fundido. En una Intel HD 620 antes no pasaba de 30 fps.
- Animaciones casi instantáneas como en macOS: las de Hyprland duran entre 120 y 280 ms (antes hasta 600 ms) y las del escritorio son un 25–40 % más cortas, al ritmo real del monitor.
- Los relojes se actualizan una vez por minuto, no cada segundo, así que el escritorio no se redibuja sin motivo.
- Spotlight y los paneles abren al instante.
- Spotlight, Aplicaciones y Archivos buscan los iconos una sola vez (antes, hasta ~100 accesos a disco por icono al escribir o desplazarse).
- La búsqueda de archivos de Spotlight no se acumula mientras escribes.
- Con Hyprland, el panel no se satura cuando una app cambia su título sin parar (terminales, navegadores), y no se pierden aperturas ni cambios de foco.
- Arrastrar y redimensionar ventanas va pegado al ratón.
- Las apps BC no repiten la animación que ya hace Hyprland.

**Nuevo**
- **Capturas como en macOS**:
  - ⌘⇧3: toda la pantalla.
  - ⌘⇧4: arrastra una zona o haz clic en una ventana.
  - ⌘⇧5: panel con captura de pantalla, ventana o selección, grabación de vídeo, temporizador y dónde guardar.
  - Con ⌃: solo al portapapeles.
  - Mientras grabas, sale un botón ⏹ en la barra.
- **GRUB personalizado de BC OS**: fondo, logo, letra Inter y selección de cristal. Viene de serie al instalar y en la ISO. En un equipo ya instalado se pone con `sudo bc-grub instalar`.
- **Energía como en macOS**: apagar la pantalla y reposo por inactividad, con tiempos distintos con batería y con cargador (Ajustes ▸ Batería y energía).
- **Actualización automática diaria**: sin descargar ISOs nuevas. Avisa cuando hay que reiniciar.
- **Batería de la barra** minimalista y **icono de Ethernet** «< ··· >».
- **Barra lateral flotante** de cristal en todas las apps.
- **Atajos iguales en todos los entornos**:
  - ⌘W cierra la ventana;
  - ⌘Intro abre la Terminal;
  - ⌘B abre Firefox;
  - ⌘1…9 cambia de escritorio y ⌘⌥1…9 lleva la ventana allí;
  - bspwm usa también la tecla ⌘ (antes Ctrl).

**Arreglos**
- Las ventanas nuevas quedan activas y se traen delante al elegirlas en el Dock o con ⌘Tab.
- Los iconos de las apps externas son los originales (Claude, VS Code, Flatpak…).
- Apps Electron con su propio marco.
- Wi-Fi: la contraseña ya no queda oculta y ya no se borra la red guardada en conexiones lentas.
- Sin avisos de Hyprland en pantalla.
- `bc-actualizar` solo pide reiniciar si ha cambiado algo.
- Controladores completos en cada equipo: región Wi-Fi, sonido de portátil, Bluetooth, Vulkan y VA-API.
- Servicios de BC Core estables.
- Pantalla que se apaga por inactividad también en Hyprland.
- La ISO incluye todas las órdenes de BC OS.
- Cambiar entre ventanas flotantes y mosaico funciona en Hyprland.
