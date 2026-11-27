---
title: Skills
---

# Skills

Skills reach `~/.claude/skills/` from three owners with different lifecycles: git and stow for the skills
written here, the `claude plugin` CLI for marketplace plugins, and upstream installers for third-party skills.
`skills-apply` (`scripts/.scripts/skills-apply`) drives the last two from declarations in the repo, so a fresh
host gets the same set with one command. Design notes: `claude/.claude/skills/README.md`.
The full list is on [Skills inventory](/claude/skills-inventory).

## The three classes

| Class | Owner | Declared in | In `~/.claude/skills/` |
|---|---|---|---|
| **A** custom | git + stow | `claude/.claude/skills/<name>/` | symlink into the repo |
| **B** plugin | `claude plugin` CLI | `settings.json` → `enabledPlugins` (marketplaces in `extraKnownMarketplaces`) | nothing; loaded from `~/.claude/plugins/cache/` |
| **C** third-party | upstream installer | `claude/.claude/skills/manifest.toml` | a symlink to a clone, or real directories, depending on the installer |

Class A stows everywhere. Class B is the same on every host, since `settings.json` is shared. Class C is
filtered per host by `machines/<hostname>.skills`: one name per line, blank lines and `#` comments ignored. A
missing file means every manifest entry, so a new host opts out rather than in.

## skills-apply

```bash
skills-apply install        # install everything declared; idempotent
skills-apply update         # update every installed plugin and class-C skill
skills-apply status         # installed vs declared, for all three classes
skills-apply remove <name>  # uninstall one plugin or class-C skill (alias: uninstall)
```

| Command | Class B | Class C |
|---|---|---|
| `install` | `claude plugin install <p>` unless `claude plugin list` already has it | runs `install` unless `check` exits 0 |
| `update` | `claude plugin update <p>`; a failure warns and continues | runs `update`; warns and skips an entry whose `check` fails |
| `status` | `!` for an enabled plugin not installed | `!` for an entry whose `check` fails |
| `remove` | `claude plugin uninstall` | runs `uninstall` |

Restart Claude Code after `install` or `update`, so plugin changes load. `status` always exits 0: it is a
report, not a gate. It needs `python3` 3.11+ (`tomllib`, or `tomli` on older Python) and the `claude` CLI, and
exits 2 when either is missing.

## Adding a skill

**Class A.** Create the directory with at least a `SKILL.md`, commit it, re-stow:

```bash
mkdir -p ~/dotfiles/claude/.claude/skills/<name>
$EDITOR ~/dotfiles/claude/.claude/skills/<name>/SKILL.md
cd ~/dotfiles && git add claude/.claude/skills/<name>/
bash ~/dotfiles/dotify.sh claude
```

**Class B.** Install once, then commit the `enabledPlugins` entry Claude Code added. Other hosts get it from
`skills-apply install`.

```bash
claude plugin install <name>@<marketplace>
cd ~/dotfiles && git diff claude/.claude/settings.json
```

**Class C.** Add an entry to `manifest.toml` and the name to each `machines/<host>.skills` that should get it.
The repo owns the recipe; the upstream tool does the work, so never vendor an installer.

```toml
[skills.<name>]
description = "one line, shown by skills-apply status"
check       = "test -L ~/.claude/skills/<name> && test -d ~/.local/share/claude-skills/<name>/.git"
install     = "{ test -d ~/.local/share/claude-skills/<name>/.git || git clone --depth 1 <url> ~/.local/share/claude-skills/<name>; } && ln -sfn ~/.local/share/claude-skills/<name> ~/.claude/skills/<name>"
update      = "git -C ~/.local/share/claude-skills/<name> pull --ff-only"
uninstall   = "rm -f ~/.claude/skills/<name>; rm -rf ~/.local/share/claude-skills/<name>"
```

Two rules keep an entry repairable after a partial install:

- `check` tests every piece the install produces. A `check` that tests only the clone reports "already
  installed" while the symlink is missing, and `install` never runs again.
- `install` is idempotent, because it is what runs when `check` fails. A bare `git clone` aborts on an existing
  directory and never reaches the `ln -sfn`; guard it as above.

## Drift signals

`skills-apply status` marks drift with `!` and never fixes it:

| Message | Meaning |
|---|---|
| `<name> (outside dotfiles — not yet migrated?)` | A directory in `~/.claude/skills/` that resolves outside the repo and belongs to no plugin or manifest entry |
| `<name> (in dotfiles but SKILL.md not tracked by git)` | A skill in the repo you forgot to `git add`, or an empty directory left by a tool |
| `<plugin> (declared but not installed — run skills-apply install)` | Enabled in `settings.json`, absent on this host |
| `<name> (declared but not installed)` | A class-C entry whose `check` fails |

A real directory in `~/.claude/skills/` is the usual drift signal: a class-A skill not yet moved into the repo,
or a stale copy. Expected exceptions are the installers that write real directories (the Remotion entry),
`synced/`, and `learned/` (an empty directory left by the ECC plugin's continuous learning). `llm-wiki` is
always flagged "outside dotfiles" too: its class-A entry is a tracked symlink into `~/llm-wiki`, so it resolves
outside the repo and its `SKILL.md` is tracked there.

`remove` does not edit the declarations. It prints which file to edit (`enabledPlugins` in `settings.json` or
`[skills.<name>]` in `manifest.toml`); without that edit the next `install` brings the skill back. A class-A skill
is removed by deleting its directory from the repo and re-stowing.

## Exporting the HPC skills

`export-public-skills.sh` (repo root) copies an allowlist of class-A skills into the working tree of the public
`claude-skills-hpc` repository, at `$CLAUDE_SKILLS_HPC_REPO` (default `~/claude/claude-skills-hpc`), under
`skills/<name>`.

```bash
bash ~/dotfiles/export-public-skills.sh --dry-run   # list what would be exported (also -n)
bash ~/dotfiles/export-public-skills.sh
```

- Only the 13 skills in its `ALLOWLIST` are exported: the seven standard and spec references, `cpp-hpc`,
  `python-hpc`, `gpu-multithreading`, `hpc-numerics`, `hpc-cluster-tooling`, `hpc-index`. Anything else cannot
  leak through it.
- Each export replaces the destination copy (`rm -rf`, then `cp -RL`), so deletions propagate; nested `.git`
  directories are dropped.
- It never runs `git add`, `commit` or `push`: review and publish the target repo by hand.
- It stops if the target repo does not exist.

## Things to know

- Bundles show their members under class A in `status` (`diagnose`, `tdd`, `remotion-captions`, …), flagged
  with the "outside dotfiles" drift message, because `skills-apply` keys class C by entry name and the members
  resolve outside the repo. Benign.
- `skills-apply` runs under `set -euo pipefail`: one failing `claude plugin install` or class-C `install`
  command aborts the rest of the run. Fix it and run `install` again; it is idempotent.
- `export-public-skills.sh --dry-run` still creates the destination directory.
- `claude/.claude/skills/README.md` holds the design notes and points to [Skills inventory](/claude/skills-inventory)
  for the list: the inventory lives in one place, so it cannot drift between two copies.
- `~/.claude/skills/synced/` is written by Claude Code itself: the skills provisioned to each claude.ai account,
  one bucket per account. It is gitignored, skipped by `status`, and must not be deleted.
- `latex-document-skill`'s `setup.sh` runs `pip install --break-system-packages`; the manifest builds a venv from
  its `requirements.txt` instead.
- A class-C `.venv` built inside a stowed skill directory lands in the repo; `.gitignore` excludes
  `claude/.claude/skills/*/.venv/`.
