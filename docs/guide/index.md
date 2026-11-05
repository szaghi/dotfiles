---
title: Introduction
---

# Introduction

This repository is Stefano Zaghi's home directory, kept in git: the shell, the editors, the HPC
toolchains, the desktops and the Claude Code setup of three machines. One clone and one command
(`bash ~/dotfiles/dotify.sh`) turn a fresh account into a working environment, and the same commands
keep the three machines in step afterwards.

::: tip Not meant to be forked
A dotfiles repository is a personal backup and a source of ideas. Take what is useful; expect paths,
host names and habits that are Stefano's own.
:::

## What is in it

Every top-level directory is a **stow package**: its inside mirrors `$HOME`, and GNU Stow links each
file to the same place under your home ([how](/guide/dotify)).

| Area | Packages | What you get |
|---|---|---|
| Shell | [bash](/packages/bash), [tmux](/packages/tmux), [ssh](/packages/ssh) | prompt with git and module status, aliases, functions, a 50k-line tmux |
| Editors | [vim](/packages/vim), [Neovim](/packages/nvim) | two independent configurations, one key map, LSP for Fortran, Python, LaTeX, bash |
| Development | [git](/packages/git), [Python and LaTeX](/packages/python-latex) | Conventional Commits template, GPG signing, latexmk, pythonrc |
| HPC | [HPC modules](/packages/modules) | Lmod modulefiles for NVIDIA HPC SDK, GCC, Open MPI, Intel, AMD |
| Tools | [scripts](/packages/scripts) | image, PDF and video helpers, backups, `git-health`, `claude-remote`, `night` |
| Desktops | [quark](/packages/desktop-quark), [astrobit](/packages/desktop-astrobit) | sway + Noctalia on the laptop, niri + Sunshine on the telescope controller |
| Claude Code | [Claude Code](/claude/) | global instructions, skills, slash commands, hooks, account and local-LLM wrappers |

## The three machines

| Host | Hardware | OS | Desktop | Role |
|---|---|---|---|---|
| **adam** | workstation | WSL2 (Ubuntu) on Windows 11 | none | HPC development, the main machine |
| **quark** | Chuwi Minibook X N150 | CachyOS | sway + Noctalia | the laptop |
| **astrobit** | GMKtec NucBox G5 (Intel N97) | CachyOS | niri + Noctalia | controls the telescopes (INDI, KStars, PHD2) |

What differs per machine is declared in `machines/<host>`: see [The machines](/guide/machines).

## Three rules the whole repository follows

1. **The repository is the source of truth.** A live file that drifted from its dotfile is pulled back
   into the repository, never the other way ([settings.json drift](/guide/dotify#claude-settings-json-drift)).
2. **Only authored files are tracked.** Generated files (Noctalia themes, vim plugins, Claude Code
   transcripts) stay out of git, even when they live next to tracked ones.
3. **No secrets in git.** The repository is public: keys, tokens and private settings live in gitignored
   files such as `bash/.bash/private` ([Conventions](/guide/conventions#secrets)).

## How to read these pages

Start with [Fresh install](/guide/installation), then [Updating](/guide/updating). The
[How it works](/guide/dotify) pages explain the mechanism; the Packages and Claude Code pages are
reference; the [Cookbook](/guide/cookbook) collects the everyday tasks. Each page ends with a
*Things to know* section: the non-obvious behaviour, learnt the hard way.
