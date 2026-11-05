---
title: Cookbook
---

# Cookbook

The everyday tasks, each as the shortest sequence of commands that does it right. The reasons are on
the pages linked from each recipe.

## Track a new file in an existing package

Put it at its mirrored path inside the package, then re-stow:

```bash
cp ~/.config/foo/foo.conf ~/dotfiles/desktop/.config/foo/foo.conf
rm ~/.config/foo/foo.conf                 # the link takes its place
bash ~/dotfiles/dotify.sh desktop
git -C ~/dotfiles add desktop/.config/foo/foo.conf
```

If the program also generates files next to it, track the file, not the directory
([Conventions](/guide/conventions#source-of-truth)).

## Add a new package

```bash
mkdir -p ~/dotfiles/foo/.config/foo
mv ~/.config/foo/config ~/dotfiles/foo/.config/foo/config
```

Add `foo` to `PACKAGES` in `dotify.sh` (every machine) or to `machines/<host>` (one machine), then
`bash ~/dotfiles/dotify.sh foo` and commit both.

## Add a machine

Create `machines/<host>` (and `machines/<host>.skills` if needed), commit, clone on the new machine and
run the [fresh install](/guide/installation). Details: [The machines](/guide/machines#adding-a-machine).

## Add an HPC toolchain

Install it under `/opt`, then write `modules/.modules/<name>/<version>.lua` from the template in
[HPC modules](/packages/modules). It is visible at once: `module avail`.

## Add a Claude Code skill

| Kind | Steps |
|---|---|
| your own | create `claude/.claude/skills/<name>/SKILL.md`, `git add`, `bash dotify.sh claude` |
| a plugin | `claude plugin install <name>@<marketplace>`, check `settings.json` → `enabledPlugins`, commit |
| a third-party loose skill | add `[skills.<name>]` to `claude/.claude/skills/manifest.toml`, list it in `machines/<host>.skills`, `skills-apply install` |

Restart Claude Code afterwards. Details: [Skills](/claude/skills).

## Add a slash command

```bash
vim ~/dotfiles/claude/.claude/commands/<name>.md   # front matter + prompt body
bash ~/dotfiles/dotify.sh claude
```

Format: [Slash commands](/claude/commands).

## Keep a change Claude Code made to settings.json

```bash
cp ~/.claude/settings.json ~/dotfiles/claude/.claude/settings.json
rm ~/.claude/settings.json
bash ~/dotfiles/dotify.sh claude
```

Why: [settings.json drift](/guide/dotify#claude-settings-json-drift).

## Switch the quark desktop palette

```bash
noctalia-retheme --list
noctalia-retheme builtin Nord
noctalia-retheme community Solarized
```

It reloads the daemon and waits for every generated file before re-applying the local patches:
[quark desktop](/packages/desktop-quark).

## Check the repositories after a crash

```bash
git-health -d 7            # repositories touched in the last week
git-health --deep          # also git fsck
```

It reports, never repairs: [git-health](/packages/scripts#git-health).

## Keep a Claude session alive across SSH

```bash
claude-remote start                # on adam
claude-remote -H wsl-adam attach   # from quark
```

Details: [claude-remote](/packages/scripts#claude-remote).

## Let Claude work unattended

Ask for the work "in /night-protocol". In the morning:

```bash
night status && night verify
night commit           # in your own terminal: it signs every step
night clean
```

Details: [Night protocol](/claude/night-protocol).

## Write a commit message

Run `/semantic-commit` in Claude Code. With nothing staged it stages the files the session changed;
`/semantic-commit all` stages everything. It never commits: [Slash commands](/claude/commands).

## Work on these docs

```bash
cd ~/dotfiles/docs
npm install
npm run docs:dev       # live preview
npm run docs:build     # what CI publishes
```
