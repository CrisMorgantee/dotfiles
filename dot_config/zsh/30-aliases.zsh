alias c="ditto" # similar to `cp`

# Prefer not overriding `cat` globally; use bcat when desired.
alias bcat='bat --theme="Nord"'

alias l="eza -lag --time-style=long-iso"
alias lt="eza --tree --level=2 --long --group --time-style=long-iso"
alias find="fd"
alias g="rg"

alias a="php artisan"
alias m="a migrate"
alias mm="a make:model"
alias mc="a make:controller"
alias mcr="a -r make:controller"
alias ma="a make:model -cmrfs"
alias mf="a migrate:fresh"
alias mfs="a migrate:fresh --seed"
alias mrs="a migrate:refresh --seed" # Migrar e semear
alias rl="a route:list"
alias horizon="a horizon"
alias key="a key:generate"
alias pint="./vendor/bin/pint"
alias tk="a tinker"
alias tp="a test --parallel"

alias gs="git status"
alias ga="git add"
alias gp="git push"
alias gl="git log --oneline --decorate --color --graph"
alias gkt="git checkout -"
alias nah="git reset --hard && git clean -df"
alias putz="git reset --soft HEAD~1"
alias wip="git add . && git commit -m 'wip' >/dev/null"
alias wips="git add . && git commit -m 'wip' >/dev/null && git push"
alias clrgkb="rm -f /tmp/.gkb_branch && echo 'Cache de branches limpo.'"

alias mkdir="mkdir -pv"
alias ping="ping -c 5"
alias clr="clear; echo Currently logged in on $TTY, as $USERNAME in directory $PWD."
alias hist="history | grep" # Pesquisa rápida no histórico

alias neoconfig="cd ~/.config/nvim && nvim init.lua"
alias ce="chezmoi edit"
alias ca="chezmoi apply"
alias cc="chezmoi cd"

alias icloud='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs/"'
alias work='cd "$HOME/workspace"'

