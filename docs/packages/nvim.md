---
title: Neovim
---

# Neovim

The `nvim/` package is a port of the [vim](/packages/vim) setup to Lua and Neovim-native plugins. It runs alongside
vim, not instead of it: same leader, same key map, no shared state. vim stays the default editor (`$EDITOR`, git
`core.editor` and difftool are still `vim`).

## Usage

```bash
~/.scripts/install-nvim           # nvim + rg, fd, tree-sitter CLI
~/.scripts/install-vim-lsp.sh     # language servers, shared with vim
bash ~/dotfiles/dotify.sh nvim    # link ~/.config/nvim
nvim                              # first start clones lazy.nvim, installs plugins and parsers
```

`install-nvim` is idempotent and never touches vim:

| Host | nvim | rg, fd | tree-sitter CLI |
|---|---|---|---|
| Arch / CachyOS | `pacman -S --needed neovim` | pacman | pacman (`tree-sitter-cli`) |
| Ubuntu / WSL2 | upstream tarball, pinned `NVIM_VERSION`, checked against `NVIM_SHA256` | apt (`fd-find`, exposed as `~/.local/bin/fd`) | `npm install -g tree-sitter-cli` (nvm scope) |

On Ubuntu each release unpacks into `~/.local/opt/nvim-v<version>/` and `~/.local/bin/nvim` is a symlink to the
active one. Older versions stay on disk, so a rollback is one `ln -sfn`. To upgrade, bump `NVIM_VERSION` and
`NVIM_SHA256` together.

Plugin revisions are pinned in `lazy-lock.json`, which is committed. lazy.nvim does no background checks
(`checker.enabled = false`):

```vim
:Lazy update       " move plugins forward, rewrites lazy-lock.json: commit it
:Lazy restore      " return to the revisions in lazy-lock.json
```

## Layout

| Path | Role |
|---|---|
| `nvim/.config/nvim/init.lua` | Requires `config.options`, `config.keymaps`, `config.autocmds`, `config.lazy`, in this order |
| `lua/config/options.lua` | Options that differ from Neovim defaults; leaders; WSL clipboard; `fobos` filetype |
| `lua/config/keymaps.lua` | Core maps (plugin maps live in their spec) |
| `lua/config/autocmds.lua` | Port of the vimrc autocommands |
| `lua/config/lazy.lua` | lazy.nvim bootstrap and setup |
| `lua/plugins/*.lua` | One spec per plugin or plugin family |
| `lua/plugins/extras.lua` | Plugins on trial, with no vim counterpart |
| `ftplugin/fortran.lua` | Fixed or free source form, before the runtime reads it |
| `after/ftplugin/{fortran,python,tex}.lua` | Per-filetype options |
| `queries/fortran/rainbow-delimiters.scm` | Fortran query for rainbow-delimiters (none upstream) |
| `lazy-lock.json` | Plugin revisions |

The options set the leaders first, so they exist before lazy.nvim registers any plugin key.

### Coexistence with vim

| Resource | vim | Neovim |
|---|---|---|
| config | `~/.vimrc`, `~/.vim/` | `~/.config/nvim/` |
| plugins | `~/.vim/plugged` (vim-plug) | `~/.local/share/nvim/lazy` (lazy.nvim) |
| treesitter parsers | — | `~/.local/share/nvim/site` |
| undo | `~/.vim/undo` | `~/.local/state/nvim/undo` (default; `undodir` is not set) |
| LSP servers, fzf, rg, ruff, shellcheck | shared binaries | shared binaries |

Never couple the two: no `source ~/.vimrc`, no `~/.vim` on the runtimepath, no `undodir` pointing at `~/.vim/undo`.
vim-plug and lazy.nvim on one plugin tree would race, and yegappan/lsp is Vim9script, which Neovim cannot run.

## Plugins

### From vim to Neovim

