## BC OS 0.1.0-alpha (ARM64) — prerrelease, solo pruebas

Imagen de disco arrancable (UEFI, ARM64). **No es una ISO ni tiene instalador todavía.**

### Probar en VirtualBox (Mac Apple Silicon)
1. Descomprime `BC-OS-0.1.0-alpha-ARM64.vdi.zip`.
2. VirtualBox → Nueva: Tipo Linux, versión Arch Linux (ARM 64-bit), 2 GB RAM mínimo, 2 CPU.
3. Disco: usar disco existente → el `.vdi`. Activa EFI en Sistema. Gráficos: VMSVGA, 128 MB.
4. Arranca. Autologin como `bc` (contraseña `bcos`, solo alpha) y se abre BC Shell.

### Verificado
- Arranca en QEMU aarch64 + UEFI y muestra BC Shell sobre labwc (Wayland, render por software).

### No verificado / problemas conocidos
- **No probado en VirtualBox ARM64.**
- Sin instalador, sin ISO. Contraseña por defecto pública.
- El shell es un prototipo visual (maqueta QML): el layout está pensado para 1586x992 y se solapa en pantallas menores; Dock/Archivos/Centro de control aún no son funcionales.
- Rendimiento no medido.

SHA256 del zip en `SHA256SUMS`.
