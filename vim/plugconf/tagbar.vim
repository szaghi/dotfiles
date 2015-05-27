let g:tagbar_left = 1
let g:tagbar_width = 30
let g:tagbar_sort = 1
let g:tagbar_autofocus = 0
let g:tagbar_compact = 1
let g:tagbar_type_dosini = {
    \ 'ctagstype': 'dosini',
    \ 'kinds' : [
        \'s:section'
    \]
\}
let g:tagbar_type_markdown = {
    \ 'ctagstype' : 'markdown',
    \ 'kinds' : [
        \ 'h:Heading_L1',
        \ 'i:Heading_L2',
        \ 'k:Heading_L3'
    \]
\}
if has("autocmd")
  " automatically open Tagbar
  if &diff
    " do nothing
  else
    " autocmd FileType fortran,make,dosini,sh,bash,python,c,cpp,tex,vim,css,java,php,xml,markdown :TagbarOpen
  endif
endif
noremap <F3> :TagbarToggle<CR>
