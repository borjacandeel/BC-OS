
# BC OS: iniciar la sesión gráfica en tty1
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$BC_GREETD" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec bc-session
fi
