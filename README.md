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

Plugins are managed with [vim-plug](https://github.com/junegunn/vim-plug).
The full plugin set lives in `vim/plugged/` (not tracked).

**Install / update plugins:**

```vim
:PlugInstall
:PlugUpdate
```

Selected plugins:

| Category | Plugins |
|---|---|
| Appearance | vim-colors-solarized, lightline + lightline-bufferline, numbers, rainbow-parentheses |
| Navigation | tagbar, vim-filebeagle, fzf.vim, any-jump |
| Editing | vim-commentary, trailertrash, vim-easy-align, tabular, lexima, vim-foldfocus |
| Languages | vimtex, markdown-preview.nvim, python-syntax |
| Git | vim-gitgutter |
| Utilities | vim-superman, vim-gnupg, HowMuch, plugconf, vim-bbye |

Per-filetype config is split into dedicated files: `fortranrc.vim`, `pythonrc.vim`,
`latexrc.vim`, `markdownrc.vim`, `fobosrc.vim`.

**Key mappings (leader = `,`):**

| Key | Action |
|---|---|
| `<C-Right>` / `<C-Left>` | Next / previous buffer |
| `qq` | Close buffer (Bdelete) |
| `<F2>` | Toggle line wrap |
| `<C-C>` | Toggle virtualedit |

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

**Dual-mode Claude Code** (`bash/claude_code`):

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

# Ollama management
ollama-start-multi            # start on all GPUs (large models)
ollama-plan-setup             # register plan-architect / plan-executor aliases (run once)
ollama-status                 # GPU + loaded model status
claude-help                   # full quick-reference
```

`ollama-plan-setup` must be run once after each fresh Ollama start to register the
`plan-architect` and `plan-executor` short-name aliases. Re-run it if `OLLAMA_PLAN_MODEL`
or `OLLAMA_EXEC_MODEL` are changed.

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
