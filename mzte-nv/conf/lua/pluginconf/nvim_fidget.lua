local fidget = require "fidget"

fidget.setup {
    text = {
        spinner = "zip",
    },
    window = {
        zindex = 250,
    },
}

vim.cmd [[highlight! link FidgetText DraculaFg]]
