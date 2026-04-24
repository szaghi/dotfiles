" easymotion/vim-easymotion — default trigger <leader><leader> (i.e. ,,)
" Leaves all single-, mappings intact.

" Disable the (very aggressive) default mappings; add only the common ones.
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1

" <leader><leader>s — jump to any char (2-keystroke targets)
nmap <leader><leader>s <Plug>(easymotion-bd-f)
nmap <leader><leader>w <Plug>(easymotion-bd-w)
nmap <leader><leader>j <Plug>(easymotion-j)
nmap <leader><leader>k <Plug>(easymotion-k)
nmap <leader><leader>l <Plug>(easymotion-lineforward)
nmap <leader><leader>h <Plug>(easymotion-linebackward)
