---
title: Delegating to an executor
---

# Delegating to an executor

Claude Code with Opus stays the orchestrator. For a task that is mechanical and checkable by a command, it
hands the work to a cheaper executor: [pi](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
running a local Ollama model or a cloud model. The executor works in a throwaway git clone. Opus gets back
one JSON object and judges the patch and the result of a check command it chose itself, never the executor's
own report. Sources: `claude/.claude/skills/delegate/` (`SKILL.md`, `scripts/delegate`,
`scripts/test-delegate`), and the `pi` package for the model definitions.

## Why this shape

Claude Code points one session at one endpoint, so a subagent cannot run on a different backend. A nested
headless process can, and it leaves the Opus session, its account and its subscription untouched. pi is the
executor rather than Claude Code itself or opencode because its system prompt plus tools is about 1,600
tokens, which matters on local hardware where every prompt token is prefill time. It also talks to the
OpenAI-compatible endpoint that every local server implements.

```mermaid
flowchart LR
    O["Claude Code (Opus)<br/>writes task, picks check"] -->|Bash| D["delegate"]
    D --> W["private git clone --shared<br/>(current files, uncommitted included)"]
    W --> P["pi -p<br/>local Qwen3-Coder or cloud"]
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
| `--model P/ID` | `$DELEGATE_MODEL`, else `ollama/qwen3-coder-unsloth:30b-a3b-q4_K_M` | pi provider/model |
| `--check CMD` | none | Run on a clean checkout of the patch tree plus `--link` paths; `$DELEGATE_REPO` points at the real repo |
| `--timeout S` / `--check-timeout S` | 900 / 900 | Wall-clock limits; the executor's process group is killed |
| `--base REV` | `worktree` | Start from the current files (uncommitted and untracked included) or a revision |
| `--link PATH` | none | Symlink an ignored input (venv, fetched deps) into the clone, never part of the patch |
| `--tools LIST` | pi's defaults | pi tool allowlist |
| `--thinking LEVEL` | `low` | pi thinking level |
| `--keep-alive DUR` | `30m` | How long Ollama keeps the model loaded after the run |
| `--server-wait S` | 300 | llama.cpp / ik_llama: how long to wait while `/health` reports the model loading |
| `--keep` | off | Keep the clone for inspection (`workdir` in the result) |

Status values: `ok`, `check_failed`, `timeout`, `error`, `backend_down`, `interrupted`. Exit status is 0 only
for `ok`; 2 for setup errors found before the executor starts (not a git repository, pi missing, bad `--base`,
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
- **It is not a sandbox.** pi's `bash` can write anywhere in `$HOME`. The clone protects the repository only.
- **Limits.** Submodules are empty in the clone. The starting snapshot writes blobs for untracked,
  non-ignored files into the caller's object store (unreachable, reclaimed by `git gc`).
- **A cloud model sends the files it reads to its provider.** Use one only on repositories where that is
  acceptable.

## Models

Defined in `pi/.pi/agent/models.json` (adam only, through `machines/adam`). Only that file is tracked: pi
rewrites `settings.json`, and `auth.json` holds keys.

| Provider/model | Engine | Notes |
|---|---|---|
| `ollama/qwen3-coder-unsloth:30b-a3b-q4_K_M` (default) | Ollama, loads on demand | Imported from the GGUF with `claude/.claude/skills/delegate/ollama/Modelfile.qwen3-coder-30b-a3b` (recipe inside) |
| `llamacpp/llama` | llama.cpp on `:8080` | Serves whatever GGUF `llm-local-server start --backend llama --model … --ctx 32k` loaded |
| `ikllama/ikllama` | ik_llama.cpp on `:8081` | Same, `--backend ikllama` |
| `ollama/qwen3.8:27b` | Ollama | Former default, dense 27B; its GGUF is Ollama-specific and does not load in llama.cpp |

For the two llama-server engines the model id is only the server's alias, so `delegate` reads `/props` and puts
the real GGUF and the per-slot context in the result's `server` block. A stopped server is `backend_down` with the
start command; a server still loading (HTTP 503) is waited for up to `--server-wait`.

`contextWindow` must match the context the engine allocated: `ollama ps` (column CONTEXT) for Ollama, the `--ctx`
the server was started with for the others. Ollama truncates silently; llama-server rejects the request. `delegate`
warns when `contextWindow` exceeds a llama-server's `n_ctx`.

### Engine comparison (2026-11-26)

Same weights on every engine for the Qwen3-Coder rows: unsloth Qwen3-Coder-30B-A3B-Instruct Q4_K_M (18.56 GB,
MoE, 3B active), Qwen's recommended sampling (temperature 0.7, top-p 0.8, top-k 20, repeat penalty 1.05), 32k context,
2 × RTX 4070. Two tasks through `delegate` with a check, warm server, three runs each: **T1** fix a one-line bug,
**T2** implement a function from its docstring until a 5-case unittest passes, test file unchanged. Times are pi's
wall clock (`executor.elapsed_s`), medians.

| Engine, model | Cold load | GPU share | T1 | T2 |
|---|---|---|---|---|
| Ollama 0.34, qwen3.8:27b dense (former default) | 31 s | 89% | 3/3, 14.7 s | 3/3, 137.9 s |
| Ollama 0.34, Qwen3-Coder-30B-A3B | 32 s | 94% | 3/3, 5.1 s | 3/3, 24.6 s |
| llama.cpp b8645, same GGUF | 18 s | 100% | 2/3, 5.6 s | 3/3, 23.5 s |
| ik_llama.cpp b4433, same GGUF | 8 s (file in page cache) | 100% | 3/3, 3.3 s | 3/3, 17.3 s |
| llama.cpp master 09c1410, Inkling-2-Mini UD-Q4_K_XL | 41 s | partial (auto-fit) | 3/3, 73.0 s | 3/3, 223.4 s |

- The MoE coder model is 3-6x faster than the dense 27B at the same pass rate: hence the default.
- llama.cpp's failure: Qwen3-Coder wrote its tool call as plain text (no opening `<tool_call>`), llama.cpp did
  not parse it, pi ended after one turn with no change, and the check reported `check_failed`. Ollama's own
  Qwen3-Coder parser handled all six runs.
- One ik_llama T1 run took 49.5 s: the model's first command was `find /home/stefano -name calc.py`, a scan of
  the whole home directory, before it edited the file in its clone. The preamble's "work only inside the current
  directory" is advice, not enforcement: see *not a sandbox* above.
- Inkling-2-Mini (unsloth UD-Q4_K_XL, 17.6 GB; arch `inkling2_loop`: 128-expert MoE, blocks 6-18 looped 3
  times) needs llama.cpp newer than b8645: it ran on a master build (`~/llama.cpp-master`, gcc-14 + CUDA 13.1),
  which has since replaced the b8645 build as adam's `LLAMACPP_BIN` (Qwen3-Coder on it: T1 3/3 5.0 s, T2 3/3
  23.1 s, 70-74 tokens/s); ik_llama and Ollama 0.34 do not know the architecture. Correct on
  every run, with its own sampling defaults (temperature 1.0, top-k 0), but slow on 2 × RTX 4070: 11-16 tokens/s
  generated against 66-90 for Qwen3-Coder on the same probe, because 17.6 GB of weights plus the 32k cache do not
  fit, so the fitter keeps some tensors on the CPU (`--fit-target 256,256`: 15-16 tokens/s), and it writes 2-3x
  more tokens per task. Not a delegate executor on this hardware.
- n = 3 per cell: enough to rank the dense model against the MoE one, not to separate the three engines on
  speed. Cold loads are not comparable: Ollama reads its own copy of the blob, the llama.cpp-family servers read
  the GGUF in `~/models`, which earlier loads had left in the page cache.

### Executor quality (2026-11-26)

`claude/.claude/skills/delegate/bench/bench-delegate` runs `delegate` on a fixed suite and reports pass rate and
time per task. T1 and T2 are the two tasks above; H1-H3 are harder, multi-module tasks on a small `ledger` package:
exact Decimal money with half-up rounding across parser and report (H1), monthly grouping in the library and the CLI
(H2), and renaming a dataclass field behind a deprecation shim for read, write and keyword (H3). Hidden tests decide;
the executor never sees them (they ship compressed, because an executor once ran `find /home/stefano`).
`bench-delegate --validate` proves each task fails untouched and passes with a reference fix.

```bash
bench=~/.claude/skills/delegate/bench/bench-delegate
$bench --validate
$bench --label qwen38 -- --model llamacpp/llama --thinking off --timeout 1800
```

Three runs per task; hard-task medians:

| Executor | All | Hard (H1-H3) | Hard: time, turns, output tokens | Generation |
|---|---|---|---|---|
| Ollama Qwen3-Coder-30B-A3B Q4_K_M (default) | 8/15 | 2/9 | 71 s, 29, 4,084 | 66-90 tok/s |
| llama.cpp Qwen3.8-27B UD-Q4_K_XL, thinking off | **15/15** | **9/9** | 83 s, 8, 1,980 | 25 tok/s |
| same + harness-hub `Qwen3.8-27B-pi-adapted` LoRA (F16) | 13/15 | 8/9 | 58 s, 5, 1,254 | 23-24 tok/s |

- The dense Qwen3.8-27B is the better executor on anything beyond a one-liner: Qwen3-Coder fails 7 of 9 hard runs
  after 24-38 turns (H2: accepted `2026-1-5` as a date; H3: no `amt=` keyword, both stated in the task), while
  Qwen3.8-27B passes all 9 in 5-11 turns. Despite generating 3x slower its hard-task times are similar; on T1/T2 it
  is slower (12 s and 20 s against 5 s and 19 s).
- The pi adapter delivers the efficiency its card claims (about 30% less time and 37% fewer tokens than the base on the
  hard tasks) but not more passes here: the base leaves no headroom on this suite, and the adapter's two failures were a
  run that declared T2 done without running its tests and an H3 run that never exercised the `amt=` requirement.
- All 206 tool calls of the two Qwen3.8 configurations stayed inside their clones (scratch CSVs in `/tmp` aside); none
  touched the hidden tests or reference patches.
- Caveats: n = 3 per task, five Python tasks, a Q4 quant (the adapter was trained on BF16; its card recommends Q8_0,
  which does not fit 24 GB), sampling as the adapter was trained (temperature 0.8, top-p 1.0) for both Qwen3.8 rows.
  The first run of the suite counted an added test file as tampering; the check was fixed and the Qwen3-Coder patches
  rescored before these numbers.

## Testing

```bash
~/.claude/skills/delegate/scripts/test-delegate --offline   # 36 checks, fake pi, no model
~/.claude/skills/delegate/scripts/test-delegate             # + a live fix with the local model
```

The offline cases swap pi for a fake through `DELEGATE_PI`. Besides the basics (usage, missing repository, dead
backend, dirty tree, failing check, timeout, executor failure, `--link`, `--keep`, `--base`) they hold one
reproducer per finding of the correctness review: binary and trailing-whitespace last hunks, hostile diff config,
a provider error behind exit 0, detached child processes, SIGTERM, executor commits/branches/stash, a sibling
worktree, the check on the patch tree, a task starting with `-`, Latin-1 content, malformed events, `--link
.venv/`, setup exit codes. The live case needs Ollama and the model. `DELEGATE_TEST_MODEL` picks another one.
