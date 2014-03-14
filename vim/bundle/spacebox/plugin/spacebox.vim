" Select a block of indentation whitespace in Visual block mode based on
" the indentation of the current line.  Try it with ":SpaceBox"!
"
" Author: glts <676c7473@gmail.com>
" Date: 2012-03-26

function! s:is_not_blank(line)
  return match(getline(a:line), "^\s*$") == -1
endfunction

function! s:top_line()
  let l:curr = s:line
  let l:top = l:curr
  while l:curr > 0
    if indent(l:curr-1) >= s:indent
      let l:top = l:curr - 1
    elseif s:is_not_blank(l:curr-1)
      break
    endif
    let l:curr = l:curr - 1
  endwhile
  return l:top
endfunction

function! s:bottom_line()
  let l:curr = s:line
  let l:bottom = l:curr
  let l:last = line("$")
  while l:curr <= l:last
    if indent(l:curr+1) >= s:indent
      let l:bottom = l:curr + 1
    elseif s:is_not_blank(l:curr+1)
      break
    endif
    let l:curr = l:curr + 1
  endwhile
  return l:bottom
endfunction

function! s:spacebox()
  let s:line = line(".")
  let s:indent = indent(s:line)
  if s:indent == 0 | echo | return | endif

  let s:top = s:top_line()
  let s:bottom = s:bottom_line()

  call cursor(s:top, 1)
  let s:linespan = s:bottom - s:top
  if s:linespan == 0
    exec 'normal ' . s:indent . '|'
  else
    exec 'normal ' . s:linespan . 'j' . s:indent . '|'
  endif
endfunction

command! SpaceBox call s:spacebox()
