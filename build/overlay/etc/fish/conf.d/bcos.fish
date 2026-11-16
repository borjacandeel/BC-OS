# BC OS: fish con sugerencias automáticas, colores de la marca y atajos inteligentes
# Saludo: functions/fish_greeting.fish (último inicio de sesión, como en macOS)
set -g fish_autosuggestion_enabled 1

# Colores base de BC OS (azul medianoche, plata y acento #2F7BF5)
set -g fish_color_command 2F7BF5 --bold
set -g fish_color_param E8ECF5
set -g fish_color_quote 34C759
set -g fish_color_error FF5F57
set -g fish_color_comment 8E9BB2
set -g fish_color_operator FF9F0A
set -g fish_color_escape FF9F0A
set -g fish_color_end 8E9BB2
set -g fish_color_redirection FF9F0A
set -g fish_color_autosuggestion 6B7894
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=2D63D8
set -g fish_color_search_match --background=2D63D8
set -g fish_pager_color_prefix 2F7BF5 --bold
set -g fish_pager_color_completion E8ECF5
set -g fish_pager_color_description 8E9BB2
set -g fish_pager_color_selected_background --background=2D63D8
set -g fish_pager_color_progress 8E9BB2

# Abreviaturas (se expanden al pulsar espacio, así se ve qué se ejecuta)
if status is-interactive
    abbr -a actualizar 'sudo pacman -Syu'
    abbr -a instalar 'sudo pacman -S'
    abbr -a buscar 'pacman -Ss'
    abbr -a ll 'ls -lah'
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a gs 'git status'
    abbr -a gd 'git diff'
    abbr -a gl 'git log --oneline -15'
    if command -sq eza
        alias ls 'eza --group-directories-first'
        alias ll 'eza -lah --group-directories-first'
    end
    if command -sq bat
        alias cat 'bat --paging=never --style=plain'
    end
    # cd inteligente: «z carpeta» salta a la más usada
    if command -sq zoxide
        zoxide init fish | source
    end
    # Ctrl+R / Ctrl+T / Alt+C con búsqueda difusa
    if command -sq fzf
        set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border --color=bg+:#16275A,fg+:#E8ECF5,hl:#2F7BF5,hl+:#2F7BF5,pointer:#2F7BF5,prompt:#2F7BF5,info:#8E9BB2'
        if test -e /usr/share/fzf/key-bindings.fish
            source /usr/share/fzf/key-bindings.fish
            fzf_key_bindings
        end
    end
end
