---
title: Troubleshooting
---

# Troubleshooting

Symptoms seen on these machines, their cause, and the fix.

## Stow: "existing target is neither a link nor a directory"

A real file sits where a link must go. Stow changed nothing. Move the file aside (or merge it into the
dotfile), then run `dotify.sh` again. For `~/.claude/settings.json`, `dotify.sh` prints the diff and the
commands itself: [settings.json drift](/guide/dotify#claude-settings-json-drift).

## Keys or credentials appear in `git status`

Stow folded a directory that did not exist (`~/.ssh`, `~/.claude`) into the repository, and a program
wrote into it. Unstow, create the real directory, re-stow:

```bash
bash ~/dotfiles/dotify.sh -D ssh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
mv ~/dotfiles/ssh/.ssh/id_* ~/.ssh/          # move the keys out of the repository
bash ~/dotfiles/dotify.sh ssh
```

Never commit what was written there. Prevention: [Fresh install, step 3](/guide/installation#_3-create-the-directories-that-must-stay-real).

## `ssh host cmd` does not find my scripts

Remote commands are non-interactive: `.bashrc` returns at its prompt guard before `~/.bash/paths` runs,
so `~/.scripts` and `~/.local/bin` are not on `PATH`. Call scripts by absolute path. This is deliberate:
do not loosen the guard ([bash](/packages/bash)).

## `module load` works in a terminal but not in a script

In non-interactive shells on adam, `module load` does not populate `PATH`. Export the toolchain paths
directly in the script ([HPC modules](/packages/modules)).

## `fatal: bad object HEAD` after a crash

An unclean WSL2 or host shutdown left empty git objects. Find the affected repositories with
`git-health`, then follow the recovery playbook in `scripts/.scripts/git-health.md`. Some of those
objects can be staged blobs whose only other copy is the working tree: look before you delete anything
([git-health](/packages/scripts#git-health)).

## vim or nvim colours unreadable on quark

The colourscheme took its colours from the terminal's ANSI palette, which Noctalia rewrites. Both
editors use 24-bit schemes with `termguicolors`; a 16-colour scheme will break again
([quark desktop](/packages/desktop-quark)).

## Half the quark desktop has the old palette

`noctalia color-scheme-set` does not reload the daemon, and `templates-apply` returns before it has
written the files. Use `noctalia-retheme`, which handles both ([quark desktop](/packages/desktop-quark)).

## Windows ParaView opens an HDF5/XDMF file from WSL with no data

HDF5 locks every file it opens, and the lock fails on WSL's file server. Set the Windows *user*
environment variable `HDF5_USE_FILE_LOCKING=FALSE` and restart ParaView. A mapped drive letter alone does
not help; map it with `net use W: \\wsl$\<distro>` from a non-elevated prompt.

## `night commit` refuses

Read the first line it prints:

| Message | Cause | Fix |
|---|---|---|
| `the chain does not verify` | a step's patch no longer replays | `night verify` names the step |
| `the index has staged changes` | something was staged during the night | unstage it, then run again |
| `HEAD is neither the base nor a step` | a day-time commit landed during the night | rebase by hand, applying the step patches in order |
| `commit runs only from the owner's terminal` | it was run without a TTY (by an agent) | run it yourself |

Details: [Night protocol](/claude/night-protocol).
