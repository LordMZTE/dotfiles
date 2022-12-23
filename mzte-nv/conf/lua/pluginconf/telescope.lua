local telescope = require "telescope"
local map = vim.api.nvim_set_keymap

telescope.setup {
    defaults = {
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
        },
    },

    pickers = {
        find_files = {
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
        },
    },

    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown {},
        },
    },
}

telescope.load_extension "ui-select"
telescope.load_extension "harpoon"

-- File finding mappings
map("n", "ff", "<cmd>Telescope find_files<cr>", { silent = true })
map("n", "fg", "<cmd>Telescope live_grep<cr>", { silent = true })

-- LSP mappings
map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { silent = true })
map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", { silent = true })
map("n", "gr", "<cmd>Telescope lsp_references<CR>", { silent = true })
map("n", "gs", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", { silent = true })

map("n", "gp", "<cmd>Telescope diagnostics bufnr=0<CR>", { silent = true })
map("n", "gP", "<cmd>Telescope diagnostics<CR>", { silent = true })

-- other mappings
map("n", "gm", "<cmd>Telescope harpoon marks<cr>", { silent = true })
