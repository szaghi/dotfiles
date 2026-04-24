" yegappan/lsp — pure Vim9 LSP client
"
" Configuration is deferred to VimEnter because plugconf runs immediately
" after plug#end(), but plug#end() only registers runtime paths — it does
" NOT source plugin/*.vim on initial startup. The lsp plugin defines
" g:LspOptionsSet / g:LspAddServer in plugin/lsp.vim which runs later in
" Vim's startup sequence, so calling them here directly fails with E117.

function! s:LspSetup() abort
   " Global options. Manual completion (no auto-popup) per preference.
   call LspOptionsSet(#{
         \ autoComplete: v:false,
         \ showSignature: v:true,
         \ echoSignature: v:false,
         \ hoverInPreview: v:false,
         \ showDiagOnStatusLine: v:false,
         \ showDiagInPopup: v:true,
         \ autoHighlightDiags: v:true,
         \ autoPopulateDiags: v:false,
         \ usePopupInCodeAction: v:true,
         \ useQuickfixForLocations: v:true,
         \ })

   " Server registrations. Paths discovered via $PATH; if a server is missing
   " the LSP client just doesn't attach. Run ~/.scripts/install-vim-lsp.sh
   " to provision them.
   let l:servers = []

   if executable('fortls')
      " fortls diagnostics are suppressed globally. fortls has no way to
      " express relative-path excludes via CLI (--excl_paths needs absolute
      " paths), so on repos with FoBiS-fetched third-party libs + FORD
      " docs/api/src shadow trees it emits spurious diagnostics for any
      " symbol coming from a shadow-duplicated module. Navigation, hover,
      " completion and refs still work perfectly — only the diagnostic
      " signs/highlights are disabled. For projects where you want
      " diagnostics, drop a per-project .fortls and override there.
      call add(l:servers, #{
            \ name: 'fortls',
            \ filetype: ['fortran'],
            \ path: exepath('fortls'),
            \ args: [
            \    '--notify_init',
            \    '--hover_signature',
            \    '--use_signature_help',
            \    '--lowercase_intrinsics',
            \ ],
            \ features: #{ diagnostics: v:false },
            \ })
   endif

   if executable('basedpyright-langserver')
      call add(l:servers, #{
            \ name: 'basedpyright',
            \ filetype: ['python'],
            \ path: exepath('basedpyright-langserver'),
            \ args: ['--stdio'],
            \ })
   endif

   if executable('texlab')
      call add(l:servers, #{
            \ name: 'texlab',
            \ filetype: ['tex', 'plaintex', 'bib'],
            \ path: exepath('texlab'),
            \ args: [],
            \ })
   endif

   if executable('bash-language-server')
      call add(l:servers, #{
            \ name: 'bashls',
            \ filetype: ['sh', 'bash'],
            \ path: exepath('bash-language-server'),
            \ args: ['start'],
            \ })
   endif

   if !empty(l:servers)
      call LspAddServer(l:servers)
   endif
endfunction

augroup lsp_setup
   autocmd!
   autocmd VimEnter * call s:LspSetup()
augroup END

" Mappings (safe to define unconditionally; they no-op on buffers without a
" server attached).
nnoremap <silent> gd           :LspGotoDefinition<CR>
nnoremap <silent> gr           :LspShowReferences<CR>
nnoremap <silent> K            :LspHover<CR>
nnoremap <silent> <leader>rn   :LspRename<CR>
nnoremap <silent> <leader>la   :LspCodeAction<CR>
nnoremap <silent> <leader>lf   :LspFormat<CR>
nnoremap <silent> [d           :LspDiagPrev<CR>
nnoremap <silent> ]d           :LspDiagNext<CR>

" <Tab> completion:
"   - popup visible       → select next item
"   - after a word char   → trigger omnicompletion (LSP)
"   - otherwise           → literal <Tab>
" <S-Tab> selects the previous popup item.
function! s:LspTabComplete() abort
   if pumvisible()
      return "\<C-n>"
   endif
   let l:col = col('.') - 1
   if l:col == 0 || getline('.')[l:col - 1] =~# '\s'
      return "\<Tab>"
   endif
   return "\<C-x>\<C-o>"
endfunction

inoremap <silent><expr> <Tab>   <SID>LspTabComplete()
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" <CR> accepts the selected completion when the popup is open; otherwise
" delegates to lexima (auto-pair expansion on Enter).
inoremap <silent><expr> <CR> pumvisible() ? "\<C-y>" : lexima#expand('<LT>CR>', 'i')
