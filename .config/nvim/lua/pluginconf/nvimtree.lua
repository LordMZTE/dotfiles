require("nvim-tree").setup {
    open_on_setup = true,
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
