if has("autocmd")
  autocmd BufEnter,BufRead,BufNewFile fobos* set syntax=dosini
  autocmd BufEnter,BufRead,BufNewFile fobos* set filetype=dosini
endif
