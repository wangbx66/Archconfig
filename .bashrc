[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

alias ls='ls --color=auto'
alias la='ls -A'
alias sudo='sudo -E'
alias syu='sudo pacman -Syu'
alias syyu='sudo pacman -Syyu'
alias syua='yaourt -Syua'
alias syyua='yaourt -Syyua'
alias sws='python ~/Tools/swslogin.py'
alias erg='python ~/Tools/ergwave/ergwave.py'
alias pipi='pip install --upgrade --user'
alias pipi2='pip2 install --upgrade --user'
alias pipu='python ~/Tools/pipu.py'
alias trash='rm -rf /home/wangbx/.local/share/Trash/files'
alias dcj='/home/wangbx/dcj_linux/dcj.sh'
