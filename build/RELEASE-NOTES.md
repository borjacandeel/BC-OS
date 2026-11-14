## BC OS @VERSION@ (ARM64) — prerrelease alpha, solo pruebas

Imagen de disco arrancable (UEFI, ARM64). **Aún no hay ISO**: el instalador (`sudo bc-install`) viene dentro de la imagen.

### Probar en VirtualBox (Mac Apple Silicon)
1. Descomprime `BC-OS-@VERSION@-ARM64.vdi.zip`.
2. VirtualBox → Nueva: Linux / Arch Linux (ARM 64-bit), ≥ 2 GB RAM, 2 CPU. **Sistema → Habilitar EFI.** Gráficos: VMSVGA.
3. Disco: usar el `.vdi`. Red → Avanzado → Reenvío de puertos: TCP 2222 → 22 si quieres SSH (`ssh -p 2222 bc@127.0.0.1`).
4. Arranca: menú de 5 s con **BC OS** (animación de arranque con el logo, por defecto) y **BC OS (modo seguro, sin animación)**.
5. Aparece el **panel de login**. Usuario `bc`, contraseña `bcos` (**solo alpha**; cámbiala con `passwd`).

### Novedades de 0.3.1
- Terminal por defecto **Alacritty** (translúcida, con respaldo a foot); ventanas de BC con transparencia suave.
- **Cursor tipo macOS** por defecto (tema libre apple_cursor de ful1e5, GPL-3.0).
- **Fondo sin parpadeos** al arrancar y al alternar mosaico/flotante (el fondo lo pinta sway; ya no se recarga la configuración en caliente).
- Dock con ventanas minimizadas; lanzador sin herramientas de desarrollo; instalador al día (dos entradas de arranque, Plymouth).
- Nota: no hay `picom` (es solo para X11); el desenfoque de fondo no está disponible en sway estándar.

### Novedades de 0.3.0: sway, mosaico y atajos
- **Compositor sway**: ventanas **flotantes** (por defecto, como macOS) o en **mosaico** (como bspwm). Botón en la barra superior o `Súper+Mayús+Espacio`.
- Atajos: **Ctrl+Intro** terminal, **Ctrl+B** Firefox, Ctrl+Espacio lanzador, Súper+E Archivos, Súper+Q cerrar, Súper+F pantalla completa, Súper+M minimizar. Lista completa: `/etc/bc/atajos.txt` (Súper+F1).
- **Menús globales tipo macOS** en la barra: nombre de la app enfocada y sus menús (Archivo, Editar, Ver, Ventana, Ayuda); las apps de BC reciben las acciones por D-Bus.
- **Dock con ventanas reales** (puntos de apps abiertas, enfocar al pulsar).
- BC Shell ahora es un panel (layer-shell) más apps en procesos aparte.

### Qué incluye
- **Login gráfico** (greetd + pantalla propia), **bloqueo** (Ctrl+Súper+Q o menú del logo BC), cerrar sesión, reiniciar, apagar y suspender con confirmación.
- **BC Shell**: barra superior y Centro de control con estado real (audio, red, batería, brillo, Bluetooth, No molestar), notificaciones del sistema,
  lanzador con búsqueda (Ctrl+Espacio o icono del Dock), **Archivos** (carpetas reales, nueva carpeta, renombrar, Papelera), **Monitor del sistema**,
  **Configuración**, **Tienda** (pacman), Terminal (`foot`) y Navegador (Firefox).
- Pack de **iconos BC**, fondo BC, animaciones en ventanas, Dock, menús y login (movimiento reducido en Configuración).
- Servicios **BC Core** (Rust, D-Bus) como servicios de usuario, SSH activado y cortafuegos.
- Si el login gráfico fallara 3 veces seguidas, el sistema arranca con **autologin** de `bc` para no quedarte fuera.

### Verificado (QEMU aarch64 UEFI + pruebas automáticas)
- Arranque → login (contraseña buena y mala) → escritorio → bloqueo (PAM) → cerrar sesión → vuelta al login; respaldo de autologin.
- Estado real de red y audio en la sesión; Tienda abierta; firefox y foot instalados.
- `ctest` del shell (carga QML es/en, protocolo greetd, notificaciones D-Bus, Papelera, lanzador, analizadores).

### No verificado / problemas conocidos
- **Esta versión puede no estar probada en VirtualBox ARM64** (las anteriores 0.1.2 y 0.1.3 sí arrancaron).
- Sin hardware real probado con sway; el Dock no muestra ventanas minimizadas.
- El bloqueo es una superposición: no usa `ext-session-lock`, otra ventana podría recibir teclado. Contraseña por defecto pública.
- Música sin implementar; sin tema claro; Wi-Fi/Bluetooth solo probados por sus analizadores (sin hardware en la VM).
- Render por software (VirtualBox no tiene 3D): rendimiento no medido con precisión. RAM en reposo observada: ~250 MB usados tras iniciar sesión (QEMU, 2 GB).

SHA256 del zip en `SHA256SUMS`.
