local lspc = require "lspconfig"
local caps = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

caps.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
}

local function disableFormatter(client, _)
    client.server_capabilities.documentFormattingProvider = false
end

local lua_runtime_path = vim.split(package.path, ";")
table.insert(lua_runtime_path, "lua/?.lua")
table.insert(lua_runtime_path, "lua/?/init.lua")

lspc.clangd.setup {
    capabilities = caps,
    on_attach = disableFormatter,
}
lspc.cssls.setup { capabilities = caps }
lspc.elixirls.setup {
    capabilities = caps,
    cmd = { "elixir-ls" },
}
lspc.eslint.setup { capabilities = caps }
lspc.haxe_language_server.setup { capabilities = caps }
lspc.html.setup { capabilities = caps }
lspc.jsonls.setup { capabilities = caps }
lspc.ocamllsp.setup { capabilities = caps }
lspc.prosemd_lsp.setup { capabilities = caps }
lspc.racket_langserver.setup { capabilities = caps }
lspc.rust_analyzer.setup {
    capabilities = caps,
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
lspc.taplo.setup { capabilities = caps }
lspc.yamlls.setup { capabilities = caps }
lspc.zls.setup { capabilities = caps }
