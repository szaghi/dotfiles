---
title: Conventions
---

# Conventions

The rules that keep three machines and one public repository consistent. Most are enforced by a tool;
the rest are written here so they are not rediscovered the hard way.

## Commits

| Rule | Enforced by |
|---|---|
| Conventional Commits: `<type>(<scope>): <description>` | the template `git/.git-templates/git_commit_message_template` |
| types `feat fix build ci test docs refactor perf style chore revert` | the template |
| commits and tags are GPG-signed | `git/.gitconfig` (`commit.gpgsign`, the key in `bash-<host>/.gitconfig.local`) |
| no `Co-authored-by` line for Claude or any AI | the `no-ai-coauthor` hook in agent sessions ([hooks](/claude/hooks)) |
| Claude never commits on its own | the global `CLAUDE.md`; [`/semantic-commit`](/claude/commands) only stages and writes the message |

The scope is the package or area: `feat(claude): …`, `fix(scripts): …`, `docs(nvim): …`.

## Source of truth

- **The dotfile wins.** When a live file differs from its dotfile, copy the change into the repository,
  then re-link; never copy the dotfile over a newer live change without looking at it.
- **Authored, not generated.** Track what a person writes. Generated output (Noctalia themes, plugin
  directories, caches) stays out, and a package must not link a directory whose siblings a
  program generates.
- **One copy.** A file needed in two places is linked, not copied: `scripts/.scripts/night` is a link to
  the night-protocol skill's script, `claude/.claude/skills/llm-wiki` a link into the `llm-wiki`
  repository.

## Secrets

The repository is public on GitHub. Nothing that identifies an account or opens a door goes in:
API keys and tokens go in `bash/.bash/private`; ssh keys stay in `~/.ssh` (only `config` is tracked);
Sunshine and Claude Code credentials are gitignored. A per-host value that is not secret but differs by
machine (the signing key id, GPU ids) goes in `bash-<host>/`.

## Per-host differences

Common behaviour goes in the common packages. A difference between machines is a package listed in
`machines/<host>` (`bash-<host>`, `desktop`, `desktop-astrobit`), never a `hostname` test inside a
common file.

## Editors

- **Indentation:** 3 spaces everywhere, 4 for Python; trailing whitespace is stripped on save.
- **One key map for vim and Neovim**, leader `,`. A map must not be a prefix of another (`,r` and `,rn`):
  vim would wait `timeoutlen` on the short one.
- **vim and Neovim never share state:** no shared runtimepath, undo directory or plugin directory.
- **Colours come from 24-bit schemes** (`vim-solarized8`, `solarized.nvim` with `termguicolors`), never
  from the terminal's ANSI palette, which Noctalia rewrites.

## Shell scripts

Scripts in `scripts/.scripts/` are mostly bash; shellcheck reads `.shellcheckrc` at the root, and ALE runs
it on save in vim. A script that reports rather than repairs stays that way: `git-health` never touches a
repository, because repair needs judgement.

## Modulefiles

`modules/.modules/<name>/<version>.lua`: guard the install root with `isDir` and `LmodError`, declare
`family("compiler")` for compilers, set `CC`, `CXX`, `FC`, `F77`, `F90`, and build paths with
`pathJoin`. On WSL2, NVHPC modules prepend `/usr/lib/wsl/lib` to `LD_LIBRARY_PATH` and set
`UCX_MEMTYPE_CACHE=n`. Template: [HPC modules](/packages/modules).

## Documentation

These pages are the reference; `README.md` stays the GitHub landing page and `CLAUDE.md` the
instructions for Claude Code. A change to behaviour updates the page that describes it in the same
commit.