| vim | Neovim | Notes |
|---|---|---|
| vim-plug + plugconf | [lazy.nvim](https://github.com/folke/lazy.nvim) | one spec file per plugin replaces plugconf |
| yegappan/lsp | native `vim.lsp.config` / `vim.lsp.enable` + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | lspconfig is used only for its `lsp/*.lua` server definitions |
| ALE | [conform.nvim](https://github.com/stevearc/conform.nvim) + ruff server + bash-language-server | conform formats; linting moved to the servers (bashls runs shellcheck itself) |
| vim-solarized8 | [maxmx03/solarized.nvim](https://github.com/maxmx03/solarized.nvim) | 24-bit, independent of the terminal palette |
| lightline + lightline-bufferline | [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | buffer tabline, no icons |
| fzf + fzf.vim | [fzf-lua](https://github.com/ibhagwan/fzf-lua) | also serves `vim.ui.select` (code actions) |
| vim-dirvish | [oil.nvim](https://github.com/stevearc/oil.nvim) | editable directory buffer, replaces netrw |
| vim-easymotion | [flash.nvim](https://github.com/folke/flash.nvim) | same `,,` keys; native `f` `t` `F` `T` untouched |
| vim-surround + vim-repeat | [nvim-surround](https://github.com/kylechui/nvim-surround) | same `ys` `cs` `ds` `S` keys, dot-repeat built in |
| vim-commentary | built-in `gc` / `gcc` | — |
| lexima.vim | [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | — |
| vim-gitgutter | [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | same keys |
| tagbar | [aerial.nvim](https://github.com/stevearc/aerial.nvim) | symbols from LSP, then treesitter; no ctags; source order |
| vim-bbye | [snacks.nvim](https://github.com/folke/snacks.nvim) `bufdelete` | only snack in use |
| rainbow_parentheses | [rainbow-delimiters.nvim](https://github.com/HiPhish/rainbow-delimiters.nvim) | custom Fortran query |
| python-syntax, regex syntax | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch) | not for LaTeX |
| vim-unimpaired | — | not ported |
| tabular | — | dropped, redundant with easy-align |
| vim-fugitive, vimtex, markdown-preview.nvim, vim-gnupg, vim-easy-align, VisIncr, HowMuch, vim-maketable | kept | `lua/plugins/vim-plugins.lua`, `lua/plugins/git.lua` |

### New in Neovim

| Plugin | What for | Spec |
|---|---|---|
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Pops up the continuations of a pending key sequence; groups `,g` git, `,l` lsp | `which-key.lua` |
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | Sticky header (up to 3 lines) with the enclosing module, procedure or block | `treesitter.lua` |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Lists for diagnostics, symbols, quickfix | `extras.lua` |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Tabpage for a diff or a file's history | `extras.lua` |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlights TODO, FIXME, NOTE in comments (needs plenary.nvim) | `extras.lua` |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Renders markdown in the buffer; off until toggled | `extras.lua` |

`extras.lua` holds the plugins on trial, one block each, so dropping one is deleting its block.

### LSP

The servers are the vim ones plus ruff, enabled only when the executable is on `$PATH`:

| Server | Executable |
|---|---|
| `fortls` | `fortls` |
| `basedpyright` | `basedpyright-langserver` |
| `ruff` | `ruff` |
| `texlab` | `texlab` |
| `bashls` | `bash-language-server` |

No mason: `~/.scripts/install-vim-lsp.sh` provisions the servers once for both editors. fortls runs with the same flags
as in vim and its `publishDiagnostics` handler is a no-op. basedpyright owns hover; ruff has its hover capability
switched off and owns lint and fixes.

Diagnostics: signs `✗` and `!`, underlined ranges, no virtual text, messages on demand (`,ld` or after `[d` / `]d`).
Completion is manual, as in vim: `vim.lsp.completion` with `autotrigger = false`, triggered by `<Tab>`.

### Formatting

conform.nvim fixes and formats Python on save (`ruff_fix`, `ruff_format`, LSP formatting never). Every other filetype
formats only on `,lf`, through the LSP when no conform formatter exists.

### Treesitter

Parsers installed on first start, then a no-op: `fortran python bash c cpp cuda make cmake lua vim vimdoc query regex
markdown markdown_inline latex bibtex json yaml toml ini diff gitcommit git_rebase`. They compile with the tree-sitter
CLI and a C compiler.

A `FileType` autocmd starts treesitter highlighting per buffer and, where the parser has fold queries, switches the
window to `foldmethod=expr` with `vim.treesitter.foldexpr()`. It runs after the filetype plugins, so treesitter folds
win; the `foldmethod` set in `config/autocmds.lua` is the fallback. Python gets treesitter folds instead of vim's
`foldmethod=indent`.

`tex` and `plaintex` are excluded from treesitter highlighting: vimtex needs its own syntax for motions, text objects
and concealment. The `latex` parser is still installed for rainbow delimiters and math in markdown.

## Key map

The common key map is on the [vim page](/packages/vim#key-map): core editing keys, `qq`, finders, LSP, git and the `,,`
jumps use the same keys in both editors. Leader and localleader are `,`. This table lists only what differs.

| Key | Neovim | vim |
|---|---|---|
| `,r` | fzf-lua `live_grep`: rg re-runs as you type | `:Rg ` then pattern |
| `,h` | fzf-lua `oldfiles`, including this session's files | `:History` |
| `,lf` | conform format, LSP fallback | `:LspFormat` |
| `,ld` | line diagnostics float | — |
| `[d` / `]d` | jump and open the diagnostic float | jump |
| `K` | hover (Neovim default) | `:LspHover` |
| `<C-s>` (insert) | signature help (Neovim default) | — |
| `gr` | references, `nowait`: fires at once instead of waiting for Neovim's `grn` `gra` `grr` `gri` | `:LspShowReferences` |
| `,gu` | gitsigns reset hunk | gitgutter undo hunk |
| `<F3>` | aerial outline, left | tagbar |
| `-` | oil: parent directory | dirvish, its own maps |
| `gc` / `gcc` | built-in comment | vim-commentary |
| `,gD` / `,gH` | diffview: working tree / current file history | — |
| `,xx` `,xb` `,xs` `,xq` | trouble: diagnostics, buffer diagnostics, symbols, quickfix | — |
| `,T` | search TODO comments (fzf-lua) | — |
| `,m` | toggle in-buffer markdown rendering | — |

The LSP maps (`gd`, `gr`, `,lr`, `,la`, `,ld`, `[d`, `]d`) and the hunk maps are buffer-local, set when a server or
gitsigns attaches. In vim the LSP maps are global.

The [no-prefix-collision rule](/packages/vim#no-prefix-collisions) holds here too: rename is `,lr`, because `,r` is grep
and must not wait `timeoutlen`.

## Other differences from vim

| Topic | Neovim |
|---|---|
| `termguicolors` | always on, not conditional on `$COLORTERM` |
| trailing whitespace on write | stripped for every filetype except `diff`, `gitsendemail`, `mail`; skipped for binary buffers; search register and view preserved |
| blank-line squeeze | same filetypes as vim |
| `foldmethod` per filetype | `setlocal`, so it does not leak into new windows |
| WSL clipboard | `+` and `*` copy via OSC 52, paste via `powershell.exe Get-Clipboard` with UTF-8 output; `clipboard` stays empty |
| providers | python3, node, perl, ruby disabled |
| oil | deletes go to the trash; hidden files shown; netrw replaced, so `scp://` editing is gone (oil has `oil-ssh://`) |
| lualine tabline | labels shrink from path relative to cwd, to shortened path, to file name, so every buffer stays visible |

## Things to know

- **No icons.** The terminal font has no Nerd Font glyphs. Every plugin is configured with ASCII or plain Unicode
  (`icons_enabled = false`, `use_icons = false`, `nerd_font = false`, `file_icons = false`); a new plugin must be too.
- **Options go in `after/ftplugin/`.** The runtime `ftplugin/<ft>.vim` runs after `ftplugin/` and would override it.
  Only variables the runtime reads early belong in `ftplugin/`: `b:fortran_fixed_source` in `ftplugin/fortran.lua`.
- **One spec per plugin family** in `lua/plugins/`, with its keys inside the spec so they lazy-load with it.
  Commit `lazy-lock.json` whenever it changes.
- **vimtex is not lazy-loaded.** It sets up filetype detection and its ftplugin at startup. vim-gnupg is not lazy
  either: its `BufReadCmd` hook must exist before the first encrypted file is read.
- **On Arch the nvim version is pacman's.** The pin and checksum in `install-nvim` apply to the Ubuntu tarball only.

### Headless testing

- `VeryLazy` never fires without a UI, so nvim-surround and which-key do not load in `nvim --headless`: load the
  plugin explicitly (`require("lazy").load({ plugins = { ... } })`).
- `feedkeys(..., "x")` leaves insert mode before an asynchronous LSP completion reply arrives, so it cannot test
  `<Tab>` completion.
- markdown-preview's build step calls `mkdp#util#install_sync()`: the async installer downloads in a terminal job
  that a headless `Lazy! sync` never awaits.
