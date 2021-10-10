require 'nvim-tree'.setup {
    -- don't open tree when using firenvim
    open_on_setup = not vim.g.started_by_firenvim,
    auto_close = true,
    diagnostics = {
        enable = true,
    },
    view = {
        auto_resize = true,
    },
}

