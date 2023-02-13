local map = vim.api.nvim_set_keymap

require("nvim-tree").setup {
    actions = {
        change_dir = {
            global = true,
        },
    },
    view = {
        adaptive_size = true,
    },
    diagnostics = {
        enable = true,
    },
    git = {
        ignore = false,
    },
    renderer = {
        indent_markers = { enable = true },
        group_empty = true,
    },
}

vim.api.nvim_create_autocmd({ "VimEnter" }, {
    callback = function(data)
        local is_no_name = data.file == "" and vim.bo[data.buf].buftype == ""
        local is_dir = vim.fn.isdirectory(data.file) == 1

        if is_dir then
            vim.cmd.cd(data.file)
        end

        if is_no_name or is_dir then
            require("nvim-tree.api").tree.open()
        end
    end,
})

map("n", "TT", [[<cmd>NvimTreeToggle<CR>]], { noremap = true, silent = true })
