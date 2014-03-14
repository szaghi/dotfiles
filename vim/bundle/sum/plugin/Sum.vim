" Sum.vim : sum a visual-block column of floating point numbers
" Author  : Charles E. Campbell, Jr.
" Date    : Mar 22, 2010
" Version : 1a	ASTRO-ONLY
" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_Sum")
 finish
endif
let g:loaded_Sum= "v1a"

" ---------------------------------------------------------------------
" Public Interface: {{{1
com! -range -nargs=* Sum call s:ColSum(<f-args>)

" ---------------------------------------------------------------------
" s:ColSum: {{{1
fun! s:ColSum(...) range
"  call Dfunc("s:ColSum() a:0=".a:0." lines[".line("'<").",".line("'>")."] cols[".col("'<").",".col("'>")."]")
  let akeep= @a
  norm! gv"ay
  let prblm = substitute(@a,'\_s\+','+','ge')
  let prblm = substitute(prblm,'^+\+','','e')
  let prblm = substitute(prblm,'+\+$','','e')
  let prblm = substitute(prblm,'+\{2,}','+','ge')
  let prblm = substitute(prblm,'+-','-','ge')
  let prblm = substitute(prblm,'-+','-','ge')
"  call Decho("prblm=".prblm)
"  let result= substitute(system("calc '".prblm."'"),'\_s*$','','ge')
  exe "let Fresult=".prblm
  let result= printf("%f",Fresult)
"  call Decho("result=".result)
  let @*    = result
  let @a    = akeep
  redraw!
  echomsg result
"  call Dret("s:ColSum ".result)
  return result
endfun
" ---------------------------------------------------------------------
"  vim: ts=4 fdm=marker
