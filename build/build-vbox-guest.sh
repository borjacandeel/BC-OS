#!/usr/bin/env bash
# Guest Additions de VirtualBox para la imagen ARM64 (en x86_64 vienen de Arch: virtualbox-guest-utils).
# Descarga el ISO oficial, compila los módulos vboxguest/vboxsf para el kernel de la imagen e instala VBoxService,
# VBoxClient y VBoxDRMClient (ajuste de resolución, portapapeles, carpetas compartidas, hora). Si falla, solo avisa.
# Uso: build-vbox-guest.sh <rootfs>
set -euo pipefail
R="$(realpath "${1:?uso: $0 <rootfs>}")"; HERE="$(cd "$(dirname "$0")" && pwd)"
[ "${BC_ARCH:-aarch64}" = aarch64 ] || exit 0
source "$HERE/lib/chroot.sh"
V="$(curl -fsS https://download.virtualbox.org/virtualbox/LATEST.TXT)"
T="$(mktemp -d)"; trap 'bc_umount "$R" 2>/dev/null || true; rm -rf "$T"' EXIT
curl -fsSL -o "$T/ga.iso" "https://download.virtualbox.org/virtualbox/$V/VBoxGuestAdditions_$V.iso"
xorriso -osirrox on -indev "$T/ga.iso" -extract /VBoxLinuxAdditions-arm64.run "$T/arm.run" 2>/dev/null
sh "$T/arm.run" --noexec --target "$T/x" >/dev/null
mkdir -p "$T/ga"; tar -xjf "$T/x/VBoxGuestAdditions-arm64.tar.bz2" -C "$T/ga"
install -Dm755 "$T/ga/sbin/VBoxService" "$R/usr/bin/VBoxService"
for b in VBoxClient VBoxDRMClient VBoxControl; do [ -f "$T/ga/bin/$b" ] && install -Dm755 "$T/ga/bin/$b" "$R/usr/bin/$b"; done
# Módulos del kernel (mainline trae vboxguest/vboxsf en algunas versiones; si no, se compilan los de Oracle)
bc_binfmt; bc_mount "$R"
KV="$(ls "$R/usr/lib/modules" | head -n1)"
if ! ls "$R/usr/lib/modules/$KV" -R 2>/dev/null | grep -q '^vboxguest\.ko'; then
  rm -rf "$R/tmp/vboxsrc"; cp -a "$T/ga/src/vboxguest-$V" "$R/tmp/vboxsrc"
  BUILD="linux-aarch64-headers gcc make"
  NEW="$(bc_chroot "$R" bash -c "for p in $BUILD; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr '\n' ' ')"
  bc_chroot "$R" bash -c "pacman -S --needed --noconfirm --disable-sandbox $BUILD" || true
  bc_chroot "$R" bash -c "cd /tmp/vboxsrc && for m in vboxguest vboxsf; do make -C /usr/lib/modules/$KV/build M=/tmp/vboxsrc/\$m KERN_DIR=/usr/lib/modules/$KV/build modules -j\$(nproc) && install -Dm644 \$m/\$m.ko /usr/lib/modules/$KV/extra/\$m.ko; done; depmod $KV" \
    || echo "AVISO: no se pudieron compilar los módulos de VirtualBox para $KV (portapapeles y carpetas compartidas no funcionarán)"
  rm -rf "$R/tmp/vboxsrc"
  [ -n "${NEW// /}" ] && bc_chroot "$R" bash -c "pacman -Rns --noconfirm --disable-sandbox $NEW" || true
fi
# Servicios: VBoxService (hora, propiedades) y VBoxDRMClient (resolución de la ventana) solo dentro de VirtualBox
cat > "$R/etc/systemd/system/vboxservice.service" <<U
[Unit]
Description=Servicio de invitado de VirtualBox
ConditionVirtualization=oracle
[Service]
ExecStartPre=-/usr/bin/modprobe vboxguest
ExecStart=/usr/bin/VBoxService -f
[Install]
WantedBy=multi-user.target
U
cat > "$R/etc/systemd/system/vboxdrmclient.service" <<U
[Unit]
Description=Ajuste de resolución de VirtualBox
ConditionVirtualization=oracle
After=vboxservice.service
[Service]
ExecStart=/usr/bin/VBoxDRMClient
Restart=on-failure
[Install]
WantedBy=multi-user.target
U
bc_chroot "$R" bash -c "systemctl enable vboxservice vboxdrmclient" || true
echo "Guest Additions de VirtualBox $V instaladas (ARM64)"
