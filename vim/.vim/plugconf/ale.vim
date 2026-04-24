" dense-analysis/ale — linting + fixing only
" LSP work (completion, hover, goto-def, diagnostics from LSP) is handled
" by yegappan/lsp. ALE complements with linters/fixers that aren't LSP servers.

" Do NOT let ALE run its own LSP clients — yegappan/lsp owns that surface.
let g:ale_disable_lsp = 1

" Per-filetype linters. Add more as needed; ALE only runs what's installed.
" Fortran: fortls (LSP) handles project-aware diagnostics; gfortran as an ALE
" linter runs on single files without .mod info and produces noisy false
" positives for any external module (PENF, MPI, etc.). Disabled.
let g:ale_linters = {
      \ 'python':  ['ruff'],
      \ 'fortran': [],
      \ 'sh':      ['shellcheck'],
      \ 'bash':    ['shellcheck'],
      \ 'tex':     [],
      \ }

" Per-filetype fixers. ruff handles both lint autofix and formatting for Python.
let g:ale_fixers = {
      \ '*':      ['trim_whitespace', 'remove_trailing_lines'],
      \ 'python': ['ruff', 'ruff_format'],
      \ }

" Format Python on save; other filetypes only lint (no autofix without intent).
let g:ale_fix_on_save = 0
augroup ale_python_fix_on_save
   autocmd!
   autocmd FileType python let b:ale_fix_on_save = 1
augroup END

" Visual style: signs in the gutter, diagnostics on demand.
let g:ale_sign_error   = '✗'
let g:ale_sign_warning = '!'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_save = 1
