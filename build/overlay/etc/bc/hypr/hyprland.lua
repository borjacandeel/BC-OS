-- BC OS — Hyprland (con GPU): escritorio Golden Gate con animaciones fluidas tipo macOS.
-- Sistema; personaliza en ~/.config/bc/hypr-user.lua (se carga al final si existe).
-- Atajos iguales que en la sesión sway: lista completa en /etc/bc/atajos.txt

---------------- Pantalla y entrada ----------------
-- Resolución NATIVA del monitor («preferred») y escala 1: «highrr» podía elegir otra resolución (la de más Hz) y
-- «auto» agrandaba todo en algunos monitores. La frecuencia más alta y la escala por ppp las aplica bc-display.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local function leer(ruta) local f = io.open(ruta, "r"); if not f then return nil end; local s = f:read("*l"); f:close(); return s end
local home = os.getenv("HOME") or "/root"
local teclado = leer(home .. "/.config/bc/keyboard-layout") or "es"

hl.env("XCURSOR_THEME", "McMojave-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "BC")

hl.config({
    input = {
        kb_layout = teclado,
        follow_mouse = 2,             -- como macOS: foco al hacer clic; la rueda va a la ventana bajo el puntero
        touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true },
    },
})

---------------- Aspecto: ventanas como en macOS ----------------
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 0,              -- macOS no tiene borde de color: sombra y esquinas
        resize_on_border = true,
        extend_border_grab_area = 12,
        layout = "dwindle",
        allow_tearing = false,
    },
    decoration = {
        rounding = 20,               -- radio de ventana Golden Gate
        rounding_power = 2,          -- arco circular: el MISMO que dibujan las apps BC y la Terminal (con 4, squircle,
                                     -- el recorte no coincidía con su filo y las esquinas se veían cortadas y con halo)
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = false,
        shadow = {
            enabled = true,
            range = 42,
            render_power = 3,
            offset = "0 12",
            color = 0x55000000,
            color_inactive = 0x33000000,
        },
        blur = {
            enabled = true,          -- Liquid Glass real: desenfoque de lo que hay detrás
            size = 10,               -- como los widgets de macOS: fondo muy difuminado (solo luz y color)
            passes = 3,
            noise = 0.01,
            contrast = 1.08,
            brightness = 1.05,
            vibrancy = 0.35,
            vibrancy_darkness = 0.0,
            popups = true,
            new_optimizations = true,
            xray = false,
        },
    },
    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = 0x04111F,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    dwindle = { preserve_split = true },
    cursor = { inactive_timeout = 0 },
})

---------------- Animaciones (curvas tipo macOS: rápidas al empezar, suaves al terminar) ----------------
-- «speed» va en décimas de segundo: 2,2 = 220 ms. macOS es casi instantáneo pero animado (150–300 ms); antes había 600 ms.
hl.curve("mac",       { type = "bezier", points = { {0.25, 1.0}, {0.5, 1.0} } })      -- ease-out
hl.curve("macIn",     { type = "bezier", points = { {0.42, 0.0}, {1.0, 1.0} } })      -- ease-in (salidas)
hl.curve("macInOut",  { type = "bezier", points = { {0.42, 0.0}, {0.58, 1.0} } })
hl.curve("muelle",    { type = "spring", mass = 1, stiffness = 420, damping = 35 })    -- rebote leve y rápido (abrir, ~0,2 s)
hl.curve("lineal",    { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 2.5, bezier = "mac" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 2.2, spring = "muelle",  style = "popin 88%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.5, bezier = "macIn",   style = "popin 90%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 2.0, spring = "muelle" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.6, bezier = "mac" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.3, bezier = "macIn" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 1.8, bezier = "mac" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 1.8, bezier = "mac" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 1.8, bezier = "mac" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.7, bezier = "mac",     style = "popin 94%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.2, bezier = "macIn",   style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.5, bezier = "mac" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "macIn" })
-- Cambio de escritorio: deslizamiento lateral como los Spaces de macOS
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.8, bezier = "macInOut", style = "slide" })
-- Minimizar (escritorio especial): baja hacia el Dock
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.6, bezier = "mac", style = "slidevert" })
hl.animation({ leaf = "border",        enabled = false, speed = 1, bezier = "lineal" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 5,   bezier = "mac" })

---------------- Reglas ----------------
-- Como macOS: todas las ventanas flotan, centradas (el modo mosaico se activa con Súper+Mayús+Espacio)
-- Modo de ventanas (bc-wm-mode): «floating» (por defecto, como macOS) o «tiling» (mosaico)
local modo = leer(home .. "/.config/bc/layout-mode") or "floating"
if modo ~= "tiling" then hl.window_rule({ name = "flotar", match = { class = ".*" }, float = true }) end
hl.window_rule({ name = "centrar",      match = { class = ".*", float = true }, center = true })
-- Las apps de BC dibujan su marco con el mismo radio (20): Hyprland las recorta igual y les da la sombra de macOS
hl.window_rule({ name = "no-maximizar", match = { class = ".*" }, suppress_event = "maximize" })
-- Superficies del panel (barra, Dock, menús, avisos): vidrio con el desenfoque del compositor
hl.layer_rule({ name = "bc-vidrio", match = { namespace = "^bc-(popups|dock|notify|topbar|center|desktop)$" }, blur = true, ignore_alpha = 0.02 })
hl.layer_rule({ name = "bc-capa-sin-anim", match = { namespace = "^bc-(wallpaper|desktop|chrome|full|hot)$" }, no_anim = true })

