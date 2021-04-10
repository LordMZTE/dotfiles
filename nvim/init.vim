syntax on
set tabstop=4
set shiftwidth=4
set expandtab
command GoToFile cd %:p:h
tnoremap <Esc> <C-\><C-n>
set number

call plug#begin(stdpath('data') . '/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
Plug 'jdonaldson/vaxe', {'branch' : 'neovaxe', 'do' : 'sh install.sh'}
Plug 'SirVer/ultisnips'
    let g:UltiSnipsSnippetDirectories=["UltiSnips", "bundle/UltiSnips/UltiSnips"]

Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'ryanoasis/vim-devicons'
Plug 'cespare/vim-toml'
Plug '~/go/src/github.com/junegunn/fzf'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'cespare/vim-toml'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-endwise'
Plug 'vimwiki/vimwiki'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jreybert/vimagit'
Plug 'airblade/vim-gitgutter'
Plug 'dag/vim-fish'
Plug 'uiiaoo/java-syntax.vim'

call plug#end()

colorscheme dracula

let g:airline_powerline_fonts = 1
let g:neovide_iso_layout = v:true
let NERDTreeShowHidden=1

set guifont=Iosevka:h12
nnoremap <silent> fzf :FZF<CR>

" quick cursor movement while holding ctrl
nnoremap <C-Up> 5k
nnoremap <C-Down> 5j

" quick pasting/yoinking to system register
nnoremap +y "+y
nnoremap +p "+p
nnoremap +d "+d

nnoremap *y "*y
nnoremap *p "*p
nnoremap *d "*d

" firemvim config
let g:firenvim_config = {
    \ 'localSettings': {
        \ '.*twitch\.tv.*': {
            \ 'takeover': 'never'
        \ }
    \ }
\ }

" Symbol renaming.
nmap cn <Plug>(coc-rename)

" Apply AutoFix to problem on the current line.
nmap cf  <Plug>(coc-fix-current)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Use space o to show symbols
nnoremap <silent> <space>o :CocList -I symbols<CR>

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
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') && !exists("g:started_by_firenvim") | NERDTree | endif

filetype plugin on
set nocompatible
set mouse=a
set termguicolors

