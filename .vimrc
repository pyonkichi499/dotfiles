set belloff=all
set vb t_vb=

set expandtab
set tabstop=4
set shiftwidth=4
set mouse=a
set ttymouse=xterm2

set hlsearch
set term=xterm-256color 
syntax on
set number
inoremap <expr><CR> pumvisible() ? "<C-y>" : "<CR>"
set completeopt=menuone,noinsert
inoremap <expr><C-n> pumvisible() ? "<Down>" : "<C-n>"
inoremap <expr><C-p> pumvisible() ? "<Up>" : "<C-p>"

set title
