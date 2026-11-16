#!/usr/bin/env bash
# Configura un rootfs Arch Linux ARM como BC OS: español, usuarios, /home, /root, servicios.
# Uso: configure-rootfs.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/chroot.sh"
bc_binfmt; bc_mount "$R"; trap 'bc_umount "$R"' EXIT
sh() { bc_chroot "$R" bash -c "$*"; }

# Identidad
install -m644 "$HERE/overlay/etc/os-release" "$R/etc/os-release"
install -m644 "$HERE/overlay/etc/issue" "$R/etc/issue"
echo "bcos" > "$R/etc/hostname"
printf '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 bcos\n' > "$R/etc/hosts"

# Idioma, teclado, zona horaria (español de España)
sed -i 's/^#\(es_ES.UTF-8\)/\1/; s/^#\(en_US.UTF-8\)/\1/' "$R/etc/locale.gen"
sh locale-gen
printf 'LANG=es_ES.UTF-8\nLC_MESSAGES=es_ES.UTF-8\nLANGUAGE=es_ES:en_US\n' > "$R/etc/locale.conf"
printf 'KEYMAP=es\n' > "$R/etc/vconsole.conf"
ln -sf /usr/share/zoneinfo/Europe/Madrid "$R/etc/localtime"

# Directorios de usuario en español (plantilla para todos los usuarios nuevos)
S="$R/etc/skel"
mkdir -p "$S/Escritorio" "$S/Documentos" "$S/Descargas" "$S/Imágenes" "$S/Música" "$S/Vídeos" "$S/Público" "$S/Plantillas" "$S/.config"
cat > "$S/.config/user-dirs.dirs" <<'E'
XDG_DESKTOP_DIR="$HOME/Escritorio"
XDG_DOCUMENTS_DIR="$HOME/Documentos"
XDG_DOWNLOAD_DIR="$HOME/Descargas"
XDG_MUSIC_DIR="$HOME/Música"
XDG_PICTURES_DIR="$HOME/Imágenes"
XDG_PUBLICSHARE_DIR="$HOME/Público"
XDG_TEMPLATES_DIR="$HOME/Plantillas"
XDG_VIDEOS_DIR="$HOME/Vídeos"
E
echo "es_ES" > "$S/.config/user-dirs.locale"
install -m644 "$HERE/overlay/etc/skel/.bashrc" "$S/.bashrc"
mkdir -p "$S/.config/fish"; install -m644 "$HERE/overlay/etc/skel/.config/fish/config.fish" "$S/.config/fish/config.fish"
install -D -m644 "$HERE/overlay/etc/fish/conf.d/bcos.fish" "$R/etc/fish/conf.d/bcos.fish"
for fn in fish_prompt fish_greeting fish_title; do install -D -m644 "$HERE/overlay/etc/fish/functions/$fn.fish" "$R/etc/fish/functions/$fn.fish"; done
sed -i '/# BC OS: iniciar la sesión gráfica/,$d' "$S/.bash_profile"
cat "$HERE/overlay/etc/skel/.bash_profile" >> "$S/.bash_profile"
install -m755 "$HERE/overlay/usr/bin/bc-session" "$HERE/overlay/usr/bin/bc-wm-mode" "$HERE/overlay/usr/bin/bc-ctl" "$HERE/overlay/usr/bin/bc-terminal" "$HERE/overlay/usr/bin/bc-screenshot" "$HERE/overlay/usr/bin/bc-display" "$HERE/overlay/usr/bin/bc-appearance" "$R/usr/bin/"
install -D -m644 "$HERE/overlay/etc/bc/sway/efectos.conf" "$R/etc/bc/sway/efectos.conf"
# Hyprland (con aceleración 3D): animaciones fluidas tipo macOS
install -D -m644 "$HERE/overlay/etc/bc/hypr/hyprland.lua" "$R/etc/bc/hypr/hyprland.lua"
install -D -m644 "$HERE/overlay/etc/bc/sway/claro.conf" "$R/etc/bc/sway/claro.conf"
for f in alacritty alacritty-oscuro alacritty-claro; do install -D -m644 "$HERE/overlay/etc/bc/$f.toml" "$R/etc/bc/$f.toml"; done
install -D -m644 "$HERE/overlay/etc/bc/ghostty.conf" "$R/etc/bc/ghostty.conf"
# Apps de BC en el lanzador, Spotlight y el Dock (Archivos, Ajustes del Sistema, Monitor de Actividad, Tienda, Terminal)
install -m644 "$HERE"/overlay/usr/share/applications/bc-*.desktop "$R/usr/share/applications/"
# Repositorio propio de BC OS ([bc], publicado en GitHub Releases por .github/workflows/repo.yml) antes de [core],
# para que los paquetes de BC tengan prioridad. bc-actualizar actualiza desde ahí (y la Tienda lo usa).
install -m755 "$HERE/repo/bc-actualizar" "$R/usr/bin/bc-actualizar"
# Instantáneas antes de cada cambio de paquetes (gancho de pacman) y bc-restaurar; la caché guarda 3 versiones
install -D -m755 "$HERE/overlay/usr/lib/bc/bc-instantanea" "$R/usr/lib/bc/bc-instantanea"
install -D -m644 "$HERE/overlay/usr/share/libalpm/hooks/00-bc-instantanea.hook" "$R/usr/share/libalpm/hooks/00-bc-instantanea.hook"
install -m755 "$HERE/overlay/usr/bin/bc-restaurar" "$HERE/overlay/usr/bin/bc-rendimiento" "$R/usr/bin/"
sh "systemctl enable paccache.timer 2>/dev/null || true"
# Tienda sin contraseña para administradores con sesión activa (polkit + ayudante restringido)
install -D -m755 "$HERE/overlay/usr/lib/bc/bc-paquetes" "$R/usr/lib/bc/bc-paquetes"
install -D -m644 "$HERE/overlay/usr/share/polkit-1/actions/org.bcos.paquetes.policy" "$R/usr/share/polkit-1/actions/org.bcos.paquetes.policy"
install -D -m644 "$HERE/overlay/etc/polkit-1/rules.d/50-bcos-paquetes.rules" "$R/etc/polkit-1/rules.d/50-bcos-paquetes.rules"
# Firma del repositorio [bc]: si está la clave pública del creador (build/repo/bcos-repo.asc), pacman la confía y
# exige paquetes firmados; si no, el repositorio se acepta sin firma (como hasta ahora).
BC_SIG="Optional TrustAll"
if [ -f "$HERE/repo/bcos-repo.asc" ]; then
  cp "$HERE/repo/bcos-repo.asc" "$R/tmp/bcos-repo.asc"
  FPR="$(gpg --with-colons --show-keys "$HERE/repo/bcos-repo.asc" 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')"
  sh "pacman-key --init >/dev/null 2>&1 || true; pacman-key --add /tmp/bcos-repo.asc && pacman-key --lsign-key $FPR" && BC_SIG="Required"
  rm -f "$R/tmp/bcos-repo.asc"
