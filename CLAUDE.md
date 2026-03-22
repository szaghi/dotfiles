# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for Stefano Zaghi — a Linux/WSL2 workstation setup focused on HPC (Fortran/C/MPI), scientific computing (Python), LaTeX, and vim-based development. The primary shell is bash; the editor is vim.

## Deployment

Dotfiles are deployed via `dotify.sh` (custom symlink script, not dotbot despite the README):

```bash
bash ~/dotfiles/dotify.sh
```

This creates symlinks from `~/dotfiles/<dir>/file` → `~/<target>`. Key mappings:
- `bash/*` → `~/.bash/*` and `~/.bashrc`, `~/.inputrc`
- `vim/` → `~/.vim/` and `~/.vimrc`
- `git/gitconfig` → `~/.gitconfig`
- `desks/*.sh` → `~/.desk/desks/*.sh`
- `python/*` → `~/.pythonrc`, `~/.pylintrc`
- `miscellanea/latexmkrc` → `~/.latexmkrc`

## Directory Structure

- **`bash/`** — Shell config: `bashrc`, `aliases`, `exports`, `functions`, `paths`, `optprogs`, `inputrc`, `claude_code`, `prompt`, `compilers`
- **`vim/`** — Vim config: `vimrc` + per-filetype rc files (`fortranrc.vim`, `pythonrc.vim`, `latexrc.vim`, `markdownrc.vim`, `fobosrc.vim`); plugins managed via vim-plug in `plugged/`
- **`git/`** — `gitconfig`, commit message template (Conventional Commits), `gibo` (gitignore generator), `git-hub` CLI
- **`desks/`** — [desk](https://github.com/jamesob/desk) environment scripts for HPC toolchains (nvidia HPC SDK, Intel, AMD, GCC, OpenMPI variants); activated via `desk` command
- **`scripts/`** — Bundled third-party scripts: `bd` (back-directory), `gws` (git workspace), `desk`, `borg-automated-backup`, image utilities, etc.
- **`python/`** — `pythonrc`, `pylintrc`, `gdb-dashboard`, `git-remote-dropbox`, `markdown-toclify`, `scholar`
- **`bin/`** — `act` (GitHub Actions local runner)
- **`miscellanea/`** — `latexmkrc`, `mount-zaghi-nas.sh`

## Commit Convention

Commits use **Conventional Commits** (enforced by the git commit template at `git/git_commit_message_template`):

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `build`, `ci`, `test`, `docs`, `refactor`, `perf`, `style`, `chore`, `revert`. GPG signing is enabled for commits and tags.

## Claude Code / Ollama Setup (`bash/claude_code`)

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

Each desk script in `desks/` sets `PATH`, `LD_LIBRARY_PATH`, `MANPATH`, and compiler-specific env vars. The NVIDIA desk also sets MPI launch flags tuned for UCX.

## Vim Key Conventions

- **Leader**: `,`
- **Plugins**: vim-plug (`~/.vim/plugged/`); update with `:PlugUpdate`
- **Color scheme**: Solarized dark
- **Tabs**: 3 spaces, expanded
- **Notable mappings**: `<C-Right>`/`<C-Left>` for buffer navigation, `qq` to close buffer (Bdelete), `<C-e>` for CtrlP, `<F2>` toggle wrap
- Trailing whitespace and multiple blank lines are auto-stripped on save for most filetypes
