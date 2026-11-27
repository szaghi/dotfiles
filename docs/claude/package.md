---
title: The claude package
---

# The claude package

The `claude` package holds the whole Claude Code configuration: global instructions, settings, hooks, agents,
slash commands, skills and the status line. Stow links it into `~/.claude`, so every machine and every account
runs the same setup. The shell functions that start Claude Code live in the [bash](/packages/bash) package
(`bash/.bash/claude_code`): see [Session commands](/claude/sessions).

## What the package holds

Source: `claude/.claude/`, deployed to `~/.claude/`.

| Path | Content |
|---|---|
| `CLAUDE.md` | Global instructions, loaded into every session |
| `CLAUDE-fortran.md` | Fortran rules: source files, kinds, modern syntax, OOP, `pure`, module wiring, I/O, OpenMP |
| `CLAUDE-gpu.md` | GPU rules: OpenACC directives, device variables, GPU/MPI coherence, FP64 trap, compiler pitfalls |
| `settings.json` | Permissions; default model and effort (`effortLevel`, per-model `modelSettings`); hooks; status line; enabled plugins and marketplaces; `env` (`ECC_DISABLED_HOOKS`); UI and connector switches |
| `settings.local.json` | Extra allow-list (tracked): WebFetch domains, `WebSearch`, `Read(//tmp/**)` and Bash commands, some of them one-off leftovers |
| `statusline-command.sh` | The status line, see [Status line](/claude/statusline) |
| `commands/` | Custom slash commands, see [Slash commands](/claude/commands) |
| `skills/` | Class-A skills, `manifest.toml`, `README.md`, see [Skills](/claude/skills) |
| `agents/` | Subagents, see [Agents](/claude/agents) |
| `hooks/` | Hook scripts, see [Hooks](/claude/hooks) |

## Deploy

```bash
bash ~/dotfiles/dotify.sh claude
```

Before stowing `claude`, `dotify.sh` checks `~/.claude/settings.json` for drift (see below). Skills of class B
and C need a second step, `skills-apply install`: see [Skills](/claude/skills).

## settings.json drift

Claude Code rewrites `settings.json` (on `/model`, on plugin toggles) by replacing the file. The stow symlink
becomes a plain file and stow aborts with "existing target is neither a link nor a directory". `dotify.sh`
(`check_drift`) handles it before stowing:

| State of `~/.claude/settings.json` | Action |
|---|---|
| Symlink into the repo | Nothing |
| Plain file, identical to the dotfile | Removed and re-linked (prints `drift: ... re-linking`) |
| Plain file, different from the dotfile | Prints the `diff -u`, the two commands below, and exits 1 |

The dotfile is the source of truth. `dotify.sh` never overwrites it, since it can hold uncommitted edits.
The check covers `settings.json` only, not `settings.local.json`.

```bash
# keep the live changes
cp ~/.claude/settings.json ~/dotfiles/claude/.claude/settings.json && rm ~/.claude/settings.json && bash ~/dotfiles/dotify.sh claude
# discard them
rm ~/.claude/settings.json && bash ~/dotfiles/dotify.sh claude
```

The check skips the file when its real path is inside the repo: on a host where stow folded `~/.claude` into a
single directory link, the "live" file is the tracked one, and removing it would delete it from the repo.

## Secrets

`.gitignore` excludes `claude/.claude/.credentials.json` (the OAuth login) and `claude/.claude/.env`. API keys
for third-party providers are read from files in `$HOME` (`~/.z-ai-key`, `~/.nvidia-api-key`,
`~/.huggingface-token`) or from the environment, never from the repo. See [Session commands](/claude/sessions) and [Environment reference](/claude/environment).

`.gitignore` also excludes every path matching `*secret*`, `*api-key*`, `*api_key*` or `*token*`, anywhere in
the repository. The patterns are broad on purpose (`*token*` also catches vim's undo copy of `~/.hf_token`);
a file they would hide wrongly is re-included with a `!` rule, as the Fortran-standard chapter
`ch06-lexical-tokens.md` is. `git check-ignore -v <path>` tells which rule applies to a file.

## Things to know

- Hook and status-line commands in `settings.json` use absolute paths under `/home/stefano` (except
  `no-ai-coauthor.py`, which uses `$HOME`). A host with another user name needs them edited.
- `settings.json` registers a SessionStart hook, `herdr-agent-state.sh`, that is not in the repo: the herdr
  installer writes it into `~/.claude/hooks/`, which is why that directory is real and its tracked hooks are
  linked file by file. `~/.claude/commands/` is a real directory with per-file links too.
- `~/.claude/RTK.md` and `~/.claude/hooks/rtk-rewrite.sh` are untracked leftovers of an RTK install: the account
  wrappers link `RTK.md` into every account, but no instruction loads it and no hook registers the script.
- After a plugin install or a `/model` change, `ls -l ~/.claude/settings.json` tells whether the file is still a
  link. If it is not, the change sits in the plain file and not in git until `dotify.sh claude` surfaces it.
