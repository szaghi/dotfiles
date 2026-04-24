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
- **`modules/`** — Lmod modulefiles in `.modules/` for HPC toolchains (NVIDIA HPC SDK, Intel, AMD, GCC, OpenMPI variants). Load with `module load gcc/15.1.0`.
- **`scripts/`** — Scripts in `.scripts/` (image utils, iso mount, borg backup, etc.) and `.bin/act`. The `bd` script is vendored here.
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

This file (sourced by `~/.bashrc`) configures Claude Code over three local backends plus cloud:

- **`claude-local`** — default backend (Ollama). Override with `--backend llama` or `--backend ikllama`.
- **`claude-local --backend llama`** — mainline llama.cpp server (port 8080).
- **`claude-local --backend ikllama`** — ik_llama.cpp fork (port 8081); aggressive CPU/hybrid optimizations and newer quant types (IQ4_KS, IQ2_KS), faster on MoE models that spill to RAM.
- **`claude-sonnet`** / **`claude-opus`** / **`claude-plan`** — Cloud Anthropic API
- **`claude-openrouter`** / **`claude-zai`** — Other cloud providers (OpenRouter, Z.ai)
- **`llm-local-server start|stop|restart|status --backend <name>`** — manage a specific server
- **`claude-help`** — print the full quick-reference

`claude-local` auto-starts the requested backend and stops any other local backend that's running, so only one of ollama/llama/ikllama is live at a time. Shared state lives in `~/.bash/claude_code`; machine-specific overrides (GPU IDs, binary paths, model defaults) in `~/.bash/claude_code.local`.

## HPC Lmod Environments

Environment toolchains are managed via Lmod (install: `sudo apt install lmod`).
Modulefiles live in `modules/.modules/` (deployed to `~/.modules/` via stow).
Lmod is initialised in `bash/.bash/exports` with `MODULEPATH=$HOME/.modules`.

```bash
module avail                         # list all modules
module load gcc/15.1.0               # load GCC 15.1.0
module load nvhpc/24.11              # load NVIDIA HPC SDK 24.11
module load openmpi/5.0.7-gnu14.2.0  # load OpenMPI
module list                          # show loaded modules
module purge                         # unload everything
```

The bash prompt reflects loaded modules: `env {gcc/15.1.0 openmpi/5.0.7-gnu14.2.0}`.

### Adding a new modulefile

Create `modules/.modules/<name>/<version>.lua`. The file is immediately visible to
Lmod (no re-stow needed — the directory is already a symlink into the repo).
Conventions to follow:

- Always guard the install path with `isDir(root)` / `LmodError(...)`.
- Use `family("compiler")` for compiler modules so only one is active at a time.
- Set `CC` / `CXX` / `FC` / `F77` / `F90` env vars for compiler modules.
- For NVHPC modules on WSL2: prepend `/usr/lib/wsl/lib` to `LD_LIBRARY_PATH`
  and set `UCX_MEMTYPE_CACHE=n`.
- Use `pathJoin(root, "subdir")` (not string concatenation) for portable paths.

Minimal compiler template:

```lua
whatis("Toolchain name and version")
help([[Longer description — install path, what is included, WSL2 notes.]])

local root = "/path/to/install"
family("compiler")

if not isDir(root) then
  LmodError(root .. " not found")
end

prepend_path("PATH",            pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH",         pathJoin(root, "share/man"))

setenv("CC",  "gcc")
setenv("CXX", "g++")
setenv("FC",  "gfortran")
setenv("F77", "gfortran")
setenv("F90", "gfortran")
```

Verify with `module avail` and `module load <name>/<version>`.

## Adding New Dotfiles

### File in an existing package

Place the file at the mirrored path inside the package directory, then re-stow:

```bash
# Example: new bash helper
cp my-helper ~/dotfiles/bash/.bash/my-helper
bash ~/dotfiles/dotify.sh bash     # idempotent, safe to re-run
```

### New stow package

1. Mirror the `$HOME` layout inside a new top-level directory:

   ```bash
   mkdir -p ~/dotfiles/foo/.config/foo
   cp ~/.config/foo/config ~/dotfiles/foo/.config/foo/config
   ```

2. Add the package name to `PACKAGES` in `dotify.sh`.

3. Deploy and commit:

   ```bash
   bash ~/dotfiles/dotify.sh foo
   git add dotify.sh foo/
   git commit
   ```

### Machine-specific package

Add the package name to `machines/<hostname>` (one name per line).
`dotify.sh` reads this file automatically after the common packages.

## Vim Key Conventions

- **Leader**: `,`
- **Plugins**: vim-plug (`~/.vim/plugged/`); update with `:PlugUpdate`
- **Color scheme**: Solarized dark
- **Tabs**: 3 spaces, expanded (4 for Python, per ftplugin)
- **Navigation**: `<C-Right>`/`<C-Left>` next/prev buffer · `qq` close buffer (Bdelete) · `<F2>` toggle wrap · `<leader><leader>{s,w,j,k,h,l}` easymotion jumps
- **Finders (fzf.vim)**: `<leader>f` files · `<leader>b` buffers · `<leader>r` ripgrep · `<leader>t` tags · `<leader>h` history · `<leader>/` lines
- **LSP (yegappan/lsp)**: `gd` goto-def · `gr` refs · `K` hover · `<leader>rn` rename · `<leader>la` code-action · `<leader>lf` format · `[d`/`]d` prev/next diagnostic · `<Tab>` completion
- **Git (fugitive)**: `<leader>gs` status · `<leader>gb` blame · `<leader>gd` diff · `<leader>gl` log · `<leader>gc` commit · `<leader>gp` push
- **LSP servers**: `fortls` (Fortran), `basedpyright` (Python), `texlab` (LaTeX), `bash-language-server` (bash). Install via `~/.scripts/install-vim-lsp.sh`.
- **ALE** handles linting (ruff, gfortran, shellcheck) and formats Python on save via `ruff_format`. LSP diagnostics are separate (`let g:ale_disable_lsp = 1`).
- Trailing whitespace and multiple blank lines are auto-stripped on save for most filetypes
