#!/usr/bin/env bash
# ISO live de BC OS (UEFI) a partir del rootfs ya configurado: el sistema arranca desde un squashfs en RAM con los
# ganchos de archiso (mkinitcpio-archiso) y trae el instalador (sudo bc-install). Funciona en VirtualBox con EFI
# activado y en USB (dd). Uso: mkiso.sh <rootfs> <salida.iso>
set -euo pipefail
R="$(realpath "${1:?uso: $0 <rootfs> <salida.iso>}")"; OUT="$(realpath -m "${2:?}")"
HERE="$(cd "$(dirname "$0")" && pwd)"
ARCH="${BC_ARCH:-aarch64}"; LABEL="BCOS_LIVE"
source "$HERE/lib/chroot.sh"
if [ "$ARCH" = x86_64 ]; then KIMG=vmlinuz-linux; EFI=systemd-bootx64.efi; EFIN=BOOTX64.EFI; CON="console=tty0 console=ttyS0"
else KIMG=Image; EFI=systemd-bootaa64.efi; EFIN=BOOTAA64.EFI; CON="console=tty0 console=ttyAMA0"; fi
T="$(mktemp -d)"; trap 'bc_umount "$R" 2>/dev/null || true; rm -rf "$T"' EXIT

# 1) initramfs live con los ganchos de archiso (squashfs + capa en RAM)
bc_binfmt; bc_mount "$R"
# La imagen se entrega sin las bases de datos de paquetes (se borran para ahorrar espacio): se descargan aquí
bc_chroot "$R" bash -c "pacman -Sy --needed --noconfirm --disable-sandbox mkinitcpio-archiso squashfs-tools && rm -rf /var/lib/pacman/sync/* /var/cache/pacman/pkg/*"
cat > "$R/etc/mkinitcpio-live.conf" <<C
MODULES=(virtio_blk virtio_pci virtio_scsi virtio_gpu nvme ahci xhci_pci usb_storage uas sr_mod isofs squashfs overlay loop vfat ext4)
HOOKS=(base udev modconf kms memdisk archiso archiso_loop_mnt block filesystems keyboard)
COMPRESSION=zstd
C
bc_chroot "$R" bash -c "mkinitcpio -c /etc/mkinitcpio-live.conf -k /boot/$KIMG -g /boot/initramfs-live.img"
cp "$R/boot/initramfs-live.img" "$T/initramfs-live.img"; rm -f "$R/boot/initramfs-live.img" "$R/etc/mkinitcpio-live.conf"
bc_umount "$R"

# En live no hay particiones propias: fstab vacío (la imagen de disco ya se generó antes con el suyo)
printf '# BC OS live: la raíz la monta archiso\n' > "$R/etc/fstab"
# 2) raíz en squashfs (zstd), en la ruta que espera archiso: /arch/<arch>/airootfs.sfs
mkdir -p "$T/iso/arch/$ARCH"
mksquashfs "$R" "$T/iso/arch/$ARCH/airootfs.sfs" -comp zstd -Xcompression-level 15 -b 1M -noappend -quiet \
  -e proc sys dev run tmp var/cache/pacman/pkg
sha512sum "$T/iso/arch/$ARCH/airootfs.sfs" | sed "s| .*/| |" > "$T/iso/arch/$ARCH/airootfs.sha512"

# 3) imagen EFI (FAT) con systemd-boot, kernel e initramfs live
ESZ=$(( ( $(stat -c %s "$R/boot/$KIMG") + $(stat -c %s "$T/initramfs-live.img") ) / 1048576 + 24 ))
truncate -s "${ESZ}M" "$T/efiboot.img"; mkfs.vfat -F32 -n BCOS_EFI "$T/efiboot.img" >/dev/null
export MTOOLS_SKIP_CHECK=1
mmd -i "$T/efiboot.img" ::/EFI ::/EFI/BOOT ::/loader ::/loader/entries
mcopy -i "$T/efiboot.img" "$R/usr/lib/systemd/boot/efi/$EFI" "::/EFI/BOOT/$EFIN"
mcopy -i "$T/efiboot.img" "$R/boot/$KIMG" "::/$KIMG"
mcopy -i "$T/efiboot.img" "$T/initramfs-live.img" ::/initramfs-live.img
printf 'default live.conf\ntimeout 5\nconsole-mode max\n' > "$T/loader.conf"
OPTS="archisobasedir=arch archisolabel=$LABEL rw quiet splash plymouth.ignore-serial-consoles $CON lang=es_ES"
printf 'title   BC OS (live)\nlinux   /%s\ninitrd  /initramfs-live.img\noptions %s\n' "$KIMG" "$OPTS" > "$T/live.conf"
printf 'title   BC OS (live, modo seguro)\nlinux   /%s\ninitrd  /initramfs-live.img\noptions %s\n' "$KIMG" "${OPTS/quiet splash/plymouth.enable=0}" > "$T/live-seguro.conf"
mcopy -i "$T/efiboot.img" "$T/loader.conf" ::/loader/loader.conf
mcopy -i "$T/efiboot.img" "$T/live.conf" "$T/live-seguro.conf" ::/loader/entries/
mkdir -p "$T/iso/EFI"; cp "$T/efiboot.img" "$T/iso/EFI/efiboot.img"

# 4) ISO híbrida (DVD/USB), arranque UEFI
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -joliet -joliet-long -rational-rock \
  -volid "$LABEL" -appid "BC OS live" -publisher "BC OS" \
  -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
  -output "$OUT" "$T/iso" 2>&1 | tail -n 3
ls -lh "$OUT"
