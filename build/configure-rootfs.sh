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
sed -i '/# BC OS: iniciar la sesión gráfica/,$d' "$S/.bash_profile"
cat "$HERE/overlay/etc/skel/.bash_profile" >> "$S/.bash_profile"
mkdir -p "$S/.config/labwc"; install -m644 "$HERE"/overlay/etc/skel/.config/labwc/* "$S/.config/labwc/"
install -m755 "$HERE/overlay/usr/bin/bc-session" "$R/usr/bin/bc-session"
install -D -m644 "$HERE/overlay/etc/systemd/system/getty@tty1.service.d/autologin.conf" "$R/etc/systemd/system/getty@tty1.service.d/autologin.conf"

# /root para root (0700), /home para usuarios (0755)
chmod 755 "$R/home"; chmod 700 "$R/root"
cp -a "$S/." "$R/root/" 2>/dev/null || true; chmod 700 "$R/root"

# Usuarios: se elimina el usuario por defecto 'alarm'; se bloquea root; usuario 'bc' con cambio de contraseña obligatorio
sh "userdel -r alarm 2>/dev/null || true"
sh "passwd -l root"
sh "userdel -r bc 2>/dev/null || true"
sh "useradd -m -G wheel,audio,video,input -s /bin/bash -c 'BC' bc"
sh "echo 'bc:bcos' | chpasswd"
install -m440 "$HERE/overlay/etc/sudoers.d/10-wheel" "$R/etc/sudoers.d/10-wheel"

# Tema de iconos BC (Freedesktop) como tema por defecto
mkdir -p "$R/usr/share/icons"; rm -rf "$R/usr/share/icons/BC"
cp -a "$HERE/../icons/dist/theme/BC" "$R/usr/share/icons/BC"
mkdir -p "$R/etc/gtk-3.0"; printf '[Settings]\ngtk-icon-theme-name=BC\n' > "$R/etc/gtk-3.0/settings.ini"

# Reducción de tamaño (imagen para máquinas virtuales UEFI; BC_KEEP_FIRMWARE=1 conserva linux-firmware)
if [[ "${BC_KEEP_FIRMWARE:-0}" != "1" ]]; then
  sh "pacman -Q linux-firmware >/dev/null 2>&1 && pacman -Rdd --noconfirm --disable-sandbox linux-firmware linux-firmware-whence 2>/dev/null || true"
  sh "pacman -Q linux-firmware-whence >/dev/null 2>&1 && pacman -Rdd --noconfirm --disable-sandbox linux-firmware-whence || true"
fi
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
sh "systemctl enable NetworkManager systemd-timesyncd systemd-resolved nftables sshd bluetooth"
install -D -m644 "$HERE/overlay/etc/ssh/sshd_config.d/10-bcos.conf" "$R/etc/ssh/sshd_config.d/10-bcos.conf"
install -D -m644 "$HERE/overlay/etc/systemd/zram-generator.conf" "$R/etc/systemd/zram-generator.conf"
install -D -m644 "$HERE/overlay/etc/nftables.conf" "$R/etc/nftables.conf"

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
