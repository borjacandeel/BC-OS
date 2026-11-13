# ADR 0001 — Base: Arch Linux ARM (aarch64)

- Estado: aceptada
- Fecha: 2026-11-13

## Contexto

BC OS necesita una base Linux aarch64 ligera, actual y con pacman, mantenible por una sola persona, con Wayland, Mesa, PipeWire y Qt 6 recientes.

## Opciones

| Opción | A favor | En contra |
|---|---|---|
| **Arch Linux ARM** | rolling, paquetes recientes (Qt 6, Mesa, Wayland), mínimo, pacman, rootfs genérico aarch64 | repositorio comunitario con menos garantías que Arch x86_64; sin Archiso ARM64 oficial; requiere cuidar roturas rolling |
| Debian/Ubuntu arm64 | estable, amplio soporte | versiones más antiguas de Qt/Mesa; más pesado; apt/debootstrap |
| Alpine aarch64 | muy ligero | musl complica Qt/Mesa/drivers; no pacman |
| Construir desde cero (LFS/Yocto) | control total | coste de mantenimiento inasumible |

## Decisión

Base **Arch Linux ARM aarch64**, partiendo de `ArchLinuxARM-aarch64-latest.tar.gz` verificado con su MD5 publicado. Kernel de distribución `linux-aarch64` sin modificar. systemd, PipeWire, NetworkManager, nftables, zram. Gestión de paquetes con pacman; no se crea formato de paquete propio.

## Consecuencias

- No se usa Archiso (no ofrece imagen ARM64 soportada): se construye la imagen a partir del rootfs (ADR 0002).
- Al ser rolling, los builds no son idénticos bit a bit; se registran versiones y se fija el rootfs por build.
- El keyring `archlinuxarm` debe inicializarse en cada rootfs (`pacman-key --init/--populate`).
- Riesgo: dependencia de la salud del proyecto Arch Linux ARM; se mitiga aislando el pipeline para poder cambiar de base (el overlay y los scripts son específicos de BC OS).
- Verificado hasta ahora: el rootfs se descarga, se ejecuta en chroot bajo qemu-user, `pacman -Syu` y la instalación de paquetes base funcionan, y se genera initramfs.
