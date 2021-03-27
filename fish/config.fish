# activate usable-mode
fish_vi_key_bindings

# ALIASES
alias ls="lsd"
alias ll="ls -l"
alias la="ll -a"
alias lt="la --tree"
alias clip="xclip -sel clip"
function rbg
    $argv &>/dev/null&
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

# ENV
export CXX=clang++
export EDITOR=nvim

export PATH="$PATH:$HOME/.cargo/bin:$HOME/.local/bin:/var/lib/snapd/snap/bin"

starship init fish | source
zoxide init fish | source
cod init %self fish | source
