if has("autocmd")
  " autocmd FileType python syn sync ccomment
  set foldmethod=indent foldlevel=0 expandtab tabstop=2 shiftwidth=2 softtabstop=2
  " let c_minlines=500
  let g:python_highlight_builtins = 1
  let g:python_highlight_builtin_funcs_kwarg = 1
  let g:python_highlight_exceptions = 1
  let g:python_highlight_string_formatting = 1
  let g:python_highlight_indent_errors = 1
  let g:python_highlight_space_errors = 1
  let g:python_highlight_doctests = 1
  let g:python_highlight_func_calls = 1
  let g:python_highlight_class_vars = 1
  let g:python_highlight_operators = 1
  autocmd BufEnter,BufRead,BufNewFile *.py set tw=300
endif
