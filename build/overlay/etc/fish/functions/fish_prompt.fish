function fish_prompt --description 'Prompt de BC OS (como zsh en el Terminal de macOS: usuario@equipo carpeta %)'
    set -l last $status
    set -l mark '%'
    test (id -u) -eq 0; and set mark '#'
    set -l color normal
    test $last -ne 0; and set color FF5F57
    echo -n -s (whoami) '@' (prompt_hostname) ' ' (basename (prompt_pwd)) ' ' (set_color $color) $mark (set_color normal) ' '
end
