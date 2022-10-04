local lspc = require "lspconfig"
local navic = require "nvim-navic"

local caps = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

local function on_attach(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
        navic.attach(client, bufnr)
    end
end

local lua_runtime_path = vim.split(package.path, ";")
table.insert(lua_runtime_path, "lua/?.lua")
table.insert(lua_runtime_path, "lua/?/init.lua")

lspc.clangd.setup { capabilities = caps, on_attach = on_attach }
lspc.cssls.setup { capabilities = caps, on_attach = on_attach }
lspc.eslint.setup { capabilities = caps, on_attach = on_attach }
lspc.haxe_language_server.setup { capabilities = caps, on_attach = on_attach }
lspc.html.setup { capabilities = caps, on_attach = on_attach }
lspc.jsonls.setup { capabilities = caps, on_attach = on_attach }
lspc.ocamllsp.setup { capabilities = caps, on_attach = on_attach }
lspc.prosemd_lsp.setup { capabilities = caps, on_attach = on_attach }
lspc.rust_analyzer.setup {
    capabilities = caps,
    on_attach = on_attach,
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = {
                command = "clippy",
            },
        },
    },
}
lspc.sumneko_lua.setup {
    capabilities = caps,
    on_attach = on_attach,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
                path = lua_runtime_path,
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
}
lspc.taplo.setup { capabilities = caps, on_attach = on_attach }
lspc.yamlls.setup { capabilities = caps, on_attach = on_attach }
lspc.zls.setup { capabilities = caps, on_attach = on_attach }

-- Mappings.
local opts = { noremap = true, silent = true }

local map = vim.api.nvim_set_keymap
-- See `:help vim.lsp.*` for documentation on any of the below functions
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
map("n", "-n", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
map("n", "-a", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
map("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
map("n", "-d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
map("n", "-r", "<cmd>lua vim.lsp.buf.format { asnyc = true }<CR>", opts)
