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

parser_config.norg_meta = {
    install_info = {
        url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
        files = { "src/parser.c" },
        branch = "main",
    },
}

parser_config.norg_table = {
    install_info = {
        url = "https://github.com/nvim-neorg/tree-sitter-norg-table",
        files = { "src/parser.c" },
        branch = "main",
    },
}

configs.setup {
    ensure_installed = { "haxe", "norg", "norg_meta", "norg_table" },
    highlight = {
        enable = true,
    },

    autotag = {
        enable = true,
    },

    rainbow = {
        enable = true,
        extended_mode = true,

        colors = {
            "#ff00be",
            "#ff7e00",
            "#64d200",
            "#00e6b6",
            "#00e1ff",
            "#9598ff",
        },
    },
}