fi
if ! grep -q '^\[bc\]' "$R/etc/pacman.conf"; then
  sed -i '0,/^\[core\]/s//# Repositorio propio de BC OS (GitHub). Firmado cuando el creador añada la clave (ver build\/repo\/LEEME.md)\n[bc]\nSigLevel = '"$BC_SIG"'\nServer = https:\/\/github.com\/borjacandeel\/BC-OS\/releases\/download\/repo-$arch\n\n[core]/' "$R/etc/pacman.conf"
fi
# Iconos propios de las apps de BC (estilo Golden Gate, icons/src/app) como bc-<app> en hicolor
HI="$R/usr/share/icons/hicolor/scalable/apps"; mkdir -p "$HI"
for pair in bc-files:system-file-manager bc-settings:preferences-system bc-monitor:utilities-system-monitor bc-store:gnome-software \
            bc-terminal:utilities-terminal bc-calculator:accessories-calculator bc-notes:accessories-notes bc-preview:multimedia-photo-viewer \
            bc-calendar:bc-calendar bc-reminders:bc-reminders bc-music:multimedia-audio-player; do
  src="$HERE/../shell/assets/apps/${pair#*:}.svg"; [ -f "$src" ] || src="$HERE/../shell/assets/icons/${pair#*:}.svg"
  [ -f "$src" ] && install -m644 "$src" "$HI/${pair%%:*}.svg"
