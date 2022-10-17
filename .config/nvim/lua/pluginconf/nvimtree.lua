require("nvim-tree").setup {
    open_on_setup = not vim.g.started_by_vinput,
    open_on_setup_file = false,
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
