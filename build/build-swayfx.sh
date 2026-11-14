#!/usr/bin/env bash
# Compila swayfx (sway con esquinas redondeadas, sombras y desenfoque) en el rootfs aarch64 y lo instala en /opt/swayfx.
# Requiere el renderizador GLES2 (con GPU o llvmpipe); BC OS lo usa solo si el kernel arranca con bc.gpu=1. Uso: build-swayfx.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"; HERE="$(cd "$(dirname "$0")" && pwd)"
SWAYFX_TAG="0.6.1"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
DEPS="meson ninja pkgconf gcc scdoc git scenefx wlroots0.20 wayland-protocols json-c pcre2 cairo pango gdk-pixbuf2 libevdev libinput libxkbcommon"
NEW="$(sh "for p in $DEPS; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr "\n" " ")"
sh "pacman -S --needed --noconfirm --disable-sandbox $DEPS"
sh "rm -rf /tmp/swayfx && git clone -q --depth 1 --branch $SWAYFX_TAG https://github.com/WillPower3309/swayfx /tmp/swayfx"
sh "cd /tmp/swayfx && meson setup build --prefix=/opt/swayfx -Dwerror=false -Dman-pages=disabled -Dsd-bus-provider=libsystemd 2>&1 | tail -5 && ninja -C build && ninja -C build install"
sh "rm -rf /tmp/swayfx"
[[ -n "$NEW" ]] && sh "pacman -Rns --noconfirm --disable-sandbox $NEW || true"
echo "swayfx $SWAYFX_TAG instalado en $R/opt/swayfx"
