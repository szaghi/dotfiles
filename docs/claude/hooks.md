---
title: Hooks, agents, status line
---

# Hooks, agents, status line

Hooks are scripts Claude Code runs on session and tool events; they enforce rules that instructions alone do
not. Agents are subagent definitions Claude can delegate to in a fresh context. The status line is a script that
renders one line of session state. All three live in `claude/.claude/` and are wired in `settings.json`.

## Hooks

Scripts in `claude/.claude/hooks/`, registered under `hooks` in `claude/.claude/settings.json`.

| Event | Matcher | Command | Effect |
|---|---|---|---|
| `SessionStart` | any | `load-context-by-cwd.sh` | Injects path-gated instruction files |
| `SessionStart` | `startup\|resume\|clear\|compact\|fork` | `herdr-agent-state.sh session` (10 s timeout) | herdr session state; installed by herdr, not in the repo |
| `UserPromptSubmit` | any | `context-memory-guard.sh` | Asks Claude to save memory before the context fills |
| `PostToolUse` | any | `context-memory-guard.sh` | Same, during long autonomous turns |
| `Stop` | any | `context-memory-guard.sh` | Same, at turn end |
| `PreToolUse` | `Bash` | `no-ai-coauthor.py` | Blocks commits with an AI co-author trailer |

### load-context-by-cwd

Gates on the session's project directory (`$CLAUDE_PROJECT_DIR`, else `$PWD`, symlinks resolved) and prints the
matching files from `~/.claude/` to stdout, which a SessionStart hook feeds to Claude as context:

| Project under | Loads |
|---|---|
| `~/fortran` | `CLAUDE-fortran.md`, `CLAUDE-gpu.md` |
| `~/python` | nothing yet |

New gates are new `case` arms in the script.

### context-memory-guard

Saves the session state before a `/compact` can lose it.

1. The status line writes the context usage of each session to `$XDG_RUNTIME_DIR/claude-ctx/<session>.pct`
   (`/tmp/claude-ctx` without `XDG_RUNTIME_DIR`). Hook inputs carry no usage field; the status line input does.
2. When usage reaches `CLAUDE_MEMORY_GUARD_PCT` (default 60), the hook injects `additionalContext` telling Claude
   to save work done, decisions, resume point and lessons to its memory, then to tell you it is safe to run
   `/compact`.
3. A `<session>.fired` marker limits it to one reminder per cycle. The marker is removed once usage drops below
   the threshold again, which re-arms the guard after a compaction.

It never chains a second continuation off its own Stop reminder (`stop_hook_active`). The percentage is against
the model's full window: with `CLAUDE_CODE_AUTO_COMPACT_WINDOW` set, it no longer matches the point where
auto-compact runs.

### no-ai-coauthor

The deterministic backstop for the rule "never add an AI `Co-authored-by`". On every Bash call it checks whether
the command is a `git ... commit` carrying a trailer that names Claude, Anthropic, Copilot, OpenAI, ChatGPT,
Gemini or Cursor, either at the start of a line (`Co-authored-by: ...`) or through `--trailer`. If so it exits 2,
which blocks the call and tells Claude why.

It sees only the command line. A message passed with `-F` or written in an editor is not checked; the
commit-msg hook of the git template covers those where it is installed. A subject that only mentions the words
is not a trailer and passes.

## Agents

Definitions in `claude/.claude/agents/`, linked to `~/.claude/agents/`.

| Agent | Tools | Purpose |
|---|---|---|
| `blog-code-checker` | Read, Bash, Glob, Grep | Checks every code block, command and API claim of a blog post against the real repos under `~/fortran` and `~/python`; returns verified or BLOCKING per claim, with the correct version from the repo. No prose review. |
| `blog-prose-reviewer` | Read, Edit, Skill | Reviews the prose of a post after the code check: removes AI tells, hedging and filler with the `stop-slop` skill, uses `scientific-writing` for technical voice; returns line-level edits. |
| `correctness-reviewer` | Read, Grep, Glob, Bash | Reviews a diff it did not write, after implementation: correctness, precision, memory, MPI, GPU coherence, architecture, never style. Each finding has file:line, a failure scenario and a tier (T0 reasoned, T1 reproduced). It fixes nothing. |

The two blog agents are driven by the `blog` skill.

## Status line

`claude/.claude/statusline-command.sh`, bound in `settings.json` under `statusLine`. It reads the session JSON
on stdin and prints these fields, separated by `│`, in Solarized colours:

| Field | Shows |
|---|---|
| Account | Account name (`default`, or the suffix of `CLAUDE_CONFIG_DIR`, e.g. `cfd-iac`) and the login address of that account, read from its `.claude.json`. Absent for proxied and local backends. |
| Model | Model display name; for `claude-local`, also `·N×GPU` from `CLAUDE_LOCAL_GPUS` |
| Directory | Basename of the working directory |
| Git | Branch (or short hash), then `+` staged, `!` modified, `?` untracked, `$` stash, `↑n` / `↓n` ahead/behind upstream |
| Context | `ctx:NN%` of the context window |
| Rate limits | `5h:NN%(reset in)` and `7d:NN%(reset in)` |
| Weekly tokens | Tokens used in the current 7-day window, total and output (e.g. `1.2M tok (out 85k)`) |

Percentages are green below 50, yellow from 50, orange from 80, red from 95.

The weekly token count is not reported by Anthropic. The script sums it from the local transcripts
(`~/.claude/projects/**/*.jsonl`) since the window start, counting only `claude-*` models, each message id once.
Since all accounts share `projects/`, a reply is attributed to the account whose `history.jsonl` holds the
latest prompt of its session before the reply; sessions with no prompt in any history count for the personal
account. The scan runs in the background at most once a minute and the line prints the cached value from
`${XDG_CACHE_HOME:-~/.cache}/claude-statusline/`. Usage from other machines or claude.ai is not visible.

## Things to know

- Hook commands use absolute paths (`/home/stefano/.claude/hooks/...`), except `no-ai-coauthor.py`, which uses
  `$HOME`.
- The status line doubles as the sensor of `context-memory-guard`: with a different status line, the guard
  never fires.
- `context-memory-guard.sh` lists the account directories by their pre-rename names in its header comment; the
  behaviour is unaffected, since every account links `hooks/` and `settings.json` to `~/.claude`.
