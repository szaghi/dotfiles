" Personal preferences .vimrc file
" Maintained by Stefano Zaghi <stefano.zaghi@gmail.com>

" Use vim settings, rather than vi settings (much better!)
" This must be first, because it changes other options as a side effect.
set nocompatible

" Ensure filetype detection, plugins and indent are active.
" plug#end() enables this too, but stating it explicitly avoids breakage
" if the plug block is ever reordered or disabled.
filetype plugin indent on

" Set localleader BEFORE plug#begin — plugins (e.g. vimtex) read it at load time.
let maplocalleader = ","

" Plugins handling with vim-plug and plugconf {{{
call plug#begin('~/.vim/plugged')
" apparence
Plug 'altercation/vim-colors-solarized'
Plug 'junegunn/rainbow_parentheses.vim'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'myusuf3/numbers.vim'

" buffers and files
Plug 'majutsushi/tagbar'
Plug 'moll/vim-bbye'
Plug 'justinmk/vim-dirvish'

" selection
Plug 'vasconcelloslf/vim-foldfocus', { 'for':  ['python','fortran'] }

" spell check and languages
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'vim-python/python-syntax'

" text utilities
Plug 'vim-scripts/VisIncr', { 'on': ['I','II','IB','IIB','IO','IIO','IX','IIX','IYMD','IMDY','IDMY','IA','ID','IM','IPOW','IIPOW'] }
Plug 'tpope/vim-commentary'
Plug 'godlygeek/tabular'
Plug 'junegunn/vim-easy-align'
Plug 'mattn/vim-maketable'
Plug 'cohama/lexima.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" git & github
Plug 'airblade/vim-gitgutter'

" utilities
Plug 'jamessan/vim-gnupg'
Plug 'sk1418/HowMuch', { 'on': 'HowMuch' }
Plug 'niboan/plugconf'

call plug#end()
call plugconf#load()
" }}}

" Highlighting and colors {{{
if &t_Co > 2 || has("gui_running")
  syntax on " switch syntax highlighting on, when the terminal has colors
endif
set background=dark
colorscheme solarized
hi clear SpellBad
hi SpellBad cterm=underline
" cursor style
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"
" enable :Man command (bundled, not loaded by default)
runtime ftplugin/man.vim
" }}}

" lightline tabline setting {{{
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'tabline': {
      \   'left': [ ['buffers'] ],
      \   'right': [ ['close'] ]
      \ },
      \ 'component_expand': {
      \   'buffers': 'lightline#bufferline#buffers'
      \ },
      \ 'component_type': {
      \   'buffers': 'tabsel'
      \ }
      \ }
let g:lightline#bufferline#show_number  = 1
let g:lightline#bufferline#shorten_path = 0
let g:lightline#bufferline#unnamed      = '[No Name]'
" }}}

" Editing behaviour {{{
let mapleader = ","                                                      " leader symbol
set cursorline                                                           " enable cursorline
set nowrap                                                               " don't wrap lines
set tabstop=3                                                            " a tab is 3 spaces
set softtabstop=3                                                        " when hitting <BS>, pretend like a tab is removed, even if spaces
set expandtab                                                            " expand tabs by default (overloadable per file type later)
set shiftwidth=3                                                         " number of spaces to use for autoindenting
set shiftround                                                           " use multiple of shiftwidth when indenting with '<' and '>'
set backspace=indent,eol,start                                           " allow backspacing over everything in insert mode
set autoindent                                                           " rely on filetype indent plugins; smartindent is harmful
set copyindent                                                           " copy the previous indentation on autoindenting
set number                                                               " always show line numbers
set showmatch                                                            " set show matching parenthesis
set ignorecase                                                           " ignore case when searching
set smartcase                                                            " ignore case if search pattern is all lowercase, case-sensitive otherwise
set smarttab                                                             " insert tabs on the start of a line according to shiftwidth, not tabstop
set scrolloff=4                                                          " keep 4 lines off the edges of the screen when scrolling
set sidescrolloff=8                                                      " horizontal scroll padding (relevant with nowrap)
set virtualedit=all                                                      " allow the cursor to go in to "invalid" places
set hlsearch                                                             " highlight search terms
set incsearch                                                            " show search matches as you type
set nolist                                                               " don't show invisible characters by default,
set listchars=tab:▸\ ,trail:·,extends:#,nbsp:·                           " characters shown when :set list is active
set mouse=a                                                              " enable using the mouse if terminal emulator supports it (xterm does)
set formatoptions+=1                                                     " When wrapping paragraphs, don't end lines with 1-letter words (looks stupid)
set encoding=utf-8                                                       " file encoding
set laststatus=2                                                         " tell VIM to always put a status line in, even if there is only one window
set cmdheight=1                                                          " default cmdline height
set signcolumn=yes                                                       " always show signcolumn to avoid gitgutter flicker
set hidden                                                               " hide buffers instead of closing them this
set switchbuf=useopen                                                    " reveal already opened files from the quickfix window instead of opening new buffers
set nobackup                                                             " do not keep backup files, it's 70's style cluttering
set noswapfile                                                           " do not write annoying intermediate swap files
set undofile                                                             " persistent undo across sessions
set undodir=~/.vim/undo//                                                " dedicated undo dir (trailing // = full-path-encoded names)
set wildmenu                                                             " make tab completion for files/buffers act like bash
set wildmode=list:full                                                   " show a list when pressing tab and complete first full match
set title                                                                " change the terminal's title
set noerrorbells                                                         " don't beep
set showcmd                                                              " show (partial) command in the last line of the screen
set modeline                                                             " honor per-file mode lines (e.g. vim: ts=4 sw=4)
set modelines=1                                                          " only scan the first line — reduces historical modeline CVE surface
set diffopt+=iwhite                                                      " ignoring trailing white spaces when doing diff
set foldenable                                                           " enable folding
set foldcolumn=1                                                         " add a fold column
set foldmethod=marker                                                    " detect triple-{ style fold markers
set foldlevelstart=0                                                     " start out with everything folded
set foldopen=block,hor,insert,jump,mark,percent,quickfix,search,tag,undo " which commands trigger auto-unfold
set fileformats="unix,dos,mac"                                           " file formats
set termencoding=utf-8                                                   " file encoding
set showtabline=2                                                        " show tabline
" Ensure undodir exists (silent on re-run).
if !isdirectory(expand('~/.vim/undo'))
  call mkdir(expand('~/.vim/undo'), 'p', 0700)
