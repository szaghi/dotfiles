---
title: vim
---

# vim

The `vim/` package is the main editor setup: one `.vimrc`, per-filetype ftplugins and one configuration file per
plugin, with plugins managed by [vim-plug](https://github.com/junegunn/vim-plug). It covers Fortran, Python, LaTeX,
bash and prose, with LSP navigation and completion, ALE linting and git inside the editor. Neovim has its own
independent port, see [Neovim](/packages/nvim).

## Usage

```bash
bash ~/dotfiles/dotify.sh vim     # link ~/.vimrc and ~/.vim/
~/.scripts/install-vim-lsp.sh     # language servers and shellcheck (once per host)
vim                               # first start installs every missing plugin
```

The first start needs no `:PlugInstall`: a `VimEnter` autocmd (`augroup plug_autoinstall`) installs any plugin
declared in `.vimrc` but missing from `~/.vim/plugged`, then re-sources `.vimrc`. This also covers a `Plug` line
pulled from another host.

```vim
:PlugUpdate        " update all plugins
:PlugClean!        " remove plugins no longer listed in .vimrc
```

## Layout

| Path | Role |
|---|---|
| `vim/.vimrc` | Plugins, options, autocommands, core mappings |
| `vim/.vim/autoload/plug.vim` | vim-plug itself (tracked) |
| `vim/.vim/plugconf/<plugin>.vim` | Configuration of one plugin, loaded by [plugconf](https://github.com/niboan/plugconf) after `plug#end()` |
| `vim/.vim/ftplugin/{fortran,python,tex}.vim` | Per-filetype options |
| `vim/.vim/ftdetect/fobos.vim` | `fobos*` and `*.fobos` files are `dosini` |
| `vim/.vim/colors/solarized.vim` | Symlink into `plugged/vim-colors-solarized`, a plugin no longer installed (dangling) |
| `~/.vim/plugged/` | Plugin checkouts (gitignored) |
| `~/.vim/undo/` | Persistent undo files, created on first start with mode `0700` (gitignored) |

`vim/.stow-local-ignore` keeps `view`, `vim`, `plugged` and `undo` out of the stow tree.

### plugconf naming rule

plugconf sources `plugconf/<name>.vim` only when `<name>` is the plugin's **directory** name under `~/.vim/plugged`:
`vim-fugitive.vim`, not `fugitive.vim`. A misnamed file is skipped without an error.

plugconf also sees only the plugins on the runtimepath at `plug#end()`. On-demand plugins (`'for'` or `'on'` in
their `Plug` line: vimtex, markdown-preview, VisIncr, HowMuch) are invisible to it and are configured in `.vimrc` or
in an ftplugin instead.

## Plugins

### Plugin set

| Plugin | What for | Key maps |
|---|---|---|
| [lifepillar/vim-solarized8](https://github.com/lifepillar/vim-solarized8) | Solarized dark colour scheme, 24-bit | — |
| [junegunn/rainbow_parentheses.vim](https://github.com/junegunn/rainbow_parentheses.vim) | Nested brackets in alternating colours | — |
| [itchyny/lightline.vim](https://github.com/itchyny/lightline.vim) | Status line (`solarized` theme) | — |
| [mengelbrecht/lightline-bufferline](https://github.com/mengelbrecht/lightline-bufferline) | Buffer list in the tabline, with buffer numbers and full paths | — |
| [majutsushi/tagbar](https://github.com/majutsushi/tagbar) | Symbol outline, left side, 30 columns, sorted | `<F3>` |
| [moll/vim-bbye](https://github.com/moll/vim-bbye) | `:Bdelete`: close a buffer, keep the window layout | `qq` |
| [justinmk/vim-dirvish](https://github.com/justinmk/vim-dirvish) | Directory as a buffer, replaces netrw | plugin defaults |
| [lervag/vimtex](https://github.com/lervag/vimtex) | LaTeX; loaded for `tex` only | plugin defaults on `<localleader>` |
| [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | Live markdown preview in the browser; loaded for markdown only | `:MarkdownPreview` |
| [vim-python/python-syntax](https://github.com/vim-python/python-syntax) | Richer Python highlighting | — |
| [vim-scripts/VisIncr](https://github.com/vim-scripts/VisIncr) | Number, letter or date sequences down a visual-block column | `:I`, `:II`, `:IA`, `:IYMD`, ... (16 commands) |
| [tpope/vim-commentary](https://github.com/tpope/vim-commentary) | Toggle comments | plugin defaults (`gc`) |
| [tpope/vim-surround](https://github.com/tpope/vim-surround) | Change, delete, add surrounding delimiters | plugin defaults |
| [tpope/vim-repeat](https://github.com/tpope/vim-repeat) | `.` repeats plugin actions | — |
| [tpope/vim-unimpaired](https://github.com/tpope/vim-unimpaired) | Paired `[x` / `]x` mappings | plugin defaults |
| [easymotion/vim-easymotion](https://github.com/easymotion/vim-easymotion) | Labelled jumps | `,,s` `,,w` `,,j` `,,k` `,,l` `,,h` |
| [godlygeek/tabular](https://github.com/godlygeek/tabular) | `:Tabularize` alignment | — |
| [junegunn/vim-easy-align](https://github.com/junegunn/vim-easy-align) | Interactive alignment | — |
| [mattn/vim-maketable](https://github.com/mattn/vim-maketable) | Selection to markdown table | `:MakeTable` |
| [cohama/lexima.vim](https://github.com/cohama/lexima.vim) | Auto-close brackets and quotes | `<CR>` fallback |
| [junegunn/fzf](https://github.com/junegunn/fzf) + [fzf.vim](https://github.com/junegunn/fzf.vim) | Fuzzy finders; the fzf binary is installed by vim-plug | `,f` `,b` `,r` `,t` `,h` `,/` |
| [yegappan/lsp](https://github.com/yegappan/lsp) | LSP client, pure Vim9script | `gd` `gr` `K` `,lr` `,la` `,lf` `[d` `]d` `<Tab>` |
| [dense-analysis/ale](https://github.com/dense-analysis/ale) | Linting, Python fixing | — |
| [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive) | Git porcelain | `,gs` `,gb` `,gd` `,gl` `,gc` `,gp` |
| [airblade/vim-gitgutter](https://github.com/airblade/vim-gitgutter) | Hunk signs and hunk operations | `]c` `[c` `,gh` `,ga` `,gu` |
| [jamessan/vim-gnupg](https://github.com/jamessan/vim-gnupg) | Transparent edit of GPG-encrypted files | — |
| [sk1418/HowMuch](https://github.com/sk1418/HowMuch) | Evaluate arithmetic in a selection; loaded on `:HowMuch` | `:HowMuch` |
| [niboan/plugconf](https://github.com/niboan/plugconf) | Loads `plugconf/*.vim` | — |

### LSP

[yegappan/lsp](https://github.com/yegappan/lsp) is configured in `vim/.vim/plugconf/lsp.vim`. A server is registered
only when its executable is on `$PATH`; otherwise the buffer simply gets no client.

| Language | Server | Executable | Filetypes |
|---|---|---|---|
| Fortran | fortls | `fortls` | `fortran` |
| Python | basedpyright | `basedpyright-langserver --stdio` | `python` |
| LaTeX | texlab | `texlab` | `tex`, `plaintex`, `bib` |
| bash | bash-language-server | `bash-language-server start` | `sh`, `bash` |

`~/.scripts/install-vim-lsp.sh` provisions them, idempotently: fortls and basedpyright with pipx,
bash-language-server with npm (nvm scope, no sudo), texlab from the upstream GitHub release into `~/.local/bin`,
shellcheck with apt. It assumes ruff and gfortran are already installed.

fortls runs with `--notify_init --hover_signature --use_signature_help --lowercase_intrinsics`, and its diagnostics
are off (`features: #{ diagnostics: v:false }`). Navigation, hover, completion and references still work.

Client options: no auto-popup completion, signature help shown, diagnostics in a popup and highlighted, code actions
in a popup, locations in the quickfix list.

| Key | Command |
|---|---|
| `gd` | `:LspGotoDefinition` |
| `gr` | `:LspShowReferences` |
| `K` | `:LspHover` |
| `,lr` | `:LspRename` |
| `,la` | `:LspCodeAction` |
| `,lf` | `:LspFormat` |
| `[d` / `]d` | `:LspDiagPrev` / `:LspDiagNext` |

### Completion

Completion is manual: nothing pops up while typing.

| Key (insert) | Popup open | Popup closed |
|---|---|---|
| `<Tab>` | next item | after a word character: omni-completion (`<C-x><C-o>`, served by LSP); at line start or after a space: literal `<Tab>` |
| `<S-Tab>` | previous item | literal `<S-Tab>` |
| `<CR>` | accept the item | lexima's `<CR>` (auto-pair expansion) |

### ALE

ALE (`vim/.vim/plugconf/ale.vim`) lints and fixes; it runs no LSP client of its own (`g:ale_disable_lsp = 1`), so
LSP stays with yegappan/lsp.

| Filetype | Linters | Fixers |
|---|---|---|
| python | `ruff` | `ruff`, `ruff_format` |
| sh, bash | `shellcheck` | — |
| fortran, tex | none | — |
| `*` | — | `trim_whitespace`, `remove_trailing_lines` |

Fix on save is on for Python only (`b:ale_fix_on_save = 1` from a `FileType python` autocmd); everywhere else
`g:ale_fix_on_save = 0`, so the `*` fixers run only on `:ALEFix`. Linting runs on save, on leaving insert mode and on
normal-mode text changes. Signs: `✗` error, `!` warning.

### Git: fugitive and gitgutter

| Key | Action |
|---|---|
| `,gs` | `:Git` (status) |
| `,gb` | `:Git blame` |
| `,gd` | `:Gdiffsplit` |
| `,gl` | `:Git log --oneline --decorate --all` |
| `,gc` | `:Git commit` |
| `,gp` | `:Git push` |
| `]c` / `[c` | next / previous hunk |
| `,gh` | preview hunk |
| `,ga` | stage hunk |
| `,gu` | undo hunk |

gitgutter's default maps are off (`g:gitgutter_map_keys = 0`, `vim/.vim/plugconf/vim-gitgutter.vim`): its
`<leader>h*` maps would make `,h` wait. `signcolumn=yes` is pinned so the gutter does not flicker as signs come and
go.

### fzf finders

| Key | Command |
|---|---|
| `,f` | `:Files` |
| `,b` | `:Buffers` |
| `,r` | `:Rg ` (type the pattern, then `<CR>`) |
| `,t` | `:Tags` |
| `,h` | `:History` |
| `,/` | `:Lines` |

`:Rg` needs ripgrep on `$PATH`.

### easymotion

The default mappings are off (`g:EasyMotion_do_mapping = 0`), smartcase is on. Only these six are defined, in
`vim/.vim/plugconf/vim-easymotion.vim`:

| Key | Target |
|---|---|
| `,,s` | any character, both directions (`easymotion-bd-f`) |
| `,,w` | start of any word, both directions |
| `,,j` / `,,k` | line below / above |
| `,,l` / `,,h` | forward / backward in the current line |

### Folding

| Setting | Value |
|---|---|
| global `foldmethod` | `marker` (<code v-pre>{{{</code> / <code v-pre>}}}</code>) |
| `foldmethod=syntax` | fortran, make, dosini, c, cpp, tex, css, java, php, xml, markdown |
| `foldmethod=indent` | sh, bash; python (from `ftplugin/python.vim`) |
| `foldlevelstart` | `0`: files open fully folded |
| `foldcolumn` | `1` |
| Fortran | `fortran_fold` and `fortran_fold_conditionals` on |

`augroup folding` switches to `foldmethod=manual` on `InsertEnter` and restores the previous method on
`InsertLeave`, so folds are not recomputed on every keystroke. `sh_fold_enabled` and `xml_syntax_folding` are set
per filetype.

### vimtex

vimtex loads for `tex` buffers. `ftplugin/tex.vim` sets the viewer to Evince
(`g:vimtex_view_general_viewer = 'evince'`). Its maps are vimtex's defaults under `<localleader>`, which is `,`.

### markdown-preview

Loaded for markdown buffers; `:MarkdownPreview` opens the live preview in the browser, `:MarkdownPreviewStop` stops it.
Only two values differ from the defaults, set in `.vimrc`: `g:mkdp_theme = 'dark'` and `g:mkdp_auto_close = 0`
(the preview stays open when the buffer is left).

### gnupg

vim-gnupg decrypts an encrypted file on read and re-encrypts it on write. It has no
configuration in this package; passphrases go through gpg-agent, whose pinentry terminal is set in
`~/.bash/exports` (see [bash](/packages/bash)).

## Colours

Solarized dark from [vim-solarized8](https://github.com/lifepillar/vim-solarized8). `termguicolors` is set when the
terminal advertises 24-bit colour (`$COLORTERM` is `truecolor` or `24bit`); solarized8 then paints exact hex values
and never reads the terminal's ANSI palette. Without truecolor it falls back to 256-colour approximations.

The ANSI palette is not trusted because Noctalia, the theme engine on quark, lifts ANSI 8 (bright black) above the
background in every palette. A 16-colour scheme that paints `Normal` from it, as the old altercation solarized did,
becomes unreadable (see [quark desktop](/packages/desktop-quark)). Windows Terminal renders 24-bit colour but does not
set `COLORTERM`, so `~/.bash/exports` exports `COLORTERM=truecolor` when `WT_SESSION` is set.

Other appearance settings: `cursorline`, `SpellBad` underlined instead of coloured, bar cursor in insert mode and block
cursor in normal mode, `:Man` enabled. If solarized8 is not installed yet, `.vimrc` falls back to `default` instead of
failing with E185.

## Editing settings

### Indentation

| Scope | tabstop / shiftwidth / softtabstop | Other |
|---|---|---|
| global | 3 / 3 / 3 | `expandtab`, `shiftround`, `autoindent`, `copyindent` |
| python | 4 / 4 / 4 | `textwidth=300`, `python_highlight_*` options on |
| fortran, free form | 3 / 3 / 3 | `textwidth=132`, `synmaxcol=132` |
| fortran, fixed form | global | `textwidth=72` |
| tex | global | `spell spelllang=en`, `textwidth=175`, `formatoptions+=t -=l`, `synmaxcol=0` |

Fortran source form is decided per buffer from the extension: `.f77`, `.f`, `.for`, `.fpp` and `.fortran` (any case)
set `b:fortran_fixed_source = 1`, everything else is free form.

### Write-time cleanup

`augroup programming` in `.vimrc` acts on `BufWritePre`:

| Action | Filetypes |
|---|---|
| strip trailing whitespace | fortran, make, dosini, sh, bash, python, c, cpp, tex, vim, css, java, php, xml, markdown |
| squeeze 3+ newlines to one blank line | the same list minus dosini and python |

The same block turns on `RainbowParentheses` for the trailing-whitespace list.

### Options worth knowing

| Option | Effect |
|---|---|
| `relativenumber` | on only in the focused window in normal mode (`augroup relnum_toggle`) |
| `virtualedit=all` | cursor allowed past end of line; toggle with `,v` |
| `nowrap`, `sidescrolloff=8`, `scrolloff=4` | no wrapping; toggle with `<F2>` |
| `undofile`, `undodir=~/.vim/undo//` | persistent undo |
| `noswapfile`, `nobackup` | no swap or backup files |
| `hidden`, `switchbuf=useopen` | buffers hide instead of closing; quickfix reuses open windows |
| `modeline`, `modelines=1` | modelines read from the first line only |
| `diffopt+=iwhite` | diffs ignore whitespace |
| `ignorecase`, `smartcase` | case-insensitive search unless the pattern has capitals |

Cursor returns to the last position on reopening a file; windows rebalance on terminal resize.

## Key map

Leader and localleader are both `,`. Only maps defined in this package are listed; plugin defaults (surround,
commentary, unimpaired, dirvish, vimtex) stay active.

### Editing and windows

| Key | Mode | Action |
|---|---|---|
| `/` | n, x | search with very-magic regex (`/\v`) |
| `Y` | n | yank to end of line |
| `<C-j>` | n | split the line at the cursor (opposite of `J`) |
| `v` | x | cycle visual, visual-block, visual-line |
| `<C-e>` / `<C-y>` | n | scroll 2 lines down / up |
| `<A-Up>` `<A-Down>` `<A-Left>` `<A-Right>` | n | focus window above / below / left / right |
| `<F2>` | n | toggle wrap |
| `<C-n>` | n | toggle `relativenumber` |
| `,v` | n | toggle `virtualedit=all` |

### Buffers and outline

| Key | Action |
|---|---|
| `<C-Right>` / `<C-Left>` | `:bnext` / `:bprevious` |
| `qq` | `:Bdelete` |
| `<F3>` | `:TagbarToggle` |

### Leader maps

| Key | Action | Section |
|---|---|---|
| `,f` `,b` `,r` `,t` `,h` `,/` | files, buffers, ripgrep, tags, history, lines | [fzf finders](#fzf-finders) |
| `,lr` `,la` `,lf` | rename, code action, format | [LSP](#lsp) |
| `,gs` `,gb` `,gd` `,gl` `,gc` `,gp` | status, blame, diff, log, commit, push | [Git](#git-fugitive-and-gitgutter) |
| `,gh` `,ga` `,gu` | preview, stage, undo hunk | [Git](#git-fugitive-and-gitgutter) |
| `,,s` `,,w` `,,j` `,,k` `,,l` `,,h` | labelled jumps | [easymotion](#easymotion) |
| `,v` | toggle `virtualedit` | [Editing](#editing-and-windows) |

### Other plugin maps

| Key | Mode | Action |
|---|---|---|
| `gd` `gr` `K` | n | definition, references, hover |
| `[d` / `]d` | n | previous / next diagnostic |
| `]c` / `[c` | n | next / previous hunk |
| `<Tab>` `<S-Tab>` `<CR>` | i | completion, see [Completion](#completion) |

### No prefix collisions

A leader map must never be a prefix of another one. If `,r` and `,rn` both exist, vim cannot tell whether `,r` is
complete and waits `timeoutlen` every time it is typed. Hence LSP rename is `,lr`, not `,rn` (`,r` is ripgrep), and the
hunk maps are `,g{h,a,u}` instead of gitgutter's `,h*` (`,h` is history). Check every new map against this table. vim
and Neovim share this key map, so the rule applies to both.

## Things to know

- **`mapleader` must stay before `plug#begin`.** plugconf defines its mappings right after `plug#end()`, and
  `<leader>` is expanded when a mapping is defined; vimtex reads `maplocalleader` when it loads. Moved later, every
  plugconf map lands on `\`.
- **The LSP maps are global.** `gd`, `gr`, `K`, `[d` and `]d` are defined for every buffer and do nothing where no
  server is attached; native `K` (`keywordprg`) and `gd` are gone everywhere.
- **LSP setup waits for `VimEnter`.** `LspOptionsSet` and `LspAddServer` come from the plugin's `plugin/lsp.vim`,
  which is not sourced yet when plugconf runs. Calling them directly fails with E117.
- **gfortran is not an ALE linter.** It lints one file without the `.mod` files of external modules (PENF, MPI, ...)
  and reports false errors.
- **fortls diagnostics are off on purpose.** `--excl_paths` takes absolute paths only, so on FoBiS-fetched
  third-party trees and FORD `docs/api/src` shadow copies fortls reports spurious errors for every duplicated module.
  Drop a per-project `.fortls` to get them back.
- **`install-vim-lsp.sh` is Debian/Ubuntu only.** Its preflight exits when pipx, npm or `apt-get` is missing, so on
  CachyOS install the servers by hand.
- **Trailing-whitespace stripping is per filetype in vim.** Filetypes outside the list (e.g. `yaml`, `lua`, `toml`)
  keep trailing whitespace on write. Neovim strips it everywhere except `diff`, `gitsendemail` and `mail`.
- **`foldmethod=syntax` uses `set`, not `setlocal`.** Opening a C or Fortran file changes the global value, which new
  windows inherit.
