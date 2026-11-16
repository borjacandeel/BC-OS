function fish_greeting --description 'Como el Terminal de macOS: «Último inicio de sesión: … en ttys000»'
    set -l f (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo ~/.local/state)/bc/ultimo-login
    set -l tty (tty 2>/dev/null | string replace '/dev/' '')
    test -n "$tty"; or set tty ttys000
    test -r $f; and echo "Último inicio de sesión: "(cat $f)
    mkdir -p (dirname $f) 2>/dev/null
    echo (LC_TIME=es_ES.UTF-8 date '+%a %e %b %H:%M:%S' | string replace -r '\s+' ' ')" en $tty" > $f 2>/dev/null
end
