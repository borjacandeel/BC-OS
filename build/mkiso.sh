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
# Bases de datos al día (incluida la de [bc], que se añade al final de la configuración)
bc_chroot "$R" bash -c "pacman -Sy --needed --noconfirm --disable-sandbox mkinitcpio-archiso squashfs-tools"
# (las bases quedan en la ISO: sin ellas «pacman -S» falla en el sistema live)
bc_chroot "$R" bash -c "rm -rf /var/cache/pacman/pkg/*"
cat > "$R/etc/mkinitcpio-live.conf" <<C
MODULES=(virtio_blk virtio_pci virtio_scsi virtio_gpu nvme ahci xhci_pci usb_storage uas sr_mod isofs squashfs overlay loop vfat ext4)
HOOKS=(base udev modconf kms archiso archiso_loop_mnt block filesystems keyboard)
COMPRESSION=zstd
C
bc_chroot "$R" bash -c "mkinitcpio -c /etc/mkinitcpio-live.conf -k /boot/$KIMG -g /boot/initramfs-live.img"
# x86_64: arranque BIOS (Legacy) además de UEFI, con el GRUB del propio sistema (PCs antiguos sin UEFI)
if [ "$ARCH" = x86_64 ] && [ -d "$R/usr/lib/grub/i386-pc" ]; then
  bc_chroot "$R" grub-mkimage -d /usr/lib/grub/i386-pc -O i386-pc-eltorito -p /boot/grub -o /tmp/bc-eltorito.img \
    biosdisk iso9660 part_gpt part_msdos fat search search_label configfile normal linux echo ls test all_video gfxterm
  mv "$R/tmp/bc-eltorito.img" "$T/eltorito.img"; cp "$R/usr/lib/grub/i386-pc/boot_hybrid.img" "$T/boot_hybrid.img"
fi
cp "$R/boot/initramfs-live.img" "$T/initramfs-live.img"; rm -f "$R/boot/initramfs-live.img" "$R/etc/mkinitcpio-live.conf"
bc_umount "$R"

# Solo en live: app «Instalar BC OS» y permiso polkit para lanzarla (ver overlay-live/LEEME.md)
cp -a "$HERE/overlay-live/usr" "$HERE/overlay-live/etc" "$R/"
# Live: entra directamente en la sesión (sin pedir contraseña) y se abre el instalador, como el de macOS.
# bc-install quita este bloque al instalar (marcador «# bc-live»).
printf '\n# bc-live\n[initial_session]\ncommand = "/usr/bin/bc-session --greetd"\nuser = "bc"\n' >> "$R/etc/greetd/config.toml"
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
# Copiar todo a la RAM: tarda más en arrancar pero luego va fluido aunque el USB sea 2.0 (necesita ~6 GB de RAM)
printf 'title   BC OS (live, cargar en RAM: USB lento)\nlinux   /%s\ninitrd  /initramfs-live.img\noptions %s copytoram=y\n' "$KIMG" "$OPTS" > "$T/live-ram.conf"
mcopy -i "$T/efiboot.img" "$T/loader.conf" ::/loader/loader.conf
mcopy -i "$T/efiboot.img" "$T/live.conf" "$T/live-seguro.conf" "$T/live-ram.conf" ::/loader/entries/
mkdir -p "$T/iso/EFI"; cp "$T/efiboot.img" "$T/iso/EFI/efiboot.img"
if [ -f "$T/eltorito.img" ]; then
  mkdir -p "$T/iso/boot/grub"; cp "$T/eltorito.img" "$T/iso/boot/grub/eltorito.img"
  cp "$R/boot/$KIMG" "$T/iso/boot/$KIMG"; cp "$T/initramfs-live.img" "$T/iso/boot/initramfs-live.img"
  cat > "$T/iso/boot/grub/grub.cfg" <<G
search --no-floppy --label $LABEL --set=root
set timeout=5
set default=0
menuentry "BC OS (live)" { linux /boot/$KIMG $OPTS; initrd /boot/initramfs-live.img; }
menuentry "BC OS (live, modo seguro)" { linux /boot/$KIMG ${OPTS/quiet splash/plymouth.enable=0}; initrd /boot/initramfs-live.img; }
menuentry "BC OS (live, cargar en RAM: USB lento)" { linux /boot/$KIMG $OPTS copytoram=y; initrd /boot/initramfs-live.img; }
G
fi

# 4) ISO híbrida (DVD/USB), arranque UEFI
if [ -f "$T/eltorito.img" ]; then
  # BIOS + UEFI, como CD y como USB (probado en QEMU con SeaBIOS y OVMF): GRUB en El Torito y MBR híbrido,
  # partición EFI añadida como GPT para UEFI
  xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -joliet -joliet-long -rational-rock \
    -volid "$LABEL" -appid "BC OS live" -publisher "BC OS" \
    -partition_offset 16 --grub2-mbr "$T/boot_hybrid.img" \
    -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "$T/efiboot.img" -appended_part_as_gpt \
    -b boot/grub/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot -e --interval:appended_partition_2:all:: -no-emul-boot \
    -output "$OUT" "$T/iso" 2>&1 | tail -n 3
else
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -joliet -joliet-long -rational-rock \
  -volid "$LABEL" -appid "BC OS live" -publisher "BC OS" \
  -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot -isohybrid-gpt-basdat \
  -output "$OUT" "$T/iso" 2>&1 | tail -n 3
fi
ls -lh "$OUT"
