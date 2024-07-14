def l [path: glob = "."] { ls $path | sort-by type }
def ll [path: glob = "."] { ls -la $path | sort-by type }
def la [path: glob = "."] { ls -a $path | sort-by type }
alias nv = nvim
alias nvide = & neovide "--no-fork"

# "new shell"
alias ns = enter .

# "quit shell"
alias qs = dexit

