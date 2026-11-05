---
title: Updating
---

# Updating

A change made on one machine reaches the others through git: commit and push where you made it, then
pull and re-deploy everywhere else. `dotify.sh` is idempotent, so re-running it is always safe.

## The everyday update

```bash
cd ~/dotfiles
git pull
bash dotify.sh
```

Re-stowing adds links for new files and leaves existing ones alone. It is enough for any change to a
file that is already linked: the link points into the repository, so the new content is live as soon
as `git pull` writes it.

## What needs more than a re-stow

| The pull brought | Also run |
|---|---|
| a new plugin or third-party skill | `skills-apply install`, then restart Claude Code |
| a skill update upstream | `skills-apply update`, then restart Claude Code |
| a new or changed vim plugin | `:PlugInstall` or `:PlugUpdate` in vim |
| a changed `nvim/.config/nvim/lazy-lock.json` | `:Lazy restore` in Neovim |
| a new or changed systemd user unit | `systemctl --user daemon-reload` |
| a new modulefile | nothing: `~/.modules` is a folded link into the repository |
| a change under `desktop/system/` or `desktop-astrobit/system/` | `~/.scripts/quark-desktop-install` or `~/.scripts/astrobit-system-install` |
| a change to bash files | a new shell, or `source ~/.bashrc` |

## When `dotify.sh claude` stops with a diff

Claude Code rewrites `~/.claude/settings.json` by replacing the file, which breaks the link. `dotify.sh`
notices: an identical plain file is re-linked silently; a different one stops the run and prints the
diff with the two commands to keep or discard the live changes. The dotfile wins; see
[settings.json drift](/guide/dotify#claude-settings-json-drift).

## Removing or renaming a tracked file

A link whose target disappeared from the repository stays behind as a dangling link. Unstow the
package before the change, then stow it again:

```bash
bash ~/dotfiles/dotify.sh -D bash      # remove the package's links
git mv bash/.bash/old bash/.bash/new   # change the repository
bash ~/dotfiles/dotify.sh bash         # link again
```

## Undeploying

```bash
bash ~/dotfiles/dotify.sh --uninstall          # every package, this machine's included
bash ~/dotfiles/dotify.sh --uninstall nvim     # one package
```

Only links that point into the repository are removed; your other files are untouched.

## Things to know

- **Machine packages are always processed.** `bash dotify.sh nvim` stows `nvim` *and* the packages of
  `machines/$(hostname -s)`; the same holds for `--uninstall`.
- **Pull before you edit.** The links make every edit live in the working tree of the repository; an edit
  on a stale checkout turns into a merge on the next pull.
- **After an unclean shutdown**, run `git-health -d 7` before committing: an interrupted write can leave
  empty git objects ([git-health](/packages/scripts#git-health)).
