set nocompatible
"Vim-pathogen 
execute pathogen#infect()
filetype plugin indent on

"vim-colors-solarized
"syntax enable
"set background=dark
"colorscheme solarized
"set t_Co=256

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

"Fold
"set foldmethod=indent
"set foldmethod=syntax
"set foldnestmax=10
"set nofoldenable
"set foldlevel=1

"Auto Save fold
"au BufWinLeave * mkview
"au BufWinEnter * silent loadview

"Auto Gen Ctags when saved
"autocmd BufWritePost * call system("ctags -R")

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

