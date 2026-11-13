# ADR 0002 — Imagen raw GPT con systemd-boot, construida sin montajes loop

- Estado: aceptada (implementación en curso)
- Fecha: 2026-11-13

## Contexto

El entregable es una imagen ARM64 arrancable por UEFI, probable en QEMU y VirtualBox ARM64. El entorno de construcción puede ser un contenedor sin garantías de `losetup`/`mount` (privilegios), por lo que conviene no depender de montajes loop.

## Opciones de formato

| Opción | Nota |
|---|---|
| ISO live estilo Archiso | no hay soporte ARM64 oficial; complejo |
| **Imagen de disco raw GPT** | simple, convertible a VDI/VMDK/qcow2, arrancable por UEFI |
| Imágenes específicas de placa (U-Boot, Raspberry Pi) | fuera del alcance inicial |

## Opciones de bootloader

| Opción | Nota |
|---|---|
| **systemd-boot** | `systemd-bootaa64.efi` ya viene en el paquete `systemd`; configuración mínima; arranca el kernel EFI stub |
| GRUB | más pesado y complejo, sin beneficio inicial |

## Decisión

Disco raw con tabla **GPT**:

1. **ESP** FAT32, 512 MiB, etiqueta `BC-ESP`, montada en `/boot`: `EFI/BOOT/BOOTAA64.EFI` (systemd-boot), `loader/loader.conf`, `loader/entries/bcos.conf`, `Image`, `initramfs-linux.img`.
2. **Raíz** ext4, etiqueta `bc-root`, resto del disco.

Cmdline: `root=LABEL=bc-root rw quiet loglevel=3 console=tty0 console=ttyAMA0`. `/etc/fstab` por etiquetas.

Construcción **sin loop mounts**: crear ficheros de partición, `mke2fs -d <árbol>` para la raíz (excluyendo `/boot`), `mformat` + `mcopy` (mtools) para la ESP, `sfdisk` para la GPT y ensamblado con `dd`. Después, conversión opcional (`qemu-img`/`VBoxManage convertfromraw`).

## Consecuencias

- Funciona en contenedores sin privilegios de loop; reproducible en CI.
- El initramfs se genera sin `autodetect` e incluye `virtio_blk`, `virtio_pci`, `nvme`, `ahci`, `vfat`, `ext4` para que arranque en distintos hipervisores.
- Pendiente de verificar: arranque real en QEMU (AAVMF) y en VirtualBox ARM64; ajuste de consola serie y gráfica.
- El instalador (fase 7) reutilizará la misma disposición de particiones, con cifrado LUKS2 opcional.
