---
title: bash
---

# bash

The `bash/` package is the shell configuration shared by every host. `~/.bashrc` is a short loader: the real content
sits in small files under `~/.bash/`, one concern per file, so a host can override one part without forking the rest.

## Install

```bash
bash ~/dotfiles/dotify.sh bash
```

This links `~/.bashrc`, `~/.bash_profile`, `~/.inputrc`, `~/.dircolors.256dark` and every file of `bash/.bash/` into
`~/.bash/`. Per-host additions come from the `bash-<host>` packages, see [Per-host packages](/packages/host-specific).

## Files

| File | What it does |
|---|---|
| `bash/.bashrc` | Loader: returns early for non-interactive shells, sources `~/.bash/*`, sets history and `shopt` options, completions, pnpm, nvm, conda |
| `bash/.bash_profile` | Sources `~/.bashrc`, so login shells get the same setup |
| `bash/.inputrc` | Readline: case-insensitive completion, key bindings |
| `bash/.dircolors.256dark` | Solarized colours for `ls`, read by `exports` |
| `bash/.bash/private` | Per-host secrets, not tracked (see below) |
| `bash/.bash/aliases` | Aliases, plus the `vman` function |
| `bash/.bash/compilers` | MPI/compiler environment; today only `OMPI_MCA_btl_base_warn_component_unused=0`, the rest is commented out |
| `bash/.bash/claude_code` | Claude Code wrappers and local LLM servers |
| `bash/.bash/exports` | Environment: editor, history, locale, colours, Lmod, `GPG_TTY` |
| `bash/.bash/functions` | Shell functions, including `pathmunge` |
| `bash/.bash/optprogs` | `PATH` entries for optional programs under `/opt` and Linuxbrew |
| `bash/.bash/paths` | `PATH` entries for `~/.bin`, `~/.local/bin`, `~/.scripts`; `CDPATH` |
| `bash/.bash/prompt` | The prompt |
| `bash/.bash/welcome` | Banner printed when a terminal opens |
| `bash/.bash/bh-ascii.txt` | The banner's ANSI art, printed by `welcome` |
| `bash/.bash/completions/bd` | Tab completion for `bd` |
| `bash/.bash/claude_code_cluster` | Minimal Claude Code + Ollama setup for HPC cluster nodes; not loaded by `.bashrc` |

## Load order

`.bashrc` sources these files, in this order, skipping any that is missing or unreadable:

```text
private  aliases  compilers  claude_code  exports  functions  optprogs  paths  prompt  welcome
```

`claude_code` sources `~/.bash/claude_code.local` at its end; that file comes from the host's `bash-<host>` package.
`compilers`, `optprogs` and `paths` each source `functions` themselves, because they call `pathmunge` before
`.bashrc` reaches `functions`.

After the loop `.bashrc` sets the history options (`histappend`, `ignoredups`), `checkwinsize`, `nocaseglob`,
`cdspell`, `autocd`, `globstar`, `lesspipe` (Debian `lesspipe` or Arch `lesspipe.sh`), `/etc/bash_completion`,
ssh host completion from `~/.ssh/config`, the `bd` completion, pnpm, nvm, the mosaic/FoBiS/MaTiSSe completions and,
where `~/miniforge3` exists, conda.

::: warning Remote commands get no dotfiles
The first line of `.bashrc` is `[ -z "$PS1" ] && return`. A non-interactive shell, such as `ssh host cmd` or
`bash -lc cmd`, stops there: it never runs `paths`, so `~/.scripts`, `~/.bin` and `~/.local/bin` are not on its
`PATH`, and no alias or function exists. Call remote tools by absolute path. Do not loosen the guard to work around
it; `claude-remote` prepends the directories itself, see [scripts](/packages/scripts).
:::

## The private file

`bash/.bash/private` holds what must not be public: API keys, private aliases, host-specific credentials. It is
listed in `.gitignore`, so it lives only on the machine that wrote it. `.bashrc` sources it first, so everything after
it can use its variables. A fresh clone has no `private`; the shell works without it.

```bash
vim ~/dotfiles/bash/.bash/private     # create it on the new host
chmod 600 ~/dotfiles/bash/.bash/private
```

## Prompt

`bash/.bash/prompt` builds a three-line prompt and sets the terminal title to the working directory:

```text
┌╼ user@host(time date) on branch [+!?$ ↑1 ↓2] env {gcc/16.2.0 openmpi/5.0.11-gnu16.2.0} pvenv {venv}
├───╼ ~/current/dir 12 files, 48Kb
└──────╼
```

