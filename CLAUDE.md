# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for Stefano Zaghi — a Linux/WSL2 workstation setup focused on HPC (Fortran/C/MPI), scientific computing (Python), LaTeX, and vim-based development. The primary shell is bash; the editor is vim.

Two machines:

- **adam** — WSL2 workstation, no desktop session.
- **quark** — Chuwi Minibook X N150 running **CachyOS** with a **sway + Noctalia**
  Wayland desktop. Its desktop configuration lives in the `desktop` package
  (machine-specific, see `machines/quark`).

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
- **`scripts/`** — Scripts in `.scripts/` (image utils, iso mount, borg backup, `git-health`, etc.) and `.bin/act`. The `bd` script is vendored here. Also ships systemd **user** units in `.config/systemd/user/`.
- **`python/`** — `.pythonrc`, `.pylintrc`
- **`miscellanea/`** — `.latexmkrc`
- **`usr/`** — Desktop application entries in `.local/share/applications/` (machine-specific, see `machines/`)
- **`desktop/`** — quark's Wayland desktop (sway + Noctalia + foot + Qt), machine-specific via `machines/quark`. Holds only *authored* config; Noctalia's generated theme files are gitignored on purpose (see below). `desktop/system/` is **not** a stow path — it carries root-owned files installed by `~/.scripts/quark-desktop-install`.

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

## Claude Code Skills (`claude/.claude/skills/`, `~/.scripts/skills-apply`)

Skills in `~/.claude/skills/` are managed declaratively across machines via
three lanes — three structurally different lifecycle owners, one driver
script. Full design in `claude/.claude/skills/README.md`.

### The three classes

| Class | Owner | Declared in | Examples |
|---|---|---|---|
| **A. Custom user-authored** | git + stow | `claude/.claude/skills/<name>/` (real source dirs) | `fobis`, `research-lookup`, `markdown-mermaid-writing`, `markitdown`, `scientific-writing`, `generate-image`, `remotion-infographics` |
| **B. Plugin / marketplace** | `claude plugin` CLI | `settings.json` → `enabledPlugins` | `frontend-design`, `skill-creator`, `cli-anything`, `document-skills` |
| **C. Third-party loose** | upstream installers | `claude/.claude/skills/manifest.toml` | `perplexity-search` (`.venv` + `litellm`) |

Per-host filtering of class C: `machines/<hostname>.skills` (one skill name
per line; blanks and `#` comments allowed). Missing file = install every
manifest entry. Class A stows everywhere (cheap source-only); class B is
host-uniform via `settings.json`.

### `skills-apply` interface

```bash
skills-apply install          # install everything declared (idempotent)
skills-apply update           # update every installed skill
skills-apply status           # show installed-vs-declared for all three classes
skills-apply remove <name>    # uninstall one skill (plugin or manifest)
```

Restart Claude Code after `install` or `update` so plugin changes load.

### Adding a new skill

- **Class A** (custom): drop `claude/.claude/skills/<name>/` with at least a
  `SKILL.md`, `git add`, `bash dotify.sh claude`. New symlink at
  `~/.claude/skills/<name>/` is immediate.
- **Class B** (plugin): `claude plugin install <name>@<marketplace>`, confirm
  `settings.json` `enabledPlugins` was updated, commit. Other hosts pick it
  up via `skills-apply install`.
- **Class C** (loose): add `[skills.<name>]` block to `manifest.toml` with
  `check` / `install` / `update` / `uninstall` shell commands. Add the name
  to each `machines/<host>.skills` that should sync it. The dotfiles own
  the *recipe*; the upstream installer owns the *work* — do NOT vendor
  install logic, wrap it.

### Things to know when editing

- `~/.claude/skills/` should only ever contain symlinks once the machinery
  is in place. A real directory there is a drift signal — either it is a
  not-yet-migrated class-A skill or a stale copy that should be removed.
- `~/.claude/settings.json` is a stow symlink; Claude Code writes back to
  it when plugins are enabled/disabled, so commit settings.json drift
  before re-stowing or you will lose the live state. The dotfile is the
  source of truth — pull changes into the dotfile, never the other way.
