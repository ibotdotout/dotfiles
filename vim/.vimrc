call plug#begin('~/.vim/plugged')

" Vim Plugin
Plug 'zhaocai/GoldenView.Vim'
Plug 'bronson/vim-trailing-whitespace'
Plug 'scrooloose/nerdtree'
Plug 'justinmk/vim-sneak'
Plug 'vim-scripts/ZoomWin'
Plug 'majutsushi/tagbar'
Plug 'ervandew/supertab'
Plug 'kien/ctrlp.vim'
Plug 'ddollar/nerdcommenter'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'ibotdotout/vimrc-custom'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-unimpaired'

"Syntax Highligh
Plug 'ekalinin/Dockerfile.vim'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

" Vim Theme
Plug 'noahfrederick/vim-hemisu'
Plug 'edkolev/tmuxline.vim'

call plug#end()

"change <Leader> / to space
let mapleader = " "

" remao NERDTree
map <leader>n  :NERDTreeToggle<CR>

" remap Tagbar
nnoremap <leader>[ :TagbarToggle<CR>
nnoremap <leader>] :TagbarOpen fj<CR>

" remap NERDComToggleComment
nmap <leader>/ <leader>c<Space>
vmap <leader>/ <leader>c<Space>

" remap CtrlP to avoid GoldenView.View
let g:ctrlp_map = '<leader>p'
nnoremap <leader>p :CtrlP<CR>
nnoremap <leader>. :CtrlPTag<cr>

" enable powerline font
let g:airline_theme = 'dark'
let g:tmuxline_theme = 'airline'
let g:promptline_theme = 'airline'
" Fix vim-airline not appear unitl create new split
set laststatus=2

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" syntastic
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" set theme
if filereadable(expand("~/.vim/plugged/vim-hemisu"))
  syntax enable
  set background=dark
  colorscheme hemisu
  let g:solarized_termcolors=256
endif


" local settings
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
