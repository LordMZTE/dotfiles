local caps = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
local mztenv = require "mzte_nv"

local bundle_info = mztenv.jdtls.getBundleInfo()

require("jdtls").start_or_attach {
    cmd = {
        "jdtls",
        "-configuration",
        vim.loop.os_homedir() .. "/.cache/jdtls/config",
        "-data",
        vim.loop.os_homedir() .. "/.cache/jdtls/workspace",
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
                runtimes = mztenv.jdtls.findRuntimes(),
            },
            contentProvider = bundle_info.content_provider,
        },
    },

    init_options = {
        bundles = bundle_info.bundles,
    },
}
