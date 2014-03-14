" natbib.vim: support for the lstlisting package
"     Author: Hector Arciga
"       Date: Nov 16, 2013
"    Version: 2
"       NOTE: Place this file in your $HOME/.vim/after/syntax/tex/ directory (make it if it doesn't exist)
let b:loaded_texpkg_natbib  = "v2"
syn match texRefZone '\\cite\%(text\|\%(\%([tp]\|author\)\*\=\)\|\%(year\%(par\)\=\)\|alt\|alp\)\=' nextgroup=texRefOption,texCite conceal cchar=※ " ※ REFERENCE MARK Unicode: U+203B, UTF-8: E2 80 BB

" TO DO
" - Put the code in github so it works with package managers
" - Put all latex-related support packages in one big plug-in
"
" Version History
" v2  : Added conceal feature
" v1  : Initial release
