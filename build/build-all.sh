#!/usr/bin/env bash
# Construcción completa de BC OS ARM64 desde cero. Requiere root. Uso: build-all.sh [versión] [directorio_trabajo]
# En host aarch64 corre nativo; en x86_64 usa qemu-user (qemu-user-static + binfmt).
set -euo pipefail
VER="${1:-0.1.0-alpha}"; W="${2:-$PWD/build/work}"
HERE="$(cd "$(dirname "$0")" && pwd)"; OUT="$HERE/out"
source "$HERE/lib/chroot.sh"
R="$W/root"; mkdir -p "$W" "$OUT"

if [[ ! -d "$R/etc" ]]; then
  mkdir -p "$R"
  curl -fSL -o "$W/alarm.tar.gz" http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
  curl -fSL -o "$W/alarm.tar.gz.md5" http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz.md5
  (cd "$W" && echo "$(cut -d' ' -f1 alarm.tar.gz.md5)  alarm.tar.gz" | md5sum -c -)
  bsdtar -xpf "$W/alarm.tar.gz" -C "$R"; rm -f "$W/alarm.tar.gz"
fi

bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sed -i 's/^CheckSpace/#CheckSpace/' "$R/etc/pacman.conf"
bc_chroot "$R" bash -c "pacman-key --init && pacman-key --populate archlinuxarm"
bc_chroot "$R" pacman -Syu --noconfirm --disable-sandbox
PK="$(grep -v '^#' "$HERE/packages/base.txt" | grep -v '^$' | tr '\n' ' ')"
bc_chroot "$R" bash -c "pacman -S --needed --noconfirm --disable-sandbox $PK"
bc_umount "$R"; trap - EXIT

bash "$HERE/build-shell.sh" "$R"
sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"BC OS $VER\"/; s/^VERSION=.*/VERSION=\"$VER\"/; s/^VERSION_ID=.*/VERSION_ID=\"$VER\"/" "$HERE/overlay/etc/os-release"
bash "$HERE/configure-rootfs.sh" "$R"

IMG="$OUT/BC-OS-$VER-ARM64.img"
bash "$HERE/mkimage.sh" "$R" "$IMG" 6144
if grep -q " $(realpath "$R")/" /proc/self/mountinfo; then echo "Aviso: quedan montajes en $R; no se borra"; else rm -rf --one-file-system "$R"; fi
qemu-img convert -f raw -O vdi "$IMG" "$OUT/BC-OS-$VER-ARM64.vdi"
rm -f "$IMG" "$IMG.sha256"
(cd "$OUT" && zip -q -6 "BC-OS-$VER-ARM64.vdi.zip" "BC-OS-$VER-ARM64.vdi" && rm -f "BC-OS-$VER-ARM64.vdi" && sha256sum "BC-OS-$VER-ARM64.vdi.zip" > SHA256SUMS && cat SHA256SUMS)
