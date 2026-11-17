function fish_prompt --description 'Prompt de BC OS: usuario, carpeta y rama de git con colores e iconos (CaskaydiaCove Nerd Font)'
    set -l last $status
    # Colores de BC OS (mismos que el sistema: verde, azul, violeta, naranja y rojo de macOS)
    set -l c_user 30D158
    set -l c_dir 64D2FF
    set -l c_git BF5AF2
    set -l c_dirty FF9F0A
    set -l c_mark 0A84FF
    set -l mark '❯'
    if test (id -u) -eq 0
        set c_user FF453A
        set mark '#'
    end
    test $last -ne 0; and set c_mark FF453A

    # Carpeta: ~ para la personal, el resto abreviado como en macOS (solo el último nivel completo)
    set -l dir (prompt_pwd --dir-length 1 --full-length-dirs 1)
    set -l icon_dir ''
    test "$PWD" = "$HOME"; and set icon_dir ''

    # Rama de git (y un punto naranja si hay cambios sin guardar)
    set -l git ''
    if command -sq git; and git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        set git ' '(set_color $c_git)' '$branch
        if not git diff --quiet --ignore-submodules HEAD 2>/dev/null
            set git $git(set_color $c_dirty)' ●'
        end
    end

    echo -n -s (set_color --bold $c_user) ' ' (whoami) (set_color normal) (set_color 8E8E93) '@' (prompt_hostname) ' ' \
        (set_color --bold $c_dir) $icon_dir ' ' $dir (set_color normal) $git (set_color normal) ' ' \
        (set_color --bold $c_mark) $mark (set_color normal) ' '
end
