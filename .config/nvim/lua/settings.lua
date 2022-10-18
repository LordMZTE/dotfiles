local cmd = vim.cmd

local o = vim.o
local wo = vim.wo
local g = vim.g
local opt = vim.opt

cmd "syntax on"
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
opt.number = true
opt.relativenumber = true
o.guifont = "Iosevka:h10"
o.mouse = "a"
o.termguicolors = true
wo.cursorline = true
wo.cursorcolumn = true

g.zig_fmt_autosave = 0

o.conceallevel = 2

-- disable garbage providers
g.loaded_python_provider = false
g.loaded_python3_provider = false
g.loaded_ruby_provider = false
g.loaded_perl_provider = false
g.loaded_node_provider = false

cmd "colorscheme dracula"

cmd "autocmd StdinReadPre * let s:std_in=1"

cmd "filetype plugin on"
