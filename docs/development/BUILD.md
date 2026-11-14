# Construir BC OS

Estado: serie 0.3.x-alpha. La imagen se construye de extremo a extremo con `build/build-all.sh` + `build/mkimage.sh` y arranca en QEMU aarch64. Esta guía describe el proceso real.

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

## 4. Imagen

Diseño (ADR 0002): disco raw GPT con ESP FAT32 de 512 MiB (`BC-ESP`: systemd-boot, `Image`, `initramfs-linux.img`, entradas de arranque) y partición raíz ext4 (`bc-root`). Se construye **sin montajes loop**: `mke2fs -d`, `mformat`/`mcopy` (mtools), `sfdisk` y `dd`.

## 5. Probar en QEMU

```bash
qemu-system-aarch64 -machine virt -cpu cortex-a72 -m 2048 -smp 2 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/AAVMF/AAVMF_CODE.fd \
  -drive file=bcos.img,format=raw,if=virtio \
  -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -nographic
```

Para pruebas con teclado y capturas usa `tools/qemu/start.sh` (ver `TESTING.md`).

## 6. VirtualBox ARM64

Las imágenes publicadas ya incluyen el `.vdi`; para convertir a mano: `VBoxManage convertfromraw bcos.img bcos.vdi --format VDI`. Activar EFI en la VM. Ver `docs/development/ARM64.md`; compatibilidad **no verificada** desde 0.2.0 (0.1.2/0.1.3 sí arrancaron).

## Reproducibilidad

Entradas fijadas: URL y MD5 del rootfs, lista de paquetes `build/packages/base.txt`, overlay `build/overlay/`. Arch Linux ARM es rolling: dos builds en fechas distintas no son idénticos bit a bit; se registran las versiones de paquetes por build.


## Componentes que construye `build/build-all.sh`

1. `build-shell.sh`: compila `shell/` (BC Shell + `bc-greeter`) **dentro** del rootfs aarch64 (Qt 6, PAM) y lo instala en `/usr`.
2. `build-core.sh`: compila BC Core (Rust) para aarch64 (nativo o compilación cruzada) y habilita sus unidades de usuario.
3. `configure-rootfs.sh`: idioma, usuarios, greetd + respaldo, PipeWire, iconos BC, tema Plymouth, instalador y reducción de tamaño
   (`BC_KEEP_FIRMWARE=1` conserva `linux-firmware`).
4. `mkimage.sh`: GPT (ESP FAT32 + ext4), systemd-boot con las entradas «BC OS» (animación) y «modo seguro».


## Orden real de construcción (resumen)

```bash
# Todo desde cero (root; host aarch64 nativo, o x86_64 con qemu-user-static + binfmt)
sudo build/build-all.sh 0.3.2-alpha /ruta/trabajo      # deja el rootfs en /ruta/trabajo/root, listo
sudo build/mkimage.sh /ruta/trabajo/root bcos.img 6144 # imagen raw GPT (ESP 512 MiB + ext4), sin loop mounts
```

`build-all.sh` encadena, dentro del rootfs aarch64: `pacman -Syu` + `packages/base.txt`, `build-shell.sh`, `build-core.sh`,
`build-swayfx.sh` y `configure-rootfs.sh`. En CI, `.github/workflows/image.yml` hace lo mismo en un runner ARM64 y empaqueta el `.zip`.

### Scripts por separado (iteración rápida sobre un rootfs ya construido)

| Script | Qué hace |
|---|---|
| `build/build-shell.sh <rootfs>` | instala dependencias de `packages/build-deps.txt`, compila `shell/` (BC Shell + `bc-greeter`) en el chroot y lo instala en `/usr`; quita después las dependencias que instaló solo para compilar |
| `build/build-core.sh <rootfs>` | compila BC Core (Rust) y habilita sus unidades de usuario |
| `build/build-swayfx.sh <rootfs>` | compila **swayfx 0.6.1** con meson/ninja en `/opt/swayfx`; el `git clone` se hace en el anfitrión (el chroot no tiene los certificados del proxy). Requiere renderizador GLES2; BC OS solo lo usa si el kernel arranca con `bc.gpu=1` y hay `/dev/dri/renderD*` |
| `build/configure-rootfs.sh <rootfs>` | identidad, locale, usuarios, greetd + respaldo, PipeWire, sway/swaybg/alacritty, cursor `apple_cursor` (GPL-3.0, con aviso en `/usr/share/licenses/bc-cursor-macos/`), overlay, Plymouth, instalador y reducción de tamaño |
| `build/mkimage.sh <rootfs> <img> [MiB]` | ensambla la imagen y copia las tres entradas de arranque: `bcos.conf`, `bcos-seguro.conf` y `bcos-efectos.conf` (`bc.gpu=1`) |

### Variables útiles

- `BC_KEEP_FIRMWARE=1`: conserva todo `linux-firmware` (por defecto se quita el de GPU/CPU x86 y similares para ahorrar tamaño).

### Overlay (`build/overlay/`)

Ficheros que se copian tal cual al rootfs: configuración de sway (`/etc/bc/sway/`), `/etc/bc/atajos.txt`, `/etc/bc/alacritty.toml`, scripts
`bc-session`, `bc-wm-mode`, `bc-ctl`, `bc-terminal`, `bc-greeter-session`, greetd, PAM de bloqueo, nftables, zram y entradas de arranque.
Para cambiar un atajo o el modo de ventanas se edita aquí (o `~/.config/bc/sway-user.conf` en una sesión de prueba).

### Compilar solo BC Shell en el host (desarrollo)

```bash
cmake -S shell -B build-shell -G Ninja && cmake --build build-shell
```
Dependencias: Qt 6 (Quick, Widgets, DBus, LinguistTools), `layer-shell-qt` y PAM. Ver `TESTING.md` para ejecutar las pruebas.
