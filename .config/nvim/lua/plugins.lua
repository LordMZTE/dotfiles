vim.cmd [[packadd packer.nvim]]

local function pconf(plugin)
    return 'require("pluginconf.' .. plugin .. '")'
end

local function cmp_plugins(use)
    use {
        "neovim/nvim-lspconfig",
        config = pconf "lspconf",
    }
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use "hrsh7th/cmp-cmdline"
    use {
        "hrsh7th/nvim-cmp",
        config = pconf "nvim_cmp",
    }

    use "saadparwaiz1/cmp_luasnip"
    use {
        "L3MON4D3/LuaSnip",
        config = pconf "nvim_luasnip",
        requires = {
            "rafamadriz/friendly-snippets",
            "honza/vim-snippets",
        },
    }

    use {
        "simrat39/rust-tools.nvim",
        config = pconf "rust_tools",
    }

    use {
        "Saecki/crates.nvim",
        config = function()
            require("crates").setup {}
        end,
    }

    use "lukas-reineke/cmp-rg"
end

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"

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
    use "sheerun/vim-polyglot"
    use {
        "dsych/galaxyline.nvim",
        branch = "bugfix/diagnostics", -- fork with a fix to not use deprecated API
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
        "windwp/nvim-autopairs",
        config = pconf "autopairs",
    }

    use "windwp/nvim-ts-autotag"
    use {
        "p00f/nvim-ts-rainbow",
        requires = "nvim-treesitter/nvim-treesitter",
    }

    cmp_plugins(use)
end)
