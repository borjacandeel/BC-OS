#!/usr/bin/env bash
# Compila BC Shell dentro del rootfs aarch64 (qemu-user) y lo instala en /usr. Uso: build-shell.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"; HERE="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE/../shell"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
DEPS="$(grep -v '^#' "$HERE/packages/build-deps.txt" | tr '\n' ' ')"
NEW="$(sh "for p in $DEPS; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr "\n" " ")"
sh "for i in 1 2 3; do pacman -S --needed --noconfirm --disable-sandbox $DEPS && exit 0; echo \"reintento \$i\"; sleep 20; done; exit 1"
rm -rf "$R/tmp/bc-shell"; mkdir -p "$R/tmp/bc-shell"; cp -a "$SRC"/. "$R/tmp/bc-shell/"
# CMake falla de forma intermitente al buscar Qt6QmlIntegration bajo qemu-user: se reintenta la configuración.
sh "cd /tmp/bc-shell && for i in 1 2 3 4 5; do rm -rf build; cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && break; [ \$i = 5 ] && exit 1; done && cmake --build build && cmake --install build"
rm -rf "$R/tmp/bc-shell"
[[ -n "$NEW" ]] && sh "pacman -Rns --noconfirm --disable-sandbox $NEW || true"
echo "BC Shell instalado en $R/usr/bin/bc-shell"
