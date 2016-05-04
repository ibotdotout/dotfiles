call plug#begin('~/.vim/plugged')

" colemak
Plug 'vim-scripts/colqer'

" Vim Plugin
Plug 'zhaocai/GoldenView.Vim'
Plug 'justinmk/vim-sneak'
Plug 'ibotdotout/vimrc-custom'
Plug 'Yggdroot/indentLine'
Plug 'matze/vim-move'

Plug 'bronson/vim-trailing-whitespace', { 'on': 'FixWhitespace' }
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'vim-scripts/ZoomWin', { 'on': 'ZoomWin' }
Plug 'kien/ctrlp.vim', { 'on': ['CtrlP', 'CtrlPTag'] }

" Coding
Plug 'majutsushi/tagbar'
Plug 'ervandew/supertab'
Plug 'tpope/vim-unimpaired'
Plug 'ddollar/nerdcommenter'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Syntax Highligh
Plug 'scrooloose/syntastic', { 'for': ['javascript', 'python', 'ruby', 'markdown', 'sh'] }
Plug 'ekalinin/Dockerfile.vim', { 'for': 'Dockerfile' }
Plug 'godlygeek/tabular'

" Vim Theme Plugin
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
"
" Theme
Plug 'tomasr/molokai'

call plug#end()

"change <Leader> / to space
let mapleader = " "

" remao NERDTree
map <leader>n  :NERDTreeToggle<CR>

" zoomwin
nnoremap <leader>zw :ZoomWin<CR>

" remap Tagbar
nnoremap <leader>[ :TagbarToggle<CR>
nnoremap <leader>] :TagbarOpen fj<CR>

" remap NERDComToggleComment
nmap <leader>/ <leader>c<Space>
vmap <leader>/ <leader>c<Space>

" remap CtrlP to avoid GoldenView.View
let g:ctrlp_map = '<leader>p'
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
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
let g:syntastic_always_populate_loc_list = 1

" set indentLine
let g:indentLine_enabled = 1
let g:indentLine_leadingSpaceEnabled = 1
let g:indentLine_leadingSpaceChar = '.'

" set theme
if filereadable(expand("~/.vim/plugged/molokai/colors/molokai.vim"))
  colorscheme molokai
endif

" vim-move - move line up/down
let g:move_key_modifier = 'C'

" auto enable colemak in insert mode
autocmd VimEnter * call IMapColemakSwitch()

" local settings
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
