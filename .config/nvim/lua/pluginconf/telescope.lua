require("telescope").setup {
    defaults = {
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
        },
    },

    pickers = {
        find_files = {
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden" },
        },
    },

    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown {},
        },
    },
}

require("telescope").load_extension "ui-select"
