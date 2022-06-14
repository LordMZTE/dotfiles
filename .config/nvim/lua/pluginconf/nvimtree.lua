require("nvim-tree").setup {
    -- don't open tree when using firenvim
    open_on_setup = not vim.g.started_by_firenvim,
    diagnostics = {
        enable = true,
    },
    git = {
        ignore = false,
    },
    renderer = {
        indent_markers = { enable = true },
    },
}
