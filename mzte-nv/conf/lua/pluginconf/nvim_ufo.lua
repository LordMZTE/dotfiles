local ufo = require "ufo"
local ts_parsers = require "nvim-treesitter.parsers"
local map = vim.api.nvim_set_keymap

local function has_lsp_folds(bufnr)
    local clients = vim.lsp.get_active_clients { bufnr = bufnr }
    for _, client in ipairs(clients) do
        if client.server_capabilities.foldingRangeProvider then
            return true
        end
    end
    return false
end

ufo.setup {
    open_fold_hl_timeout = 0, -- disable blinky thingy when opening fold
    provider_selector = function(bufnr, ft, _)
        if has_lsp_folds(bufnr) then
            return { "lsp", "indent" }
        elseif ts_parsers.has_parser(ft) then
            return { "treesitter", "indent" }
        else
            return { "indent" }
        end
    end,
}

-- https://github.com/neovim/neovim/pull/17446
--vim.o.foldcolumn = "1"
--vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.o.foldcolumn = "0"
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