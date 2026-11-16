function bc-tema --description 'Elige el tema de colores de fish: bc-tema [Medianoche|Aurora|Atardecer|Lavanda|Grafito|Papel]'
    set -l temas "BC Medianoche" "BC Aurora" "BC Atardecer" "BC Lavanda" "BC Grafito" "BC Papel (claro)"
    if test (count $argv) -eq 0
        echo "Temas de BC OS:"; for t in $temas; echo "  "(string replace "BC " "" -- $t); end
        echo "Uso: bc-tema Aurora   (o «fish_config theme show» para verlos)"; return 0
    end
    for t in $temas
        if string match -qi -- "*$argv[1]*" $t
            fish_config theme save "$t" </dev/null 2>/dev/null; or fish_config theme choose "$t"
            set -U __bc_tema $t
            echo "Tema: $t"; return 0
        end
    end
    echo "No existe el tema «$argv[1]»"; return 1
end
