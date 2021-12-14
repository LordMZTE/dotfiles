vim.cmd [[packadd packer.nvim]]

local function pconf(plugin)
    return 'require("pluginconf.' .. plugin .. '")'
end

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"

    use {
        "neoclide/coc.nvim",
        branch = "release",
        config = pconf "coc",
    }
    use "ryanoasis/vim-devicons"
    use {
        "dracula/vim",
        as = "dracula",
    }
    use {
        "glacambre/firenvim",
        run = function()
            vim.fn["firenvim#install"](0)
        end,
        config = pconf "firenvim",
    }
    use "airblade/vim-gitgutter"
    use "dag/vim-fish"
    use "uiiaoo/java-syntax.vim"
    use "honza/vim-snippets"
    use "sheerun/vim-polyglot"
    use {
        "glepnir/galaxyline.nvim",
        branch = "main",
        config = pconf "galaxyline",
    }
    use {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        config = pconf "treesitter",
    }
    use {
        "euclio/vim-markdown-composer",
        run = "cargo build --release",
        config = pconf "markdowncomposer",
    }

    use "kassio/neoterm"

    use "kyazdani42/nvim-web-devicons"

    use {
        "kyazdani42/nvim-tree.lua",
        requires = "kyazdani42/nvim-web-devicons",
        config = pconf "nvimtree",
    }

    use {
        "TimUntersberger/neogit",
        requires = "nvim-lua/plenary.nvim",
    }

    use "ron-rs/ron.vim"

    use {
        "nvim-telescope/telescope.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = pconf "telescope",
    }
    use "gluon-lang/vim-gluon"
    use {
        "steelsojka/pears.nvim",
        config = pconf "nvim_pears",
    }
    use {
        "p00f/nvim-ts-rainbow",
        requires = "nvim-treesitter/nvim-treesitter",
    }
end)
