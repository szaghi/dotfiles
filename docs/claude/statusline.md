---
title: Status line
---

# Status line

`claude/.claude/statusline-command.sh`, bound in `settings.json` under `statusLine`. It reads the session JSON
on stdin and prints these fields, separated by `│`, in Solarized colours:

## Fields

| Field | Shows |
|---|---|
| Account | Account name (`default`, or the suffix of `CLAUDE_CONFIG_DIR`, e.g. `cfd-iac`) and the login address of that account, read from its `.claude.json`. Absent for proxied and local backends. |
| Model | Model display name; for `claude-local`, also `·N×GPU` from `CLAUDE_LOCAL_GPUS` |
| Directory | Basename of the working directory |
| Git | Branch (or short hash), then in brackets `+` staged, `!` modified, `?` untracked, `$` stash, `↑n` / `↓n` ahead/behind upstream, e.g. `master [+! ↑2]` |
| Context | `ctx:NN%` of the context window |
| Rate limits | `5h:NN%(reset in)` and `7d:NN%(reset in)`, the latter followed by the tokens used in the current 7-day window, total and output (e.g. `7d:41%(2d3h) 1.2M tok (out 85k)`) |

Percentages are green below 50, yellow from 50, orange from 80, red from 95.

## Weekly token count

The weekly token count appears only when a 7-day rate limit is reported and the cached count belongs to the
current window. It is not reported by Anthropic. The script sums it from the local transcripts
(`~/.claude/projects/**/*.jsonl`) since the window start, counting only `claude-*` models, each message id once.
Since all accounts share `projects/`, a reply is attributed to the account whose `history.jsonl` holds the
latest prompt of its session before the reply; sessions with no prompt in any history count for the personal
account. The scan runs in the background at most once a minute and the line prints the cached value from
`${XDG_CACHE_HOME:-~/.cache}/claude-statusline/`. Usage from other machines or claude.ai is not visible.

## Things to know

- The status line doubles as the sensor of `context-memory-guard`: with a different status line, the guard
  never fires.
