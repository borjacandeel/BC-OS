# yay (asistente del AUR) desde su versión publicada (binario oficial de github.com/Jguer/yay, GPL-3.0).
# Uso: bc_yay <destino> <arquitectura aarch64|x86_64>  → deja <destino>/usr/bin/yay (y su licencia)
bc_yay() {
  local dst="$1" arch="$2" ver tmp
  ver="$(curl -fsSL https://api.github.com/repos/Jguer/yay/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || ver=12.4.2
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/Jguer/yay/releases/download/v$ver/yay_${ver}_${arch}.tar.gz" | tar -xz -C "$tmp" || { rm -rf "$tmp"; return 1; }
  install -D -m755 "$tmp"/yay_*/yay "$dst/usr/bin/yay"
  [ -f "$tmp"/yay_*/LICENSE ] && install -D -m644 "$tmp"/yay_*/LICENSE "$dst/usr/share/licenses/yay/LICENSE"
  [ -f "$tmp"/yay_*/yay.8 ] && install -D -m644 "$tmp"/yay_*/yay.8 "$dst/usr/share/man/man8/yay.8"
  rm -rf "$tmp"; echo "yay $ver ($arch)"
}