endif
" }}}

" Autocommands {{{
if has("autocmd")
  " let terminal resize scale the internal windows
  autocmd VimResized * :wincmd =

  " positiong the cursor to the last position before closing the file
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

  " Don't screw up folds when inserting text that might affect them, until
  " leaving insert mode. Foldmethod is local to the window.
  augroup folding
    autocmd!
    autocmd InsertEnter * let w:last_fdm=&foldmethod | setlocal foldmethod=manual
    autocmd InsertLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | endif
    autocmd FileType sh,bash let sh_fold_enabled=1
    autocmd FileType xml let xml_syntax_folding=1
  augroup END

  " programming tips {{{
  augroup programming
    autocmd!
    " removing trailing space
    autocmd FileType fortran,make,dosini,sh,bash,python,c,cpp,tex,vim,css,java,php,xml,markdown autocmd BufWritePre <buffer> :%s/\s\+$//e
    " condensing multiple blank lines into a single blank line
    autocmd FileType fortran,make,sh,bash,c,cpp,tex,vim,css,java,php,xml,markdown autocmd BufWritePre <buffer> :%s/\n\{3,}/\r\r/e
    " set fold method
    autocmd FileType fortran,make,dosini,c,cpp,tex,css,java,php,xml,markdown set foldmethod=syntax
    autocmd FileType sh,bash set foldmethod=indent
    " activate rainbowparenthesis
    autocmd FileType fortran,make,dosini,sh,bash,python,c,cpp,tex,vim,css,java,php,xml,markdown RainbowParentheses
  augroup END
  " }}}
endif
" }}}

" Mappings {{{
" Perl/Python regex
nnoremap / /\v
xnoremap / /\v
" Speed up scrolling of the viewport slightly
nnoremap <C-e> 2<C-e>
nnoremap <C-y> 2<C-y>
" Change window splits
nnoremap <silent> <A-Up> :wincmd k<CR>
nnoremap <silent> <A-Down> :wincmd j<CR>
nnoremap <silent> <A-Left> :wincmd h<CR>
nnoremap <silent> <A-Right> :wincmd l<CR>
" Map Y do be analog of D
noremap Y y$
" Wrap ON/OFF
noremap <F2> :set wrap! wrap?<CR>
" Buffer navigation
nnoremap <C-Right> :bnext<CR>
nnoremap <C-Left> :bprevious<CR>
" Buffer close
nnoremap qq :Bdelete<CR>
" Cursor movements limited or not — moved off <C-C> so Ctrl-C keeps its default meaning
function! ToggleVirtualedit()
  if &virtualedit != ""
    set virtualedit&
    echo "Cursor movements limited"
  else
    set virtualedit=all
    echo "Cursor movements unlimited"
  endif
endfunction
nnoremap <leader>v :call ToggleVirtualedit()<CR>
" Maps Ctrl-J to insert line break (like the opposite of J)
nnoremap <NL> i<CR><ESC>
" cycle through visual modes: visual -> visual-block -> visual-line -> visual
xnoremap <expr> v
            \ (mode() ==# 'v' ? "\<C-V>"
            \ : mode() ==# 'V' ? 'v' : 'V')
" fzf.vim fuzzy finders (leader = ,)
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>r :Rg<Space>
nnoremap <leader>t :Tags<CR>
nnoremap <leader>h :History<CR>
nnoremap <leader>/ :Lines<CR>
" }}}
