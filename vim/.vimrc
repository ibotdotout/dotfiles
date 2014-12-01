set nocompatible

"About Search
set incsearch
set hlsearch

"Syntax Color
syntax on

"Show line number
set nu

"Automatically indent
set smartindent

"About Tab
set smarttab

"Use UTF-8.
set encoding=utf8

"PEP 8 Python
set textwidth=79  " lines longer than 79 columns will be broken
set shiftwidth=4  " operation >> indents 4 columns; << unindents 4 columns
set tabstop=4     " an hard TAB displays as 4 columns
set expandtab     " insert spaces when hitting TABs
set softtabstop=4 " insert/delete 4 spaces when hitting a TAB/BACKSPACE
set shiftround    " round indent to multiple of 'shiftwidth'
set autoindent    " align the new line indent with the previous line

"Disable arrow key
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

"Mapp jk to <ESC>
inoremap jk <ESC>
inoremap kj <ESC>

" no swap file
set noswapfile

" use motion work with display line
nnoremap k gk
nnoremap gk k
nnoremap j gj
nnoremap gj j
nnoremap $ g$
nnoremap ^ g^
nnoremap 0 g0

"move between windows
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

"Mute Highlighting
nnoremap <silent> <C-l> :<C-u>nohlsearch<CR><C-l>
