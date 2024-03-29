# activate usable-mode
fish_vi_key_bindings

# ALIASES
alias clip="xclip -sel clip"
alias nv="nvim"

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

