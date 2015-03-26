let fortran_fold=1
let fortran_fold_conditionals=1
let s:extfname = expand("%:e")
if s:extfname ==? "f77"
  let g:fortran_fixed_source=1
elseif s:extfname ==? "f"
  let g:fortran_fixed_source=1
else
  let g:fortran_free_source=1
endif
if has("autocmd")
  let fortran = "$VIM/syntax/fortran.vim"
  " associate *.inc file to fortran type
  autocmd BufEnter,BufRead,BufNewFile *.inc set syntax=fortran
  " marking columns > 132(72)
  autocmd BufEnter,BufRead,BufNewFile *.F,*.FOR,*.FPP,*.F77,*.f,*.for,*.fortran,*.fpp,*.f77 let w:m2=matchadd('ErrorMsg', '\%>72v.\+', -1)
  autocmd BufEnter,BufRead,BufNewFile *.F90,*.F95,*.F03,*.F08,*.f90,*.f95,*.f03,*.f08,*.inc let w:m2=matchadd('ErrorMsg', '\%>132v.\+', -1)
  " fixing indent
  autocmd BufEnter,BufRead,BufNewFile *.F,*.FOR,*.FPP,*.F77,*.f,*.for,*.fortran,*.fpp,*.f77 set tw=72
  autocmd BufEnter,BufRead,BufNewFile *.F90,*.F95,*.F03,*.F08,*.f90,*.f95,*.f03,*.f08,*.inc set tw=132
endif
