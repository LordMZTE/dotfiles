local ls = require "luasnip"

require("luasnip.loaders.from_vscode").load()
require("luasnip.loaders.from_snipmate").load()

ls.add_snippets("markdown", {
    ls.snippet("shrug", {
        ls.text_node [[¯\_(ツ)_/¯]],
    }),
})
