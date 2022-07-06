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
    use { "hrsh7th/nvim-cmp", config = pconf "nvim_cmp" }

    use "saadparwaiz1/cmp_luasnip"
    use {
        "L3MON4D3/LuaSnip",
        config = pconf "nvim_luasnip",
        requires = {
            "rafamadriz/friendly-snippets",
            -- temporarily removed due to syntax error in recent commit
            --"honza/vim-snippets",
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
    use "ray-x/cmp-treesitter"

    use {
        "jose-elias-alvarez/null-ls.nvim",
        config = pconf "nullls",
    }

    use {
        "LhKipp/nvim-nu",
        config = function()
            require("nu").setup {
                complete_cmd_names = true,
            }
        end,
    }
end

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"

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
    use {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {}
        end,
    }
    use "dag/vim-fish"
    use "uiiaoo/java-syntax.vim"
    use "sheerun/vim-polyglot"
    use {
        "nvim-lualine/lualine.nvim",
        requires = "arkav/lualine-lsp-progress",
        config = pconf "line",
    }
    use {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdateSync",
        config = pconf "treesitter",
    }
    use {
        "euclio/vim-markdown-composer",
        run = "cargo build --release",
        config = pconf "markdowncomposer",
    }

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
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
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

    use {
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup {}
        end,
    }

    use {
        "itmecho/neoterm.nvim",
        config = pconf "nterm",
    }

    cmp_plugins(use)
end)
