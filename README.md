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

- [Bootstrap](#bootstrap)
- [Directory structure](#directory-structure)
  - [bash](#bash)
  - [vim](#vim)
  - [git](#git)
  - [desks — HPC environments](#desks--hpc-environments)
  - [claude](#claude)
  - [scripts](#scripts)
- [Copyrights](#copyrights)

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

Only two third-party tools are tracked as git submodules:

| Submodule | Purpose |
|---|---|
| `scripts/desk` | Lightweight environment switcher for HPC toolchains |
| `scripts/bd` | `bd` — back-directory navigation |

Initialize them after cloning:

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
├── desks/         HPC desk environment scripts
├── git/           git configuration and commit template
├── miscellanea/   single-file configs (latexmkrc, NAS mount script)
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

### desks — HPC environments

[desk](https://github.com/jamesob/desk) is used to switch between compiler toolchains.
Each script in `desks/` loads a full environment (compilers, MPI, paths).

```bash
desk go nvidia-26          # NVIDIA HPC SDK 26
desk go gcc-15.1.0         # GCC 15.1.0
desk go intel              # Intel oneAPI compilers
desk go amd-5.1.0          # AMD AOCC
desk go openmpi-5.0.7-gnu-14.2.0
```

Available desks: `nvidia-24`, `nvidia-25`, `nvidia-26`, `gcc-15.1.0`, `intel`,
`amd-5.1.0`, and several OpenMPI variants.

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
# Local — Ollama, privacy-first (requires 2× NVIDIA GPU)
claude-local                  # qwen3.5:latest (default)
claude-local-fast             # qwen3-coder (fits in VRAM, 1 GPU)
claude-local-plan             # architect model, switch to executor mid-session
claude-local-exec             # jump straight to executor model

# Cloud — Anthropic API
claude                        # subscription default
claude-sonnet                 # force Sonnet
claude-opus                   # force Opus
claude-plan                   # Opus plan + Sonnet execute

# Ollama management
ollama-start-multi            # start on all GPUs (large models)
ollama-status                 # GPU + loaded model status
claude-help                   # full quick-reference
```

---

### scripts

| Path | Purpose |
|---|---|
| `scripts/desk/` | desk submodule |
| `scripts/bd/` | bd back-directory submodule |
| `scripts/images/` | Image processing utilities (convert, crop, scale, alpha…) |
| `scripts/iso/` | ISO mount/umount helpers |
| `scripts/miscellanea/` | Misc scripts (archive, PDF preview, NAS mount…) |
| `scripts/borg-automated-backup/` | Borg backup automation |
| `scripts/pdf/` | PDF utilities |

---

## Copyrights

My dotfiles come from many years of GNU/Linux usage and inspiration from countless
people sharing their configs on the web. Distributed under the terms of the
[WTFPL — Do What the Fuck You Want to Public License](http://www.wtfpl.net/),
without any warranty.

Go to [Top](#top)
