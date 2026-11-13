# BC OS — configuración de shell
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
PS1='\[\e[1;37m\]\u@bcos\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
