# Entorno «Dotfiles (bspwm)» — preparado, SIN integrar en la imagen todavía

Contiene la sesión X11 (bspwm, sxhkd, polybar, picom, rofi, dunst) basada en `borjacandeel/dotfiles-2026` y adaptada a BC OS.
Para activarla falta:
1. Copiar este árbol sobre el rootfs desde `build/configure-rootfs.sh` (`usr/bin/*` a 755; `usr/share/bc/sessions/*.desktop`; `usr/share/bc/dotfiles`; `etc/bc/atajos-dotfiles.txt`; `etc/X11/xorg.conf.d`), e instalar también `usr/share/bc/sessions/bc.desktop` para que el login muestre el selector.
2. Añadir a `build/packages/base.txt`: xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xrdb xorg-setxkbmap xorg-xset xf86-input-libinput xdotool xclip maim slop feh bspwm sxhkd polybar picom rofi dunst playerctl pavucontrol pcmanfm ttf-cascadia-code-nerd wmname xsecurelock xss-lock gnome-themes-extra (todos disponibles en aarch64 según el mirror).
3. Copiar `assets/wallpapers/montanas.jpg` (ya en el repo) — `configure-rootfs.sh` ya instala todos los `.jpg` de esa carpeta.
4. Probar en QEMU: elegir «Dotfiles (bspwm)» en el login; comprobar que Xorg arranca (log en `~/bc-session.log`), la barra, los atajos y `bc-xdisplay`.
El shell ya trae el selector de sesión (login y Configuración) y la tarjeta Dotfiles en la bienvenida; sin los archivos de sesión solo se ve «BC OS».
