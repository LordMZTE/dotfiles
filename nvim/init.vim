syntax enable

set tabstop=4
set shiftwidth=4
set expandtab
command GoToFile cd %:p:h
set clipboard^=unnamedplus
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

Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'ryanoasis/vim-devicons'
Plug 'cespare/vim-toml'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'airblade/vim-gitgutter'
Plug 'cespare/vim-toml'
Plug 'frazrepo/vim-rainbow'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-endwise'

call plug#end()

colorscheme dracula
let g:rainbow_active = 1

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

