nnoremap <silent> ,g :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
nnoremap <silent> ° :<C-u>UniteWithCursorWord grep<CR>
if executable('pt')
  let g:unite_source_grep_command = 'pt'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor -S -f'
  let g:unite_source_grep_recursive_opt = ''
  let g:unite_source_grep_encoding = 'utf-8'
endif
