# ARM64 en BC OS

BC OS apunta **solo a aarch64** en la versión inicial. Hay cuatro piezas distintas que se validan por separado:

| Pieza | Descripción | Estado |
|---|---|---|
| Host de desarrollo del creador | Mac Apple Silicon (ARM64) | por inspeccionar con `tools/host-check.sh` |
| Entorno de construcción | contenedor x86_64 + qemu-user + chroot aarch64 (o runner ARM64 de CI) | funcionando para el rootfs |
| Distribución | Arch Linux ARM aarch64 | rootfs descargado, actualizado y configurado |
| Imagen descargable | disco raw GPT arrancable por UEFI | en desarrollo |
| VM de prueba | VirtualBox ARM64 en macOS | **sin verificar** |

## Arch Linux ARM

- Repositorios y rootfs: `os.archlinuxarm.org`, `mirror.archlinuxarm.org`. Rolling, mantenido por la comunidad.
- No se usa Archiso: no proporciona imagen ARM64 soportada oficialmente. Se parte del rootfs genérico `ArchLinuxARM-aarch64-latest.tar.gz`.
- Kernel: `linux-aarch64` (kernel Image ARM64, EFI stub). Sin kernel propio.
- Paquetes de Arch x86_64 no son aplicables; las instrucciones de la wiki de Arch deben adaptarse.

## Arranque

UEFI → systemd-boot (`systemd-bootaa64.efi`, incluido en el paquete `systemd`) → `Image` + `initramfs-linux.img` desde la ESP. No se necesita DTB en plataformas UEFI/ACPI como QEMU `virt` o VirtualBox ARM64 (a confirmar al probar). Placas reales (Raspberry Pi, etc.) quedan fuera del alcance inicial.

## VirtualBox ARM64 (macOS Apple Silicon)

Hechos a verificar por el creador con `tools/host-check.sh`:

- Versión de VirtualBox con soporte de invitados ARM64 (7.1+ en macOS ARM). Confirmar con `VBoxManage --version`.
- Firmware: EFI obligatorio; activar en la VM.
- Controladora: NVMe o SATA/AHCI; el initramfs ya incluye `nvme`, `ahci`, `virtio_*`.
- Gráficos: **no asumir aceleración 3D** en el invitado ARM64. Hay que probar qué adaptador gráfico y qué driver funcionan (`virtio-gpu`, `VMSVGA`, framebuffer simple). Hasta confirmarlo, el shell debe poder ejecutarse con render por software (`QT_QUICK_BACKEND=software`, `LIBGL_ALWAYS_SOFTWARE=1`) y las transparencias con desenfoque se desactivan (ver design system §7).
- Conversión: `VBoxManage convertfromraw bcos.img bcos.vdi --format VDI`.

## Alternativas si VirtualBox falla

QEMU con HVF (`-accel hvf`) o UTM en el mismo Mac; se documentarán como vías de prueba equivalentes. No se promete rendimiento gráfico nativo en virtualización.

## Cross-compilación y CI

- Rust: `aarch64-unknown-linux-gnu`; preferible compilar dentro del chroot aarch64 o en runner ARM64 nativo.
- Qt/QML: compilar contra el sysroot del rootfs aarch64 (chroot con qemu-user es lento pero válido).
- GitHub Actions: usar runners ARM64 nativos (`ubuntu-24.04-arm`) cuando estén disponibles para el repositorio; **no** presentar un build x86_64 como ARM64.
