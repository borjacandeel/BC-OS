#!/usr/bin/env bash
# Rootfs base de Arch para BC OS según la arquitectura de destino (BC_ARCH):
#   aarch64 → Arch Linux ARM (os.archlinuxarm.org)   ·   x86_64 → Arch Linux (archlinux-bootstrap)
# Uso: source build/lib/rootfs.sh; bc_rootfs <carpeta> [arch]   (deja pacman listo: claves y mirrors)
bc_rootfs() {
  local r="$1" a="${2:-${BC_ARCH:-aarch64}}" t; t="$(mktemp -d)"
  mkdir -p "$r"
  if [ "$a" = aarch64 ]; then
    curl -fSL -o "$t/alarm.tar.gz" http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
    curl -fSL -o "$t/alarm.tar.gz.md5" http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz.md5
    (cd "$t" && echo "$(cut -d' ' -f1 alarm.tar.gz.md5)  alarm.tar.gz" | md5sum -c -)
    bsdtar -xpf "$t/alarm.tar.gz" -C "$r"
    # Varios mirrors: si el redirector (mirror.archlinuxarm.org) se cuelga, pacman pasa al siguiente
    # (en CI una descarga «Operation too slow» tumbaba la imagen ARM entera)
    printf '%s\n' 'Server = http://mirror.archlinuxarm.org/$arch/$repo' 'Server = http://de.mirror.archlinuxarm.org/$arch/$repo' \
      'Server = http://de3.mirror.archlinuxarm.org/$arch/$repo' 'Server = http://eu.mirror.archlinuxarm.org/$arch/$repo' \
      'Server = http://fl.us.mirror.archlinuxarm.org/$arch/$repo' 'Server = http://ca.us.mirror.archlinuxarm.org/$arch/$repo' > "$r/etc/pacman.d/mirrorlist"
  else
    curl -fSL -o "$t/boot.tar.zst" https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst
    curl -fSL -o "$t/sums" https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt
    (cd "$t" && grep " archlinux-bootstrap-x86_64.tar.zst$" sums | sed 's/archlinux-bootstrap-x86_64.tar.zst/boot.tar.zst/' | sha256sum -c -)
    bsdtar -xpf "$t/boot.tar.zst" -C "$r" --strip-components 1
    printf 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch\nServer = https://mirror.rackspace.com/archlinux/$repo/os/$arch\n' > "$r/etc/pacman.d/mirrorlist"
  fi
  rm -rf "$t"
  sed -i 's/^CheckSpace/#CheckSpace/' "$r/etc/pacman.conf"
}
# Claves de pacman (dentro del chroot ya montado)
bc_rootfs_keys() {
  local r="$1" a="${2:-${BC_ARCH:-aarch64}}"
  if [ "$a" = aarch64 ]; then bc_chroot "$r" bash -c "pacman-key --init && pacman-key --populate archlinuxarm"
  else bc_chroot "$r" bash -c "pacman-key --init && pacman-key --populate archlinux"; fi
}
# Lista de paquetes de la imagen adaptada a la arquitectura
bc_packages() {
  local a="${1:-${BC_ARCH:-aarch64}}" here; here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local pk; pk="$(grep -v '^#' "$here/packages/base.txt" | grep -v '^$' | tr '\n' ' ')"
  if [ "$a" = x86_64 ]; then pk="${pk//linux-aarch64/linux} virtualbox-guest-utils linux-firmware vulkan-intel vulkan-radeon vulkan-nouveau intel-media-driver libva-utils vulkan-tools intel-ucode amd-ucode"; fi
  echo "$pk"
}
