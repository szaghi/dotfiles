" Fortran settings — loaded automatically when filetype=fortran

let fortran_fold = 1
let fortran_fold_conditionals = 1

let s:extfname = expand("%:e")
if s:extfname ==? "f77" || s:extfname ==? "f" || s:extfname ==? "for" ||
      \ s:extfname ==? "fpp" || s:extfname ==? "fortran"
   let g:fortran_fixed_source = 1
   setlocal textwidth=72
else
   let g:fortran_free_source = 1
   setlocal textwidth=132
   setlocal tabstop=3
   setlocal shiftwidth=3
   setlocal softtabstop=3
   setlocal synmaxcol=132
endif
