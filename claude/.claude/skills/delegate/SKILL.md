---
name: delegate
description: Hand one self-contained, mechanically checkable coding task from this Claude Code session (the orchestrator) to a cheaper executor - pi running a local model (Qwen3.8-27B on Ollama by default; llama.cpp or ik_llama) or a cloud model - in a throwaway git clone, then judge the returned patch and check result instead of the executor's report. Use when the owner says "delegate this", "let the local model / qwen / pi / deepseek do it", "use the executor", "orchestrate with a local executor", or when a task is mechanical (rename, boilerplate, spec-driven edit, test scaffolding) and a command can verify it. Not for design, debugging root causes, numerics or anything whose correctness a command cannot check.
---

# Delegate

`DG=~/.claude/skills/delegate/scripts/delegate` (also `delegate` on the owner's PATH). You stay the
orchestrator: you write the task, choose the check, read the patch, and decide. The executor's own
words are a T0 claim; the patch and the check result are the evidence.

## When to delegate

All three must hold, otherwise do the work yourself or use a Claude subagent:

1. **Mechanical**: the what and the where are already decided (a rename, boilerplate from a pattern,
   applying a spec you wrote, converting a file's format, adding tests to a stated contract).
2. **Checkable by a command**: a build, a test, a grep, a script whose exit status means "done right".
   No check means you would have to re-derive the work to review it, which saves nothing.
3. **Bounded**: a few files, explainable in one self-contained prompt. The executor sees no
   conversation, no CLAUDE.md, no skills: only the task text and the files.

Never delegate design choices, root-cause debugging, numerical kernels, or edits to goldens/baselines.

## Write the task

The executor starts cold. The prompt must carry everything:

- the goal in one sentence, then the exact files to touch and what must not change;
- the conventions that matter (indent, naming, the pattern to copy, with a path to an example file);
- what "done" means, ideally the same command you pass as `--check`;
- for anything over ~15 lines, write it to a file and pass `--task-file`.

## Run

```bash
$DG --check '<cmd that proves it>' [--model ollama/qwen3.8-unsloth:27b-ud-q4_K_XL] [--timeout 900] \
    [--link .venv --link <fetched deps dir>] [--base HEAD] [--thinking off] "<task>"
```

| Option | Use |
|---|---|
| `--check CMD` | Always pass one. Runs on a clean checkout of the patch tree plus `--link` paths, so it proves the patch, not the executor's leftovers; `$DELEGATE_REPO` = the real repo |
| `--model P/ID` | pi `provider/id`; default `$DELEGATE_MODEL`, else `ollama/qwen3.8-unsloth:27b-ud-q4_K_XL`. List: `pi --list-models` |
| `--link PATH` | Symlink an ignored input (venv, `fobis fetch` deps, build cache) into the clone; never part of the patch |
| `--base REV` | Start from a revision instead of the current working tree (default includes uncommitted work) |
| `--timeout S` | Executor wall-clock limit (default 900). `--check-timeout` bounds the check |
| `--tools LIST` | Restrict pi's tools, e.g. `read,edit` for a no-shell task |
| `--keep` | Keep the clone (`workdir` in the result) to inspect a failure; a plain directory, `rm -rf` it after |

Run it in the foreground for short tasks; for long ones use `run_in_background` and keep working.
The local model runs one task at a time (one GPU set), so do not fan out local runs in parallel.

## Read the result

One JSON object on stdout (a copy in `<artifacts>/result.json`), exit 0 only for `status: ok`.

| `status` | Meaning | Next |
|---|---|---|
| `ok` | Executor finished, check passed | Review the patch (below) |
| `check_failed` | Executor finished, check failed | Read `check.tail`; re-delegate with a sharper task once, else do it yourself |
| `timeout` | Executor killed at `--timeout` | Smaller task, or do it yourself |
| `error` | pi failed or never finished its loop (`executor.stderr_tail`, `error`) | Fix the setup or the model id; do not retry blindly |
| `backend_down` | Ollama unreachable or model failed to load | `llm-local-server start`, or tell the owner |
| `interrupted` | delegate got SIGINT/SIGTERM/SIGHUP (exit 128+N); clone and executor already cleaned up | Rerun if the interruption was yours |

Then, for `ok`:

1. **Read `changed_files`.** Anything outside the task's scope (scratch files, artifacts, files you
   said not to touch) is a rejection or a manual trim, never a silent apply.
2. **Read the whole patch** (`patch`). The check proves what it tests, nothing more.
3. Apply to the real working tree with the repo-rooted form, from any directory:
   `git -C <repo> apply --check <patch> && git -C <repo> apply <patch>` (the `apply` field is that
   command). A bare `git apply` run from a subdirectory exits 0 and silently skips every file
   outside it. Never `--index` or `--3way`: both write the real index. If it does not apply, your
   tree moved since the run: re-delegate from the current tree or apply by hand.
4. Run your normal gate in the real tree. Report to the owner what was delegated, the model, the
   status, and that you reviewed and re-gated it.

`executor.tool_errors > 0`, `turns` near zero with a non-empty patch, or a `final_message` claiming
checks the `check` field does not show are reasons for extra scrutiny, not for rejection by themselves.

## Models and where the code goes

| Model | Use for | Cost |
|---|---|---|
| `ollama/qwen3.8-unsloth:27b-ud-q4_K_XL` (default) | Multi-file fixes, features, refactors with a spec | Hard bench tasks 9/9 in ~1-6 min, 5-57 turns; one-liners ~10 s; dense 27B at ~23 tok/s; thinking off |
| `ollama/qwen3-coder-unsloth:30b-a3b-q4_K_M` | One-liners when speed matters | 3x faster per token, but 2/9 on the hard bench tasks |
| `ikllama/ikllama` | Qwen3-Coder when you keep a server up for many delegations: ~30% faster | Start it first: `llm-local-server start --backend ikllama --model ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --ctx 32k` |
| `llamacpp/llama` | Whatever GGUF the server loaded, e.g. Qwen3.8-27B (same 15/15 as on Ollama, H3 faster) | Start it first with `--ctx 32k`; the `server` block names the GGUF |
| `opencode-go/deepseek-v4.1-flash` (cloud) | Fast opt-in when code may leave the machine; parallel fan-out | Hard bench tasks 9/9 in 12-20 s, 4-6 turns (~5x the local default); OpenCode Go plan |
| other `opencode-go/*` (`pi --list-models opencode-go`) | Only after a `bench-delegate` run | qwen3.7-plus 9/9 at 50-81 s; kimi-k2.7-code 7/9 |

A cloud model sends the repository files it reads to that provider. Use one only on repositories
where the owner has accepted that (public libraries: yes; unpublished institute or client code: ask).
OpenCode Go (`opencode-go/*`) is built into pi ≥ 1.6: no `models.json` entry; the key (`oc_sk_…`, from the
OpenCode Console, a workspace with the Go plan) goes in pi's `auth.json` via `/login`, or `OPENCODE_API_KEY`.
Other providers: edit `pi/.pi/agent/models.json` in the dotfiles (see pi's `docs/models.md`); keys never go in
the tracked file.

## Pitfalls

- The `server` block of a llamacpp/ikllama result names the GGUF actually loaded (the model id is
  only the server alias); a `warnings` entry means models.json `contextWindow` exceeds the server's
  `n_ctx`: restart the server with a matching `--ctx`.
- To evaluate a new executor model, run `~/.claude/skills/delegate/bench/bench-delegate` (see the docs page):
  on 2026-11-26 the dense Qwen3.8-27B passed 9/9 hard tasks where Qwen3-Coder passed 2/9: hence the default.
- Do not call `pi` directly: `pi -p` with an open stdin blocks forever without output; `delegate`
  handles that, the clone, the timeout and the warm-up.
- The clone holds tracked and untracked-but-not-ignored files only. Ignored inputs the task or
  check needs (venvs, fetched dependencies, generated headers) must be passed with `--link`.
  Submodules are empty in the clone: do not delegate work inside one.
- The executor's commits, branches and stash stay in its clone and vanish with it; only the patch
  comes back. It runs as you, though: its `bash` can write anywhere in `$HOME`. Not a sandbox.
- The starting snapshot writes blobs for untracked files into your repository's object store
  (unreachable, reclaimed by `git gc`). A large untracked output directory that is not ignored
  costs its full size per run: ignore it, or use `--base HEAD`.
- Artifacts live in `$XDG_CACHE_HOME/delegate/<id>/` (`task.md`, `events.jsonl`, `pi.err`,
  `patch.diff`, `check.log`, `result.json`) and are never pruned automatically.
- In a night-protocol night, applying a patch is an ordinary working-tree edit: snapshot it as part
  of the step it belongs to, with the delegate run in the step's evidence.
