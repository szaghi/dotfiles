---
title: git
---

# git

The `git/` package holds the global git configuration, the Conventional Commits message template and two hooks. The
signing key is the one per-host value, so it lives outside this package in `~/.gitconfig.local`.

## Install

```bash
bash ~/dotfiles/dotify.sh git
```

| File | Linked to |
|---|---|
| `git/.gitconfig` | `~/.gitconfig` |
| `git/.git-templates/git_commit_message_template` | `~/.git-templates/git_commit_message_template` |
| `git/.git-templates/hooks/commit-msg` | `~/.git-templates/hooks/commit-msg` |
| `git/.git-templates/hooks/post-commit` | `~/.git-templates/hooks/post-commit` |

## Per-host include

The last section of `.gitconfig` is:

```ini
[include]
	path = ~/.gitconfig.local
```

`~/.gitconfig.local` comes from the host's `bash-<host>` package and sets `user.signingkey`, so each machine signs
with its own key. A missing file is ignored by git. See [Per-host packages](/packages/host-specific).

## Settings

| Setting | Value | Effect |
|---|---|---|
| `commit.template` | `~/.git-templates/git_commit_message_template` | the editor opens on the template |
| `commit.gpgsign`, `tag.gpgsign` | `true` | every commit and tag is GPG-signed |
| `core.editor` | `vim` | |
| `core.whitespace` | `space-before-tab,-indent-with-non-tab,trailing-space` | flag spaces before a tab and trailing spaces; space indentation is not an error |
| `apply.whitespace` | `fix` | `git apply` and `git am` repair those whitespace errors in the patch instead of only warning |
| `diff.tool`, `merge.tool` | `vimdiff` | |
| `difftool.prompt` | `false` | `git d` opens vimdiff without asking per file |
| `color.*` | `always` (branch, diff, grep, interactive, ui) | colour even when output is not a terminal |
| `credential.helper` | `cache` | HTTPS credentials kept in memory, not on disk |
| `init.defaultBranch` | `main` | |
| `filter.lfs` | git-lfs clean/smudge/process | Git LFS enabled globally |
| `git-up.fetch.all` | `true` | for the `git-up` tool: fetch all remotes |
| `github.user` | `szaghi` | |

## Aliases

| Alias | What it does |
|---|---|
| `git d` | `git difftool` (vimdiff) |
| `git hist` | graph log, one line per commit: short hash, date, subject, refs, author |
| `git lg` | coloured one-line log with relative dates and author |
| `git tree` | `git lg --graph` |
| `git rebase-last-five` | rewrite the current branch so that `HEAD~4` becomes its root commit, then `git gc` |

## Commit message template

`git_commit_message_template` is a commented Conventional Commits cheat sheet: the
`<type>(<scope>)!: <description>` line with a 50/72-character ruler, the eleven types (`feat`, `fix`, `build`, `ci`,
`test`, `docs`, `refactor`, `perf`, `style`, `chore`, `revert`), the meaning of `!` and the footer kinds. Every line
is a comment, so an untouched template aborts the commit.

## Hooks

| Hook | What it does |
|---|---|
| `commit-msg` | rejects the commit if a `Co-authored-by:` trailer names Claude, Anthropic, Copilot, OpenAI, ChatGPT, Gemini or Cursor |
| `post-commit` | on `master`, in a repository with a `src/` directory, rebuilds a `sources` branch without the top-level files and without `src/third_party` |

The hooks are not active by default: `.gitconfig` sets no `init.templateDir`. Install them per repository:

```bash
cp ~/.git-templates/hooks/commit-msg .git/hooks/
```

## Things to know

- **`color.ui = always` leaks escape codes into pipes.** `git log | grep` or a script parsing `git` output sees ANSI
  sequences. Pass `--no-color` in scripts.
- **Signing needs a secret key and `GPG_TTY`.** On a fresh host every commit fails until the host's key is imported
  or generated and its id is in `.gitconfig.local`. `GPG_TTY` is exported by
  `bash/.bash/exports`.
- **`rebase-last-five` rewrites history.** Everything older than `HEAD~4` is dropped from the branch, so publishing it
  needs a force-push. It reads the branch from `git branch | cut -c3-`, so it only works in a repository with a single local
  branch.
- **`post-commit` is destructive on the `sources` branch.** It force-deletes the branch, runs `rm -f *` in the work
  tree, commits with `-a` and checks out `master` again. Install it only in repositories built for that layout.
