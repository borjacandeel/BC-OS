#!/usr/bin/env bash
# Compila box64 (ptitSeb, MIT) en el rootfs aarch64: ejecuta programas y juegos Linux x86_64 en ARM64 con
# recompilación dinámica. Se registra en binfmt_misc para que los binarios x86_64 se abran solos.
# Solo para BC_ARCH=aarch64. Uso: build-box64.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"; HERE="$(cd "$(dirname "$0")" && pwd)"
[ "${BC_ARCH:-aarch64}" = aarch64 ] || { echo "box64 solo hace falta en aarch64"; exit 0; }
BOX64_TAG="${BOX64_TAG:-v0.3.8}"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
BUILD="cmake gcc make python git"
NEW="$(sh "for p in $BUILD; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr "\n" " ")"
sh "pacman -S --needed --noconfirm --disable-sandbox $BUILD"
rm -rf "$R/tmp/box64"; git clone -q --depth 1 --branch "$BOX64_TAG" https://github.com/ptitSeb/box64 "$R/tmp/box64" \
  || git clone -q --depth 1 https://github.com/ptitSeb/box64 "$R/tmp/box64"
# ARM_DYNAREC: recompilación dinámica; genérico ARMv8 (vale para Apple Silicon en VM, Raspberry Pi 4/5, etc.)
sh "cd /tmp/box64 && mkdir -p build && cd build && cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr \
    -DNOGIT=1 && make -j\$(nproc) && make install"
sh "rm -rf /tmp/box64"
# binfmt_misc: binarios ELF x86_64 → box64 (systemd-binfmt lo carga al arrancar)
mkdir -p "$R/etc/binfmt.d"
printf ':x86_64:M::\\x7fELF\\x02\\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x02\\x00\\x3e\\x00:\\xff\\xff\\xff\\xff\\xff\\xfe\\xfe\\x00\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xfe\\xff\\xff\\xff:/usr/bin/box64:\n' > "$R/etc/binfmt.d/box64.conf"
rm -f "$R"/etc/binfmt.d/box64.conf.* "$R"/usr/lib/binfmt.d/box64.conf 2>/dev/null || true
[[ -n "${NEW// /}" ]] && sh "pacman -Rns --noconfirm --disable-sandbox $NEW || true"
sh "command -v box64 >/dev/null" && echo "box64 instalado en $R/usr/bin/box64"
