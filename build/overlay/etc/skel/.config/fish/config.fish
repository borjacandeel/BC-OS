# BC OS: en tty1 sin sesión gráfica (autologin de respaldo) se inicia la sesión de escritorio
if status is-login
    if test -z "$WAYLAND_DISPLAY"; and test -z "$BC_GREETD"; and test (tty) = /dev/tty1
        exec bc-session
    end
end
