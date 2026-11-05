---
title: Slash commands
---

# Slash commands

Custom slash commands are markdown prompt files in `claude/.claude/commands/`, linked into
`~/.claude/commands/` by stow. They have no installer: git tracks them, stow deploys them, and `/<name>` works
on the next session.

| Command | Purpose |
|---|---|
| `/semantic-commit [instructions]` | Stage this session's changes if nothing is staged, then print a Conventional Commits message |
| `/capture-findings` | Harvest durable findings from the session and propose edits to repo docs, repo Claude config, global instructions or memory |

## /semantic-commit

```text
/semantic-commit
/semantic-commit scope=docs
/semantic-commit all files, one commit
```

What it does:

1. Collects the context before Claude reads anything: branch, `git status --short` (60 lines), the staged stat,
   the staged diff size, the staged diff capped at 1500 lines, the last 15 commits as a style reference, and
   whether a night-protocol night is open.
2. Stages, if needed:
   - something already staged: uses exactly that and adds nothing;
   - nothing staged: stages the files this session created or modified, by explicit path
     (`git add -- <path>...`). `git add -A` or `git add .` only when the instructions say "all". Build products,
     scratch files, logs and secrets stay out. When it cannot tell which changes belong to the commit, it shows
     `git status --short` and asks;
   - nothing to commit: says so and stops.
3. Reads the diff. Beyond 1500 lines the excerpt is truncated, so it reads the rest per file where the content
   decides the message, and skips generated, vendored and binary files.
4. Prints the message in a fenced block, plus a one-line changelog preview
   (`Changelog preview → [Section] scope: description`).

It **never runs `git commit`** or `--amend`: you commit from your own terminal, where GPG signing works. It never
adds an AI co-author.

**Open night.** If `.night/current/base` exists in the repo, a [night](/claude/night-protocol) is open. The
command says so before staging: unless `night status` reports `committed: yes`, staging now makes `night commit`
refuse. Commit the night first.

Message rules it applies: subject of at most 72 characters, imperative, lowercase, no trailing period; scope
inferred from the most affected directory or omitted when the change is cross-cutting; `!` plus a
`BREAKING CHANGE:` footer for breaking changes; body explains why; issue references in footers; the style of
recent history wins when it is consistent. Types and their changelog sections:

| Type | Changelog section |
|---|---|
| `feat` | Added |
| `fix` | Fixed |
| `perf`, `refactor`, `docs` | Changed |
| `revert` | Removed |
| `style`, `test`, `chore`, `ci`, `build` | omitted |

Allowed tools: `git diff`, `git log`, `git status`, `git add`, `git branch`, `git rev-parse`, `head`, `wc`,
`test`.

## /capture-findings

It collects repo context (root, branch, merge base, staged and unstaged stats, commits since the merge base, which
of `CLAUDE.md`, `.claude/`, `docs/`, `README.md` exist, auto-memory files), then classifies each durable finding
of the session:

| Class | Destination |
|---|---|
| 1 | Repo docs: `README.md`, `docs/**`, docstrings |
| 2 | Repo Claude config: `<repo>/CLAUDE.md`, `<repo>/.claude/**` |
| 3a | Global instructions: `~/dotfiles/claude/.claude/CLAUDE.md` |
| 3b | Auto-memory: `~/.claude/projects/<slug>/memory/` and its `MEMORY.md` index |

For each finding it prints the destination, the section and the exact diff, with a deduplication check against
the target, then a summary and an approval prompt (`all`, a class, one finding, `none`). It writes nothing
before approval, applies only the approved subset in the order 1, 2, 3a, 3b, and never stages or commits. With
no durable finding it says so in one sentence and stops.

## File format

```markdown
---
description: One line shown in the slash-command menu
argument-hint: "[what the user may type after the command]"
allowed-tools: Bash(git diff:*), Bash(git status:*), Read, Edit
---

## Context

- Branch: !`git branch --show-current`
- Extra instructions from the user: $ARGUMENTS

## Task

...
```

| Element | Meaning |
|---|---|
| `description` | Text in the command menu |
| `argument-hint` | Hint for the arguments (optional) |
| `allowed-tools` | Tools the command may use without a permission prompt |
| `` !`cmd` `` | Shell substitution, run when the command is invoked; its output replaces the backticks |
| `$ARGUMENTS` | Everything typed after `/<name>` |

## Adding a command

```bash
$EDITOR ~/dotfiles/claude/.claude/commands/<name>.md
cd ~/dotfiles && git add claude/.claude/commands/<name>.md
bash ~/dotfiles/dotify.sh claude
```

Other hosts get it with `git pull && bash dotify.sh claude`.

## Things to know

- The context of `/semantic-commit` is captured before staging. After it runs `git add`, it rereads the staged
  diff itself; the excerpt at the top of the prompt is stale by then.
- The `no-ai-coauthor` hook backs up the "no AI co-author" rule for commits run by an agent, see
  [Hooks](/claude/hooks#no-ai-coauthor).
