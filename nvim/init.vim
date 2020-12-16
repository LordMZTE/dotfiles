packadd dracula
syntax enable
colorscheme dracula


set tabstop=4
set shiftwidth=4
set expandtab
command GoToFile cd %:p:h
set clipboard^=unnamed
set shell=bash shellquote=\" shellxquote=\"
set shcf=-c
tnoremap <Esc> <C-\><C-n>
set number

call plug#begin('~/AppData/Local/nvim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
Plug 'jdonaldson/vaxe', {'branch' : 'neovaxe', 'do' : 'sh install.sh'}
Plug 'SirVer/ultisnips'
    let g:UltiSnipsSnippetDirectories=["UltiSnips", "bundle/UltiSnips/UltiSnips"]

call plug#end()

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

