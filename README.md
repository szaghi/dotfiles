<a name="top"></a>

# szaghi's dotfiles

> *dotfiles* are your virtual home... this is my home

| | My choice |
|---|---|
| **OS** | [Arch Linux](https://archlinux.org) + [WSL2](https://learn.microsoft.com/en-us/windows/wsl/) on Windows 11 |
| **Desktop** | [KDE Plasma](https://kde.org/plasma-desktop/) |
| **Shell** | [bash](https://www.gnu.org/software/bash/) |
| **Terminal** | [Konsole](https://konsole.kde.org/) (Arch) · [Windows Terminal](https://github.com/microsoft/terminal) (WSL2) |
| **Editor** | [vim](https://www.vim.org) |
| **Theme** | [Solarized dark](https://ethanschoonover.com/solarized/) (everywhere) |

> A dotfiles repository is not intended to be forked — it is a personal backup and a source of inspiration.
> Feel free to take what is useful; sharing configs is great.

## Table of contents

- [Dependencies](#dependencies)
- [Bootstrap](#bootstrap)
- [Directory structure](#directory-structure)
  - [bash](#bash)
  - [vim](#vim)
    - [Plugin set](#plugin-set)
    - [Language Server Protocol (LSP)](#language-server-protocol-lsp)
    - [Linting and autofix (ALE)](#linting-and-autofix-ale)
    - [Completion workflow](#completion-workflow)
    - [Git (fugitive + gitgutter)](#git-fugitive--gitgutter)
    - [Fuzzy finders (fzf.vim)](#fuzzy-finders-fzfvim)
    - [Navigation (easymotion)](#navigation-easymotion)
    - [Text manipulation (surround, commentary, unimpaired, repeat)](#text-manipulation-surround-commentary-unimpaired-repeat)
    - [Alignment (tabular, easy-align, maketable)](#alignment-tabular-easy-align-maketable)
    - [Incrementing columns (VisIncr)](#incrementing-columns-visincr)
    - [Auto-pairs (lexima)](#auto-pairs-lexima)
    - [Buffer and file navigation (dirvish, bbye, tagbar)](#buffer-and-file-navigation-dirvish-bbye-tagbar)
    - [Folding (FoldFocus, native markers)](#folding-foldfocus-native-markers)
    - [LaTeX (vimtex)](#latex-vimtex)
    - [Markdown (markdown-preview)](#markdown-markdown-preview)
    - [Encryption (gnupg)](#encryption-gnupg)
    - [Arithmetic (HowMuch)](#arithmetic-howmuch)
    - [Per-filetype configuration](#per-filetype-configuration)
    - [Key mappings reference](#key-mappings-reference)
  - [git](#git)
  - [modules — HPC environments](#modules--hpc-environments)
  - [claude](#claude)
  - [scripts](#scripts)
- [Extending the dotfiles](#extending-the-dotfiles)
  - [Adding a file to an existing package](#adding-a-file-to-an-existing-package)
  - [Creating a new stow package](#creating-a-new-stow-package)
  - [Machine-specific packages](#machine-specific-packages)
- [Copyrights](#copyrights)

---

## Dependencies

### Core — required for the dotfiles system to work

| Tool | Purpose | Arch | Ubuntu / WSL2 |
|---|---|---|---|
| **git** | Version control | `pacman -S git` | `apt install git` |
| **bash** ≥ 4.4 | Shell (uses `autocd`, `globstar`, `histappend`) | pre-installed | `apt install bash` |
| **vim** | Editor | `pacman -S vim` | `apt install vim` |
| **GNU Stow** | Symlink manager — deploys packages | `pacman -S stow` | `apt install stow` |
| **Lmod** | Environment module system | `yay -S lmod` (AUR) | `apt install lmod` |
| **dircolors** | Colour-coded `ls` output (reads `~/.dircolors.256dark`) | coreutils (pre-installed) | coreutils (pre-installed) |

### Recommended — shell features degrade without these

| Tool | Purpose | Arch | Ubuntu / WSL2 |
|---|---|---|---|
| **fzf** | Fuzzy finder — used by vim (`fzf.vim`) and shell | `pacman -S fzf` | `apt install fzf` |
| **rsync** | `synccp` / `syncmv` shell functions | `pacman -S rsync` | `apt install rsync` |
| **bc** | Arithmetic in shell functions | `pacman -S bc` | `apt install bc` |
| **lesspipe** | Rich pager for binary files | `pacman -S lesspipe` | `apt install lesspipe` |
| **python3** | Claude Code status line, helper scripts | `pacman -S python` | `apt install python3` |
| **curl** | Ollama API calls in `claude_code` helpers | pre-installed | `apt install curl` |

### HPC toolchains — manual install, loaded via Lmod

These are not packaged in distro repos. Install to the paths expected by each
modulefile (see `modules/.modules/<name>/<version>.lua` for the exact `root`).

| Toolchain | Source |
|---|---|
| **NVIDIA HPC SDK** | [developer.nvidia.com/hpc-sdk](https://developer.nvidia.com/hpc-sdk) |
| **Intel oneAPI Base + HPC Toolkit** | [intel.com/oneapi](https://www.intel.com/content/www/us/en/developer/tools/oneapi/toolkits.html) |
| **AMD AOCC** | [developer.amd.com/amd-aocc](https://www.amd.com/en/developer/aocc.html) |
| **OpenMPI** | [open-mpi.org](https://www.open-mpi.org/software/) — build from source against the desired compiler |

### Development extras — optional

| Tool | Purpose | Arch | Ubuntu / WSL2 |
|---|---|---|---|
| **Ollama** | Local LLM server for `claude-local` | `yay -S ollama` (AUR) | `curl -fsSL https://ollama.com/install.sh \| sh` |
| **Claude Code** | AI coding assistant (`claude` CLI) | `npm install -g @anthropic-ai/claude-code` | same |
| **nvm** | Node.js version manager | [github.com/nvm-sh/nvm](https://github.com/nvm-sh/nvm) | same |
| **pnpm** | Fast Node package manager | `npm install -g pnpm` | same |
| **texlive + latexmk** | LaTeX compilation | `pacman -S texlive-core latexmk` | `apt install texlive latexmk` |
| **ImageMagick** | Image conversion scripts in `scripts/images/` | `pacman -S imagemagick` | `apt install imagemagick` |
| **ffmpeg** | Video-to-GIF and media helpers | `pacman -S ffmpeg` | `apt install ffmpeg` |
| **exiftool** | EXIF metadata in image scripts | `pacman -S perl-image-exiftool` | `apt install libimage-exiftool-perl` |
| **borg** | Automated backup (`scripts/borg-automated-backup/`) | `pacman -S borg` | `apt install borgbackup` |
| **nvidia-smi** | GPU status in `ollama-status` | part of NVIDIA driver | part of NVIDIA driver |

---

## Bootstrap

Deployment is handled by `dotify.sh`, a custom symlink script.
It creates `~/.bash/`, `~/.vim/`, etc. and populates them with symlinks
pointing back into this repository.

### Fresh installation

```bash
# 1. Clone the repository
git clone https://github.com/szaghi/dotfiles ~/dotfiles

# 2. (optional) copy your private bash file
cp your-private-stuff ~/dotfiles/bash/private

# 3. Run the deploy script
bash ~/dotfiles/dotify.sh
```

`dotify.sh` is idempotent — re-running it is safe; it overwrites symlinks with `ln -fs`.

### Submodules

One third-party tool is tracked as a git submodule:

| Submodule | Purpose |
|---|---|
| `scripts/bd` | `bd` — back-directory navigation |

Initialize it after cloning:

```bash
git submodule update --init
```

---

## Directory structure

```
dotfiles/
├── bash/          shell configuration
├── bin/           standalone binaries (act)
├── claude/        Claude Code configuration
├── git/           git configuration and commit template
├── miscellanea/   single-file configs (latexmkrc, NAS mount script)
├── modules/       Lmod modulefiles for HPC toolchains
├── python/        Python env (pythonrc, pylintrc)
├── scripts/       bundled third-party scripts and image utilities
├── usr/           user-level service files
├── vim/           vim configuration and plugins
└── dotify.sh      deploy script
```

---

### bash

`bash/bashrc` loads modular files from `~/.bash/`:

| File | Purpose |
|---|---|
| `aliases` | Command shortcuts (`ll`, `bd`, pacman helpers, LaTeX, git push aliases) |
| `exports` | Environment variables |
| `paths` | `PATH` additions |
| `functions` | Shell utility functions |
| `compilers` | Compiler flags and module helpers |
| `optprogs` | Optional program configuration |
| `prompt` | Two-line bash prompt with git status integration |
| `claude_code` | Dual-mode Claude Code setup (local Ollama + cloud Anthropic) |
| `private` | Machine-specific secrets — **not tracked** |

The prompt is two-line and git-aware: it shows branch, dirty state, and ahead/behind counts.

---

### vim

Vim is the editor for everything I do — Fortran/HPC, Python, LaTeX, prose.
The setup is a single `.vimrc` plus per-filetype ftplugins and per-plugin
configuration files, all managed through [vim-plug](https://github.com/junegunn/vim-plug).
Persistent undo, native relative line numbers, LSP-driven navigation and
completion for Fortran/Python/LaTeX/bash, and ALE-powered linting round out
an IDE-grade experience that stays 100% Vim (no Neovim required).

- **Leader**: `,` — all custom mappings are prefixed with `,`.
- **Localleader**: `,` — set *before* `plug#begin` so vimtex picks it up at load.
- **Persistent undo**: `~/.vim/undo/` (auto-created, excluded from stow/git).
- **Color scheme**: Solarized dark with cursorline, 1-column foldcolumn,
  `signcolumn=yes` pinned (no gitgutter flicker).

**Install / update plugins:**

```vim
:PlugInstall       " install missing plugins after pulling the repo
:PlugUpdate        " update all plugins
:PlugClean!        " remove plugins no longer listed in .vimrc
```

#### Plugin set

| Category | Plugins |
|---|---|
| Appearance | [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized), [lightline](https://github.com/itchyny/lightline.vim) + [lightline-bufferline](https://github.com/mengelbrecht/lightline-bufferline), [rainbow_parentheses](https://github.com/junegunn/rainbow_parentheses.vim) |
| LSP & linting | [yegappan/lsp](https://github.com/yegappan/lsp), [ALE](https://github.com/dense-analysis/ale) |
| Git | [vim-fugitive](https://github.com/tpope/vim-fugitive), [vim-gitgutter](https://github.com/airblade/vim-gitgutter) |
| Fuzzy finders | [fzf](https://github.com/junegunn/fzf) + [fzf.vim](https://github.com/junegunn/fzf.vim) |
| Navigation | [easymotion](https://github.com/easymotion/vim-easymotion), [vim-dirvish](https://github.com/justinmk/vim-dirvish), [tagbar](https://github.com/majutsushi/tagbar), [vim-bbye](https://github.com/moll/vim-bbye), [vim-foldfocus](https://github.com/vasconcelloslf/vim-foldfocus) |
| Text editing | [vim-surround](https://github.com/tpope/vim-surround), [vim-repeat](https://github.com/tpope/vim-repeat), [vim-commentary](https://github.com/tpope/vim-commentary), [vim-unimpaired](https://github.com/tpope/vim-unimpaired), [lexima](https://github.com/cohama/lexima.vim), [VisIncr](https://github.com/vim-scripts/VisIncr) |
| Alignment | [tabular](https://github.com/godlygeek/tabular), [vim-easy-align](https://github.com/junegunn/vim-easy-align), [vim-maketable](https://github.com/mattn/vim-maketable) |
| Languages | [vimtex](https://github.com/lervag/vimtex), [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim), [python-syntax](https://github.com/vim-python/python-syntax) |
| Utilities | [vim-gnupg](https://github.com/jamessan/vim-gnupg), [HowMuch](https://github.com/sk1418/HowMuch), [plugconf](https://github.com/niboan/plugconf) |

Per-plugin config lives in `vim/.vim/plugconf/*.vim` (loaded by [plugconf](https://github.com/niboan/plugconf)
after `plug#end()`).

#### Language Server Protocol (LSP)

Provided by [yegappan/lsp](https://github.com/yegappan/lsp), a pure-Vim9 LSP
client (no Neovim, no Node). Configured servers:

| Language | Server | Install |
|---|---|---|
| Fortran | [fortls](https://github.com/fortran-lang/fortls) | `pipx install fortls` |
| Python | [basedpyright](https://github.com/DetachHead/basedpyright) | `pipx install basedpyright` |
| LaTeX | [texlab](https://github.com/latex-lsp/texlab) | GitHub release (Ubuntu 24.04 has no apt package) |
| Bash | [bash-language-server](https://github.com/bash-lsp/bash-language-server) | `npm install -g bash-language-server` |

One-shot install for all four plus shellcheck:

```bash
~/.scripts/install-vim-lsp.sh
```

The script is idempotent and detects missing binaries, so it is safe to re-run
after a distro upgrade or on a fresh machine.

**Key mappings (active only in buffers with an attached server):**

| Key | Action |
|---|---|
| `gd` | `:LspGotoDefinition` |
| `gr` | `:LspShowReferences` (populates quickfix) |
| `K` | `:LspHover` — docs in a floating popup under the cursor (dismissed on motion) |
| `<leader>rn` | `:LspRename` — rename symbol across project |
| `<leader>la` | `:LspCodeAction` — quick-fixes and refactors |
| `<leader>lf` | `:LspFormat` — format buffer via LSP |
| `[d` / `]d` | Previous / next diagnostic |
| `<Tab>` | Trigger completion (see below) |

**Fortran note.** `fortls` diagnostics are intentionally disabled via
`features: { diagnostics: v:false }`. `fortls`'s CLI `--excl_paths` only
accepts absolute paths, so on [FoBiS](https://github.com/szaghi/FoBiS)-managed
repos with `third_party/*/docs/api/src/` shadow trees it emits spurious
diagnostics for any symbol coming from a shadow-duplicated module.
Navigation, hover, completion and references still work perfectly —
only the red-`E>` diagnostic signs are suppressed. Projects that actually
want diagnostics can drop a per-project `.fortls` and flip the feature
back on.

#### Linting and autofix (ALE)

[ALE](https://github.com/dense-analysis/ale) handles linting and fixing
without running its own LSP client (`g:ale_disable_lsp = 1` — LSP ownership
stays with `yegappan/lsp`).

| Filetype | Linter | Fixer |
|---|---|---|
| Python | [ruff](https://docs.astral.sh/ruff/) | `ruff` + `ruff_format` on save |
| Bash / sh | [shellcheck](https://www.shellcheck.net/) | — |
| Any | — | `trim_whitespace`, `remove_trailing_lines` |

- Python files are automatically formatted with ruff on `:w`.
  Other filetypes only lint — no surprise autofix.
- Diagnostic popup under the cursor: `:ALEDetail`.
- Gutter signs: `✗` (error), `!` (warning).

#### Completion workflow

Completion is manual, not auto-popup (to keep Vim feeling like Vim). The
popup menu is triggered from LSP's omnifunc:

| Key (insert mode) | Behavior |
|---|---|
| `<Tab>` | If popup visible → next item; after a word char → trigger omnicomplete; otherwise → literal `<Tab>` |
| `<S-Tab>` | If popup visible → previous item; otherwise → literal `<S-Tab>` |
| `<CR>` | If popup visible → accept selected item; otherwise → delegate to lexima (auto-pair Enter) |
| `<C-x><C-o>` | Manual omnicomplete trigger |

The `<Tab>` behavior is context-aware: it will not eat indentation
whitespace at the start of a line.

#### Git (fugitive + gitgutter)

[vim-fugitive](https://github.com/tpope/vim-fugitive) provides the git
porcelain inside Vim. [vim-gitgutter](https://github.com/airblade/vim-gitgutter)
shows per-hunk change indicators in the `signcolumn`.

| Key | Action |
|---|---|
| `<leader>gs` | `:Git` — status window (stage/unstage with `s`/`u`, diff with `=`) |
| `<leader>gb` | `:Git blame` |
| `<leader>gd` | `:Gdiffsplit` — 3-way diff in a split |
| `<leader>gl` | `:Git log --oneline --decorate --all` |
| `<leader>gc` | `:Git commit` |
| `<leader>gp` | `:Git push` |

Example — stage a hunk, commit, push from inside Vim without leaving the buffer:

```
,gs        " open status
 → press s on the file to stage
 → press cc to write the commit message
 → :wq to commit
,gp        " push
```

`signcolumn=yes` is pinned in `.vimrc` so the gutter never flickers as
gitgutter adds or removes signs.

#### Fuzzy finders (fzf.vim)

Requires [fzf](https://github.com/junegunn/fzf) and [ripgrep](https://github.com/BurntSushi/ripgrep)
on `$PATH`.

| Key | Action |
|---|---|
| `<leader>f` | `:Files` — fuzzy file finder in cwd |
| `<leader>b` | `:Buffers` — fuzzy buffer switcher |
| `<leader>r` | `:Rg ` — ripgrep (type pattern, `<CR>` to run) |
| `<leader>t` | `:Tags` — ctags jump |
| `<leader>h` | `:History` — recently-opened files |
| `<leader>/` | `:Lines` — fuzzy search across buffer lines |

#### Navigation (easymotion)

[easymotion](https://github.com/easymotion/vim-easymotion) gives 2-keystroke
jumps to anywhere visible. Default aggressive mappings are disabled
(`g:EasyMotion_do_mapping = 0`) so single-`,` mappings stay untouched.

| Key | Action |
|---|---|
| `,,s{char}` | Jump to any occurrence of `{char}` on screen |
| `,,w` | Jump to the start of a word |
| `,,j` / `,,k` | Jump down / up to a target line |
| `,,l` / `,,h` | Jump forward / backward within the current line |

**Arrow keys for window splits:**

| Key | Action |
|---|---|
| `<A-Up>` / `<A-Down>` / `<A-Left>` / `<A-Right>` | Focus window above / below / left / right |
| `<C-Right>` / `<C-Left>` | Next / previous buffer (bnext / bprevious) |
| `qq` | Close buffer (keeps window layout, via [vim-bbye](https://github.com/moll/vim-bbye)'s `:Bdelete`) |
| `<C-N>` | Toggle relativenumber on current window |
| `<leader>v` | Toggle `virtualedit=all` (cursor allowed in empty columns) |

#### Text manipulation (surround, commentary, unimpaired, repeat)

Four [tpope](https://github.com/tpope) plugins that become muscle memory
within days.

**[vim-surround](https://github.com/tpope/vim-surround)** — manipulate
surrounding delimiters:

| Command | Effect |
|---|---|
| `cs"'` | Change surrounding `"` to `'`: `"foo"` → `'foo'` |
| `ds(` | Delete surrounding `()`: `(foo)` → `foo` |
| `ysiw]` | Wrap word in `[]`: `foo` → `[foo]` |
| `yss)` | Wrap whole line in `()` |
| `S<` (visual) | Wrap selection in `<>` |

**[vim-commentary](https://github.com/tpope/vim-commentary)** — toggle comments:

| Command | Effect |
|---|---|
| `gcc` | Toggle comment on current line |
| `gc{motion}` | Toggle comment over motion (e.g. `gcap` — around paragraph) |
| `gc` (visual) | Toggle comment on selection |

**[vim-unimpaired](https://github.com/tpope/vim-unimpaired)** — paired
bracket mappings:

| Command | Effect |
|---|---|
| `]q` / `[q` | Next / previous quickfix entry |
| `]l` / `[l` | Next / previous location list entry |
| `]b` / `[b` | Next / previous buffer |
| `]<Space>` / `[<Space>` | Add blank line below / above |
| `]e` / `[e` | Swap current line with next / previous |
| `yo{char}` | Toggle option: `yos` (spell), `yow` (wrap), `yoh` (hlsearch), `yol` (list), `yon` (number)… |

**[vim-repeat](https://github.com/tpope/vim-repeat)** — lets `.` repeat
complex plugin actions (surround, commentary, unimpaired). No mappings;
just works.

#### Alignment (tabular, easy-align, maketable)

Three overlapping plugins, used for different jobs.

**[vim-easy-align](https://github.com/junegunn/vim-easy-align)** — interactive
visual alignment (fastest for one-off work):

```
" select a visual block, then:
ga=        " align on first =
ga*=       " align on every =
ga<CR>,    " align on , with centered spacing
```

**[tabular](https://github.com/godlygeek/tabular)** — scriptable alignment for
macros and autocmds:

```vim
:Tabularize /=
:Tabularize /|
```

**[vim-maketable](https://github.com/mattn/vim-maketable)** — convert a
CSV/TSV selection to a markdown/rst/org table. Useful when pasting data
into prose.

#### Incrementing columns (VisIncr)

[VisIncr](https://github.com/vim-scripts/VisIncr) — fills a visual-block
column with an arithmetic / alphabetical / date / power sequence. More
expressive than Vim's native `g<C-a>` / `g<C-x>`.

```
" visually select a column, then:
:I        " increment: 1 2 3 4 ...
:II       " decrement
:IA       " alphabetical: a b c d ...
:IYMD     " dates: 2026-04-24 2026-04-25 ...
:IPOW2    " powers: 1 2 4 8 16 32 ...
```

Loaded lazily — vim-plug only sources it when one of the `I*` commands
is invoked.

#### Auto-pairs (lexima)

[lexima.vim](https://github.com/cohama/lexima.vim) auto-closes `()`, `[]`,
`{}`, `""`, `''` and friends. Smart enough to avoid duplicating the closer
when the cursor is already at it. `<CR>` inside an empty pair opens a new
indented block:

```
if foo|      — press <CR> →      if foo
|                                   |
                                end
```

The completion config above wires lexima's `<CR>` expansion into the
completion-`<CR>` fallback, so both behaviors coexist.

#### Buffer and file navigation (dirvish, bbye, tagbar)

**[vim-dirvish](https://github.com/justinmk/vim-dirvish)** — directory browser.
Replaces `netrw`. `:Dirvish` or `-` (dash) opens the current file's directory
as a plain, sortable buffer.

```
-          " open parent dir in dirvish
R          " rename with native vim commands on the buffer
:x         " filter (e.g. :sort)
```

Directory-as-buffer model — you `:w` to persist changes, like a normal file.

**[vim-bbye](https://github.com/moll/vim-bbye)** — `:Bdelete` closes a buffer
without destroying the window layout. Mapped to `qq`.

**[tagbar](https://github.com/majutsushi/tagbar)** — ctags-driven symbol
outline. Sidebar on the left, sorted:

| Key | Action |
|---|---|
| `<F3>` | Toggle tagbar |

Requires `ctags` (`apt install exuberant-ctags` or `universal-ctags`).
For Fortran/Python/LaTeX the LSP symbol lookup (`gd`, `gr`) is usually
more accurate; tagbar is the fallback for filetypes without an LSP.

#### Folding (FoldFocus, native markers)

`.vimrc` sets `foldmethod=marker` globally so `{{{` / `}}}` triple-brace
markers define folds. Fold column shows as a 1-col gutter.
[vim-foldfocus](https://github.com/vasconcelloslf/vim-foldfocus) (Python
and Fortran only) opens the current fold in an isolated split for
distraction-free editing:

| Key | Action |
|---|---|
| `<C-f>` | Open current fold in a vertical split (FoldFocus) |
| `za` | Native: toggle fold under cursor |
| `zR` / `zM` | Native: open all / close all folds |

`foldlevelstart=0` — files open fully folded. `foldopen` is tuned so
most navigation commands auto-open folds as needed.

A dedicated autocmd (`augroup folding`) temporarily sets `foldmethod=manual`
during insert mode to prevent fold recalculation on every keystroke in
large Fortran files.

#### LaTeX (vimtex)

[vimtex](https://github.com/lervag/vimtex) is loaded for `*.tex` files.
Compilation uses `latexmk` (configured globally in `~/.latexmkrc`, see
`miscellanea/.latexmkrc`). PDF viewer: Evince.

| Key (localleader = `,`) | Action |
|---|---|
| `,ll` | Start continuous compilation (`:VimtexCompile`) |
| `,lv` | Forward search to PDF viewer (`:VimtexView`) |
| `,lc` | Clean aux files |
| `,le` | Show compilation errors in quickfix |
| `,li` | Show compilation info |
| `,lt` | Toggle table of contents |

The `localleader = ","` is set in `.vimrc` *before* `plug#begin` — setting
it later (e.g. in an ftplugin) is too late, vimtex registers its mappings
at plugin-load time.

#### Markdown (markdown-preview)

[markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
renders markdown live in the browser. Works in plain Vim despite the `.nvim`
suffix.

```
:MarkdownPreview       " open preview in default browser
:MarkdownPreviewStop   " stop the preview server
```

Dark theme by default (`g:mkdp_theme = 'dark'`); see `vim/.vim/plugconf/markdown-preview.vim`
for all tunables (TOC, KaTeX math, Mermaid, PlantUML, custom CSS).

#### Encryption (gnupg)

[vim-gnupg](https://github.com/jamessan/vim-gnupg) transparently
encrypts/decrypts files matching `*.gpg`, `*.pgp`, `*.asc`. Opening a
`.gpg` file prompts for the passphrase; saving re-encrypts in place.

```
vim secrets.txt.gpg
" edit normally
:w
" → file is re-encrypted to disk
```

GPG agent handles passphrase caching.

#### Arithmetic (HowMuch)

[HowMuch](https://github.com/sk1418/HowMuch) evaluates an arithmetic
expression in the current selection and appends the result. Loaded
lazily via `:HowMuch`.

```
" visually select: 2 * (3 + 4)
:HowMuch
" → appends: = 14
```

#### Per-filetype configuration

Per-filetype settings live in `vim/.vim/ftplugin/<filetype>.vim` and are
auto-sourced by Vim when a buffer of that type is opened:

| File | Purpose |
|---|---|
| `fortran.vim` | Per-buffer free/fixed source-form detection (`b:fortran_fixed_source`), `textwidth` per form, syntax folding |
| `python.vim` | 4-space indent (overrides the global 3), indent-based folding, python-syntax highlight knobs |
| `tex.vim` | English spell check, synmaxcol=0 for long equations, vimtex viewer set to Evince |

A custom filetype detection file `vim/.vim/ftdetect/fobos.vim` treats
any file whose name starts with `fobos` as `dosini` (so
[FoBiS](https://github.com/szaghi/FoBiS) project files get syntax
highlighting).

Common programming-file behavior (whitespace trimming, blank-line squash,
RainbowParentheses activation, syntax folding) is defined in a single
`augroup programming` block in `.vimrc`.

#### Key mappings reference

Leader = `,`, Localleader = `,`. Only custom mappings are listed — native
Vim keys still behave as usual.

**Editing / windows**

| Key | Mode | Action |
|---|---|---|
| `/` | n, x | Search with Perl/Python regex semantics (`\v`) |
| `Y` | n | Yank to end of line (analogous to `D`) |
| `<NL>` (Ctrl-J) | n | Insert line break at cursor (opposite of `J`) |
| `v` | x | Cycle through visual → visual-block → visual-line |
| `<C-e>` / `<C-y>` | n | Scroll viewport 2 lines down / up |
| `<A-↑↓←→>` | n | Focus window above / below / left / right |
| `<F2>` | n | Toggle line wrap |
| `<C-N>` | n | Toggle relativenumber |
| `<leader>v` | n | Toggle `virtualedit=all` |

**Buffers**

| Key | Action |
|---|---|
| `<C-Right>` / `<C-Left>` | `:bnext` / `:bprevious` |
| `]b` / `[b` | Same (via unimpaired) |
| `qq` | `:Bdelete` (vim-bbye) |

**Finders (fzf.vim)** — see [Fuzzy finders](#fuzzy-finders-fzfvim).
**LSP** — see [LSP](#language-server-protocol-lsp).
**Git** — see [Git](#git-fugitive--gitgutter).
**Easymotion** — see [Navigation](#navigation-easymotion).

**Plugin togglers**

| Key | Action |
|---|---|
| `<F3>` | Toggle tagbar |
| `<C-f>` | FoldFocus — current fold in vsplit (Python/Fortran only) |

---

### git

| File | Deployed to | Purpose |
|---|---|---|
| `git/gitconfig` | `~/.gitconfig` | Git identity, aliases, GPG signing |
| `git/git_commit_message_template` | `~/.git/git_commit_message_template` | Conventional Commits template |

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): description`

---

### modules — HPC environments

[Lmod](https://lmod.readthedocs.io/) manages compiler toolchains.
Modulefiles live in `modules/.modules/` (deployed to `~/.modules/` via stow).
Lmod is initialised automatically in `bash/.bash/exports`.

**Daily usage:**

```bash
module avail                         # list all available modules
module load gcc/15.1.0               # load GCC 15.1.0
module load nvhpc/24.11              # load NVIDIA HPC SDK 24.11
module load openmpi/5.0.7-gnu14.2.0  # load OpenMPI (built against GCC 14)
module list                          # show currently loaded modules
module unload gcc/15.1.0             # unload a single module
module purge                         # unload everything
```

The bash prompt shows loaded modules automatically (`env {gcc/15.1.0 openmpi/5.0.7-gnu14.2.0}`).

**Available modules:**

| Module | Description |
|---|---|
| `gcc/15.1.0` | GCC 15.1.0 compiler toolchain |
| `nvhpc/23.1` · `24.11` · `25` · `26` | NVIDIA HPC SDK (nvfortran, nvc, nvc++) |
| `intel/oneapi` | Intel oneAPI compilers (ifort, icc, icx) |
| `amd/5.1.0` | AMD AOCC 5.1.0 compilers |
| `openmpi/3.1.5-nvhpc{20.7,22.3,23.1}` | OpenMPI 3.1.5 built against NVHPC |
| `openmpi/4.1.4-gnu11.2.0` | OpenMPI 4.1.4 built against GCC 11 |
| `openmpi/4.1.4-intel2021.5.0` | OpenMPI 4.1.4 built against Intel 2021 |
| `openmpi/5.0.7-gnu14.2.0` | OpenMPI 5.0.7 built against GCC 14 |

**Adding a new module:**

Modulefiles are Lua scripts. Create one at `modules/.modules/<name>/<version>.lua`
mirroring the existing ones. Minimal template:

```lua
whatis("Short one-line description")

help([[
Long description shown by `module help <name>/<version>`.
]])

local root = "/path/to/install"

family("compiler")  -- optional: ensures only one compiler is active at a time

if not isDir(root) then
  LmodError(root .. " not found")
end

prepend_path("PATH",            pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH",         pathJoin(root, "share/man"))

setenv("CC",  "gcc")
setenv("CXX", "g++")
setenv("FC",  "gfortran")
```

Because `~/.modules` is a stow symlink pointing into the repo, the new file is
**immediately visible** to Lmod — no re-stowing needed. Verify with `module avail`.

---

### claude

`claude/` holds configuration for [Claude Code](https://claude.ai/code),
deployed to `~/.claude/`:

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions for Claude Code |
| `settings.json` | Permissions and tool settings |
| `settings.local.json` | Machine-specific overrides — **gitignored** |
| `statusline-command.sh` | Custom status line command |
| `commands/semantic-commit.md` | `/semantic-commit` slash command |

**Three-mode Claude Code** (`bash/claude_code`):

```bash
# Local — Ollama, privacy-first (requires 2× NVIDIA GPU unless noted)
claude-local                  # qwen3-coder:latest — MoE 30B-A3B, 18 GB (default)
claude-local-light            # deepseek-coder-v2:16b, 8.9 GB — single GPU, HPC-safe
claude-local-plan             # architect: plan-architect → /model plan-executor to switch
claude-local-exec             # jump straight to executor (qwen3-coder:latest)

# Cloud — Anthropic API
claude                        # subscription default
claude-sonnet                 # force Sonnet
claude-opus                   # force Opus
claude-plan                   # read-only plan (Opus) → auto-switch to Sonnet on execute

# OpenRouter — cloud API, free-tier models
claude-openrouter             # qwen/qwen3.6-plus-preview:free (default)
claude-openrouter <model-id>  # any OpenRouter model ID (e.g. google/gemma-3-27b-it:free)

# Ollama management
ollama-start-multi            # start on all GPUs (large models)
ollama-plan-setup             # register plan-architect / plan-executor aliases (run once)
ollama-status                 # GPU + loaded model status
claude-help                   # full quick-reference
```

`ollama-plan-setup` must be run once after each fresh Ollama start to register the
`plan-architect` and `plan-executor` short-name aliases. Re-run it if `OLLAMA_PLAN_MODEL`
or `OLLAMA_EXEC_MODEL` are changed.

The OpenRouter API key is read from `~/.openrouter-ai-key` (not tracked in git).
`OPENROUTER_API_KEY` env var overrides it if set. Uses OpenRouter's Anthropic-compatible
endpoint (`https://openrouter.ai/api`) — note: the SDK appends `/v1/messages` automatically.

---

### scripts

| Path | Purpose |
|---|---|
| `scripts/bd/` | bd back-directory submodule |
| `scripts/images/` | Image processing utilities (convert, crop, scale, alpha…) |
| `scripts/iso/` | ISO mount/umount helpers |
| `scripts/miscellanea/` | Misc scripts (archive, PDF preview, NAS mount…) |
| `scripts/borg-automated-backup/` | Borg backup automation |
| `scripts/pdf/` | PDF utilities |

---

---

## Extending the dotfiles

### Adding a file to an existing package

If the config belongs to a tool already covered by a stow package, place the file
at the correct mirrored path inside that package and re-run stow:

```bash
# Example: add a new bash helper
cp my-helper ~/dotfiles/bash/.bash/my-helper

# Re-deploy the package (safe to re-run, stow is idempotent)
bash ~/dotfiles/dotify.sh bash
```

Stow will create `~/.bash/my-helper → ~/dotfiles/bash/.bash/my-helper`.

### Creating a new stow package

1. Create the package directory and mirror the `$HOME` layout inside it:

   ```bash
   # Example: track ~/.config/foo/config
   mkdir -p ~/dotfiles/foo/.config/foo
   cp ~/.config/foo/config ~/dotfiles/foo/.config/foo/config
   ```

2. Add the package name to `PACKAGES` in `dotify.sh`:

   ```bash
   PACKAGES=(bash vim git claude modules python scripts miscellanea foo)
   ```

3. Deploy:

   ```bash
   bash ~/dotfiles/dotify.sh foo
   ```

   Stow will symlink `~/.config/foo/config → ~/dotfiles/foo/.config/foo/config`.

4. Commit:

   ```bash
   git add dotify.sh foo/
   git commit
   ```

### Machine-specific packages

For configs that only belong on one machine, list the package in
`machines/<hostname>` (one package name per line):

```bash
echo "foo" >> ~/dotfiles/machines/$(hostname -s)
```

`dotify.sh` reads this file automatically and stows those packages after the
common ones. The `machines/` directory is tracked in git so the per-host
setup is reproducible.

---

## Copyrights

My dotfiles come from many years of GNU/Linux usage and inspiration from countless
people sharing their configs on the web. Distributed under the terms of the
[WTFPL — Do What the Fuck You Want to Public License](http://www.wtfpl.net/),
without any warranty.

Go to [Top](#top)
