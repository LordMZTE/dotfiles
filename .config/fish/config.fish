# activate usable-mode
fish_vi_key_bindings

# ALIASES
alias ls="lsd"
alias ll="ls -l"
alias la="ll -a"
alias lt="ll --tree"
alias jo="TERM=xterm-256color joshuto"
alias clip="xclip -sel clip"
alias nv="nvim"
#alias nvide="rbg neovide --nofork --multigrid --"
alias nvide="rbg neovide --nofork --"

# colored man pages
set -gx LESS_TERMCAP_mb \e'[1;32m'
set -gx LESS_TERMCAP_md \e'[1;32m'
set -gx LESS_TERMCAP_me \e'[0m'
set -gx LESS_TERMCAP_se \e'[0m'
set -gx LESS_TERMCAP_so \e'[01;33m'
set -gx LESS_TERMCAP_ue \e'[0m'
set -gx LESS_TERMCAP_us \e'[1;4;31m'

function rbg
    $argv &>/dev/null &
end

function rbgd
    rbg $argv
    disown
end

function !!
    eval $history[1]
end

function mkdircd
    mkdir $argv[1]
    cd $argv[1]
end

function ifpresent
    if which $argv[1] &>/dev/null
        eval $argv[2..-1]
    end
end

function todos
    rg -i -H todo
end

# custom title
functions -e fish_title
function fish_title
    echo (prompt_pwd) '|' (set -q argv[1] && echo $argv[1] || status current-command)
end


# initialization stuff
ifpresent zoxide 'zoxide init fish | source'
ifpresent cod 'cod init %self fish | source'
ifpresent opam 'eval (opam env)'
ifpresent navi 'navi widget fish | source'

