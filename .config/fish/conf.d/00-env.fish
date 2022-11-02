if set -q MZTE_ENV_SET
    exit
end
set -gx MZTE_ENV_SET

# use clang compiler
export CC=clang
export CXX=clang++

# neovim editor
export EDITOR=nvim

# paths
export PATH="$HOME/.mix/escripts:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"
export LUA_CPATH="$HOME/.local/lib/lua/?.so;$HOME/.local/lib/lua/?.lua;;"
