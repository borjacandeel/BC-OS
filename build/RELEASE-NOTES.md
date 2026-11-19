## Novedades de BC OS @VERSION@

**BC Rendering Engine** — *Adaptive. Native. Efficient.*

- **Calidad gráfica automática para todo el sistema.** BC Core detecta CPU, memoria, GPU y su controlador, si es una máquina virtual, la batería, la temperatura y el perfil de energía. Con eso elige un nivel (Ultra, Alto, Equilibrado, Eficiente o Mínimo) para el panel, las apps, el login y el compositor.
- **Se adapta en marcha:**
  - con batería baja (sin cargador) o con el equipo caliente, baja un nivel;
  - si se pierden fotogramas de forma continuada, también baja;
  - cuando todo se normaliza, vuelve al nivel de antes, sin oscilar.
- **Ajustes ▸ Pantallas ▸ Calidad gráfica:**
  - «Automática», o un nivel fijo;
  - muestra el nivel en uso y la GPU;
  - el cambio se aplica al momento, también al desenfoque, las sombras y las animaciones de Hyprland y swayfx.
- **Más ligero en máquinas virtuales sin 3D:**
  - el cristal no calcula la lente;
  - el desenfoque se guarda en disco (el siguiente arranque no lo recalcula);
  - el fondo se decodifica al tamaño de la pantalla;
  - las animaciones son más cortas en los niveles bajos.
- **Backend gráfico por proceso con reserva:** Vulkan → OpenGL → software, según lo que haya de verdad en el equipo.
- **Spotlight y todos los paneles emergentes abren al instante:** cada panel se crea solo al abrirse (antes se reconstruían todos a la vez). Abrir uno pasa de 12–19 ms a 3 ms, y BC Shell usa un 10 % menos de memoria y un 14–20 % menos de CPU al arrancar.
