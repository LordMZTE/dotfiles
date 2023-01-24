local configs = require "nvim-treesitter.configs"
local parsers = require "nvim-treesitter.parsers"

local parser_config = parsers.get_parser_configs()

parser_config.haxe = {
    install_info = {
        url = "https://github.com/vantreeseba/tree-sitter-haxe",
        files = { "src/parser.c" },
        branch = "main",
    },
    filetype = "haxe",
}

configs.setup {
    ensure_installed = { "haxe" },
    highlight = {
        enable = true,
    },

    autotag = {
        enable = true,
    },

    indent = {
        enable = true,
    },

    rainbow = {
        enable = true,

        hlgroups = {
            "TSRainbow1",
            "TSRainbow2",
            "TSRainbow3",
            "TSRainbow4",
            "TSRainbow5",
            "TSRainbow6",
        },
    },
}
