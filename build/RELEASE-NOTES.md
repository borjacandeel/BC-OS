## BC OS @VERSION@ (ARM64) — prerrelease alpha, solo pruebas

Imagen de disco arrancable (UEFI, ARM64). **Aún no hay ISO**: el instalador (`sudo bc-install`) viene dentro de la imagen.

### Probar en VirtualBox (Mac Apple Silicon)
1. Descomprime `BC-OS-@VERSION@-ARM64.vdi.zip`.
2. VirtualBox → Nueva: Linux / Arch Linux (ARM 64-bit), ≥ 2 GB RAM, 2 CPU. **Sistema → Habilitar EFI.** Gráficos: VMSVGA.
3. Disco: usar el `.vdi`. Red → Avanzado → Reenvío de puertos: TCP 2222 → 22 si quieres SSH.
4. Arranca. En el menú de arranque (5 s) hay dos entradas:
   - **BC OS** (por defecto, segura).
   - **BC OS (con animación de arranque)**: logo BC con barra de progreso. **Experimental: no probada en imagen completa.** Si no arranca, reinicia y elige la primera.
5. Sesión automática como `bc` (contraseña `bcos`, **solo alpha**). SSH: `ssh -p 2222 bc@127.0.0.1`.

### Qué incluye
- BC Shell con layout adaptable, Dock que abre Terminal (`foot`) y Archivos con carpetas reales, fondo BC y pack de iconos BC.
- Render por software (VirtualBox no tiene 3D).

### Verificado
- Arranque en QEMU aarch64 UEFI; `0.1.2-alpha` arrancó en VirtualBox ARM64.
- Tests del shell (7/7) con capturas offscreen.

### No verificado / problemas conocidos
- **Esta versión aún no se ha probado en VirtualBox.**
- Configuración, Monitor, Tienda, Navegador, Música y Papelera solo muestran "En desarrollo"; el Centro de control no tiene estado real.
- Sin pantalla de login ni de bloqueo todavía. Contraseña por defecto pública.
- Rendimiento no medido.

SHA256 del zip en `SHA256SUMS`.
