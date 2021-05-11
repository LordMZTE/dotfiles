vim.cmd  [[packadd packer.nvim]]

local function pconf(plugin)
    return "require(\"pluginconf." .. plugin .. "\")"
end

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"

    use {
        "neoclide/coc.nvim",
        branch = "release",
        config = pconf("coc")
    }
    use "scrooloose/nerdtree"
    use "Xuyuanp/nerdtree-git-plugin"
    use "tiagofumo/vim-nerdtree-syntax-highlight"
    use "ryanoasis/vim-devicons"
    use "cespare/vim-toml"
    use "junegunn/fzf"
    use {
        "dracula/vim",
        as = "dracula"
    }
    use "jiangmiao/auto-pairs"
    use "tpope/vim-endwise"
    use "vimwiki/vimwiki"
    use {
        "glacambre/firenvim",
        run = function() vim.fn["firenvim#install"](0) end,
        config = pconf("firenvim")
    }
    use "jreybert/vimagit"
    use "airblade/vim-gitgutter"
    use "dag/vim-fish"
    use "uiiaoo/java-syntax.vim"
    use "honza/vim-snippets"
    use "sheerun/vim-polyglot"
    use {
        "glepnir/galaxyline.nvim",
        branch = "main",
        config = pconf("galaxyline")
    }
    use {
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        config = pconf("treesitter")
    }
    use {
        "euclio/vim-markdown-composer",
        run = "cargo build --release",
        config = pconf("markdowncomposer")
    }
end)

