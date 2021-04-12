# activate usable-mode
fish_vi_key_bindings

# ALIASES
alias ls="lsd"
alias ll="ls -l"
alias la="ll -a"
alias lt="ll --tree"
alias clip="xclip -sel clip"
alias nv="nvim"
alias nvide="rbg neovide --multiGrid"

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

# ENV
export CXX=clang++
export EDITOR=nvim

export PATH="$PATH:$HOME/.cargo/bin:$HOME/.local/bin:/var/lib/snapd/snap/bin:$HOME/go/bin"

# initialization stuff
ifpresent starship 'starship init fish | source'
ifpresent zoxide 'zoxide init fish | source'
ifpresent cod 'cod init %self fish | source'
ifpresent navi 'navi widget fish | source'
ifpresent opam 'eval (opam env)'

