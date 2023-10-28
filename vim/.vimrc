let mapleader = ","

if &compatible
  set nocompatible
end

" Enable true colors if available
set termguicolors
" colorscheme gruvbox
" Enable italics, Make sure this is immediately after colorscheme
" https://stackoverflow.com/questions/3494435/vimrc-make-comments-italic
highlight Comment cterm=italic gui=italic

set number
set noswapfile
set nobackup
set splitbelow
set splitright
set hidden
set expandtab
set autoindent
set fileformat=unix
set cursorline
set ignorecase

" Permanent undo
set undodir=~/.vimdid
set undofile

set tabstop=2
set softtabstop=2
set shiftwidth=2

" Move by line
nnoremap j gj
nnoremap k gk

" Faster ESC
inoremap jk <esc>

" Fast saving
nnoremap <leader>w :w!<CR>
nnoremap <leader>q :q!<CR>

