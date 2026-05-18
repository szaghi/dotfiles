---
description: Capture session findings into repo docs, repo Claude config, and global Claude config
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Bash(test:*), Bash(realpath:*), Read, Edit, Write
---

## Repo Context

- Repo root: !`git rev-parse --show-toplevel 2>/dev/null || echo "(not a git repo)"`
- Branch: !`git branch --show-current 2>/dev/null`
- Default branch guess: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo master`
- Merge-base with default: !`base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo master); git merge-base HEAD "origin/$base" 2>/dev/null || git merge-base HEAD "$base" 2>/dev/null || echo "(no base)"`
- Working-tree status: !`git status --short 2>/dev/null | head -40`
- Staged stat: !`git diff --cached --stat 2>/dev/null | tail -20`
- Unstaged stat: !`git diff --stat 2>/dev/null | tail -20`
- Branch commits (since merge-base): !`base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo master); git log --oneline "origin/$base..HEAD" 2>/dev/null || git log --oneline "$base..HEAD" 2>/dev/null | head -25`
- Repo CLAUDE.md present: !`test -f "$(git rev-parse --show-toplevel 2>/dev/null)/CLAUDE.md" && echo yes || echo no`
- Repo .claude/ present: !`test -d "$(git rev-parse --show-toplevel 2>/dev/null)/.claude" && ls "$(git rev-parse --show-toplevel)/.claude" || echo "(none)"`
- Repo docs/ present: !`test -d "$(git rev-parse --show-toplevel 2>/dev/null)/docs" && echo yes || echo no`
- Repo README.md present: !`test -f "$(git rev-parse --show-toplevel 2>/dev/null)/README.md" && echo yes || echo no`
- Global CLAUDE.md: !`test -L ~/.claude/CLAUDE.md && realpath ~/.claude/CLAUDE.md || echo ~/.claude/CLAUDE.md`
- Auto-memory dir: !`ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null | head -5 || echo "(no project memory yet)"`

## Task

Harvest **findings** from the current session and from the recent git activity on this
branch, classify each one, and propose targeted edits to the right destination. Do not
write any file until I have approved the per-class plan.

A **finding** is durable knowledge that should outlive this conversation. Examples:

- "We added a `--strict` flag to the validator that rejects malformed manifests."
- "When passing pointer-array sections to assumed-shape dummies under gfortran -O2, the
  C data pointer is computed wrong — workaround is explicit-shape dummies."
- "The `claude-local --backend ikllama` server starts on port 8081, not 8080."
- "Stefano prefers conservation diagnostics normalised by L1 of the absolute field, not
  by the signed integral."

A **non-finding** is anything ephemeral — current task state, debugging breadcrumbs,
in-progress decisions, "we tried X and it didn't work yet." If in doubt, leave it out.
Memory and docs are read on every future invocation; noise compounds.

### If nothing was learned

If the session and the branch produced no durable findings worth recording, say so in
one sentence and stop. Do not invent findings to justify running the command.

### Classification — three classes, four destinations

| Class | Destination | When                                                                    |
|------:|-------------|-------------------------------------------------------------------------|
| **1** | Repo docs: `README.md`, `docs/**`, in-repo docstrings/comments | New API, feature, algorithm, flag, build target, runtime behaviour visible to *users of the repo*. |
| **2** | Repo Claude config: `<repo>/CLAUDE.md`, `<repo>/.claude/**` | Knowledge that helps an AI agent work *in this repo specifically* — internal conventions, hidden invariants, "don't touch X because Y," file-layout guidance. |
| **3a**| Global Claude instructions: `~/.claude/CLAUDE.md` (a symlink into the dotfiles repo at `~/dotfiles/claude/.claude/CLAUDE.md`) | Reusable engineering rules — Fortran/Python/HPC/GPU conventions, compiler pitfalls, edit protocols. Things that apply across *all* my projects. Insert into the matching topic section or propose a new section. |
| **3b**| Global auto-memory: `~/.claude/projects/<slug>/memory/` + index | User/feedback/project/reference facts, per the memory protocol in the global CLAUDE.md. Use this for *preferences*, *workflow corrections*, *who/why/when of ongoing work*, *pointers to external systems* — not for code-convention rules (those go to 3a). |

A single finding can belong to **more than one class** — call it out when it does and
propose one edit per destination. Example: a new repo flag (Class 1) that also encodes
a general "always set X before calling Y" rule (Class 3a).

### Sources to harvest

Inspect, in order:

1. **This conversation transcript.** Look for moments where I corrected your approach,
   confirmed a non-obvious choice, explained a constraint, gave a measured result, or
   said "remember this" / "this should go in CLAUDE.md" / "don't do X again."
2. **Staged + unstaged diff** in the Git Context above. Code that landed but isn't yet
   committed is often the most recent finding.
3. **Branch commits since merge-base.** Earlier findings from this session may have
   already been committed — read those commit messages and diffs for context.
4. **Existing destinations, for deduplication.** Before proposing a Class 2 or Class 3
   edit, grep the target file. If the finding is already documented, either skip it or
   propose a *refinement* (and say which existing line/section is being refined).

For each candidate finding, ask: "Does the codebase already make this obvious, or does
a reader need to be told?" Skip findings derivable from `git log`, the diff, or a
direct read of the code — those are CLAUDE.md anti-patterns per the global instructions.

### Output — exactly this structure

Produce **one** block per finding, then a global summary, then ask for approval.

```
─── Finding N ────────────────────────────────────────
Title: <one-line imperative summary>
Source: <transcript | staged diff | unstaged diff | commit <sha> | combined>
Class: <1 | 2 | 3a | 3b | multi: 1+3a | ...>
Why durable: <1 sentence on why this outlives the session>

For each destination:
  → <abs/path/to/file>
    Section/anchor: <e.g. "## GPU / OpenACC / CUDA Conventions" or "new section: Foo">
    Proposed edit:
    ```diff
    <unified-diff style, the exact bytes to insert or replace>
    ```
    Dedup check: <"grepped <pattern>, no match" | "refines existing line at …">
```

After all findings:

```
─── Summary ──────────────────────────────────────────
Class 1 (repo docs):           N edits across M files
Class 2 (repo .claude):        N edits across M files
Class 3a (global CLAUDE.md):   N edits across M sections
Class 3b (auto-memory):        N new/updated memories

Approve: [all] [class 1] [class 2] [class 3a] [class 3b] [finding K] [none]
```

Then **stop** and wait for my approval. On approval, apply only the approved subset
using `Edit` (or `Write` for new memory files), in this order: Class 1 → 2 → 3a → 3b.
After applying, print one line per file actually changed.

### Rules for the proposed edits

- **Class 3a (global CLAUDE.md):** the file lives at `~/.claude/CLAUDE.md` which is a
  symlink to `~/dotfiles/claude/.claude/CLAUDE.md`. Edit the dotfiles path, not the
  symlink target indirectly. Prefer appending into an existing topic section
  (`## Fortran Conventions`, `## GPU / OpenACC / CUDA Conventions`, `## Python
  Conventions`, etc.) over inventing a new top-level section.
- **Class 3b (auto-memory):** follow the exact protocol documented in the global
  CLAUDE.md auto-memory section — one file per memory with YAML frontmatter
  (`name`, `description`, `metadata.type`), one-line pointer in `MEMORY.md`. Memory
  types are `user | feedback | project | reference`. Reject "code pattern / convention /
  architecture" findings — those belong in 3a, not memory.
- **Class 2 (repo .claude/):** if the repo has no `CLAUDE.md` or `.claude/` yet,
  *propose creating* `<repo>/CLAUDE.md` rather than silently creating files. Same for
  Class 1 if the repo has no `docs/` and the finding warrants more than a README line.
- **Verbatim matching:** when the edit is a replacement (not pure insertion), copy the
  `before` block byte-exact from the file you read — no paraphrase, no whitespace
  normalisation. This is the Verbatim-Edit Protocol from the global instructions.
- **One file per edit block:** multi-file sweeps are N edits, not one fuzzy one.
- **No commits.** This command never runs `git add` or `git commit`. After files are
  updated, suggest the user run `/semantic-commit` if they want to commit the
  documentation changes.

### Non-goals

- Do not invent findings to pad the output.
- Do not propose style/formatting/whitespace edits — linters handle those (per global
  CLAUDE.md "Review focus" section).
- Do not duplicate content already in a destination — refine in place or skip.
- Do not write to any file before approval.