---------------- Gestos (siguen al dedo) ----------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------- Atajos ----------------
local mod = "SUPER"
local function b(k, d, o) hl.bind(k, d, o) end
local sh = hl.dsp.exec_cmd
b("CTRL + Return", sh("bc-terminal"))
b(mod .. " + Return", sh("bc-terminal"))
b("CTRL + B", sh("firefox"))
b(mod .. " + B", sh("firefox"))
b(mod .. " + E", sh("bc-shell --app files"))
b("CTRL + space", sh("bc-ctl spotlight"))
b(mod .. " + space", sh("bc-ctl spotlight"))
b("F4", sh("bc-ctl launchpad"))
b(mod .. " + A", sh("bc-ctl launchpad"))
b("F3", sh("bc-ctl mission"))
b("CTRL + up", sh("bc-ctl mission"))
b("CTRL + down", sh("bc-ctl mission"))
b(mod .. " + N", sh("bc-ctl notifications"))
b("F11", sh("bc-ctl desktop"))
b(mod .. " + C", sh("bc-ctl center"))
b(mod .. " + V", sh("bc-ctl clipboard"))
b("CTRL + " .. mod .. " + Q", sh("bc-ctl lock"))
b(mod .. " + SHIFT + E", sh("bc-ctl power logout"))
b(mod .. " + F1", sh("mousepad /etc/bc/atajos.txt"))
-- Ventanas (Hyprland anima el cierre por sí mismo)
b(mod .. " + Q", hl.dsp.window.close())
b(mod .. " + W", hl.dsp.window.close())   -- mismos atajos en todos los entornos (también bspwm): Súper+W cierra
b("CTRL + Q", hl.dsp.window.close())
b(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
b(mod .. " + M", sh("bc-ctl minimize"))
b("CTRL + ALT + Escape", sh("bc-ctl forcequit"))
b("CTRL + " .. mod .. " + space", sh("bc-ctl emoji"))
b(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
b(mod .. " + SHIFT + space", sh("bc-wm-mode toggle"))
b(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
b(mod .. " + right", hl.dsp.focus({ direction = "right" }))
b(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
b(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
b(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
b(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
b(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
b(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
-- Como macOS: Ctrl+←/→ cambia de escritorio
b("CTRL + left",  hl.dsp.focus({ workspace = "m-1" }))
b("CTRL + right", hl.dsp.focus({ workspace = "m+1" }))
for i = 1, 9 do
    b(mod .. " + " .. i,          hl.dsp.focus({ workspace = i }))
    b("CTRL + " .. i,             hl.dsp.focus({ workspace = i }))
    b(mod .. " + SHIFT + " .. i,  hl.dsp.window.move({ workspace = i }))
    b("CTRL + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end
-- Selector de apps (⌘Tab)
b("ALT + Tab", sh("bc-ctl switcher"))
b("ALT + SHIFT + Tab", sh("bc-ctl switcher-back"))
b(mod .. " + Tab", sh("bc-ctl switcher"))
-- Arrastrar con Ctrl/Súper: mover (izquierdo) y redimensionar (derecho)
b(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
b(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
b("CTRL + mouse:272", hl.dsp.window.drag(), { mouse = true })
b("CTRL + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Multimedia y capturas
b("XF86AudioRaiseVolume", sh("sh -c 'wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; bc-ctl osd volume'"), { locked = true, repeating = true })
b("XF86AudioLowerVolume", sh("sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; bc-ctl osd volume'"), { locked = true, repeating = true })
b("XF86AudioMute", sh("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; bc-ctl osd volume'"), { locked = true })
b("XF86MonBrightnessUp", sh("sh -c 'brightnessctl -c backlight set 5%+; bc-ctl osd brightness'"), { locked = true, repeating = true })
b("XF86MonBrightnessDown", sh("sh -c 'brightnessctl -c backlight set 5%-; bc-ctl osd brightness'"), { locked = true, repeating = true })
b("XF86AudioPlay", sh("playerctl play-pause"), { locked = true })
b("XF86AudioNext", sh("playerctl next"), { locked = true })
b("XF86AudioPrev", sh("playerctl previous"), { locked = true })
b("Print", sh("bc-screenshot pantalla"))
b(mod .. " + SHIFT + S", sh("bc-screenshot area"))
b("ALT + Print", sh("bc-screenshot ventana"))

---------------- Arranque de la sesión ----------------
hl.on("hyprland.start", function()
    local fondo = leer(home .. "/.config/bc/wallpaper") or "/usr/share/bc/wallpapers/dunas-noche.jpg"
    hl.exec_cmd("swaybg -m fill -i '" .. fondo:gsub("'", "") .. "'")
    hl.exec_cmd("bc-display watch")
    hl.exec_cmd("sh -c 'sleep 2; bc-render-apply'")   -- BC Adaptive Renderer: efectos del compositor según el nivel
    hl.exec_cmd("sh -c 'command -v VBoxClient >/dev/null && systemd-detect-virt -q --vm && VBoxClient --clipboard'")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("swayidle -w timeout 600 'bc-ctl lock' timeout 900 'hyprctl dispatch \"hl.dsp.dpms({ action = \\\"off\\\" })\"' resume 'hyprctl dispatch \"hl.dsp.dpms({ action = \\\"on\\\" })\"' before-sleep 'bc-ctl lock'")
    -- Panel de BC Shell: se relanza si termina; si cae con la pantalla bloqueada, swaylock la protege
    hl.exec_cmd("sh -c 'while [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; do bc-shell --panel; [ -f \"$XDG_RUNTIME_DIR/bc-bloqueado\" ] && swaylock -f -c 0B1020 -e -F; sleep 1; done'")
end)

-- Personalización del usuario
local usuario = home .. "/.config/bc/hypr-user.lua"
if io.open(usuario, "r") then dofile(usuario) end
