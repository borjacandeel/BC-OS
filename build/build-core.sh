#!/usr/bin/env bash
# Compila BC Core (Rust) para aarch64 y lo instala en el rootfs con sus unidades de usuario habilitadas.
# Uso: build-core.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"; HERE="$(cd "$(dirname "$0")" && pwd)"; CORE="$HERE/../core"
if [[ "$(uname -m)" == "aarch64" ]]; then
  ( cd "$CORE" && cargo build --release --locked )
  OUT="$CORE/target/release"
else
  export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
  ( cd "$CORE" && cargo build --release --locked --target aarch64-unknown-linux-gnu )
  OUT="$CORE/target/aarch64-unknown-linux-gnu/release"
fi
for b in bc-daemon bc-settings-service bc-update-service bc-security-service bc-hardware-service bc-performance-service; do
  install -D -m755 "$OUT/$b" "$R/usr/bin/$b"
done
install -d "$R/usr/lib/systemd/user"
install -m644 "$CORE"/dist/systemd/*.service "$R/usr/lib/systemd/user/"
# Habilitar para todos los usuarios (enlaces en default.target.wants)
install -d "$R/etc/systemd/user/default.target.wants"
for u in "$CORE"/dist/systemd/*.service; do
  ln -sf "/usr/lib/systemd/user/$(basename "$u")" "$R/etc/systemd/user/default.target.wants/$(basename "$u")"
done
echo "BC Core instalado en $R"
