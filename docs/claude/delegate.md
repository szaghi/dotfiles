---
title: Delegating to an executor
---

# Delegating to an executor

Claude Code with Opus stays the orchestrator. For a task that is mechanical and checkable by a command, it
hands the work to a cheaper executor: [pi](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
running a local Ollama model or a cloud model, or [opencode](https://opencode.ai) (`--harness opencode`) for
the models only it can reach. The executor works in a throwaway git clone. Opus gets back
one JSON object and judges the patch and the result of a check command it chose itself, never the executor's
own report. Executors and their setup are on
[Executors](/claude/executors), measurements on [Executor benchmarks](/claude/executor-benchmarks).
Sources: `claude/.claude/skills/delegate/` (`SKILL.md`, `scripts/delegate`,
`scripts/test-delegate`), and the `pi` package for the model definitions.

## Why this shape

Claude Code points one session at one endpoint, so a subagent cannot run on a different backend. A nested
headless process can, and it leaves the Opus session, its account and its subscription untouched. pi is the
default executor rather than Claude Code itself or opencode because its system prompt plus tools is about
1,600 tokens (opencode's: about 5,900), which matters on local hardware where every prompt token is prefill
time. It also talks to the OpenAI-compatible endpoint that every local server implements. opencode is the
second harness because OpenCode Zen's free models answer only inside it (see below).

```mermaid
flowchart LR
    O["Claude Code (Opus)<br/>writes task, picks check"] -->|Bash| D["delegate"]
    D --> W["private git clone --shared<br/>(current files, uncommitted included)"]
    W --> P["pi -p (local or cloud)<br/>or opencode run"]
    P --> X["patch.diff<br/>(taken before the check)"]
    X --> C["--check on a clean<br/>checkout of the patch"]
    C --> J["JSON result"]
    J --> O
    O -->|review, git apply, re-gate| R["real working tree"]
```

## Use

Ask for it: "delegate this to the local model", "let qwen do the boilerplate". The skill tells Claude when a
task qualifies (mechanical, checkable, bounded), how to write a self-contained task, and how to review the
result. By hand:

```bash
delegate --check 'python3 -m pytest tests/test_io.py -q' --link .venv \
  "Add type annotations to every function in src/io.py. Change nothing else."
```

| Option | Default | Purpose |
|---|---|---|
| `--chain NAME` | none | Run a fallback chain instead of one model: `public` or `private`, see [Executors](/claude/executors#fallback-chains); excludes `--model` and `--harness` |
| `--harness NAME` | `$DELEGATE_HARNESS`, else `pi` | `pi` or `opencode` |
| `--model P/ID` | pi: `$DELEGATE_MODEL`, else `ollama/qwen3.8-unsloth:27b-ud-q4_K_XL`; opencode: required (or `$DELEGATE_OPENCODE_MODEL`) | provider/model of the harness; opencode accepts `provider/model#variant` |
| `--check CMD` | none | Run on a clean checkout of the patch tree plus `--link` paths; `$DELEGATE_REPO` points at the real repo |
| `--timeout S` / `--check-timeout S` | 900 / 900 | Wall-clock limits; the executor's process group is killed |
| `--base REV` | `worktree` | Start from the current files (uncommitted and untracked included) or a revision |
| `--link PATH` | none | Symlink an ignored input (venv, fetched deps) into the clone, never part of the patch |
| `--tools LIST` | pi's defaults | pi tool allowlist (pi only) |
| `--thinking LEVEL` | `off` | pi thinking level (the default model was benchmarked with thinking off; pi only) |
| `--keep-alive DUR` | `30m` | How long Ollama keeps the model loaded after the run |
| `--server-wait S` | 300 | llama.cpp / ik_llama: how long to wait while `/health` reports the model loading |
| `--keep` | off | Keep the clone for inspection (`workdir` in the result) |

`executor.usage` holds, for both harnesses, `input` (uncached prompt tokens), `output`, `cache_read` and
`cost_usd` as the harness computes it from its model prices (0 for local models and free tiers). On a long run
cache reads are most of the tokens: the DeepSeek paper ingestion below was 107k input, 49k output and 2.78M
cache reads, $0.054.

Status values: `ok`, `check_failed`, `timeout`, `error`, `backend_down`, `interrupted`. Exit status is 0 only
for `ok`; 2 for setup errors found before the executor starts (not a git repository, harness missing, bad `--base`,
`--link` or `--out`); 128+N after signal N. Artifacts stay in `$XDG_CACHE_HOME/delegate/<id>/`. Apply a patch
with the `apply` field (`git -C <repo> apply <patch>`): a bare `git apply` from a subdirectory exits 0 and
skips every file outside it.

## Guarantees and limits

- **The caller's repository never moves.** Snapshots use a private `GIT_INDEX_FILE`. The base commit is a
  dangling `commit-tree --no-gpg-sign` object. The executor works in a `git clone --shared` with its remote
  removed and hooks disabled, so its commits, branches and stash stay there; a worktree would share refs with
  the caller. The clone is deleted afterwards, also on timeout and on SIGINT/SIGTERM/SIGHUP.
- **No executor process survives the run.** delegate is a child subreaper and kills every descendant after the
  executor and after the check: pi's `bash` tool detaches its children into their own process groups.
- **The patch is what the executor changed**, from plumbing (`git diff-tree --binary --full-index --no-textconv`
  …) written as raw bytes, so no diff configuration can alter it. Executor-created files show up as `A` lines
  and are part of the review. Python bytecode is suppressed (`PYTHONDONTWRITEBYTECODE=1`).
- **The check proves the patch**: it runs on a clean checkout of the patch tree plus `--link` paths, so an
  ignored file the executor left behind cannot make it pass.
- **It is not a sandbox.** pi's `bash` (opencode's `shell`) can write anywhere in `$HOME`. The clone protects
  the repository only.
- **Limits.** Submodules are empty in the clone. The starting snapshot writes blobs for untracked,
  non-ignored files into the caller's object store (unreachable, reclaimed by `git gc`).
- **A cloud model sends the files it reads to its provider.** Use one only on repositories where that is
  acceptable.

## Testing

```bash
~/.claude/skills/delegate/scripts/test-delegate --offline   # 56 checks, fake pi and opencode, no model
~/.claude/skills/delegate/scripts/test-delegate             # + a live fix with the local model
DELEGATE_TEST_OPENCODE_MODEL=opencode/nemotron-3.5-super-vl-free \
  ~/.claude/skills/delegate/scripts/test-delegate           # + a live fix through opencode
```

The offline cases swap pi for a fake through `DELEGATE_PI`. Besides the basics (usage, missing repository, dead
backend, dirty tree, failing check, timeout, executor failure, `--link`, `--keep`, `--base`) they hold one
reproducer per finding of the correctness review: binary and trailing-whitespace last hunks, hostile diff config,
a provider error behind exit 0, detached child processes, SIGTERM, executor commits/branches/stash, a sibling
worktree, the check on the patch tree, a task starting with `-`, Latin-1 content, malformed events, `--link
.venv/`, setup exit codes. A fake opencode (`DELEGATE_OPENCODE`) asserts the headless contract (flags, isolation
environment, `--` before the message, a `PWD` naming the clone) and covers success, a provider error event, failed
tool calls, a task starting with `-`, a 120 kB task sent as a file, and the argument rules. The live case needs
Ollama and the model. `DELEGATE_TEST_MODEL` picks another one.
