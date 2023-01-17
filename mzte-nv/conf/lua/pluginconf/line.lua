local lline = require "lualine"

lline.setup {
    options = {
        theme = "dracula",
    },
    sections = {
        lualine_b = { "branch", "diff" },
        lualine_c = { "filename", "diagnostics" },
    },
}
