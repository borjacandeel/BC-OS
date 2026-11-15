#!/usr/bin/env bash
# Genera la imagen raw (ARM64 o x86_64 según BC_ARCH) de BC OS (GPT: ESP FAT32 + root ext4) sin loop mounts.
# Uso: mkimage.sh <rootfs> <salida.img> [tamaño_MiB]
set -euo pipefail
R="${1:?uso: $0 <rootfs> <salida.img> [MiB]}"; OUT="${2:?}"; SIZE="${3:-6144}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ESP_MIB=512
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Raíz sin /boot (el ESP se monta en /boot)
mkdir -p "$TMP/root"
rsync -aHAX --exclude='/boot/*' --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' --exclude='/tmp/*' \
  --exclude='/var/cache/pacman/pkg/*' "$R"/ "$TMP/root"/
mkdir -p "$TMP/root"/{proc,sys,dev,run,tmp,boot}; chmod 1777 "$TMP/root/tmp"

# ESP: systemd-boot + kernel + initramfs + entradas
ESP="$TMP/esp.img"; truncate -s "${ESP_MIB}M" "$ESP"
mkfs.vfat -F32 -n BC-ESP "$ESP" >/dev/null
export MTOOLS_SKIP_CHECK=1
mmd -i "$ESP" ::/EFI ::/EFI/BOOT ::/loader ::/loader/entries
mcopy -i "$ESP" "$HERE/overlay/boot/loader/loader.conf" ::/loader/loader.conf
mcopy -i "$ESP" "$R/boot/initramfs-linux.img" ::/initramfs-linux.img
if [ "${BC_ARCH:-aarch64}" = x86_64 ]; then
  # x86_64 (VirtualBox con EFI activado): kernel vmlinuz-linux y consola serie ttyS0
  mcopy -i "$ESP" "$R/usr/lib/systemd/boot/efi/systemd-bootx64.efi" ::/EFI/BOOT/BOOTX64.EFI
  mcopy -i "$ESP" "$R/boot/vmlinuz-linux" ::/vmlinuz-linux
  for e in bcos bcos-seguro; do
    sed 's|^linux .*|linux   /vmlinuz-linux|; s|ttyAMA0|ttyS0|' "$HERE/overlay/boot/loader/entries/$e.conf" > "$TMP/$e.conf"
    mcopy -i "$ESP" "$TMP/$e.conf" ::/loader/entries/$e.conf
  done
else
  mcopy -i "$ESP" "$R/usr/lib/systemd/boot/efi/systemd-bootaa64.efi" ::/EFI/BOOT/BOOTAA64.EFI
  mcopy -i "$ESP" "$R/boot/Image" ::/Image
  mcopy -i "$ESP" "$HERE/overlay/boot/loader/entries/bcos.conf" ::/loader/entries/bcos.conf
  mcopy -i "$ESP" "$HERE/overlay/boot/loader/entries/bcos-seguro.conf" ::/loader/entries/bcos-seguro.conf
fi
# La entrada de efectos (swayfx, bc.gpu=1) no se incluye: falla en VirtualBox. Se puede activar a mano añadiendo bc.gpu=1 en el editor de arranque.

# Root ext4 poblada con mke2fs -d
ROOT_MIB=$((SIZE - ESP_MIB - 2))
ROOTIMG="$TMP/root.img"; truncate -s "${ROOT_MIB}M" "$ROOTIMG"
mkfs.ext4 -q -L bc-root -d "$TMP/root" "$ROOTIMG"
rm -rf "$TMP/root"

# Ensamblado GPT
truncate -s "${SIZE}M" "$OUT"
sfdisk -q "$OUT" <<E
label: gpt
unit: sectors
first-lba: 2048
start=2048, size=$((ESP_MIB*2048)), type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="BC-ESP"
start=$((2048+ESP_MIB*2048)), type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="bc-root"
E
dd if="$ESP" of="$OUT" bs=1M seek=1 conv=notrunc status=none
dd if="$ROOTIMG" of="$OUT" bs=1M seek=$((1+ESP_MIB)) conv=notrunc status=none
sha256sum "$OUT" | tee "$OUT.sha256"
echo "Imagen lista: $OUT"
