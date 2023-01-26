local lline = require "lualine"

lline.setup {
    options = {
        theme = "dracula",
    },
    sections = {
        lualine_b = { "filename", "diff" },
        lualine_c = { "diagnostics" },
    },
    tabline = {
        lualine_a = {
            {
                "tabs",
                mode = 1, -- show file name
            },
        },
        lualine_x = { "searchcount" },
        lualine_y = { "branch" },
    },
}
