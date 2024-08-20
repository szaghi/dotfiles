if has("autocmd")
  autocmd BufEnter,BufRead,BufNewFile *.tex syntax spell toplevel
  autocmd BufEnter,BufRead,BufNewFile *.tex setlocal spell spelllang=en
  autocmd BufEnter,BufRead,BufNewFile *.tex set textwidth=175
  autocmd BufEnter,BufRead,BufNewFile *.tex set formatoptions+=t
  autocmd BufEnter,BufRead,BufNewFile *.tex set formatoptions-=l
  autocmd BufEnter,BufRead,BufNewFile *.tex set synmaxcol=0
  " autocmd BufEnter,BufRead,BufNewFile *.tex setl fo=aw2tq
endif
let g:vimtex_view_general_viewer = 'evince'
let maplocalleader = ","
