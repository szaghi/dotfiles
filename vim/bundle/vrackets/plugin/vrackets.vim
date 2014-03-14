" File:		vrackets.vim
" Author:	Gerardo Marset (gammer1994@gmail.com)
" Version:	0.2.3
" Last Change:  2011-10-27
" Description:	Automatically close/delete different kinds of brackets.

" You can modify this dictionary as you wish.
let s:match = {'(': ')',
              \'{': '}',
              \'[': ']',
              \'¡': '!',
              \'¿': '?'}
" This list is for pairs in which the closing symbol is the same as the
" opening one.
let s:smatch = ["'", "\""]

let s:alpha = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
              \"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
              \"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
              \"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
for [s:o, s:c] in items(s:match)
    execute 'ino <silent> ' . s:o . " <C-R>=VracketOpen('" . s:o . "')<CR>"
    execute 'ino <silent> ' . s:c . " <C-R>=VracketClose('" . s:o . "')<CR>"
endfor
for s:b in s:smatch
    execute 'ino <silent> ' . s:b . ' <C-R>=VracketBoth("\' . s:b . '")<CR>'
endfor
inoremap <silent> <BS> <C-R>=VracketBackspace()<CR>

function! VracketOpen(bracket)
    let l:c = s:GetCharAt(0) 
    if l:c =~ "\\S" && count(s:smatch, l:c) + count(values(s:match), l:c) == 0
        return a:bracket
    endif

    return a:bracket . s:match[a:bracket] . "\<Left>"
endfunction

function! VracketClose(bracket)
    let l:close = s:match[a:bracket]

    if s:GetCharAt(0) == l:close
        return "\<Right>"
    endif
    return l:close
endfunction

function! VracketBoth(bracket)
    let l:c = s:GetCharAt(0) 
    if l:c == a:bracket
        return "\<Right>"
    endif
    if l:c =~ "\\S" && count(s:smatch, l:c) + count(values(s:match), l:c) == 0
        return a:bracket
    endif
    if col('.') == 1
        return a:bracket . a:bracket . "\<Left>"
    endif
    if s:GetCharAt(-1) == a:bracket || count(s:alpha, s:GetCharAt(-1)) == 1
        return a:bracket
    endif
    return a:bracket . a:bracket . "\<Left>"
endfunction

function! VracketBackspace()
    if col('.') == 1
        return "\<BS>"
    endif
    
    if get(s:match, s:GetCharAt(-1), '  ') == s:GetCharAt(0)
        return "\<Esc>\"_2s"
    endif

    if count(s:smatch, s:GetCharAt(0)) == 1 && s:GetCharAt(-1) == s:GetCharAt(0)
        return "\<Esc>\"_2s"
    endif
    return "\<BS>"
endfunction

function! s:GetCharAt(pos)
    let l:line = split(getline('.'), '\zs')
    let l:pos = s:Column() + a:pos
    if l:pos < 0 || l:pos >= len(l:line)
        return ''
    else
        return l:line[l:pos]
    endif
endfunction

function! s:Column()
    return col('.') > 1 ? strchars(getline(line('.'))[:col('.') - 2]) : 0
endfunction
