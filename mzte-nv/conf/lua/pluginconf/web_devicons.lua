local wdi = require "nvim-web-devicons"

local racket_icon = {
    icon = "λ",
    color = "#9f1d20",
    cterm_color = 88,
    name = "Racket",
}

wdi.setup {
    override = {
        rkt = racket_icon,
        rktl = racket_icon,
        rktd = racket_icon,
        scm = {
            icon = "λ",
            color = "#3e5ba9",
            cterm_color = 61,
            name = "Scheme",
        },
    },
}
