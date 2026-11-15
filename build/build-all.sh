#!/usr/bin/env bash
# Construcción completa de BC OS desde cero (BC_ARCH=aarch64 por defecto, o x86_64). Requiere root. Uso: build-all.sh [versión] [directorio_trabajo]
# En host aarch64 corre nativo; en x86_64 usa qemu-user (qemu-user-static + binfmt).
set -euo pipefail
VER="${1:-0.1.0-alpha}"; W="${2:-$PWD/build/work}"
HERE="$(cd "$(dirname "$0")" && pwd)"; OUT="$HERE/out"
source "$HERE/lib/chroot.sh"
R="$W/root"; mkdir -p "$W" "$OUT"

ARCH="${BC_ARCH:-aarch64}"; export BC_ARCH="$ARCH"
SUF="$([ "$ARCH" = aarch64 ] && echo ARM64 || echo x86_64)"
source "$HERE/lib/rootfs.sh"
[[ -d "$R/etc" ]] || bc_rootfs "$R" "$ARCH"

bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sed -i 's/^CheckSpace/#CheckSpace/' "$R/etc/pacman.conf"
bc_rootfs_keys "$R" "$ARCH"
bc_chroot "$R" pacman -Syu --noconfirm --disable-sandbox
PK="$(bc_packages "$ARCH")"
# Si falta algún paquete en esta arquitectura, se instala el resto uno a uno (y se avisa)
bc_chroot "$R" bash -c "pacman -S --needed --noconfirm --disable-sandbox $PK" || \
  for p in $PK; do bc_chroot "$R" pacman -S --needed --noconfirm --disable-sandbox "$p" || echo "AVISO: no se pudo instalar $p ($ARCH)"; done
[ "$ARCH" = x86_64 ] && bc_chroot "$R" bash -c "systemctl enable vboxservice 2>/dev/null || true"
bc_umount "$R"; trap - EXIT

bash "$HERE/build-shell.sh" "$R"
bash "$HERE/build-core.sh" "$R"
bash "$HERE/build-swayfx.sh" "$R"
# Programas y juegos x86_64 en ARM64 (box64); si falla la compilación, la imagen sigue sin él
[ "$ARCH" = aarch64 ] && { bash "$HERE/build-box64.sh" "$R" || echo "AVISO: no se pudo compilar box64"; }
[ "${BC_GHOSTTY:-0}" = 0 ] || bash "$HERE/build-ghostty.sh" "$R" || echo "AVISO: no se pudo compilar Ghostty; la terminal será Alacritty"
sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"BC OS $VER\"/; s/^VERSION=.*/VERSION=\"$VER\"/; s/^VERSION_ID=.*/VERSION_ID=\"$VER\"/" "$HERE/overlay/etc/os-release"
bash "$HERE/configure-rootfs.sh" "$R"

IMG="$OUT/BC-OS-$VER-$SUF.img"
bash "$HERE/mkimage.sh" "$R" "$IMG" 6144
# ISO live (BC_ISO=1): mismo sistema, arranca desde squashfs con el instalador; si falla, solo se avisa
if [ "${BC_ISO:-0}" = 1 ]; then bash "$HERE/mkiso.sh" "$R" "$OUT/BC-OS-$VER-$SUF.iso" || { echo "AVISO: no se pudo crear la ISO"; rm -f "$OUT/BC-OS-$VER-$SUF.iso"; }; fi
if grep -q " $(realpath "$R")/" /proc/self/mountinfo; then echo "Aviso: quedan montajes en $R; no se borra"; else rm -rf --one-file-system "$R"; fi
qemu-img convert -f raw -O vdi "$IMG" "$OUT/BC-OS-$VER-$SUF.vdi"
rm -f "$IMG" "$IMG.sha256"
(cd "$OUT" && zip -q -6 "BC-OS-$VER-$SUF.vdi.zip" "BC-OS-$VER-$SUF.vdi" && rm -f "BC-OS-$VER-$SUF.vdi" && sha256sum "BC-OS-$VER-$SUF.vdi.zip" $(ls "BC-OS-$VER-$SUF.iso" 2>/dev/null) > "SHA256SUMS-$SUF" && cat "SHA256SUMS-$SUF")
