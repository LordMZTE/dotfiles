local lline = require "lualine"

lline.setup {
    options = {
        theme = "dracula",
    },
    sections = {
        lualine_b = { "branch", "diff", "lsp_progress" },
        lualine_c = { "filename", "diagnostics" },
    },
}
