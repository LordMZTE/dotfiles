if set -q MZTE_ENV_SET
    exit
end
set -gx MZTE_ENV_SET

# mix should respect XDG standard
export MIX_XDG=1

# use clang compiler
export CC=clang
export CXX=clang++

# neovim editor
export EDITOR=nvim

# paths
export PATH="$HOME/.mix/escripts:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/go/bin:$PATH:$HOME/.roswell/bin"
export LUA_CPATH="$HOME/.local/lib/lua/?.so;$HOME/.local/lib/lua/?.lua;;"

if which racket >/dev/null
    set -ax PATH (racket -l racket/base -e '(require setup/dirs) (display (path->string (find-user-console-bin-dir)))')
end
