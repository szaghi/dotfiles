# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for Stefano Zaghi — a Linux/WSL2 workstation setup focused on HPC (Fortran/C/MPI), scientific computing (Python), LaTeX, and vim-based development. The primary shell is bash; the editor is vim.

## Deployment

Dotfiles are deployed via **GNU Stow** through the `dotify.sh` wrapper:

```bash
# Install stow (once)
sudo apt install stow

# Deploy all packages
bash ~/dotfiles/dotify.sh

# Dry-run (preview changes without applying)
bash ~/dotfiles/dotify.sh --dry-run

# Uninstall (remove all symlinks)
bash ~/dotfiles/dotify.sh --uninstall

# Deploy a specific package only
bash ~/dotfiles/dotify.sh bash vim
```

Each top-level directory is a **stow package** whose internal layout mirrors `$HOME`. For example, `bash/.bashrc` is symlinked to `~/.bashrc`, and `bash/.bash/aliases` to `~/.bash/aliases`.

Machine-specific packages (e.g. `usr/` for desktop files) are listed in `machines/<hostname>` and auto-applied.

## Directory Structure

Each directory is a stow package — internal paths mirror `$HOME`:

- **`bash/`** — Shell config: `.bashrc`, `.bash_profile`, `.inputrc`, `.bash/{aliases,exports,functions,paths,optprogs,claude_code,compilers,prompt}`. The `bd` back-directory completion is vendored at `.bash/completions/bd`.
- **`claude/`** — Claude Code config in `.claude/`: `CLAUDE.md` (global instructions), `settings.json`, `settings.local.json`, `statusline-command.sh`, `commands/`. Secrets (`.credentials.json`, `.env`) are gitignored.
- **`vim/`** — Vim config: `.vimrc` + `.vim/` directory (per-filetype rc files, colors, plugconf, spell, syntax). Plugins managed via vim-plug in `.vim/plugged/` (gitignored).
- **`git/`** — `.gitconfig`, `.git-templates/` (commit message template + hooks).
- **`desks/`** — [desk](https://github.com/jamesob/desk) environment scripts in `.desk/desks/` for HPC toolchains (NVIDIA HPC SDK, Intel, AMD, GCC, OpenMPI variants).
- **`scripts/`** — Scripts in `.scripts/` (image utils, iso mount, borg backup, etc.) and `.bin/act`. The `bd` and `desk` scripts are vendored here.
- **`python/`** — `.pythonrc`, `.pylintrc`
- **`miscellanea/`** — `.latexmkrc`
- **`usr/`** — Desktop application entries in `.local/share/applications/` (machine-specific, see `machines/`)

## Commit Convention

Commits use **Conventional Commits** (enforced by the git commit template at `git/.git-templates/git_commit_message_template`):

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `build`, `ci`, `test`, `docs`, `refactor`, `perf`, `style`, `chore`, `revert`. GPG signing is enabled for commits and tags.

## Claude Code / Ollama Setup (`bash/.bash/claude_code`)

This file (sourced by `~/.bashrc`) configures dual-mode Claude Code operation:

- **`claude-local [model]`** — Run Claude via local Ollama (privacy-first, 2× GPU)
- **`claude-fast`** — Local mode with lighter model (`qwen3-coder`, single GPU)
- **`claude-cloud`** / `claude-sonnet` / `claude-opus` / `claude-plan` — Cloud Anthropic API
- **`ollama-start [gpu]`** / **`ollama-start-multi`** — Start Ollama on 1 or both GPUs
- **`ollama-status`** — Show running models + GPU memory
- **`claude-help`** — Print the full quick-reference

Default local model: `qwen3-coder-next` (~52GB Q4_K_M MoE, needs both GPUs). Fast fallback: `qwen3-coder` (~19GB, fits in 2×12GB VRAM).

## HPC Desk Environments

Environment toolchains are loaded with the `desk` command (from `scripts/desk/`):

```bash
desk go nvidia-24      # Load NVIDIA HPC SDK 24.11
desk go gcc-15.1.0     # Load GCC 15.1.0
desk go intel          # Load Intel compilers
```

Each desk script in `desks/.desk/desks/` sets `PATH`, `LD_LIBRARY_PATH`, `MANPATH`, and compiler-specific env vars. The NVIDIA desk also sets MPI launch flags tuned for UCX.

## Vim Key Conventions

- **Leader**: `,`
- **Plugins**: vim-plug (`~/.vim/plugged/`); update with `:PlugUpdate`
- **Color scheme**: Solarized dark
- **Tabs**: 3 spaces, expanded
- **Notable mappings**: `<C-Right>`/`<C-Left>` for buffer navigation, `qq` to close buffer (Bdelete), `<C-e>` for CtrlP, `<F2>` toggle wrap
- Trailing whitespace and multiple blank lines are auto-stripped on save for most filetypes
