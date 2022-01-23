local cmp = require "cmp"
local luasnip = require "luasnip"

local function has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
end

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
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { "i", "s" }),
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

-- define signs
local signs = {
    Error = " ",
    Warn = " ",
    Hint = " ",
    Info = " ",
}

for k, v in pairs(signs) do
    local hl = "DiagnosticSign" .. k
    vim.fn.sign_define(hl, { text = v, texthl = hl, numhl = hl })
end
