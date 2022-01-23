local cmp = require "cmp"

cmp.setup {
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },

    mapping = {
        ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
        ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
        ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
        ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item()),
        ["<S-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item()),
        ["<CR>"] = cmp.mapping.confirm { select = true },
    },

    sources = cmp.config.sources {
        { name = "buffer" },
        { name = "crates" },
        { name = "luasnip" },
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "rg" },
        { name = "treesitter" },
    },

    formatting = {
        format = function(entry, vim_item)
            vim_item.menu = ({
                buffer = " ﬘",
                crates = " ",
                luasnip = " ",
                nvim_lsp = " ",
                path = " ",
                rg = " ",
                treesitter = " ",
            })[entry.source.name]

            return vim_item
        end,
    },
}

cmp.setup.cmdline("/", {
    sources = {
        { name = "buffer" },
    },
})

cmp.setup.cmdline(":", {
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        { name = "cmdline" },
    }),
})
