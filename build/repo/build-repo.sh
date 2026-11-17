#!/usr/bin/env bash
# Construye el repositorio de paquetes propio de BC OS ([bc]) a partir de este árbol:
#   bc-shell      — BC Shell y bc-greeter (Qt 6)
#   bc-core       — servicios de BC Core (Rust) y sus unidades de usuario
#   bc-escritorio — sesión, scripts bc-*, configuración de sway, .desktop, iconos de apps, fondos y sonidos
#   bc-os         — metapaquete: depende de los tres y de los paquetes base de la imagen (build/packages/base.txt)
# El repositorio se publica en GitHub Releases (etiqueta «repo») y el sistema se actualiza desde ahí (bc-actualizar).
# Uso (root, rootfs de Arch de la arquitectura BC_ARCH con red): build-repo.sh <rootfs> <carpeta_salida> [versión]
set -euo pipefail
R="$(realpath "${1:?uso: $0 <rootfs> <salida> [versión]}")"; OUT="$(realpath -m "${2:?falta la salida}")"
HERE="$(cd "$(dirname "$0")/.." && pwd)"; TOP="$HERE/.."
VER="${3:-$(date -u +%Y%m%d.%H%M)}"; VER="${VER//-/_}"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }
W="$R/tmp/bcrepo"; rm -rf "$W"; mkdir -p "$W/stage" "$W/pkg" "$OUT"
ST="$W/stage"

# --- bc-shell ---------------------------------------------------------------------------------
DEPS="$(grep -v '^#' "$HERE/packages/build-deps.txt" | tr '\n' ' ')"
sh "pacman -S --needed --noconfirm --disable-sandbox $DEPS fakeroot qt6-base qt6-declarative qt6-wayland qt6-svg layer-shell-qt qtermwidget"
cp -a "$TOP/shell" "$W/src-shell"
sh "cd /tmp/bcrepo/src-shell && rm -rf build && cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    && cmake --build build && DESTDIR=/tmp/bcrepo/stage/bc-shell cmake --install build"

# --- bc-core ----------------------------------------------------------------------------------
CO="$TOP/core/target/release"; [ -x "$CO/bc-daemon" ] || CO="$TOP/core/target/aarch64-unknown-linux-gnu/release"
for b in bc-daemon bc-settings-service bc-update-service bc-security-service bc-hardware-service bc-performance-service bc-antivirus-service; do
  install -D -m755 "$CO/$b" "$ST/bc-core/usr/bin/$b"
