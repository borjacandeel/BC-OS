#!/usr/bin/env bash
# Compila BC Shell dentro del rootfs aarch64 (qemu-user) y lo instala en /usr. Uso: build-shell.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"; HERE="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE/../shell"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
DEPS="$(grep -v '^#' "$HERE/packages/build-deps.txt" | tr '\n' ' ')"
NEW="$(sh "for p in $DEPS; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr "\n" " ")"
sh "pacman -S --needed --noconfirm --disable-sandbox $DEPS"
rm -rf "$R/tmp/bc-shell"; mkdir -p "$R/tmp/bc-shell"; cp -a "$SRC"/. "$R/tmp/bc-shell/"
sh "cd /tmp/bc-shell && cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build && cmake --install build"
rm -rf "$R/tmp/bc-shell"
[[ -n "$NEW" ]] && sh "pacman -Rns --noconfirm --disable-sandbox $NEW || true"
echo "BC Shell instalado en $R/usr/bin/bc-shell"
