#!/usr/bin/env bash
# Utilidades de chroot aarch64 para BC OS (host x86_64 con qemu-user, o host aarch64 nativo).
set -euo pipefail

bc_binfmt() {
  [[ "$(uname -m)" == "aarch64" ]] && return 0
  mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
  if [[ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
    echo ':qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:FC' \
      > /proc/sys/fs/binfmt_misc/register
  fi
}

bc_mount() {
  local r="$1"
  for d in proc sys dev; do mountpoint -q "$r/$d" || mount --rbind "/$d" "$r/$d"; done
  rm -f "$r/etc/resolv.conf"; cp /etc/resolv.conf "$r/etc/resolv.conf"
}

bc_umount() {
  local r="$1"
  for d in dev sys proc; do
    mountpoint -q "$r/$d" && { umount -R "$r/$d" 2>/dev/null || umount -R -l "$r/$d" 2>/dev/null || true; }
  done
}

bc_chroot() {
  local r="$1"; shift
  chroot "$r" /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/local/sbin:/usr/local/bin:/usr/bin "$@"
}
