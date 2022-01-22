local map = vim.api.nvim_set_keymap
local lspc = require "lspconfig"

local caps = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())

local lua_runtime_path = vim.split(package.path, ";")
table.insert(lua_runtime_path, "lua/?.lua")
table.insert(lua_runtime_path, "lua/?/init.lua")

lspc.bashls.setup { capabilities = caps } -- npm i -g bash-language-server
lspc.clangd.setup { capabilities = caps }
lspc.html.setup { capabilities = caps } -- paru -S vscode-langservers-extracted
lspc.jsonls.setup { capabilities = caps } -- paru -S vscode-langservers-extracted
lspc.rust_analyzer.setup { capabilities = caps } -- paru -S rust-analyzer
lspc.sumneko_lua.setup { -- paru -S lua-language-server
    capabilities = caps,
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
lspc.zls.setup { capabilities = caps } -- paru -S zls-bin
lspc.taplo.setup { capabilities = caps } -- paru -S taplo-lsp

-- Mappings.
local opts = { noremap = true, silent = true }

-- See `:help vim.lsp.*` for documentation on any of the below functions
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
map("n", "-n", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
map("n", "-a", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
map("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
map("n", "-d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
map("n", "-r", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)