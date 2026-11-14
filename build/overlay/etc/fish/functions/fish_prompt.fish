function fish_prompt --description 'Prompt de BC OS'
    set -l last $status
    set -l who (set_color 2F7BF5 --bold)(whoami)(set_color 8E9BB2)'@'(set_color E8ECF5)(prompt_hostname)
    set -l where (set_color 2F7BF5)(prompt_pwd)
    set -l mark (set_color 2F7BF5)'❯ '
    test $last -ne 0; and set mark (set_color FF5F57)'❯ '
    echo -n -s $who ' ' $where (fish_git_prompt) ' ' $mark (set_color normal)
end
