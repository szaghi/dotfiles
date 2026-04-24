" LaTeX settings — loaded automatically when filetype=tex

setlocal spell spelllang=en
syntax spell toplevel
setlocal textwidth=175
setlocal formatoptions+=t
setlocal formatoptions-=l
setlocal synmaxcol=0

let g:vimtex_view_general_viewer = 'evince'
" maplocalleader is set in .vimrc BEFORE plug#begin — setting it here is too late for vimtex.
