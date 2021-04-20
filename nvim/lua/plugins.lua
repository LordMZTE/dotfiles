vim.cmd  [[packadd packer.nvim]]

return require("packer").startup(function(use)
    use "wbthomason/packer.nvim"

    use {"neoclide/coc.nvim", branch = "release"}
    use "scrooloose/nerdtree"
    use {"jdonaldson/vaxe", branch = "neovaxe", run = "sh install.sh"}
    use "SirVer/ultisnips"
    use "Xuyuanp/nerdtree-git-plugin"
    use "tiagofumo/vim-nerdtree-syntax-highlight"
    use "ryanoasis/vim-devicons"
    use "cespare/vim-toml"
    use "~/go/src/github.com/junegunn/fzf"
    use {"dracula/vim", as = "dracula"}
    use "jiangmiao/auto-pairs"
    use "tpope/vim-endwise"
    use "vimwiki/vimwiki"
    use {"glacambre/firenvim", run = function() vim.fn["firenvim#install"](0) end}
    use 'vim-airline/vim-airline'
    use 'vim-airline/vim-airline-themes'
    use 'jreybert/vimagit'
    use 'airblade/vim-gitgutter'
    use 'dag/vim-fish'
    use 'uiiaoo/java-syntax.vim'
end)