done
sh "gtk-update-icon-cache -q -f /usr/share/icons/hicolor" 2>/dev/null || true
# Vista previa abre las imágenes por defecto; Archivos, las carpetas
install -D -m644 /dev/stdin "$R/etc/xdg/mimeapps.list" <<'MIME'
[Default Applications]
image/png=bc-preview.desktop
image/jpeg=bc-preview.desktop
image/gif=bc-preview.desktop
image/webp=bc-preview.desktop
image/bmp=bc-preview.desktop
image/svg+xml=bc-preview.desktop
inode/directory=bc-files.desktop
MIME
install -D -m644 "$HERE/overlay/etc/xdg/foot/foot.ini" "$R/etc/xdg/foot/foot.ini"
install -D -m644 "$HERE/../shell/assets/wallpaper-default.png" "$R/usr/share/bc/wallpaper-default.png"
mkdir -p "$R/usr/share/bc/wallpapers"; install -m644 "$HERE"/../assets/wallpapers/*.jpg "$R/usr/share/bc/wallpapers/"
# Sonidos originales de la interfaz (Golden Gate)
mkdir -p "$R/usr/share/sounds/bc"; install -m644 "$HERE"/../assets/sounds/*.wav "$R/usr/share/sounds/bc/"
install -D -m644 "$HERE/overlay/etc/bc/sway/config" "$R/etc/bc/sway/config"
install -m644 "$HERE/overlay/etc/bc/sway/keyboard.conf" "$R/etc/bc/sway/keyboard.conf"
install -m644 "$HERE/overlay/etc/bc/atajos.txt" "$R/etc/bc/atajos.txt"
install -m644 "$HERE/overlay/etc/bc/fastfetch.jsonc" "$HERE/overlay/etc/bc/fastfetch-logo.txt" "$R/etc/bc/"
# Entorno «Dotfiles (bspwm)» (X11), elegible en el login y en Configuración (ver build/overlay-dotfiles/LEEME.md)
DF="$HERE/overlay-dotfiles"
mkdir -p "$R/usr/share/bc/sessions" "$R/usr/share/bc/dotfiles"
cp -a "$DF/usr/share/bc/sessions/." "$R/usr/share/bc/sessions/"
cp -a "$DF/usr/share/bc/dotfiles/." "$R/usr/share/bc/dotfiles/"
for f in "$DF"/usr/bin/*; do install -m755 "$f" "$R/usr/bin/$(basename "$f")"; done
install -m644 "$DF/etc/bc/atajos-dotfiles.txt" "$R/etc/bc/atajos-dotfiles.txt"
install -D -m644 "$DF/etc/X11/xorg.conf.d/10-bcos-input.conf" "$R/etc/X11/xorg.conf.d/10-bcos-input.conf"
install -D -m644 /dev/stdin "$R/etc/X11/Xwrapper.config" <<'XW'
allowed_users=anybody
needs_root_rights=auto
XW
install -d -m1777 "$R/var/lib/bc-greeter"      # elección de entorno por usuario (la escribe cada usuario; la lee el login)
install -D -m644 "$HERE/overlay/usr/lib/firefox/distribution/policies.json" "$R/usr/lib/firefox/distribution/policies.json"   # Firefox usa la barra de título del sistema (semáforo a la izquierda)
install -D -m644 "$HERE/overlay/etc/fonts/local.conf" "$R/etc/fonts/local.conf"
install -D -m644 "$HERE/overlay/etc/sysctl.d/90-bcos.conf" "$R/etc/sysctl.d/90-bcos.conf"
install -D -m644 "$HERE/overlay/etc/udev/rules.d/60-bcos-ioscheduler.rules" "$R/etc/udev/rules.d/60-bcos-ioscheduler.rules"
install -D -m440 "$HERE/overlay/etc/sudoers.d/10-bcos-pwfeedback" "$R/etc/sudoers.d/10-bcos-pwfeedback"
install -D -m644 "$HERE/overlay/etc/systemd/system/getty@tty1.service.d/autologin.conf" "$R/etc/systemd/system/getty@tty1.service.d/autologin.conf"

# /root para root (0700), /home para usuarios (0755)
chmod 755 "$R/home"; chmod 700 "$R/root"
cp -a "$S/." "$R/root/" 2>/dev/null || true; chmod 700 "$R/root"

# Usuarios: se elimina el usuario por defecto 'alarm'; se bloquea root; usuario 'bc' con cambio de contraseña obligatorio
sh "userdel -r alarm 2>/dev/null || true"
sh "passwd -l root"
sh "userdel -r bc 2>/dev/null || true"
sh "useradd -m -G wheel,audio,video,input -s /usr/bin/fish -c 'BC' bc"
sh "echo 'bc:bcos' | chpasswd"
install -m440 "$HERE/overlay/etc/sudoers.d/10-wheel" "$R/etc/sudoers.d/10-wheel"

# Tema de iconos BC (Freedesktop) como tema por defecto
mkdir -p "$R/usr/share/icons"; rm -rf "$R/usr/share/icons/BC"
cp -a "$HERE/../icons/dist/theme/BC" "$R/usr/share/icons/BC"
# Qogir (vinceliuice, GPL-3.0): iconos de aplicaciones y archivos; la interfaz del shell usa el pack BC
rm -rf "$R/usr/share/icons/Qogir"; cp -a "$HERE/../icons/qogir/Qogir" "$R/usr/share/icons/Qogir"
mkdir -p "$R/usr/share/licenses/qogir-icon-theme"; cp "$HERE/../icons/qogir/COPYING" "$HERE/../icons/qogir/AUTHORS" "$R/usr/share/licenses/qogir-icon-theme/"
# Iconos por defecto: MacOS-Like-Dark (GPL-3.0; se construye en el anfitrión) con Qogir de respaldo; cursor McMojave (GPL-3.0)
bash "$HERE/build-icons-maclike.sh" "$R" || echo "AVISO: no se pudo construir MacOS-Like; se queda Qogir"
rm -rf "$R/usr/share/icons/McMojave-cursors"; cp -a "$HERE/../icons/mcmojave/McMojave-cursors" "$R/usr/share/icons/McMojave-cursors"
mkdir -p "$R/usr/share/licenses/mcmojave-cursors"; cp "$HERE/../icons/mcmojave/LICENSE" "$R/usr/share/licenses/mcmojave-cursors/"
ICONS=MacOS-Like-Dark; [ -d "$R/usr/share/icons/MacOS-Like-Dark" ] || ICONS=Qogir
mkdir -p "$R/etc/gtk-3.0" "$R/etc/gtk-4.0"
# Tema GTK estilo macOS para las apps externas: MacTahoe (vinceliuice, MIT), versiones ya compiladas del repositorio
GTKSHA=1e45e19f510edb8cde18fa84d6cd5319f60b086b
GTKTHEME=Adwaita-dark
mkdir -p "$R/usr/share/themes"
for t in MacTahoe-Dark MacTahoe-Light; do
  curl -fsSL "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/$GTKSHA/release/$t.tar.xz" | tar -xJ -C "$R/usr/share/themes" \
    || echo "AVISO: no se pudo descargar el tema GTK $t"
done
[ -d "$R/usr/share/themes/MacTahoe-Dark" ] && GTKTHEME=MacTahoe-Dark && \
  curl -fsSL "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/$GTKSHA/COPYING" -o "$R/usr/share/themes/MacTahoe-Dark/COPYING" || true
# Interfaz con Inter (métricas próximas a SF Pro, como el escritorio Golden Gate); monoespaciada: CaskaydiaCove
printf '[Settings]\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=McMojave-cursors\ngtk-cursor-theme-size=24\ngtk-font-name=Inter 10\ngtk-application-prefer-dark-theme=1\ngtk-decoration-layout=close,minimize,maximize:\n' "$GTKTHEME" "$ICONS" | tee "$R/etc/gtk-3.0/settings.ini" > "$R/etc/gtk-4.0/settings.ini"
# Botones de ventana a la izquierda como en macOS también en apps GTK4/libadwaita (Ghostty en Hyprland, etc.)
install -d "$R/etc/dconf/db/local.d" "$R/etc/dconf/profile"
printf "[org/gnome/desktop/wm/preferences]\nbutton-layout='close,minimize,maximize:'\n\n[org/gnome/desktop/interface]\nfont-name='Inter 10'\nmonospace-font-name='DejaVu Sans Mono 11'\ncolor-scheme='prefer-dark'\n" > "$R/etc/dconf/db/local.d/00-bcos"
printf 'user-db:user\nsystem-db:local\n' > "$R/etc/dconf/profile/user"
sh "command -v dconf >/dev/null && dconf update" || true

install -D -m644 /dev/stdin "$R/usr/share/icons/default/index.theme" <<'CUR'
[Icon Theme]
Inherits=McMojave-cursors
CUR

# Reducción de tamaño (imagen para máquinas virtuales UEFI; BC_KEEP_FIRMWARE=1 conserva todo el firmware).
# Se quitan los firmware de GPU/CPU x86 y se mantienen los de Wi-Fi/Bluetooth (atheros, broadcom, mediatek, realtek).
if [[ "${BC_KEEP_FIRMWARE:-0}" != "1" ]]; then
  FW="$(sh "pacman -Qq | grep -E '^linux-firmware-(amd|amdgpu|intel|nvidia|radeon|cirrus|ti|other)$' | tr '\n' ' '")"
  [[ -n "$FW" ]] && sh "pacman -Rdd --noconfirm --disable-sandbox $FW" || true
fi
sh "pacman -Q labwc >/dev/null 2>&1 && pacman -Rns --noconfirm --disable-sandbox labwc || true"
source "$HERE/lib/rootfs.sh"
PKS="$(bc_packages "${BC_ARCH:-aarch64}")"
sh "pacman -S --needed --noconfirm --disable-sandbox $PKS" || for p in $PKS; do sh "pacman -S --needed --noconfirm --disable-sandbox $p" || echo "AVISO: falta $p"; done
sh "pacman -Q gcc >/dev/null 2>&1 && pacman -Rdd --noconfirm --disable-sandbox gcc || true"
find "$R/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name 'es*' ! -name 'en*' ! -name 'locale.alias' -exec rm -rf {} + 2>/dev/null || true
rm -rf "$R/usr/share/doc" "$R/usr/share/man" "$R/usr/share/info" "$R/usr/share/gtk-doc" "$R/usr/share/help" 2>/dev/null || true

# Instalador (bc-install) disponible en el sistema
mkdir -p "$R/usr/lib/bc-install"
cp -a "$HERE/installer/bc-install" "$HERE/installer/lang" "$R/usr/lib/bc-install/"
chmod 755 "$R/usr/lib/bc-install/bc-install"; ln -sf ../lib/bc-install/bc-install "$R/usr/bin/bc-install"

# Login gráfico con greetd (greeter propio) y respaldo de autologin
install -D -m644 "$HERE/overlay/etc/greetd/config.toml" "$R/etc/greetd/config.toml"
install -m755 "$HERE/overlay/usr/bin/bc-greeter-session" "$R/usr/bin/bc-greeter-session"
install -D -m644 "$HERE/overlay/usr/lib/tmpfiles.d/bc-greeter.conf" "$R/usr/lib/tmpfiles.d/bc-greeter.conf"
install -m644 "$HERE/overlay/etc/pam.d/bc-lock" "$R/etc/pam.d/bc-lock"
install -m644 "$HERE/overlay/etc/systemd/system/bc-login-fallback.path" "$HERE/overlay/etc/systemd/system/bc-login-fallback.service" "$R/etc/systemd/system/"
sh "systemctl enable greetd.service bc-login-fallback.path && systemctl set-default graphical.target"
sh "systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service"

# Servicios mínimos
sh "systemctl disable systemd-networkd systemd-networkd.socket systemd-networkd-wait-online 2>/dev/null || true"
rm -f "$R"/etc/systemd/network/*.network
sh "systemctl enable NetworkManager systemd-timesyncd systemd-resolved nftables sshd bluetooth"
install -D -m644 "$HERE/overlay/etc/ssh/sshd_config.d/10-bcos.conf" "$R/etc/ssh/sshd_config.d/10-bcos.conf"
install -D -m644 "$HERE/overlay/etc/systemd/zram-generator.conf" "$R/etc/systemd/zram-generator.conf"
install -D -m644 "$HERE/overlay/etc/nftables.conf" "$R/etc/nftables.conf"

# Bases de datos de todos los repositorios (también [bc]): sin ellas «pacman -S» y la Tienda fallan en el sistema
sh "pacman -Sy --noconfirm --disable-sandbox" || echo "AVISO: no se pudieron descargar las bases de pacman (¿[bc] publicado?)"
sh "pacman -Scc --noconfirm"
install -D -m644 "$HERE/overlay/etc/mkinitcpio.conf.d/bcos.conf" "$R/etc/mkinitcpio.conf.d/bcos.conf"
# Arranque animado: tema Plymouth bcos (debe ser el tema por defecto ANTES de generar el initramfs)
if [[ -d "$R/usr/share/plymouth" ]]; then
  install -d "$R/usr/share/plymouth/themes/bcos"
  install -m644 "$HERE"/plymouth/bcos/* "$R/usr/share/plymouth/themes/bcos/"
  sh "plymouth-set-default-theme bcos"
fi
sh "mkinitcpio -P"
printf 'LABEL=bc-root / ext4 rw,noatime 0 1\nLABEL=BC-ESP /boot vfat rw,noatime,umask=0077 0 2\n' > "$R/etc/fstab"

bc_umount "$R"; trap - EXIT
rm -f "$R/etc/resolv.conf"; ln -s ../run/systemd/resolve/stub-resolv.conf "$R/etc/resolv.conf"
echo "Rootfs configurado: $R"