| Segment | Shown when | Meaning |
|---|---|---|
| `user` | always | orange, red for `root` |
| `host` | always | yellow, red when `SSH_TTY` is set |
| `on <branch>` | inside a git work tree | branch, or short SHA on a detached HEAD |
| `+` `!` `?` `$` | inside a git work tree | staged changes, unstaged changes, untracked files, a stash exists |
| `↑n` `↓n` | branch has an upstream | commits ahead of / behind the upstream |
| `env {...}` | Lmod modules loaded | `LOADEDMODULES` with colons turned into spaces |
| `pvenv {...}` | a Python venv is active | basename of `VIRTUAL_ENV` |
| line 2 | always | working directory, number of entries, `total` from `ls -lah` |

## Welcome banner

`bash/.bash/welcome` runs on every interactive shell. It prints `bh-ascii.txt`, then centred rows with host, IP,
kernel, uptime, CPU, memory and bash version, one `gpu<n>` entry per card if `nvidia-smi` exists, and a short
`fortune -s` if `fortune` is installed.

## Aliases

All in `bash/.bash/aliases`.

| Alias | What it does |
|---|---|
| `ls` | `ls --color=auto` |
| `ll` | `ls -lh` |
| `la` | `ls -A`, includes hidden files |
| `lr` | `ls -R` |
| `lx` | `ll -BX`, sorted by extension, no backups |
| `lz` | `ll -rS`, sorted by size, largest last |
| `lt` | `ll -rt`, sorted by time, newest last |
| `lsUUID` | `sudo blkid` |
| `dir` | `ls --format=vertical` |
| `vdir` | `ls --format=long` |
| `cp`, `rm`, `mv` | interactive (`-i`): ask before overwriting or deleting |
| `cd..`, `..` | `cd ..` |
| `grep` | `grep --color=auto` |
| `bd` | `. bd -si`: jump back to a parent directory by name (case-insensitive), in the current shell |
| `apt-update`, `apt-upgrade`, `apt-install`, `apt-remove`, `apt-purge` | `sudo apt-get <verb>` |
| `apt-search` | `sudo apt-cache search` |
| `pacman-clean` | remove orphaned packages: `sudo pacman -Rns $(pacman -Qqtd)` |
| `pip-upgrade` | `sudo pip2 install --upgrade pip2` (see Things to know) |
| `pip-update`, `pip2-update` | upgrade every non-editable package from `pip freeze --local` |
| `gem-upgrade` | `gem update --system` |
| `gem-update` | `gem update` |
| `packs-update` | `pip-update ; gem-update ; npm-update` |
| `make` | `make -j 10` |
| `okular`, `evince`, `gimp`, `eog`, `acroread` | start the program with stdout and stderr discarded |
| `latexmk` | `latexmk -pdf` |
| `pdflatex` | `pdflatex -interaction=nonstopmode -halt-on-error` |
| `pushgithub-master`, `pushgithub-develop`, `pushgithub-AMR`, `pushgithub-testing` | `git push -u origin <branch> --tags` |
| `pushgithub-gh-pages` | `git push -u origin gh-pages` (no tags) |
| `pushdropbox-master` | `git push -u dropbox master --tags` |
| `pushgithub-master-local` | `git push -u zaghi-local master --tags` |
| `gitjk` | pipe the last 10 history lines to `gitjk_cmd` (the npm `gitjk` tool, not shipped here) |
| `git-submodule-update` | init submodules, then in each one wipe the tree, reset to `HEAD`, check out `master` and pull |
| `yapf` | `python -m yapf` with `~/python/yapf-style.ini` |
| `salome` | preload the system libfreetype and start SALOME 9.8.0 from `/opt/salome` |
| `meshmixer` | start Autodesk Meshmixer under wine |
| `paraview-wsl` | start the Windows ParaView 5.13.0 from WSL |

## Functions

All in `bash/.bash/functions`, except `vman` (in `aliases`).

| Function | What it does |
|---|---|
| `pathmunge <dir> [after]` | prepend `<dir>` to `PATH` (append with `after`) if it exists and is not already there |
| `calc <expr>` | evaluate with `bc --mathlib`, 10 decimals, trailing zeros stripped: `calc 1/3` |
| `cp_p <src> <dst>` | copy with progress through `rsync -WavP` |
| `fs [paths]` | size of files or directories (`du -sh`); without arguments, everything in `.` |
| `extract <archive>` | unpack by extension: `.tar.bz2`, `.tar.gz`, `.bz2`, `.dmg`, `.gz`, `.tar`, `.tbz2`, `.tgz`, `.zip`, `.ZIP`, `.pax`, `.pax.Z`, `.Z` |
| `find-links <file> [path]` | find every hard or symbolic link to `<file>` (same inode), under `path` or `.` |
| `find-broken-links [path]` | list dangling symlinks under `path` or `.` |
| `find-duplicates [path]` | group files with identical size and MD5 under `path` or `.` |
| `find-zero-size <path>` | list empty files |
| `gifify <video> [--good]` | convert a video to `<video>.gif` with ffmpeg and gifsicle; `--good` goes through PNG frames and ImageMagick |
| `npm-update` | `sudo npm -g install` every outdated global npm package |
| `newtab` | open a new Windows Terminal tab in the current directory (WSL only, calls `wt.exe`) |
| `hpc-login [args]` | start an `ssh-agent` and run `~/.bin/hpc-login --headed` (from [scripts](/packages/scripts)) |
| `say [-v vol] <text>` | speak text with Piper TTS through `ffplay`; volume from `-v`/`--volume`, else `SAY_VOLUME`, else 2.0 |
| `vman <page>` | open a man page inside vim with `:SuperMan` |

