" airblade/vim-gitgutter — hunk signs and hunk operations
"
" gitgutter's default maps (<leader>hp/hs/hu) make <leader>h (fzf :History)
" wait 'timeoutlen'. All git keys live under <leader>g instead, matching nvim.

let g:gitgutter_map_keys = 0

" ]c / [c: next / previous hunk (fall back to the native ]c [c in diff mode)
nmap ]c <Plug>(GitGutterNextHunk)
nmap [c <Plug>(GitGutterPrevHunk)
nmap <leader>gh <Plug>(GitGutterPreviewHunk)
nmap <leader>ga <Plug>(GitGutterStageHunk)
nmap <leader>gu <Plug>(GitGutterUndoHunk)
