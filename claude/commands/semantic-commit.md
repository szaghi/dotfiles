---
description: Generate a semantic, changelog-ready commit message
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git commit:*)
---

## Git Context

- Branch: !`git branch --show-current`
- Staged files: !`git diff --cached --stat`
- Staged diff: !`git diff --cached`
- Recent commit history (style reference): !`git log --oneline -15`

## Task

Analyze the staged changes above and generate a semantic commit message following the
[Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification.

## Co-authors

Never add you or other AI agents as co-authors.

### If nothing is staged

Warn the user: nothing is staged — suggest `git add <files>` and stop immediately.

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
