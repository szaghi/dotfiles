let g:latex_view_general_viewer = 'okular'
function! SyncTexForward()
  call latex#view#view('--unique '
    \ . g:latex#data[b:latex.id].out()
    \ . '\#src:' . line(".") . expand('%:p'))
endfunction
if has("autocmd")
  autocmd FileType tex nnoremap <C-L> :call latex#latexmk#toggle()<CR>
  autocmd FileType tex nnoremap <C-T> :call SyncTexForward()<CR>
endif