done
install -d "$ST/bc-core/usr/lib/systemd/user" "$ST/bc-core/etc/systemd/user/default.target.wants"
install -m644 "$TOP"/core/dist/systemd/*.service "$ST/bc-core/usr/lib/systemd/user/"
for u in "$TOP"/core/dist/systemd/*.service; do ln -sf "/usr/lib/systemd/user/$(basename "$u")" "$ST/bc-core/etc/systemd/user/default.target.wants/$(basename "$u")"; done

# --- bc-escritorio ----------------------------------------------------------------------------
E2="$ST/bc-escritorio"; O="$HERE/overlay"
install -d "$E2/usr/bin" "$E2/etc/bc/sway" "$E2/usr/share/applications" "$E2/usr/share/bc/wallpapers" "$E2/usr/share/sounds/bc" \
           "$E2/usr/share/icons/hicolor/scalable/apps"
install -m755 "$O"/usr/bin/bc-* "$E2/usr/bin/"
install -m755 "$HERE/repo/bc-actualizar" "$E2/usr/bin/bc-actualizar"
install -D -m755 "$O/usr/lib/bc/bc-paquetes" "$E2/usr/lib/bc/bc-paquetes"
install -D -m755 "$O/usr/lib/bc/bc-instantanea" "$E2/usr/lib/bc/bc-instantanea"
install -D -m644 "$O/usr/share/libalpm/hooks/00-bc-instantanea.hook" "$E2/usr/share/libalpm/hooks/00-bc-instantanea.hook"
install -D -m644 "$O/usr/share/polkit-1/actions/org.bcos.paquetes.policy" "$E2/usr/share/polkit-1/actions/org.bcos.paquetes.policy"
install -D -m644 "$O/etc/polkit-1/rules.d/50-bcos-paquetes.rules" "$E2/etc/polkit-1/rules.d/50-bcos-paquetes.rules"
cp -a "$O/etc/bc/." "$E2/etc/bc/"
install -D -m644 "$O/usr/lib/firefox/distribution/policies.json" "$E2/usr/lib/firefox/distribution/policies.json"
install -D -m644 "$O/usr/lib/firefox/defaults/pref/bc-autoconfig.js" "$E2/usr/lib/firefox/defaults/pref/bc-autoconfig.js"
install -m644 "$O/usr/lib/firefox/bc.cfg" "$O/usr/lib/firefox/bc-firefox.css" "$E2/usr/lib/firefox/"
install -m644 "$O"/usr/share/applications/bc-*.desktop "$E2/usr/share/applications/"
install -m644 "$TOP"/assets/wallpapers/*.jpg "$E2/usr/share/bc/wallpapers/"
install -m644 "$TOP"/assets/sounds/*.wav "$E2/usr/share/sounds/bc/"
# También llegan con las actualizaciones: el arranque animado (Plymouth), las sesiones del login y su carpeta compartida
install -d "$E2/usr/share/plymouth/themes/bcos" "$E2/usr/share/bc/sessions"
install -m644 "$HERE"/plymouth/bcos/* "$E2/usr/share/plymouth/themes/bcos/"
install -m644 "$HERE"/overlay-dotfiles/usr/share/bc/sessions/*.desktop "$E2/usr/share/bc/sessions/"
install -D -m644 "$O/usr/lib/tmpfiles.d/bc-greeter.conf" "$E2/usr/lib/tmpfiles.d/bc-greeter.conf"
for pair in bc-files:system-file-manager bc-settings:preferences-system bc-monitor:utilities-system-monitor bc-store:gnome-software \
            bc-terminal:com.mitchellh.ghostty bc-calculator:accessories-calculator bc-notes:accessories-notes bc-preview:multimedia-photo-viewer \
            bc-calendar:bc-calendar bc-reminders:bc-reminders bc-music:multimedia-audio-player; do
  src="$TOP/shell/assets/apps/${pair#*:}.svg"; [ -f "$src" ] || src="$TOP/shell/assets/icons/${pair#*:}.svg"
  [ -f "$src" ] && install -m644 "$src" "$E2/usr/share/icons/hicolor/scalable/apps/${pair%%:*}.svg"
done

# --- PKGBUILDs --------------------------------------------------------------------------------
source "$HERE/lib/rootfs.sh"
BASE="$(bc_packages "${BC_ARCH:-aarch64}" | tr ' ' '\n' | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ' ')"
mk() {   # nombre arch descripción depends backup
  local n="$1" a="$2" d="$3" deps="$4" bk="${5:-}"
  mkdir -p "$W/pkg/$n"
  cat > "$W/pkg/$n/PKGBUILD" <<P
pkgname=$n
pkgver=$VER
pkgrel=1
pkgdesc="$d"
arch=('$a')
url='https://github.com/borjacandeel/BC-OS'
license=('custom')
depends=($deps)
backup=($bk)
options=(!strip !debug !lto)
package() { [ -d /tmp/bcrepo/stage/$n ] && cp -a /tmp/bcrepo/stage/$n/. "\$pkgdir/" || true; }
P
}
A="${BC_ARCH:-aarch64}"
mk bc-shell "$A" "BC Shell: escritorio Golden Gate y apps de BC OS" "'qt6-declarative' 'layer-shell-qt' 'qtermwidget'"
mk bc-core "$A" "BC Core: servicios del sistema de BC OS" ""
mk bc-escritorio any "Sesión, configuración, fondos y sonidos de BC OS" "'bc-shell' 'sway'"
mk bc-os any "BC OS: metapaquete del sistema completo" "'bc-shell' 'bc-core' 'bc-escritorio' $BASE"
sh "id builder >/dev/null 2>&1 || useradd -m builder; chown -R builder /tmp/bcrepo/pkg"
for n in bc-shell bc-core bc-escritorio bc-os; do
  sh "cd /tmp/bcrepo/pkg/$n && su builder -c 'PKGEXT=.pkg.tar.zst makepkg -f --nodeps --noconfirm'"
done
cp "$W"/pkg/*/*.pkg.tar.zst "$OUT/"
# Base de datos del repositorio (bc.db/bc.files como archivos normales: GitHub Releases no admite enlaces)
cp -a "$OUT" "$W/out"
sh "cd /tmp/bcrepo/out && rm -f bc.db* bc.files* && repo-add -q bc.db.tar.gz \$(ls -t *.pkg.tar.zst)"
cp "$W/out/bc.db.tar.gz" "$OUT/bc.db"; cp "$W/out/bc.files.tar.gz" "$OUT/bc.files"
cp "$W/out/bc.db.tar.gz" "$W/out/bc.files.tar.gz" "$OUT/"
rm -rf "$W"
ls -la "$OUT"
