local ufo = require "ufo"
local ts_parsers = require "nvim-treesitter.parsers"
local map = vim.api.nvim_set_keymap

ufo.setup {
    open_fold_hl_timeout = 0, -- disable blinky thingy when opening fold
    provider_selector = function(_, ft, _)
        if ts_parsers.has_parser(ft) then
            return { "lsp", "treesitter" }
        else
            return { "lsp", "indent" }
        end
    end,
}

vim.o.foldcolumn = "1"
-- https://github.com/neovim/neovim/pull/17446
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.o.foldlevel = 256
vim.o.foldlevelstart = 256
vim.o.foldenable = true

local map_opts = {
    noremap = true,
    silent = true,
}

map("n", "t", "za", map_opts) -- toggle fold
map("n", "zO", [[<cmd>lua require("ufo").openAllFolds()<CR>]], map_opts)
map("n", "zC", [[<cmd>lua require("ufo").closeAllFolds()<CR>]], map_opts)