## Key bindings

From `bash/.inputrc`.

| Key | Action |
|---|---|
| `Shift-Tab` | cycle through completions (`menu-complete`) |
| `Ctrl-P` | search history backwards for lines starting with what is typed |
| `Ctrl-L` | search history forwards, same filter |
| `Ctrl-Right` / `Ctrl-Left` | next / previous word |
| `Ctrl-T` | type and run `newtab` |

Completion ignores case, lists all matches at once, marks directories and symlinked directories, skips hidden files
and asks before showing more than 200 matches.

## Environment

The settings in `bash/.bash/exports` that change behaviour:

| Variable | Value | Why |
|---|---|---|
| `EDITOR` | `vim` | |
| `BROWSER` | `chromium` | |
| `HISTSIZE`, `HISTFILESIZE` | `32768` | |
| `HISTCONTROL` | `ignoreboth` | no duplicates, no lines starting with a space |
| `HISTIGNORE` | `&:[ ]*:exit:ls:bg:fg:history:clear` | |
| `LANG`, `LC_ALL` | `en_US.UTF-8` | |
| `PAGER`, `MANPAGER` | `less`, `less -X` | the man page stays on screen after quitting |
| `TERM` | `xterm-256color` | forced on every host |
| `COLORTERM` | `truecolor`, only under Windows Terminal | WT sets `WT_SESSION` but not `COLORTERM`; vim needs it to enable 24-bit colour |
| `PYTHONSTARTUP` | `~/.pythonrc` | see [Python and LaTeX](/packages/python-latex) |
| `MODULEPATH` | `~/.modules` | after sourcing Lmod's init, see [HPC modules](/packages/modules) |
| `GPG_TTY` | `$(tty)` | without it, GPG signing fails with "Inappropriate ioctl for device" |

`paths` sets `CDPATH=".:~:~/fortran"`, so `cd FoXy` works from anywhere when `~/fortran/FoXy` exists.

## Claude Code

`bash/.bash/claude_code` defines the `claude-*` wrappers (cloud accounts and providers, local backends) and
`llm-local-server`. Host-specific values (GPU IDs, models, binaries) go in `~/.bash/claude_code.local`. Full
reference: [Accounts and providers](/claude/wrappers) and [Local LLM servers](/claude/local-llm).

`bash/.bash/claude_code_cluster` is the cut-down variant for a cluster node, where `claude_code` is not wanted. It
keeps Node.js, Claude Code and the Ollama models on node-local scratch to stay out of the home quota, and defines
`claude-local [model]`, `ollama-start`, `ollama-stop`, `ollama-status`, `ollama-models` and `claude-help`. Source it
by hand on the node:

```bash
source ~/.bash/claude_code_cluster
```

## Things to know

- **`Ctrl-L` does not clear the screen.** `.inputrc` rebinds it to `history-search-forward`. Use `clear`.
- **`Ctrl-T` and `newtab` are WSL-only.** On quark and astrobit `wt.exe` does not exist and the binding fails.
- **`TERM` is forced to `xterm-256color`** in every interactive shell, also inside tmux and foot, whatever the
  terminal itself announced.
- **`pip-upgrade` is defined twice.** The second definition wins, so it upgrades `pip2`, not `pip`.
- **`vman` needs the vim-superman plugin,** which the [vim](/packages/vim) package does not install. Without it the
  function only prints "No manual entry".
- **`cp`, `rm` and `mv` are interactive.** Scripts are not affected (aliases do not expand in non-interactive shells);
  in an interactive shell, bypass with `\rm` or `command rm`.
- **`.bashrc` sources two completion files without a guard**: `~/.bash_completions/matisse.sh` and
  `~/.bash_completions/fobis.sh`. On a host without them every shell prints a "No such file" error until they are
  installed or the lines are guarded.
- **The `g` completion in `.bashrc` targets an alias that does not exist.** It is inert.
- **`welcome` costs time on every new shell** (`ip`, `nvidia-smi`, `fortune`). It only runs in interactive shells.
- **`claude_code_cluster` is stowed everywhere but loaded nowhere.** That is deliberate; sourcing it on a workstation
  would replace the full `claude-local` and `claude-help` from `claude_code`.
