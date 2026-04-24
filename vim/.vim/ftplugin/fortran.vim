" Fortran settings — loaded automatically when filetype=fortran

let fortran_fold = 1
let fortran_fold_conditionals = 1

" Decide source form per-buffer (not globally): g:fortran_{free,fixed}_source
" would otherwise stick across buffers and mis-classify the next file opened.
let s:extfname = expand("%:e")
if s:extfname ==? "f77" || s:extfname ==? "f" || s:extfname ==? "for" ||
      \ s:extfname ==? "fpp" || s:extfname ==? "fortran"
   let b:fortran_fixed_source = 1
   setlocal textwidth=72
else
   let b:fortran_fixed_source = 0
   setlocal textwidth=132
   setlocal tabstop=3
   setlocal shiftwidth=3
   setlocal softtabstop=3
   setlocal synmaxcol=132
endif
