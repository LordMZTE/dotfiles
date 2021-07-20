local cmd = vim.cmd

local o = vim.o
local wo = vim.wo
local g = vim.g

cmd("syntax on")
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
wo.number = true
o.guifont = "Iosevka:h12"
o.mouse = "a"
o.termguicolors = true
wo.cursorline = true
wo.cursorcolumn = true

g.airline_powerline_fonts = 1
g.neoterm_default_mod = "tab"
g.neovide_iso_layout = true
g.nvim_tree_auto_close = 1

if not g.started_by_firenvim then
    g.nvim_tree_auto_open = 1
end

cmd("colorscheme dracula")

-- Highlight the symbol and its references when holding the cursor.
cmd("autocmd CursorHold * silent call CocActionAsync('highlight')")

cmd("autocmd StdinReadPre * let s:std_in=1")

cmd("filetype plugin on")

