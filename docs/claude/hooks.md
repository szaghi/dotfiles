---
title: Hooks
---

# Hooks

Hooks are scripts Claude Code runs on session and tool events; they enforce rules that instructions alone do
not. The scripts are in `claude/.claude/hooks/`, registered under `hooks` in
`claude/.claude/settings.json`.

## Registered hooks

| Event | Matcher | Command | Effect |
|---|---|---|---|
| `SessionStart` | any | `load-context-by-cwd.sh` | Injects path-gated instruction files |
| `SessionStart` | `startup\|resume\|clear\|compact\|fork` | `herdr-agent-state.sh session` (10 s timeout) | herdr session state; installed by herdr, not in the repo |
| `UserPromptSubmit` | any | `context-memory-guard.sh` | Asks Claude to save memory before the context fills |
| `PostToolUse` | any | `context-memory-guard.sh` | Same, during long autonomous turns |
| `Stop` | any | `context-memory-guard.sh` | Same, at turn end |
| `PreToolUse` | `Bash` | `no-ai-coauthor.py` | Blocks commits with an AI co-author trailer |

## Plugin hooks

The enabled `ecc@ecc` plugin (class B, see [Skills](/claude/skills)) registers 21 hooks of its own, from
`~/.claude/plugins/cache/ecc/ecc/<version>/hooks/hooks.json`. They run in every session alongside the table
above:

| Event | Hooks |
|---|---|
| `PreToolUse` | a Bash preflight dispatcher (quality, tmux, push and git checks); a warning on non-standard documentation files; a compaction suggestion; tool-use capture for continuous learning; governance capture (secrets, policy); a block on edits to linter and formatter configs; an MCP health check; the "fact-forcing" gateguard |
| `PostToolUse` | two dispatchers (synchronous and background) |
| `PostToolUseFailure` | marks failing MCP servers unhealthy |
| `PreCompact` | saves state before compaction |
| `SessionStart` | loads the previous context; surfaces open Plan Canvas sessions |
| `Stop` | JS/TS format and typecheck; a `console.log` check; session persistence; pattern extraction; token and cost tracking; a desktop notification |
| `SessionEnd` | an end marker |

`settings.json` disables two of them through `env.ECC_DISABLED_HOOKS`: the gateguard for Bash and for edits.
To silence another, add its id (`<event>:<matcher>:<name>`) to that list.

## load-context-by-cwd

Gates on the session's project directory (`$CLAUDE_PROJECT_DIR`, else `$PWD`, symlinks resolved) and prints the
matching files from `~/.claude/` to stdout, which a SessionStart hook feeds to Claude as context:

| Project under | Loads |
|---|---|
| `~/fortran` | `CLAUDE-fortran.md`, `CLAUDE-gpu.md` |
| `~/python` | nothing yet |

New gates are new `case` arms in the script.

## context-memory-guard

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

## no-ai-coauthor

The deterministic backstop for the rule "never add an AI `Co-authored-by`". On every Bash call it checks whether
the command is a `git ... commit` carrying a trailer that names Claude, Anthropic, Copilot, OpenAI, ChatGPT,
Gemini or Cursor, either at the start of a line (`Co-authored-by: ...`) or through `--trailer`. If so it exits 2,
which blocks the call and tells Claude why.

It sees only the command line. A message passed with `-F` or written in an editor is not checked; the
commit-msg hook of the git template covers those where it is installed (per repository: `.gitconfig` sets no
`init.templateDir`). A subject that only mentions the words
is not a trailer and passes.

## Things to know

- Hook commands use absolute paths (`/home/stefano/.claude/hooks/...`), except `no-ai-coauthor.py`, which uses
  `$HOME`.
- The ECC hook logs grow without bound: `~/.claude/bash-commands.log` and `~/.claude/cost-tracker.log` were
  about 170 MB each on adam (2026-11-27). Truncate them when they get in the way.
