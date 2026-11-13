# Construir BC OS

Estado: el rootfs se construye y configura; el ensamblado de imagen y su arranque están **en desarrollo** (ver `PENDIENTE.md`). Esta guía describe el proceso real usado hasta ahora.

## Requisitos del host de construcción

Probado en: contenedor Ubuntu 24.04 **x86_64**, 4 CPU, 15 GiB RAM, ≥ 20 GiB libres, ejecución como root.

Paquetes (apt):

```bash
apt-get install -y qemu-user-static qemu-system-arm qemu-utils qemu-efi-aarch64 \
  dosfstools mtools e2fsprogs fdisk libarchive-tools zstd
```

En un host aarch64 nativo no hace falta `qemu-user-static`.

## 1. Rootfs de Arch Linux ARM

```bash
mkdir -p work && cd work
curl -LO http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
curl -LO http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz.md5
md5sum -c ArchLinuxARM-aarch64-latest.tar.gz.md5
mkdir root && bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C root
```

Extraer como root (preserva propietarios y permisos).

## 2. Chroot aarch64

`build/lib/chroot.sh` registra `binfmt_misc` para `qemu-aarch64`, monta `/proc`, `/sys`, `/dev` y ofrece `bc_chroot`:

```bash
source build/lib/chroot.sh
bc_binfmt && bc_mount work/root
bc_chroot work/root pacman-key --init
bc_chroot work/root pacman-key --populate archlinuxarm
bc_chroot work/root pacman -Syu --noconfirm --disable-sandbox
bc_umount work/root
```

`--disable-sandbox` es necesario porque el sandbox de pacman 7 falla bajo qemu-user en contenedores.

## 3. Configuración de BC OS

```bash
sudo bash build/configure-rootfs.sh work/root
```

Aplica: `/etc/os-release` y `/etc/issue` de BC OS, hostname `bcos`, locale `es_ES.UTF-8`, teclado `es`, zona `Europe/Madrid`, plantilla `/etc/skel` en español (Escritorio, Documentos, Descargas, Imágenes, Música, Vídeos, Público, Plantillas), `/home` (0755) y `/root` (0700), usuario `bc` (contraseña temporal caducada), `root` bloqueado, servicios (NetworkManager, timesyncd, resolved, nftables), zram, cortafuegos, initramfs ampliado (virtio, nvme, ahci) y `/etc/fstab` por etiquetas.

## 4. Imagen (en desarrollo)

Diseño (ADR 0002): disco raw GPT con ESP FAT32 de 512 MiB (`BC-ESP`: systemd-boot, `Image`, `initramfs-linux.img`, entradas de arranque) y partición raíz ext4 (`bc-root`). Se construye **sin montajes loop**: `mke2fs -d`, `mformat`/`mcopy` (mtools), `sfdisk` y `dd`.

## 5. Probar en QEMU

```bash
qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 2048 -smp 2 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/AAVMF/AAVMF_CODE.fd \
  -drive file=bcos.img,format=raw,if=virtio \
  -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -nographic
```

(La imagen `bcos.img` aún no existe como entregable verificado.)

## 6. VirtualBox ARM64

Convertir a VDI: `VBoxManage convertfromraw bcos.img bcos.vdi --format VDI`. Activar EFI en la VM. Ver `docs/development/ARM64.md`; compatibilidad **no verificada** todavía.

## Reproducibilidad

Entradas fijadas: URL y MD5 del rootfs, lista de paquetes `build/packages/base.txt`, overlay `build/overlay/`. Arch Linux ARM es rolling: dos builds en fechas distintas no son idénticos bit a bit; se registran las versiones de paquetes por build.
