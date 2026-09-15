<a name="top"></a>

# szaghi's dotfiles

> *dotfiles* are your virtual home... this is my home

| | My choice |
|---|---|
| **OS** | [CachyOS](https://cachyos.org) (Arch-based) + [WSL2](https://learn.microsoft.com/en-us/windows/wsl/) on Windows 11 |
| **Desktop** | Wayland: [sway](https://swaywm.org) + [Noctalia](https://github.com/noctalia-dev) on quark · [niri](https://github.com/YaLTeR/niri) on astrobit · none on adam (WSL2) |
| **Shell** | [bash](https://www.gnu.org/software/bash/) |
| **Terminal** | [foot](https://codeberg.org/dnkl/foot) (Wayland) · [Windows Terminal](https://github.com/microsoft/terminal) (WSL2) |
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
    - [GPG commit signing](#gpg-commit-signing)
  - [modules — HPC environments](#modules--hpc-environments)
  - [claude](#claude)
    - [Layout](#layout)
    - [Global configuration (CLAUDE.md, settings.json)](#global-configuration-claudemd-settingsjson)
    - [Status line](#status-line)
    - [Slash commands](#slash-commands)
    - [Skills — three-class machinery (skills-apply)](#skills--three-class-machinery-skills-apply)
    - [Claude CLI wrappers — overview](#claude-cli-wrappers--overview)
    - [Cloud: Anthropic](#cloud-anthropic)
    - [Cloud: OpenRouter](#cloud-openrouter)
    - [Cloud: Z.ai](#cloud-zai)
    - [Cloud: NVIDIA (build.nvidia.com)](#cloud-nvidia-buildnvidiacom)
      - [Latency — why this backend is parked](#latency--why-this-backend-is-parked)
    - [Local: three backends (ollama, llama.cpp, ik\_llama.cpp)](#local-three-backends-ollama-llamacpp-ik_llamacpp)
    - [Local server management (llm-local-server)](#local-server-management-llm-local-server)
    - [Ollama utilities](#ollama-utilities)
    - [llama.cpp utilities](#llamacpp-utilities)
    - [Machine-specific overrides](#machine-specific-overrides)
    - [Environment reference](#environment-reference)
  - [scripts](#scripts)
    - [skills-apply — Claude Code skills sync](#skills-apply--claude-code-skills-sync)
    - [mbox-index — searchable Gmail archive](#mbox-index--searchable-gmail-archive)
  - [desktop — quark's sway + Noctalia session](#desktop--quarks-sway--noctalia-session)
  - [desktop-astrobit — astrobit's niri session](#desktop-astrobit--astrobits-niri-session)
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
| **python3** | Claude Code status line, helper scripts, NVIDIA proxy venv (needs `python3-venv` on Debian/Ubuntu) | `pacman -S python` | `apt install python3 python3-venv` |
| **curl** | Ollama / proxy health checks in `claude_code` helpers | pre-installed | `apt install curl` |

### Desktop — quark only (CachyOS, sway + Noctalia)

Not needed on adam (WSL2, no desktop session). Not used on astrobit either: that
machine runs **niri**, not sway, so it stows `desktop-astrobit` instead — niri
plus a standalone foot config, with no Noctalia templates enabled.

| Tool | Purpose | Arch / CachyOS |
|---|---|---|
| **niri** | Wayland compositor — astrobit only | `pacman -S niri` |

| Tool | Purpose | Arch / CachyOS |
|---|---|---|
| **sway** | Wayland compositor | `pacman -S sway` |
| **noctalia** | Desktop shell — bar, launcher, notifications, lock screen; renders the colour palette into other apps' configs | AUR / upstream |
| **foot** | Terminal (`$term`) | `pacman -S foot` |
| **adw-gtk-theme** | GTK theme the Noctalia hook selects — note the package is **`adw-gtk-theme`**, *not* `adw-gtk3`, which does not exist in the repos | `pacman -S adw-gtk-theme` |
| **qt6ct** | Qt6 platform theme — reads the generated palette. `qt5ct` is deliberately **not** installed: there is no `qt5-base` on this machine | `pacman -S qt6ct` |
| **btop** | System monitor, themed via template | `pacman -S btop` |
| **grim** / **slurp** | Screenshots (`Print`, and region capture) | `pacman -S grim slurp` |

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
| **ImageMagick** | Image conversion scripts in `scripts/.scripts/` | `pacman -S imagemagick` | `apt install imagemagick` |
| **ffmpeg** | Video-to-GIF and media helpers | `pacman -S ffmpeg` | `apt install ffmpeg` |
| **exiftool** | EXIF metadata in image scripts | `pacman -S perl-image-exiftool` | `apt install libimage-exiftool-perl` |
| **borg** | Automated backup (`scripts/.scripts/borg-automated-backup.sh`) | `pacman -S borg` | `apt install borgbackup` |
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

None. `bd` (back-directory navigation) used to be a submodule and is now
vendored at `scripts/.scripts/bd`, so a plain `git clone` is complete — there
is nothing to initialise.

---

## Directory structure

Every top-level directory is a stow package whose internal layout mirrors
`$HOME`, except `machines/` (host profiles) and the two asset directories.

```
dotfiles/
├── bash/             shell configuration — common to every host
├── bash-adam/        adam's overrides (signing key, local LLM settings)
├── bash-astrobit/    astrobit's overrides
├── bash-quark/       quark's overrides
├── claude/           Claude Code configuration, skills and commands
├── desktop/          quark's Wayland desktop (sway + Noctalia + foot + Qt)
├── desktop-astrobit/ astrobit's Wayland desktop (niri + foot)
├── git/              git configuration and commit template
├── machines/         per-host package and skill lists — not a stow package
├── miscellanea/      single-file configs (latexmkrc, NAS mount script)
├── modules/          Lmod modulefiles for HPC toolchains
├── python/           Python env (pythonrc, pylintrc)
├── scripts/          scripts, user systemd units and standalone binaries
├── ssh/              ssh client configuration (config only, never keys)
├── usr/              desktop application entries (.desktop files)
├── vim/              vim configuration and plugins
└── dotify.sh         deploy script
```

---

### bash

`bash/.bashrc` loads modular files from `~/.bash/`:

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
| `git/.gitconfig` | `~/.gitconfig` | Git identity, aliases, GPG signing |
| `git/.git-templates/git_commit_message_template` | `~/.git-templates/git_commit_message_template` | Conventional Commits template |
| `git/.git-templates/hooks/post-commit` | `~/.git-templates/hooks/post-commit` | Post-commit hook shipped with the template directory |

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): description`

---

#### GPG commit signing

`commit.gpgsign = true` is set repo-wide in `git/.gitconfig`; the key itself is
**per machine**, declared in `bash-<machine>/.gitconfig.local` (symlinked to
`~/.gitconfig.local`). adam, quark and astrobit therefore carry three different
keys — a key is tied to the machine that holds its secret half, not to the
identity. All three are uploaded to the same GitHub account; GitHub accepts any
number of GPG keys and verifies a commit against whichever one signed it.

Two pieces have to be present or signing fails:

1. **The secret key.** A fresh machine has an empty keyring, and `git commit` fails
   with `gpg: skipped "<id>": No secret key`. Either import the existing key or
   generate a new one for that machine and update its `.gitconfig.local`:

   ```bash
   gpg --quick-generate-key "Stefano Zaghi <stefano.zaghi@gmail.com>" ed25519 sign never
   gpg --list-secret-keys --keyid-format=long     # take the 16-hex id
   gpg --armor --export <id>                      # paste into GitHub → SSH and GPG keys
   ```

2. **`GPG_TTY`.** The agent needs to know which terminal to draw the pinentry
   prompt on; without it signing fails with `Inappropriate ioctl for device`.
   Exported from `bash/.bash/exports`, with `~/.gnupg/gpg-agent.conf` selecting
   `pinentry-curses` so it also works over ssh and in a bare TTY.

The revocation certificate generated alongside the key
(`~/.gnupg/openpgp-revocs.d/<fingerprint>.rev`) is what revokes the key if it is
ever compromised. It is **not** in this repo and must not be — back it up somewhere
private and offline.

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

Configuration and wrappers for [Claude Code](https://claude.ai/code), a CLI
coding agent. The setup provides a single mental model over three cloud
providers (Anthropic, OpenRouter, Z.ai) and three local inference backends
(Ollama, llama.cpp, ik\_llama.cpp), plus project-aware context, persona
instructions and a custom Solarized status line.

Everything is driven by one command — `claude-help` — which prints the
live quick-reference. If a detail here ever drifts from reality, trust
`claude-help` and open a PR against this section.

#### Layout

`claude/` is a stow package deployed to `~/.claude/`:

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global persona and project rules (loaded into every session) |
| `settings.json` | Permissions, model default, status-line binding, enabled plugins, marketplaces |
| `settings.local.json` | Machine-specific overrides — **gitignored** |
| `statusline-command.sh` | Custom status line (Python-backed JSON parser, Solarized palette) |
| `commands/` | Custom slash commands — `/semantic-commit`, `/capture-findings` (see [Slash commands](#slash-commands)) |
| `skills/` | Custom user-authored skills (class A) + `manifest.toml` for third-party loose skills (class C) — see [Skills](#skills--three-class-machinery-skills-apply) |

The shell wrappers live in a separate package: `bash/.bash/claude_code`
(≈820 LOC, sourced from `~/.bashrc`). Machine-specific knobs (GPU IDs,
binary paths, model defaults) go into `~/.bash/claude_code.local` —
loaded automatically at the end of `claude_code` if present.

#### Global configuration (CLAUDE.md, settings.json)

**`CLAUDE.md`** is the system-prompt overlay, loaded into every Claude
session. It encodes:

- **Persona** — analytic peer, not service assistant; unvarnished honesty;
  challenge premises; steel-man before dismantling; Socratic questioning
  on evaluative disagreements.
- **Repo layout rules** — `~/fortran/` for Fortran, `~/python/` for Python;
  verify paths before using them.
- **Build system rules** — FoBiS.py is primary; no make/cmake substitutions;
  dependency management via `FoBiS.py fetch`, not submodules.
- **Fortran conventions** — `.F90` uppercase, `implicit none` everywhere,
  `allocatable` over `pointer`, column-major loop ordering, kind
  specifications via `iso_fortran_env`, `iso_c_binding` for C interop,
  strict `implicit SAVE` trap guard, OpenMP `default(none)`.
- **GPU/OpenACC rules** — `parallel loop` with explicit `gang`/`vector`,
  `!$acc declare` discipline, atomic-ops red-flag, reproducibility
  caveats.
- **Python conventions** — Ruff patterns (B904 chained exceptions, B905
  `strict=` on zip, RUF002 no Unicode math symbols), PEP 604 union syntax,
  NumPy-style docstrings for scientific code, Makefile as standard dev
  interface, `.venv` always, `git-cliff` for changelogs.
- **Commit rules** — Conventional Commits; never `Co-authored-by` lines
  for AI; never auto-commit. Claude cannot sign: its shell has no TTY, so the
  pinentry prompt cannot be drawn — commits are written by hand.

**`settings.json`** configures the runtime:

| Key | Value | Purpose |
|---|---|---|
| `permissions.allow` | `Read/Write/Edit` on `~/fortran/**` and `~/python/**` | Frictionless tool use inside my project trees |
| `model` | `opus` | Default cloud model |
| `statusLine.command` | `bash /home/stefano/.claude/statusline-command.sh` | Custom status line |
| `enabledPlugins` | `frontend-design`, `skill-creator`, `cli-anything`, `document-skills` | Pre-enabled plugins |
| `extraKnownMarketplaces` | `anthropic-agent-skills`, `cli-anything` | Extra plugin sources |
| `alwaysThinkingEnabled` | `false` | Thinking is opt-in per request |
| `effortLevel` | `high` | Max reasoning effort by default |
| `skipDangerousModePermissionPrompt` | `true` | Skip the `--dangerously-skip-permissions` warning |
| `agentPushNotifEnabled` | `true` | Push notifications when background agents finish |

#### Status line

`statusline-command.sh` reads the Claude Code statusLine JSON from stdin,
parses it with a one-shot inline `python3` call, and renders a Solarized-dark
status line:

```
<model>·<GPUs>×GPU │ <cwd-basename> │ <branch>[<dirty>↑n↓m] │ ctx:N% │ 5h:N%(Xh) │ 7d:N%(Xd)
```

- **Model** — from the JSON `display_name`. On local backends, appended
  with `<N>×GPU` when `CLAUDE_LOCAL_GPUS` is exported.
- **Git** — branch, `+` staged, `!` unstaged, `?` untracked, `$` stashed,
  `↑N↓M` ahead/behind upstream.
- **Context %** — percentage of context window used. Colour-graded green
  → yellow → orange → red at 50/80/95%.
- **Rate limits** — 5-hour and 7-day usage percentages with countdown to
  reset. Same colour ladder.

Requires `python3` (used once per render) and works on any terminal with
256-colour support.

#### Slash commands

Custom slash commands are plain markdown files under `claude/.claude/commands/`,
deployed by stow as symlinks into `~/.claude/commands/`. Lifecycle is identical
to class-A custom skills — git tracks the source, stow deploys symlinks, no
installer or extra machinery.

| Command | Purpose |
|---|---|
| `/semantic-commit` | Analyze staged diff + recent commit style, emit a Conventional Commits-formatted message (no auto-commit, no `Co-authored-by` lines) |
| `/capture-findings` | Capture session findings into repo docs, repo `CLAUDE.md` / `.claude/`, and global `~/.claude/CLAUDE.md` — auto-detects branch, merge-base, and existing repo Claude config |

Each command is a markdown file with a YAML front-matter declaring its
`description` and the `allowed-tools` (whitelisted Bash invocations plus
file ops). The body is the prompt template; lines beginning with `` !` ``
are shell substitutions evaluated at invocation time (see
[Claude Code custom commands docs](https://docs.claude.com/en/docs/claude-code/slash-commands)).
See `commands/semantic-commit.md` for a minimal template and
`commands/capture-findings.md` for a richer one with git-aware substitutions.

**Add a new slash command:**

```bash
# 1. write the command (front-matter + prompt body)
vim ~/dotfiles/claude/.claude/commands/my-command.md

# 2. version it
cd ~/dotfiles && git add claude/.claude/commands/my-command.md

# 3. deploy (idempotent — stow only adds the new symlink)
bash dotify.sh claude
```

The new `/my-command` is immediately available in the next Claude Code
session on this host; other hosts pick it up on their next `git pull && bash dotify.sh claude`.

#### Skills — three-class machinery (skills-apply)

Skills in `~/.claude/skills/` fall into three structurally different classes
with three different lifecycle owners. The dotfiles wire all three into one
declarative, per-host workflow via `skills-apply` (`scripts/.scripts/skills-apply`,
≈340 LOC bash) plus a TOML manifest. The full design is in
[`claude/.claude/skills/README.md`](claude/.claude/skills/README.md); the
summary:

| Class | Examples | Lifecycle owner | Where declared |
|---|---|---|---|
| **A. Custom user-authored** | `fobis`, `research-lookup`, `markdown-mermaid-writing`, `markitdown`, `scientific-writing`, `generate-image` | git + stow | `claude/.claude/skills/<name>/` (real source dirs) |
| **B. Plugin / marketplace** | `frontend-design`, `skill-creator`, `cli-anything`, `document-skills` | `claude plugin` CLI | `settings.json` → `enabledPlugins` |
| **C. Third-party loose** | `perplexity-search` | upstream installers (pipx, venv, `curl \| bash`…) | `claude/.claude/skills/manifest.toml` |

Per-host filtering of class C: `machines/<hostname>.skills` (one skill name
per line, blanks and `#` comments allowed). A missing file means "install
every manifest entry on this host". Class A always stows everywhere
(source-only, cheap); class B is host-uniform via `settings.json`.

`skills-apply` interface:

```bash
skills-apply install         # install everything declared (idempotent)
skills-apply update          # update everything installed
skills-apply status          # show installed-vs-declared for all three classes
skills-apply remove <name>   # uninstall one skill (plugin or manifest)
```

Restart Claude Code after `install` or `update` so plugin changes load.

Adding a new skill:

- **Class A** — drop the directory under `claude/.claude/skills/<name>/`
  (at minimum a `SKILL.md`), `git add`, re-stow with `bash dotify.sh claude`.
- **Class B** — `claude plugin install <name>@<marketplace>`, then commit
  the resulting `settings.json` change. Future hosts pick it up via
  `skills-apply install`.
- **Class C** — add a `[skills.<name>]` block to `manifest.toml` with
  `check` / `install` / `update` / `uninstall` shell commands; add the
  name to each `machines/<host>.skills` file that should sync it.

The new dotfiles dependency this adds is just `claude` (the Claude Code
CLI binary) — already required as a Development extra. Python 3 (already
required) is reused for inline `tomllib` parsing of the manifest.

#### Claude CLI wrappers — overview

All wrappers in `bash/.bash/claude_code` call the real `claude` binary
with a curated set of env vars and CLI flags. None replace the binary —
they're small convenience functions.

Overall flow:

```
                         ┌────────────────────┐
                         │    claude-help     │ full quick-reference
                         └────────────────────┘
                                   │
     ┌─────────────────────────────┼─────────────────────────────┐
     │                             │                             │
  CLOUD                          LOCAL                       UTILITIES
  claude                     claude-local                 llm-local-server
  claude-sonnet              (ollama|llama|ikllama)       ollama-{pull,create,…}
  claude-opus                                             llama-{models,alias,info}
  claude-plan                  claude-nvidia              nvidia-models
  claude-openrouter            (proxy backend)
  claude-zai[-fast|-turbo|-premium]
```

`claude-local` auto-starts the requested backend and auto-stops any
*other* local backend currently running — only one of ollama/llama/ikllama
is live at a time. `llm-local-server` is the lower-level management verb.

`claude-nvidia` is the odd one out: it reaches a *cloud* catalog but is
built on the *local* machinery, because NVIDIA's hosted API needs a
translation proxy running on this host. See
[Cloud: NVIDIA](#cloud-nvidia-buildnvidiacom).

#### Cloud: Anthropic

Uses your standard Anthropic subscription (no extra key file).

| Command | What it does |
|---|---|
| `claude` | Subscription default (model from `settings.json` → `opus`) |
| `claude-sonnet` | Force Sonnet (`claude --model sonnet`) |
| `claude-opus` | Force Opus (`claude --model opus`) |
| `claude-plan` | Read-only plan mode (Opus) → auto-switches to Sonnet on execute (`--permission-mode plan --model opusplan`) |

#### Cloud: OpenRouter

Routes through [OpenRouter](https://openrouter.ai/), giving access to
100+ models including free tiers.

```bash
claude-openrouter                           # default model
claude-openrouter google/gemma-3-27b-it:free
claude-openrouter anthropic/claude-3.5-sonnet
```

- API key: `~/.openrouter-ai-key` (gitignored) or `OPENROUTER_API_KEY` env override
- Endpoint: `https://openrouter.ai/api` (the Anthropic SDK appends `/v1/messages`)
- Default model: `$OPENROUTER_DEFAULT_MODEL` (currently `qwen/qwen3.6-plus-preview:free`)

#### Cloud: Z.ai

Routes through [Z.ai](https://z.ai/)'s Anthropic-compatible endpoint for
the GLM model family.

| Command | Model |
|---|---|
| `claude-zai [model]` | default: `glm-5-turbo`, or any GLM model by ID |
| `claude-zai-fast` | `glm-4.5-air` |
| `claude-zai-turbo` | `glm-5-turbo` |
| `claude-zai-premium` | `glm-5.1` |

- API key: `~/.z-ai-key` (gitignored) or `ZAI_API_KEY` env override
- Endpoint: `https://api.z.ai/api/anthropic`

#### Cloud: NVIDIA (build.nvidia.com)

Routes through NVIDIA's hosted model catalog at
[build.nvidia.com](https://build.nvidia.com/).

> **Status: working, but not in practical use.** The harness is complete
> and verified end-to-end; the blocker is on NVIDIA's side. Read
> [Latency](#latency--why-this-backend-is-parked) before spending time here.

```bash
claude-nvidia                                     # default model
claude-nvidia deepseek-ai/deepseek-v4-flash-0731  # explicit model
claude-nvidia --no-autostop                       # leave the proxy running
nvidia-models                                     # list the served catalog
nvidia-models deepseek                            # filter it
```

- API key: `~/.nvidia-api-key` (gitignored) or `NVIDIA_API_KEY` env override
- Upstream: `https://integrate.api.nvidia.com`
- Default model: `$NVIDIA_DEFAULT_MODEL` (currently `deepseek-ai/deepseek-v4-flash-0731`)

**Why this one needs a proxy.** OpenRouter and Z.ai are two-env-var
wrappers because their endpoints are already Anthropic-compatible.
NVIDIA's *hosted* catalog is not — it serves only the OpenAI API, and
`/v1/messages` returns `404` there. Claude Code speaks the Anthropic
Messages API, so a local translation proxy
([`nvd-claude-nim`](https://pypi.org/project/nvd-claude-nim/)) sits in
between:

```
claude  ──Anthropic /v1/messages──▶  127.0.0.1:8787  ──OpenAI /v1/chat/completions──▶  integrate.api.nvidia.com
                                     (local proxy)
```

That proxy is a server with a lifecycle, so it is managed as a fourth
`llm-local-server` backend rather than as a bare wrapper. `claude-nvidia`
auto-starts it exactly as `claude-local` auto-starts ollama:

```bash
llm-local-server start  --backend nvidia
llm-local-server status --backend nvidia
llm-local-server stop   --backend nvidia
```

Two deliberate asymmetries with the local backends:

- **It does not evict other backends.** `claude-local` stops any other
  local engine to free VRAM. NVIDIA inference is remote and the proxy is
  a few MB of Python, so it coexists with a running ollama — stopping a
  local model to reach a cloud one would be pure loss.
- **`--gpus` is meaningless** and ignored: no inference happens on this
  machine.

The proxy installs itself on first use into a dedicated venv at
`~/.local/share/claude-nvidia-proxy` (the WSL2 system Python is
externally managed). No manual setup beyond the key:

```bash
printf '%s' 'nvapi-...' > ~/.nvidia-api-key && chmod 600 ~/.nvidia-api-key
```

> **Note.** NVIDIA's own
> [Claude Code documentation](https://docs.nvidia.com/nim/large-language-models/latest/ai-assistant-integrations/claude-code.html)
> describes *self-hosted* NIM containers, which do expose
> `/v1/messages` natively on port 8000 and need no proxy at all. That is
> a different product from the hosted catalog an API key buys, and its
> instructions do not apply here.

##### Latency — why this backend is parked

The pipeline is verified working. A plain round-trip returns correctly
translated Anthropic JSON:

```json
{"content": [{"type": "thinking", ...}, {"type": "text", "text": "ROUNDTRIP OK"}],
 "stop_reason": "end_turn",
 "usage": {"input_tokens": 13, "output_tokens": 25}}
```

What makes it unusable is latency variance on NVIDIA's side. Measured on
2026-09-15, same account, same model, requests minutes apart:

| Request | Result |
|---|---|
| `/v1/models` (catalog) | HTTP 200 in **0.19 s**, every time |
| Short completion, no tools | a few seconds — then, unchanged, **no response in 55 s** |
| Completion with `tools` | **no response in 190 s** |
| Short completion, retried later | HTTP 200, `nvcf-status: fulfilled` |

The catalog endpoint always answers instantly, so this is neither
network nor auth: it is queueing on NVIDIA's NVCF backend, where hosted
catalog models run on shared capacity. An interactive coding agent
issues many sequential requests, and a multi-minute stall on any one of
them makes the session unworkable.

**Therefore this backend is kept but not used.** For day-to-day work
prefer `claude-local` — no shared queue, predictable latency. The reason
to keep the NVIDIA path is access to models too large for 2×12 GB, for
one-off non-interactive questions where a long wait is acceptable.

**Not verified: tool calling.** Every tool-enabled request fell into the
latency window, so whether tool calls survive the Anthropic→OpenAI
translation is untested. Claude Code is unusable as an agent without it,
so assume nothing here until it is measured.

Other findings worth keeping:

- `deepseek-ai/deepseek-coder-6.7b-instruct` is listed in the catalog but
  returns `404 Not found for account` — listed does not mean enabled.
  Check a model id with `nvidia-models` *and* one real request before
  setting it as a default.
- The proxy's liveness probe is `/healthz`, **not** the `/health` that
  llama.cpp uses. It is held in `$NVIDIA_PROXY_HEALTH_PATH` so the
  convention lives in one place; probing the wrong path makes a perfectly
  healthy proxy look like a 60-second startup timeout.

#### Local: three backends (ollama, llama.cpp, ik\_llama.cpp)

`claude-local` is a single entry point over three local inference servers.
It auto-starts the requested backend, stops any other local backend
currently running, and routes `claude` at the right port.

| Backend | Port | Why |
|---|---|---|
| **ollama** | 11434 | Easy model management (`ollama pull`), stable default |
| **llama.cpp** | 8080 | Direct GGUF loading, latest architectures first, fine-grained GPU offload |
| **ik\_llama.cpp** | 8081 | [Fork of llama.cpp](https://github.com/ikawrakow/ik_llama.cpp) with aggressive CPU/hybrid kernels and new quant types (IQ4\_KS, IQ2\_KS); faster for MoE models that spill to system RAM |

Usage:

```bash
# default backend (from LOCAL_DEFAULT_BACKEND, default: ollama)
claude-local

# explicit backend
claude-local --backend llama
claude-local --backend ikllama

# override model
claude-local --model qwen2.5-coder:14b
claude-local --backend llama --model /path/to/model.gguf

# override context (llama/ikllama only; Ollama requires ollama-create)
claude-local --backend llama --ctx 128k

# GPU topology (Ollama only; HPC-safe single-GPU mode)
claude-local --gpus 1

# do not auto-start / auto-stop
claude-local --no-autostart             # server must already be running
claude-local --no-autostop              # keep server alive after exit

# pass-through args to the claude binary
claude-local -- --verbose some prompt
```

The `-- [CLAUDE_ARGS]` form separates wrapper flags from the real `claude`
invocation — anything after `--` goes straight to `claude`.

#### Local server management (llm-local-server)

`llm-local-server` is the lower-level control verb. `claude-local` calls
it implicitly, but use it directly when you want the server up or down
independent of Claude.

```bash
llm-local-server start                                  # start default backend
llm-local-server start --backend llama --ctx 128k       # start llama-server with custom ctx
llm-local-server stop                                   # stop default backend
llm-local-server stop --backend llama                   # stop specific backend
llm-local-server start --backend nvidia                 # start the NVIDIA translation proxy
llm-local-server restart [opts]                         # stop + start
llm-local-server status                                 # process + loaded model + GPU usage
```

`status` shows the PID, the bound port, and `nvidia-smi` GPU memory/utilization.
With no `--backend` it reports all four backends.

The backend must be given as `--backend <name>`, never positionally:
`llm-local-server start ollama` is rejected with an explicit error rather
than being silently forwarded to the server process.

#### Ollama utilities

```bash
ollama-pull [model]               # pull a model (wraps `ollama pull`)
ollama-create [--ctx N] [model]   # create a context-capped variant (context window in Ollama is per-model)
ollama-models                     # list models grouped by type (coder, chat, embedding…)
ollama-rename <old> <new>         # rename a model (preserves exact casing)
```

**`ollama-create --ctx N`** is the workaround for Ollama's static context.
It clones a model with a `PARAMETER num_ctx N` override so you can pin a
specific context length per session.

#### llama.cpp utilities

```bash
llama-models                      # list all GGUFs in $LLAMACPP_MODELS_DIR + HF cache
llama-alias <name> <path>         # create short-name alias (symlink) in models dir
llama-alias <name>                # remove alias
llama-info [model]                # dump GGUF metadata (arch, params, quant) + tensor summary
```

**Aliases** let you invoke heavy GGUF paths via a short name:

```bash
llama-alias qwen3-32b ~/models/Qwen3-32B-Instruct-Q4_K_M.gguf
claude-local --backend llama --model qwen3-32b
```

**`llama-info`** reads the GGUF header and prints architecture (llama/qwen/
mixtral/…), total parameters, quantization, tensor count, and context
window — useful when auditing a model before loading.

#### Machine-specific overrides

`~/.bash/claude_code.local` is loaded at the end of the main `claude_code`
file. Use it for anything that differs per machine:

```bash
# Example ~/.bash/claude_code.local
export LOCAL_DEFAULT_BACKEND="llama"
export LLAMACPP_BIN="/opt/llama.cpp/build/bin/llama-server"
export IKLLAMA_BIN="/opt/ik_llama.cpp/build/bin/llama-server"
export LLAMACPP_MODELS_DIR="$HOME/models"
export LLAMACPP_DEFAULT_MODEL="qwen3-coder-30b"
export LLAMACPP_CTX=262144
export LLAMACPP_GPU_LAYERS=-1
export CUDA_VISIBLE_DEVICES="0,1"
export NVIDIA_DEFAULT_MODEL="deepseek-ai/deepseek-v4-flash-0731"
```

Deploy it via its own machine-specific stow package (e.g.
`bash-adam/` listed in `machines/adam`) — see
[Machine-specific packages](#machine-specific-packages).

#### Environment reference

| Variable | Default | Purpose |
|---|---|---|
| `LOCAL_DEFAULT_BACKEND` | `ollama` | Backend used when `claude-local` runs without `--backend` |
| `OLLAMA_HOST` | `127.0.0.1:11434` | Ollama server bind |
| `OLLAMA_KEEP_ALIVE` | `10m` | Keep model in VRAM after last request |
| `OLLAMA_NUM_PARALLEL` | `1` | Concurrent request slots |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | Prevent VRAM thrashing |
| `OLLAMA_DEFAULT_MODEL` | `qwen2.5-coder:7b` | Default model for `claude-local --backend ollama` |
| `LLAMACPP_BIN` | `llama-server` | llama.cpp server binary |
| `LLAMACPP_HOST` / `LLAMACPP_PORT` | `127.0.0.1` / `8080` | Bind address |
| `LLAMACPP_MODELS_DIR` | `~/models` | Where `llama-models` / `llama-alias` operate |
| `LLAMACPP_DEFAULT_MODEL` | *(unset)* | Default GGUF path or alias |
| `LLAMACPP_GPU_LAYERS` | `-1` | GPU offload layers (`-1` = all) |
| `LLAMACPP_CTX` | `131072` | Default context window |
| `IKLLAMA_BIN` | `llama-server` | ik\_llama.cpp server binary |
| `IKLLAMA_HOST` / `IKLLAMA_PORT` | `127.0.0.1` / `8081` | Bind address (distinct from mainline) |
| `IKLLAMA_GPU_LAYERS` | `99` | GPU layers (ik\_llama.cpp treats `-1` as 0, so a large sentinel is used) |
| `IKLLAMA_CTX` | `131072` | Default context window |
| `IKLLAMA_DEFAULT_MODEL` / `IKLLAMA_MODELS_DIR` | fall back to `LLAMACPP_*` | Resolved lazily at call time |
| `NVIDIA_API_KEY` / `~/.nvidia-api-key` | *(required)* | NVIDIA auth (`nvapi-…`, from build.nvidia.com) |
| `NVIDIA_DEFAULT_MODEL` | `deepseek-ai/deepseek-v4-flash-0731` | Default model for `claude-nvidia` |
| `NVIDIA_PROXY_HOST` / `NVIDIA_PROXY_PORT` | `127.0.0.1` / `8787` | Local translation-proxy bind |
| `NVIDIA_PROXY_VENV` | `~/.local/share/claude-nvidia-proxy` | Venv holding `nvd-claude-nim` (auto-created) |
| `NVIDIA_PROXY_HEALTH_PATH` | `/healthz` | Proxy liveness probe (**not** `/health`, which llama.cpp uses) |
| `OPENROUTER_API_KEY` / `~/.openrouter-ai-key` | *(required)* | OpenRouter auth |
| `ZAI_API_KEY` / `~/.z-ai-key` | *(required)* | Z.ai auth |
| `CLAUDE_LOCAL_GPUS` | *(optional)* | Shown in status line (`<N>×GPU`) when set by `claude-local --gpus N` |

Run `claude-help` at any time for the live version of this reference.

---

### scripts

Everything lives flat in `scripts/.scripts/` (deployed to `~/.scripts/`), with
the sole exception of the Tecplot converters. The per-topic subdirectories this
table used to list disappeared in the migration to stow.

| Path | Purpose |
|---|---|
| `scripts/.scripts/bd` | Back-directory navigation — vendored, formerly a submodule |
| `scripts/.scripts/{convert,crop,scale,alpha,gray,overlap}_image` | Image processing utilities |
| `scripts/.scripts/{mountiso,mount_nas.sh}` | ISO and NAS mount helpers |
| `scripts/.scripts/{archive.sh,md-preview.sh,pps,rainix,rwd}` | Misc helpers (archive, preview, …) |
| `scripts/.scripts/borg-automated-backup.sh` | Borg backup automation |
| `scripts/.scripts/{pdf2grey,pdfA4scale,pdfcompress,image2pdf}` | PDF utilities |
| `scripts/.scripts/tecplot/` | Tecplot format converters |
| `scripts/.scripts/{git-health,git-health-boot}` | Git integrity scanning — rationale and recovery playbook in `scripts/.scripts/git-health.md` |
| `scripts/.scripts/{noctalia-retheme,noctalia-qt-dim-disabled,noctalia-foot-fix-bright0}` | Noctalia palette switching and patches — quark |
| `scripts/.scripts/quark-desktop-install` | Root-owned desktop bits — quark |
| `scripts/.config/systemd/user/` | systemd **user** units |
| `scripts/.bin/{act,hpc-login}` | Standalone binaries and HPC login helper |
| `scripts/.scripts/mbox-index.py` | Index Gmail Takeout MBOX into searchable SQLite ([details](#mbox-index--searchable-gmail-archive)) |
| `scripts/.scripts/skills-apply` | Declarative install/update/status for Claude Code skills across three classes ([details](#skills-apply--claude-code-skills-sync)) |

#### skills-apply — Claude Code skills sync

`skills-apply` is the per-host driver for the three-class skills machinery
introduced in [Skills](#skills--three-class-machinery-skills-apply). It
reads:

- `~/.claude/settings.json` → `enabledPlugins` (class B — plugin/marketplace)
- `~/.claude/skills/manifest.toml` → `[skills.*]` blocks (class C — third-party)
- `~/dotfiles/machines/<hostname>.skills` (optional per-host class-C filter)

…and delegates to the upstream installer for each class: `claude plugin
install/update/uninstall` for B, the manifest's own `install`/`update`/
`uninstall` shell strings for C. Class A (custom user-authored) is managed
entirely by stow — `skills-apply status` simply reports whether each
expected symlink resolves.

```bash
skills-apply install          # idempotent: skip already-installed entries
skills-apply update           # update every installed skill
skills-apply status           # group by class, mark drift, exit 0
skills-apply remove <name>    # uninstall (plugin or manifest); does NOT
                              # rewrite settings.json or manifest.toml —
                              # script warns you to do that yourself
```

Restart Claude Code after `install` or `update` so plugin changes load
(the `claude plugin update` CLI itself says "restart required to apply").

Dependencies: `claude` (Claude Code CLI), `python3` (for inline `tomllib`
JSON/TOML parsing of `settings.json` and `manifest.toml`).

#### mbox-index — searchable Gmail archive

Reclaim Google account quota by exporting Gmail to a local archive that stays searchable
after you delete the cloud copy. Indexes a [Google Takeout](https://takeout.google.com)
**MBOX** export into a **SQLite FTS5** database and extracts attachments to a
date/sender file tree. Stdlib-only — no dependencies.

```bash
# 0. Get the mbox: Takeout (Mail → MBOX) → download zip → unzip
unzip -o takeout-*.zip -d /mnt/d/gmail-backup        # yields Takeout/Mail/*.mbox

# 1. Build the searchable index + extract attachments
python3 ~/.scripts/mbox-index.py build /mnt/d/gmail-backup \
        --db /mnt/d/gmail-backup/mail.db --attach-dir /mnt/d/gmail-backup/attachments

# 2. Search (full-text + filters: from: to: subject: has:attachment larger:N before:/after:)
python3 ~/.scripts/mbox-index.py search "invoice AND from:acme larger:5M after:2020-01-01"
python3 ~/.scripts/mbox-index.py search "larger:25M"   # find quota hogs before deleting

# 3. Verify the archive, then delete from Gmail by size and empty Trash to reclaim quota
```

Full workflow — including the Takeout export, archive verification, and the cloud-deletion
steps — is in **[`scripts/.scripts/mbox-index.md`](scripts/.scripts/mbox-index.md)**.

---

---

### desktop — quark's sway + Noctalia session

Machine-specific (`machines/quark`); adam never stows it. quark runs **CachyOS** with
**sway** and the **Noctalia** desktop shell, which replaced waybar and supplies the bar,
launcher, notifications, OSDs and lock screen.

```
desktop/
├── .config/
│   ├── sway/config                     compositor: keybinds, input, borders
│   ├── foot/foot.ini                   terminal — includes the generated theme
│   ├── qt6ct/qt6ct.conf                Qt6: Fusion style + custom palette
│   ├── chrome-flags.conf               Chrome: native Wayland + GTK4
│   └── noctalia/patches/README.md      why the local patches exist
├── system/
│   └── udev/61-evdev-local.hwdb        touchpad fuzz (root-owned, not stowed)
└── .stow-local-ignore                  keeps system/ out of the stow tree
```

#### Theming

Noctalia renders the active palette into per-application config files ("templates"),
which is what keeps foot, alacritty, GTK3/4, Qt6, btop and sway borders on one palette.
The current scheme is **Solarized dark**.

Those generated files are **gitignored** — they are rebuilt on every palette change, and
a stow *directory* symlink would make Noctalia write into the repo. `desktop/` therefore
tracks individual files, never a directory whose siblings Noctalia generates.

Enabling the template set is a **GUI-only** step (settings → Templates: `gtk3, gtk4, qt,
foot, alacritty, btop, sway`); there is no supported `settings.toml` representation.

#### Switching palettes

```bash
noctalia-retheme --list                 # schemes + current
noctalia-retheme builtin Nord           # switch
noctalia-retheme community Solarized    # switch back
```

Builtins: Catppuccin, Dracula, Gruvbox, Kanagawa, Nord, Oxocarbon. Afterwards: open a new
terminal, restart GTK/Qt apps, `swaymsg reload`.

The wrapper exists because `color-scheme-set` alone leaves the daemon rendering the *old*
palette (it needs an explicit `config-reload`), and `templates-apply` returns before the
files are written. It also re-applies two patches Noctalia would otherwise clobber:
`noctalia-qt-dim-disabled` (Qt disabled widgets are emitted identical to enabled ones) and
`noctalia-foot-fix-bright0` (the lifted ANSI 8 repaints vim's editor background). Rationale
and measurements: `desktop/.config/noctalia/patches/README.md`.

#### First-time setup

```bash
bash ~/dotfiles/dotify.sh desktop   # symlinks the configs
~/.scripts/quark-desktop-install    # touchpad hwdb (root) + verification
```

Then enable the Noctalia templates in the GUI and run `noctalia-retheme`.

---

### desktop-astrobit — astrobit's niri session

astrobit runs CachyOS with **[niri](https://github.com/YaLTeR/niri)**, a scrollable
tiling Wayland compositor, installed from the `cachyos-niri-noctalia` preset. It is
a separate package from `desktop/` because almost nothing is shared with quark:
different compositor, and a foot config that does not read a generated theme.

| File | Deployed to | Purpose |
|---|---|---|
| `.config/niri/config.kdl` | `~/.config/niri/config.kdl` | Nothing but `include` lines |
| `.config/niri/cfg/*.kdl` | `~/.config/niri/cfg/` | animation, autostart, display, input, keybinds, layout, misc, rules |
| `.config/foot/foot.ini` | `~/.config/foot/foot.ini` | Terminal — Solarized inlined, not templated |

#### Why the config is split in two levels

niri's own config is a single `config.kdl`; the split into `cfg/*.kdl` with
`include` lines comes from the preset and is kept because it makes a single
concern (keybinds, window rules) editable without scrolling through the rest.
Both levels are tracked, and stow links them **file by file** — the directories
in `~/.config/` stay real. That is deliberate: if the Noctalia templates are
ever enabled here, the daemon will write `~/.config/niri/noctalia` next to the
symlinks instead of straight into this repository, which is the same rule
`desktop/` follows for quark.

Editing backups (`*.bak`) left in `~/.config/niri/cfg/` are untracked on purpose.

#### Remote desktop: Sunshine

astrobit is normally headless, reached through a web service; ssh covers most
failures. Sunshine is the third fallback, for when the fault is *in the GUI* —
a modal dialog blocking Ekos, a mount connection wizard. It therefore streams
the **live niri session**: a dedicated RDP session would open a clean desktop
next to the broken one, useless precisely when it is needed.

| File | Tracked | Why |
|---|---|---|
| `.config/sunshine/sunshine.conf` | yes | Hand-written; Sunshine does not rewrite it |
| `.config/sunshine/apps.json` | yes | The web UI *does* rewrite this — edits there show up as a diff |
| `sunshine_state.json`, `credentials/`, `*.log` | **no** | Web-UI password, TLS keypair, pairing state — per machine, never in git |

`capture` and `encoder` are deliberately **not** set: forcing `capture = wlgrab`
makes startup fail with *"Could not initialize display with the given hw device
type"*. Autodetect picks wlgrab (niri does expose `zwlr_screencopy_manager_v1`,
despite being smithay rather than wlroots) and VAAPI on its own.

Resolution, frame rate and bitrate are **client-side** settings: `fps`,
`resolutions` and `min_bitrate` are not Sunshine options and are silently
ignored. Set them in Moonlight on quark — 1920x1080, 30 fps, ~15 Mbps.

#### Root-owned parts: `astrobit-system-install`

`desktop-astrobit/system/` is outside the stow tree (excluded by
`.stow-local-ignore`). Run `sudo ~/.scripts/astrobit-system-install` after
stowing to install the WiFi power-save settings and the virtual EDID. Idempotent.

Two things it configures deserve their reasons recorded:

- **WiFi power save, on two levels.** The RTL8821CE's `rtw88` driver enables
  Deep Power Save by default, parking parts of the radio between beacons. On a
  link measured at -45 dBm with *zero* tx retries, that alone produced the
  Moonlight stutter and disconnections inherited from the Windows install.
  NetworkManager (`wifi.powersave = 2`) covers mac80211; Deep PS is reachable
  only as a module parameter, so it needs a reboot. quark needs the same fix
  with different knobs — Intel `iwlwifi`, where `power_save` is already off but
  `iwlmvm.power_scheme` defaults to 2 (balanced) and must be 1 (active).
- **Virtual EDID.** niri has no virtual outputs and no headless mode: unplug the
  monitor and it loses its only output. The blob advertises a permanent
  1920x1080 on HDMI-A-2 — lower than the real 3440x1440 ultrawide, because this
  is what gets streamed. It replaces the real EDID *always*, so the physical
  monitor also runs at 1080p.

#### Differences from quark's foot

- **Colours are inlined** (Solarized dark, `[colors-dark]`) rather than pulled in
  with `include=~/.config/foot/themes/noctalia`: no Noctalia template is enabled
  on this host, so there is no generated theme file to include.
- **`term=xterm-256color`** instead of the default `term=foot`, because the
  `foot` terminfo entry does not exist on the remote HPC hosts and an unknown
  `TERM` breaks curses applications over ssh.
- Plain `monospace` at size 12: no Nerd Font is installed here, and the prompt
  degrades gracefully without the powerline glyphs.

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
