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
alias nvide="rbg neovide --multigrid --"

# colored man pages
set -gx LESS_TERMCAP_mb \e'[1;32m'
set -gx LESS_TERMCAP_md \e'[1;32m'
set -gx LESS_TERMCAP_me \e'[0m'
set -gx LESS_TERMCAP_se \e'[0m'
set -gx LESS_TERMCAP_so \e'[01;33m'
set -gx LESS_TERMCAP_ue \e'[0m'
set -gx LESS_TERMCAP_us \e'[1;4;31m'

function rbg
    $argv &>/dev/null&
end

function rbgd
    rbg $argv
    disown
end

function foreachdir
    for file in (find $argv[1] -type f -print)
        f=$file eval $argv[2..-1]
    end
end

function !! 
    eval $history[1]
end

function mkdircd
    mkdir $argv[1]
    cd $argv[1]
end

function ifpresent
    if which $argv[1] &> /dev/null
        eval $argv[2..-1]
    end
end

function todos
    rg -i -H todo
end

# install custom prompt to ~/.local/bin/prompt (or somewhere else in $PATH)
functions -e fish_mode_prompt
function fish_prompt
    prompt $status $fish_bind_mode
end

# ENV
export CXX=clang++
export EDITOR=nvim

export PATH="$PATH:$HOME/.cargo/bin:$HOME/.local/bin:/var/lib/snapd/snap/bin:$HOME/go/bin"

# initialization stuff
ifpresent zoxide 'zoxide init fish | source'
ifpresent cod 'cod init %self fish | source'
ifpresent opam 'eval (opam env)'
ifpresent navi 'navi widget fish | source'

# fw init
if which fw &> /dev/null
    if test -x (command -v fw)
        if test -x (command -v fzf)
            fw print-fish-setup -f | source
        else
            fw print-fish-setup | source
        end
    end
end
