call plug#begin('~/.vim/plugged')

let g:indentLine_leadingSpaceChar='·'
let g:indentLine_leadingSpaceEnabled='1'

""""""""""""""""""""  Plugin

" Vim Plugin
Plug 'tpope/vim-sensible'
Plug 'zhaocai/GoldenView.Vim'
Plug 'justinmk/vim-sneak'
Plug 'matze/vim-move'
Plug 'takac/vim-hardtime'
Plug 'mileszs/ack.vim'
Plug 'scrooloose/nerdtree' , { 'on': 'NERDTreeToggle' }
Plug 'vim-scripts/ZoomWin', { 'on': 'ZoomWin' }
Plug 'kien/ctrlp.vim', { 'on': ['CtrlP', 'CtrlPTag'] }
Plug 'chrisbra/NrrwRgn'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Coding
Plug 'Yggdroot/indentLine'
Plug 'majutsushi/tagbar'
Plug 'tpope/vim-unimpaired'
Plug 'ddollar/nerdcommenter'
Plug 'godlygeek/tabular'
Plug 'ibotdotout/vimrc-custom'
Plug 'bronson/vim-trailing-whitespace', { 'on': 'FixWhitespace' }
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Syntax Highligh
Plug 'w0rp/ale'
Plug 'ekalinin/Dockerfile.vim', { 'for': 'Dockerfile' }
Plug 'elzr/vim-json'
Plug 'jvirtanen/vim-hcl', { 'for': 'hcl' }
Plug 'hashivim/vim-terraform'
Plug 'leafgarland/typescript-vim'

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

" disable GoldenView.vim mapping
let g:goldenview__enable_default_mapping = 0

" CtrlP
let g:ctrlp_map = '<leader>p'
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

nnoremap <leader>p :CtrlP<CR>
nnoremap <leader>. :CtrlPTag<cr>

" ALE
let g:ale_sign_column_always = 1
let g:airline#extensions#ale#enabled = 1
let g:ale_linters = {'javascript': ['standard']}

" set indentLine
let g:indentLine_enabled = 1

" Fix json syntax file conflicts from indent Line
let g:vim_json_syntax_conceal = 0

" vim-move - move line up/down
let g:move_key_modifier = 'C'

" set rg for ack.vim
if executable('rg')
  let g:ackprg = 'rg --vimgrep --smart-case'
endif
cnoreabbrev Ack Ack!

" set theme
try
  colorscheme one-light
catch
endtry

" enable airline theme
let g:airline_theme = 'sol'
let g:tmuxline_theme = 'airline'
let g:promptline_theme = 'airline'

" Fix vim-airline not appear unitl create new split
set laststatus=2
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Enable Hardtime
let g:hardtime_default_on = 1

" sneak.vim
let g:sneak#streak = 1

"Tab to Space
command CleanSpace :set expandtab | retab | FixWhitespace

" local settings
try
  source ~/.vimrc.local
catch
endtry
