call plug#begin('~/.vim/plugged')

""""""""""""""""""""  Plugin

" Vim Plugin
Plug 'tpope/vim-sensible'
Plug 'zhaocai/GoldenView.Vim'
Plug 'justinmk/vim-sneak'
Plug 'matze/vim-move'
Plug 'mileszs/ack.vim'
Plug 'scrooloose/nerdtree'
Plug 'vim-scripts/ZoomWin', { 'on': 'ZoomWin' }
Plug 'kien/ctrlp.vim', { 'on': ['CtrlP', 'CtrlPTag'] }

" Coding
Plug 'Yggdroot/indentLine'
Plug 'majutsushi/tagbar'
Plug 'tpope/vim-unimpaired'
Plug 'ddollar/nerdcommenter'
Plug 'godlygeek/tabular'
Plug 'ibotdotout/vimrc-custom'
Plug 'bronson/vim-trailing-whitespace', { 'on': 'FixWhitespace' }

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Syntax Highligh
Plug 'scrooloose/syntastic', { 'for': ['typescript', 'javascript', 'python', 'ruby', 'markdown', 'sh'] }
Plug 'ekalinin/Dockerfile.vim', { 'for': 'Dockerfile' }
Plug 'elzr/vim-json'

" Vim Theme Plugin
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'
"
" Theme
Plug 'lloeki/vim-one-colorschemes'

call plug#end()


"""""""""""""""""""" Plugin Config

"change <Leader> / to space
let mapleader = " "

" remap NERDTree
map <leader>n  :NERDTreeToggle<CR>

" zoomwin
nnoremap <leader>zw :ZoomWin<CR>

" remap Tagbar
nnoremap <leader>[ :TagbarToggle<CR>
nnoremap <leader>] :TagbarOpen fj<CR>

" remap NERDComToggleComment
map <leader>/ <leader>c<Space>

" remap CtrlP to avoid GoldenView.View
let g:ctrlp_map = '<leader>p'
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
nnoremap <leader>p :CtrlP<CR>
nnoremap <leader>. :CtrlPTag<cr>

" syntastic
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_always_populate_loc_list = 1

" set indentLine
let g:indentLine_enabled = 1

" Fix json syntax file conflicts from indent Line
let g:vim_json_syntax_conceal = 0

" vim-move - move line up/down
let g:move_key_modifier = 'C'

" set ag for ack.vim
if executable('ag')
  let g:ackprg = 'ag --vimgrep --smart-case'
endif
cnoreabbrev Ack Ack!

" set theme
if filereadable(expand("~/.vim/plugged/vim-one-colorschemes/colors/one-light.vim"))
  colorscheme one-light
endif

" enable airline theme
let g:airline_theme = 'sol'
let g:tmuxline_theme = 'airline'
let g:promptline_theme = 'airline'

" Fix vim-airline not appear unitl create new split
set laststatus=2
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" local settings
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
