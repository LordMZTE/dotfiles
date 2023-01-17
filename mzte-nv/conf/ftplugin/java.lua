local jdtls = require "jdtls"
local mztenv = require("mzte_nv").jdtls

local caps = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

local bundle_info = mztenv.getBundleInfo()
local dirs = mztenv.getDirs()

jdtls.start_or_attach {
    cmd = {
        "jdtls",
        "-configuration",
        dirs.config,
        "-data",
        dirs.workspace,
    },

    capabilities = caps,

    root_dir = require("jdtls.setup").find_root {
        ".git",
        "mvnw",
        "gradlew",
        "build.gradle",
    },

    settings = {
        java = {
            configuration = {
                runtimes = mztenv.findRuntimes(),
            },
            contentProvider = bundle_info.content_provider,
        },
    },

    init_options = {
        bundles = bundle_info.bundles,
    },

    on_attach = function(client, _)
        -- formatting is handled by clang-format
        client.server_capabilities.documentFormattingProvider = false
        -- java lsp has shit highlights
        client.server_capabilities.semanticTokensProvider = false
        require("jdtls.setup").add_commands()
        jdtls.setup_dap {
            hotcodereplace = "auto",
        }
    end,
}
