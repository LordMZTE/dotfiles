local norg = require "neorg"

norg.setup {
    load = {
        ["core.norg.concealer"] = {},
        ["core.norg.completion"] = {
            config = {
                engine = "nvim-cmp",
            },
        },
        ["core.defaults"] = {},
    },
}
