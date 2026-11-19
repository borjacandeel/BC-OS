## Novedades de BC OS @VERSION@

- **Más fluido con gráficas NVIDIA (controlador nouveau).** nouveau deja la gráfica a su velocidad mínima, así que ahora el nivel automático es «Eficiente»: sin lente ni genio, una sola sombra y animaciones algo más cortas. Si lo fuerzas en Ajustes, se queda como mucho en «Equilibrado». Antes se ponían efectos de gráfica rápida y las animaciones iban a tirones.
- **Panel más ligero en equipos con GPU lenta.** El panel tiene muchas ventanas (barra, Dock, widgets, paneles emergentes). Con nouveau, o en los niveles Eficiente y Mínimo, todas comparten un solo hilo y un solo contexto de dibujo, en vez de uno por ventana. Antes había equipos con 25 hilos y 456 MB.
- **Ajustes ▸ Aspecto:**
  - el color de resaltado se elige con muestras de color y ya no pisa su etiqueta;
  - las opciones en pastillas se estrechan si no caben;
  - la miniatura «Automático» ya no sale cortada.
