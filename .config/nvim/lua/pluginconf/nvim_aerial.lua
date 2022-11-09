local aerial = require "aerial"
local map = vim.api.nvim_set_keymap

aerial.setup {
    backends = { "lsp", "treesitter", "markdown", "man" },
}

map("n", "-o", "<cmd>AerialToggle<CR>", { noremap = true, silent = true })
