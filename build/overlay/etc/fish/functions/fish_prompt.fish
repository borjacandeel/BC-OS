function fish_prompt --description 'Prompt de BC OS (como zsh en el Terminal de macOS: usuario@equipo carpeta %)'
    set -l last $status
    set -l mark '%'
    test (id -u) -eq 0; and set mark '#'
    set -l color normal
    test $last -ne 0; and set color FF5F57
    # Rama de git en gris, discreta (solo dentro de un repositorio)
    set -l git (fish_vcs_prompt ' (%s)' 2>/dev/null)
    echo -n -s (whoami) '@' (prompt_hostname) ' ' (basename (prompt_pwd)) (set_color 8E8E93) $git (set_color normal) ' ' (set_color $color) $mark (set_color normal) ' '
end
