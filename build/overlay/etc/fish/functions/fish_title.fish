function fish_title --description 'Título como el Terminal de macOS: usuario — proceso — columnas×filas'
    set -l cmd fish
    test -n "$argv[1]"; and set cmd (string split -f1 ' ' -- $argv[1])
    echo (whoami)' — '$cmd' — '$COLUMNS'×'$LINES
end
