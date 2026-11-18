## Novedades de BC OS @VERSION@
- **Fluidez**: en máquinas virtuales vuelve sway con pixman (con swayfx por software todo iba a golpes); genio al
  minimizar 4 veces más ligero; el cristal no recalcula la lente mientras cambia de tamaño; cerrar y agrandar ventanas
  con fundido por software.
- **PCs reales (x86_64)**: firmware de gráficas AMD, NVIDIA e Intel, Vulkan, vídeo por hardware y microcódigo de la CPU.
- **Dock**: globo rojo con el número de avisos de cada app, como macOS.
- **Escritorio**: nombre seleccionado en óvalo azul.
- **Liquid Glass con tinte ambiental**: el cristal toma un poco del color del fondo de pantalla.
- **Fondos dinámicos**: los fondos con versión de día y de noche (bosque, lago, pinar, nieve, salvia, dunas) cambian solos con el aspecto claro/oscuro.
- **Privacidad**: punto naranja en la barra mientras se usa el micrófono y verde con la cámara.
- **Dock**: barra de progreso sobre el icono de la Tienda mientras instala.
- **Mission Control**: soltar una ventana en «+» crea un escritorio nuevo con ella.
- **Accesibilidad** (Ajustes ▸ Aspecto): «Reducir transparencia» (cristal opaco) y «Aumentar contraste» (bordes marcados).
- **Captura de zona** como macOS: pantalla oscurecida, zona elegida iluminada y con sus medidas.
- **Claro ↔ oscuro con fundido suave** de los colores, como macOS.
- **Sin tirones al cambiar ajustes**: el cristal solo se recalcula al cambiar el fondo de pantalla (antes con cualquier ajuste).
- **Terminal**: el botón verde y el doble clic en la barra ocupan la pantalla y vuelven al tamaño anterior.
- **Microcortes en VirtualBox**: el escritorio ya no se queda cada 2 s solo con el fondo y los widgets (sin ventanas, barra ni Dock); en VirtualBox/VMware se usa la API clásica de pantalla.
- **Máquinas virtuales sin GPU**: sin lente del cristal ni genio/cierre animado (consumían la CPU que necesita el compositor y VirtualBox enseñaba fotogramas a medias al pasar por el Dock o minimizar).
