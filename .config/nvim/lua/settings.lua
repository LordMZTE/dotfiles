local cmd = vim.cmd

local o = vim.o
local wo = vim.wo
local g = vim.g

cmd "syntax on"
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
wo.number = true
o.guifont = "Iosevka:h10"
o.mouse = "a"
o.termguicolors = true
wo.cursorline = true
wo.cursorcolumn = true

g.neoterm_default_mod = "tab"
g.neovide_iso_layout = true

-- disable garbage providers
g.loaded_python_provider = false
g.loaded_python3_provider = false
g.loaded_ruby_provider = false
g.loaded_perl_provider = false
g.loaded_node_provider = false

cmd "colorscheme dracula"

cmd "autocmd StdinReadPre * let s:std_in=1"

cmd "filetype plugin on"
