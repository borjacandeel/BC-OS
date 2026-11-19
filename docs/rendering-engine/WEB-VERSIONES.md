# Texto para la web (bcos/index.html ▸ Versiones)

Sin aplicar: la web está en otro repositorio y el encargo del motor de render prohibía tocarla. Hay que copiarlo a mano.

**0.9.20-beta — BC Rendering Engine.**

- Calidad gráfica automática para todo el sistema. BC OS detecta la GPU, si es una máquina virtual, la batería y la temperatura, y elige el nivel: Ultra, Alto, Equilibrado, Eficiente o Mínimo.
- Baja solo si se pierden fotogramas, y vuelve cuando todo va bien.
- Se elige en Ajustes ▸ Pantallas ▸ Calidad gráfica.
- Los efectos de Hyprland y swayfx se ajustan al nivel.
- Más ligero en máquinas virtuales: el desenfoque se guarda en disco y el fondo se decodifica al tamaño de la pantalla.

Captura: `docs/escritorio/capturas/calidad-grafica.png`.

**0.9.21-beta.** Spotlight y todos los paneles emergentes abren al instante (3 ms en vez de 12–19 ms). BC Shell usa un 10 % menos de memoria y un 14–20 % menos de CPU al arrancar, y el Dock ya no pierde fotogramas.

**0.9.22-beta.** Más fluido con NVIDIA nouveau, panel más ligero en GPU lentas (un solo contexto de dibujo) y Ajustes ▸ Aspecto sin solapes.