- `skills-apply remove` does NOT rewrite `settings.json` or `manifest.toml`
  — it just runs the uninstall command and prints a warning that you must
  edit the declaration file by hand to make the removal persistent.
- The script uses `python3 -m tomllib` (Python 3.11+) for manifest parsing;
  the `claude` CLI is the only other hard dependency.

## Claude Code Custom Slash Commands (`claude/.claude/commands/`)

Custom slash commands are plain markdown files under
`claude/.claude/commands/`, deployed by stow as symlinks into
`~/.claude/commands/`. Lifecycle is identical to class-A custom skills —
no installer, no machinery, just git + stow.

| Command | Purpose |
|---|---|
| `/semantic-commit` | Generate Conventional Commits-formatted message from staged diff (no auto-commit, no `Co-authored-by`) |
| `/capture-findings` | Capture session findings into repo docs / repo `.claude/` / global `~/.claude/CLAUDE.md` |

Each file is YAML front-matter (`description`, `allowed-tools`) plus a
prompt body. Lines starting with `` !` `` are shell substitutions evaluated
at invocation time.

### Adding a new slash command

```bash
vim ~/dotfiles/claude/.claude/commands/<name>.md
cd ~/dotfiles && git add claude/.claude/commands/<name>.md
bash dotify.sh claude
```

`/<name>` is then available on this host immediately and on other hosts on
their next `git pull && bash dotify.sh claude`.

## Git Integrity Scanning (`~/.scripts/git-health`)

Report-only detector for repositories damaged by an unclean WSL2/host shutdown.
An abrupt reset can lose unflushed writeback while leaving metadata intact, so
git sees zero-length object files it believes are present and dies on every
read and write that touches them (`fatal: bad object HEAD`). Full rationale,
recovery playbook and design notes: `scripts/.scripts/git-health.md`.

| File | Deployed to | Role |
|---|---|---|
| `scripts/.scripts/git-health` | `~/.scripts/git-health` | The scanner. Report-only, usable by hand. |
| `scripts/.scripts/git-health-boot` | `~/.scripts/git-health-boot` | Dirty-boot gate — runs the scanner only after an unclean shutdown |
| `scripts/.config/systemd/user/git-health-boot.service` | `~/.config/systemd/user/` | systemd **user** unit; arms a marker at start, disarms at clean stop |

```bash
git-health                 # every repo under $HOME (slow)
git-health -d 7            # only repos touched in the last 7 days (fast)
git-health -r ~/fortran    # limit to one tree
git-health --deep          # additionally run `git fsck`
```

Exit status: `0` all healthy, `1` at least one suspect, `2` usage error.

Enable the automatic post-crash check once per host:

```bash
systemctl --user daemon-reload
systemctl --user enable --now git-health-boot.service
journalctl --user -u git-health-boot -b     # read the results
```

### Things to know when editing

- **It never repairs, and must stay that way.** Repair needs judgement: during
  the 2026-07-31 incident that motivated this, 4 of 13 "orphaned" empty objects
  were blobs staged but not committed — the working-tree files were the only
  surviving copies. An unattended fixer would have destroyed real work.
- The unit enforces this structurally, not by good intentions: `ProtectHome=read-only`
  means the scan *cannot* modify a repository. Do not relax it.
- `SuccessExitStatus=0 1` is load-bearing — exit 1 means "suspect repos found",
  a report rather than a unit malfunction.
- The marker must live in `$XDG_RUNTIME_DIR`, not plain `/run`: a *user* unit
  writing to root-owned `/run` gets EACCES, the marker never appears, and every
  boot then looks clean while no crash is ever detected.
- Both scripts `trap '' PIPE` — a downstream `| head` would otherwise turn the
  0/1 healthy/suspect status into a SIGPIPE 141 that systemd misreports.

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

## quark Desktop (`desktop/`, sway + Noctalia)

quark runs CachyOS with sway and the **Noctalia** desktop shell (bar, launcher,
notifications, lock screen — it replaced waybar). Noctalia renders a colour palette
into config files for other applications through a *template* system, which is what
keeps the terminal, GTK, Qt, btop and sway borders on one coherent theme.

### Authored vs generated — the rule that matters

Only *authored* files are tracked. Every path below is regenerated by Noctalia on
each `templates-apply` and is **gitignored**:

```
~/.config/sway/noctalia              ~/.config/gtk-3.0/noctalia.css
~/.config/foot/themes/noctalia       ~/.config/gtk-4.0/noctalia.css
~/.config/alacritty/themes/*.toml    ~/.config/qt6ct/colors/noctalia.conf
~/.config/btop/themes/*.theme        ~/.config/starship.toml
```

Tracking them would put palette churn in git, and — worse — a stow *directory*
symlink would make Noctalia write its output straight into the repo. This is why
`desktop/` deliberately contains individual files (`.config/sway/config`) rather
than whole directories: stow then links file-by-file and the generated siblings
stay outside the repo as real files. **Do not add a directory to `desktop/` whose
sibling files Noctalia writes.**

### Enabling templates is a GUI-only step

The enabled-template set has no supported `settings.toml` representation — a
hand-written `[templates]` section is rejected by `noctalia config validate`. It
must be enabled once, by hand, in Noctalia's settings → Templates:
`gtk3, gtk4, qt, foot, alacritty, btop, sway`.

### Switching palettes: `noctalia-retheme`

    noctalia-retheme --list                 available schemes + current
    noctalia-retheme builtin Nord           switch
    noctalia-retheme community Solarized    switch back
    noctalia-retheme                        re-apply current + patches

It wraps two daemon quirks that otherwise leave a half-themed desktop:

1. **`color-scheme-set` does not reload the daemon.** It persists the choice and
   `color-scheme-get` immediately reports the new scheme, but templates keep
   rendering from the *previously loaded* palette. The wrapper issues
   `noctalia msg config-reload` after switching.
2. **`templates-apply` returns `ok` before writing.** Rendering is asynchronous and
   `~/.config/sway/noctalia` is consistently written last. The wrapper waits for the
   generated files' checksums to settle — content hashing, not mtime, because
   Noctalia skips rewriting a file whose content would be unchanged.

It then re-applies two local patches that Noctalia would otherwise clobber:

- **`noctalia-qt-dim-disabled`** — Noctalia emits qt6ct's `disabled_colors`
  byte-identical to `active_colors`, so disabled widgets look enabled. Blends the
  foreground roles toward the background, leaving background roles untouched.
- **`noctalia-foot-fix-bright0`** — every Noctalia palette lifts ANSI 8
  (bright black) above the background so dim text stays legible. Solarized's *vim*
  colorscheme maps `base03` → ANSI 8 and paints `Normal` with it, so the lift
  repaints vim's whole editor area in washed-out slate. Applied **only** when
  `~/.vimrc` uses a `solarized*` colorscheme; revisit that condition if the vim
  colorscheme changes.

Full rationale, contrast measurements and revert paths:
`desktop/.config/noctalia/patches/README.md`.

### Root-owned parts: `quark-desktop-install`

`desktop/system/` is outside the stow tree (excluded by `desktop/.stow-local-ignore`).
Run `~/.scripts/quark-desktop-install` after stowing to install the touchpad hwdb
entry and verify the fuzz landed. Idempotent.

The hwdb sets `fuzz=8` on the multitouch axes (35/36) that upstream leaves at 0 —
without it the pointer drifts under a resting finger. libinput reads fuzz **only at
device init**, so `swaymsg reload` does not apply it; the script runs
`udevadm trigger`, otherwise a relogin is needed.

### Not themeable

**Google Chrome.** No Noctalia template exists or can exist — Firefox works only via
Pywalfox's extension + native host, and Chrome's UI is not styleable by external
config. `desktop/.config/chrome-flags.conf` gets it as far as native Wayland (sharper
at the 1.5x scale) plus GTK4 integration, so it follows `adw-gtk3-dark`. Its tab strip
will not be Solarized.

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
