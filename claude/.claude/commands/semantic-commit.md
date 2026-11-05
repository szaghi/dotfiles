---
description: Stage this session's changes if nothing is staged, then generate a semantic, changelog-ready commit message
argument-hint: "[extra instructions, e.g. 'all files', 'one commit', 'scope=docs']"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git add:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(head:*), Bash(wc:*), Bash(test:*)
---

## Git Context

- Branch: !`git branch --show-current`
- Working-tree status: !`git status --short | head -60`
- Staged files: !`git diff --cached --stat`
- Staged diff size: !`git diff --cached | wc -l` lines (the diff below stops at 1500)
- Staged diff: !`git diff --cached | head -n 1500`
- Recent commit history (style reference): !`git log --oneline -15`
- Open night-protocol night: !`top=$(git rev-parse --show-toplevel); test -f "$top/.night/current/base" && echo "yes ($(readlink "$top/.night/current"))" || echo no`
- Extra instructions from the user: $ARGUMENTS

## Task

Generate a semantic commit message for the staged changes, following the
[Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification.
**Never run `git commit`** (nor `--amend`): the owner commits from their own terminal (GPG).

## Co-authors

Never add you or other AI agents as co-authors.

### Staging

- **Something is staged:** use exactly that. Do not add to it: the owner staged it on purpose.
- **Nothing is staged:** stage the files this session created or modified for the work being
  committed, by explicit path (`git add -- <path>...`). Never `git add -A` or `git add .` unless the
  extra instructions say "all". Leave out build products, scratch files, logs, secrets and anything
  this session did not touch. If you cannot tell which changes belong to the commit (no edits in
  this session, or unrelated changes mixed in), show `git status --short` and ask instead.
  The context above was captured *before* staging: after `git add`, read the staged diff yourself
  (`git diff --cached --stat`, then `git diff --cached -- <path>` per file).
- **Diff longer than 1500 lines:** the excerpt above is truncated. Read the rest per file where the
  content decides the message; skip generated, vendored and binary files (the stat is enough).
- **Open night:** if a night-protocol night is open, say so before staging. Unless `night status`
  reports `committed: yes`, staging now makes `night commit` refuse (night-protocol rule 7): the
  owner should commit that night first.
- **Nothing to commit at all:** say so and stop.

### Message Format

```
<type>[(<scope>)][!]: <description>

[body]

[footers]
```

### Type Selection Guide

| Type       | Use when                                      | Changelog section |
|------------|-----------------------------------------------|-------------------|
| `feat`     | A new feature is introduced                   | **Added**         |
| `fix`      | A bug is corrected                            | **Fixed**         |
| `perf`     | Performance improvement, no API change        | **Changed**       |
| `refactor` | Code restructure, no feature or fix           | **Changed**       |
| `docs`     | Documentation changes only                    | **Changed**       |
| `style`    | Formatting, whitespace (no logic change)      | *(omitted)*       |
| `test`     | Test additions or updates only                | *(omitted)*       |
| `chore`    | Build process, tooling, dependency bumps      | *(omitted)*       |
| `ci`       | CI/CD pipeline configuration changes          | *(omitted)*       |
| `build`    | Build system or compiler option changes       | *(omitted)*       |
| `revert`   | Reverts a previous commit                     | **Removed**       |

### Rules

- **Subject line**: max 72 chars · imperative mood · lowercase · no trailing period
  - ✅ `fix(auth): prevent token refresh loop on page reload`
  - ❌ `Fixed token bug.`
- **Scope**: optional, identifies the module/component (e.g. `api`, `ui`, `auth`, `db`, `cli`)
  - Infer scope from the directory/module most affected by the diff
  - Omit scope if changes are truly cross-cutting
- **Breaking change**: append `!` after type/scope AND add a `BREAKING CHANGE: <description>` footer
- **Body**: explain the *why*, not the *what*; wrap at 72 chars; separated from subject by a blank line
- **Footers** (each on its own line after a blank line): `BREAKING CHANGE:`, `Closes #N`, `Refs #N`
- If a clear, consistent commit style is visible in recent history, match it

### Changelog Readiness

To ensure machine-parseable changelogs (e.g. with `git-cliff`, `conventional-changelog`,
`release-please`):

- Prefer the types that map to changelog sections (`feat`, `fix`, `perf`, `revert`)
- Use `BREAKING CHANGE:` footer (not inline) so parsers can detect it reliably
- Reference issues/PRs in footers (`Closes #N`, `Refs #N`) for traceability
- Keep the subject line free of ticket numbers — put them in footers

### Output

1. Present the proposed commit message in a fenced code block, ready to copy-paste.
2. Below it, show a one-line changelog entry preview:
   ```
   Changelog preview → [Section] scope: description
   ```
