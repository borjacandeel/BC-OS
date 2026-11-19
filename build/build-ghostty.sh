#!/usr/bin/env bash
# Compila Ghostty (terminal por defecto de BC OS) dentro del rootfs (aarch64 o x86_64, BC_ARCH) y lo instala en /usr.
# Ghostty no está empaquetado en Arch Linux ARM y pide una Zig más nueva que la del repositorio,
# así que se usa la Zig oficial de ziglang.org. Las dependencias de Zig se descargan en el ANFITRIÓN
# (el chroot no tiene los certificados del proxy). Zig 0.17 guarda los paquetes comprimidos (p/<hash>.tar.gz) y
# «--system» espera carpetas extraídas (aborta con «reached unreachable code»), así que se usa la caché global tal cual.
# Pensado para el runner ARM64 nativo de CI; con qemu-user tarda horas. Uso: build-ghostty.sh <rootfs>
set -euo pipefail
R="$(realpath "$1")"
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/chroot.sh"
# /proc, /dev y /sys montados: Zig necesita /proc/self/exe dentro del chroot
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
GHOSTTY_TAG="${GHOSTTY_TAG:-v1.4.0}"
ZIG_VER="${ZIG_VER:-0.17.0}"
HOSTARCH="$(uname -m)"

# Herramientas de compilación (se quitan al terminar) y librerías de ejecución (se conservan)
BUILD="blueprint-compiler gettext pkgconf git"
LIBS="gtk4 libadwaita gtk4-layer-shell"
NEW="$(sh "for p in $BUILD; do pacman -Qq \$p >/dev/null 2>&1 || echo \$p; done" | tr "\n" " ")"
sh "for i in 1 2 3; do pacman -S --needed --noconfirm --disable-sandbox $BUILD $LIBS && exit 0; echo \"reintento \$i\"; sleep 20; done; exit 1"

W="$R/tmp/ghostty-build"; rm -rf "$W"; mkdir -p "$W"
git clone -q --depth 1 --branch "$GHOSTTY_TAG" https://github.com/ghostty-org/ghostty "$W/src"
# Zig del anfitrión (para descargar dependencias) y Zig aarch64 (para compilar dentro del chroot)
curl -fsSL "https://ziglang.org/download/$ZIG_VER/zig-$HOSTARCH-linux-$ZIG_VER.tar.xz" | tar -xJ -C "$W"
TA="${BC_ARCH:-aarch64}"
[ "$HOSTARCH" = "$TA" ] || curl -fsSL "https://ziglang.org/download/$ZIG_VER/zig-$TA-linux-$ZIG_VER.tar.xz" | tar -xJ -C "$W"
# Por defecto Zig descarga las dependencias dentro del chroot (con la predescarga en el anfitrión los hashes no
# coincidían). BC_GHOSTTY_NOPREFETCH=0 vuelve a predescargar en el anfitrión (redes sin certificados en el chroot).
if [ "${BC_GHOSTTY_NOPREFETCH:-1}" = 0 ]; then
PATH="$W/zig-$HOSTARCH-linux-$ZIG_VER:$PATH" ZIG_GLOBAL_CACHE_DIR="$W/cache" sh "$W/src/nix/build-support/fetch-zig-cache.sh" >/dev/null 2>&1 \
  || PATH="$W/zig-$HOSTARCH-linux-$ZIG_VER:$PATH" ZIG_GLOBAL_CACHE_DIR="$W/cache" bash "$W/src/nix/build-support/fetch-zig-cache.sh"
fi

# GHOSTTY_ARGS: opciones extra para depurar (p. ej. "-j1 --verbose"); BC_GHOSTTY_LOG: guardar la salida completa
# BC_GHOSTTY_WRAP: envoltorio de depuración (p. ej. «strace -f -o /tmp/st.txt»)
build_sh() { ${BC_GHOSTTY_WRAP:-} chroot "$R" /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/local/sbin:/usr/local/bin:/usr/bin bash -c "$*"; }
build_sh "cd /tmp/ghostty-build/src && ZIG_GLOBAL_CACHE_DIR=/tmp/ghostty-build/cache /tmp/ghostty-build/zig-$TA-linux-$ZIG_VER/zig build \
  --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline -Dpie=true -Demit-docs=false ${GHOSTTY_ARGS:-}" \
  2>&1 | tee "${BC_GHOSTTY_LOG:-/dev/null}" | tail -n 200
[ "${PIPESTATUS[0]}" = 0 ]
rm -rf "$W"
[ -z "${NEW// /}" ] || sh "pacman -Rns --noconfirm $NEW" || true
sh "command -v ghostty >/dev/null"
echo "Ghostty $GHOSTTY_TAG instalado en $R/usr"
