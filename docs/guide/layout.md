---
title: Repository layout
---

# Repository layout

Every top-level directory is either a stow package (its inside mirrors `$HOME`) or one of a few
repository-only directories that Stow never sees.

## Stow packages

| Package | Deployed to | Stowed on | Page |
|---|---|---|---|
| `bash/` | `~/.bashrc`, `~/.bash_profile`, `~/.inputrc`, `~/.dircolors.256dark`, `~/.bash/` | all | [bash](/packages/bash) |
| `vim/` | `~/.vimrc`, `~/.vim/` | all | [vim](/packages/vim) |
| `nvim/` | `~/.config/nvim/` | all | [Neovim](/packages/nvim) |
| `git/` | `~/.gitconfig`, `~/.git-templates/` | all | [git](/packages/git) |
| `claude/` | `~/.claude/` (instructions, settings, skills, commands, agents, hooks) | all | [Claude Code](/claude/) |
| `modules/` | `~/.modules/` | all | [HPC modules](/packages/modules) |
| `python/` | `~/.pythonrc`, `~/.pylintrc` | all | [Python and LaTeX](/packages/python-latex) |
| `scripts/` | `~/.scripts/`, `~/.bin/`, `~/.config/systemd/user/` | all | [scripts](/packages/scripts) |
| `miscellanea/` | `~/.latexmkrc` | all | [Python and LaTeX](/packages/python-latex) |
| `ssh/` | `~/.ssh/config` (never keys) | all | [ssh](/packages/ssh) |
| `tmux/` | `~/.tmux.conf` | all | [tmux](/packages/tmux) |
| `bash-adam/`, `bash-quark/`, `bash-astrobit/` | `~/.bash/`, `~/.gitconfig.local` | its host | [Per-host packages](/packages/host-specific) |
| `usr/` | `~/.local/share/applications/` | adam | [Per-host packages](/packages/host-specific) |
| `desktop/` | `~/.config/` (sway, foot, Noctalia, Qt, GTK) | quark | [quark desktop](/packages/desktop-quark) |
| `desktop-astrobit/` | `~/.config/` (niri, foot, Sunshine) | astrobit | [astrobit desktop](/packages/desktop-astrobit) |

## Repository-only entries

| Entry | What it is |
|---|---|
| `dotify.sh` | the deploy script ([Stow and dotify.sh](/guide/dotify)) |
| `machines/` | per-host package lists and skill lists ([The machines](/guide/machines)) |
| `docs/` | this documentation (VitePress) |
| `export-public-skills.sh` | copies an allowlist of HPC reference skills to the public `claude-skills-hpc` repository; never commits ([Skills](/claude/skills)) |
| `background/` | desktop wallpapers |
| `screenshots/` | old screenshots of the bash prompt and desktop |
| `README.md`, `CLAUDE.md` | the GitHub landing page, pointing here; the instructions Claude Code reads in this repository |
| `.gitignore`, `.gitattributes`, `.shellcheckrc`, `.stow-local-ignore` | repository settings |

## What is never tracked

The repository is public. Besides secrets, these are left out on purpose:

| Ignored | Why |
|---|---|
| `bash/.bash/private` | tokens and private settings, sourced by `.bashrc` |
| `claude/.claude/.credentials.json`, `claude/.claude/.env` | Claude Code credentials |
| `claude/.claude/skills/synced/`, `claude/.claude/skills/*/.venv/` | account-synced skills, per-skill virtual environments |
| `vim/.vim/plugged/`, `vim/.vim/undo/`, `vim/.vim/view/` | vim-plug's plugins and vim's state |
| `desktop-astrobit/.config/sunshine/sunshine_state.json`, `credentials/` | Sunshine's web-UI password, TLS key, pairing state |
| `scripts/.config/systemd/user/*.target.wants/` | links created by `systemctl --user enable` |
| `*.gpg`, `*token*` | anything that looks like a key or a token |
| `docs/node_modules/`, `docs/.vitepress/cache/`, `docs/.vitepress/dist/` | documentation build products |

Noctalia's generated theme files are kept out by Stow linking file by file, not by `.gitignore`
alone: see [quark desktop](/packages/desktop-quark).
