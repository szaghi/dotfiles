---
title: Executors
---

# Executors

The models and harnesses `delegate` can hand a task to: what each costs, where the code goes, and how to set
each one up. How they compare is on [Executor benchmarks](/claude/executor-benchmarks).

## Models

Defined in `pi/.pi/agent/models.json` (adam only, through `machines/adam`). Only that file is tracked: pi
rewrites `settings.json`, and `auth.json` holds keys.

| Provider/model | Engine | Cost, data | Notes |
|---|---|---|---|
| `ollama/qwen3.8-unsloth:27b-ud-q4_K_XL` (default) | Ollama, loads on demand | free; stays on adam | Imported with `claude/.claude/skills/delegate/ollama/Modelfile.qwen3.8-27b`; `thinkingLevelMap` maps `off` to `reasoning_effort: "none"`, without which Ollama thinks despite `--thinking off` |
| `ollama/qwen3-coder-unsloth:30b-a3b-q4_K_M` | Ollama, loads on demand | free; stays on adam | Former default; imported with `Modelfile.qwen3-coder-30b-a3b` (recipe inside) |
| `llamacpp/llama` | llama.cpp on `:8080` | free; stays on adam | Serves whatever GGUF `llm-local-server start --backend llama --model … --ctx 32k` loaded |
| `ikllama/ikllama` | ik_llama.cpp on `:8081` | free; stays on adam | Same, `--backend ikllama` |
| `opencode-go/deepseek-v4.1-flash` | OpenCode Go (cloud) | $0.15 / $0.60 per M tokens in / out, doubled on weekdays 01-04 and 06-10 UTC; zero data retention, no training | Built into pi ≥ 1.6, not in `models.json`; the fastest executor measured |
| `opencode-go/qwen3.7-plus` | OpenCode Go (cloud) | $0.40 / $1.60 | Benchmarked only (below) |
| `opencode-go/kimi-k2.7-code` | OpenCode Go (cloud) | $0.95 / $4.00 | Benchmarked only (below) |

Every `opencode-go/*` call is billed against the Go plan's monthly allowance, not free: the prices and the
data-policy flags come from the provider's model metadata (`cost`, `zdr`, `training`), checked 2026-11-27. A
hard bench task costs DeepSeek well under a cent; the paper ingestion below, about 107k input and 49k output
tokens, about $0.05 (twice that in the peak windows). The OpenCode Zen models marked *free* (e.g.
`nemotron-3.5-super-vl-free`) cost nothing but work only inside the opencode agent, which logs in with OAuth:
through the API, and so through pi, they answer HTTP 429 `FreeUsageLimitError`; `--harness opencode` reaches
them. Their metadata states no retention or training policy: treat them as public.

For the two llama-server engines the model id is only the server's alias, so `delegate` reads `/props` and puts
the real GGUF and the per-slot context in the result's `server` block. A stopped server is `backend_down` with the
start command; a server still loading (HTTP 503) is waited for up to `--server-wait`.

`contextWindow` must match the context the engine allocated: `ollama ps` (column CONTEXT) for Ollama, the `--ctx`
the server was started with for the others. Ollama truncates silently; llama-server rejects the request. `delegate`
warns when `contextWindow` exceeds a llama-server's `n_ctx`.

## Local servers

The local engines of [Local models](/claude/local-llm) serve the pi
executor too: providers `ollama`,
`llamacpp` (`:8080`) and `ikllama` (`:8081`) in `pi/.pi/agent/models.json`. Ollama loads the model on demand;
the other two serve whatever GGUF was started, so start them with a context that matches `contextWindow`:

```bash
llm-local-server start --backend ikllama --model ~/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --ctx 32k \
  -- --temp 0.7 --top-p 0.8 --top-k 20 --repeat-penalty 1.05
```

To run the same model on Ollama and on the llama.cpp engines, start from a standard GGUF and import it into
Ollama with a Modelfile (as the default executor was, from `claude/.claude/skills/delegate/ollama/`). A model
pulled from Ollama's own library may not load in llama.cpp: Ollama's former `qwen3.8:27b` blob failed with
`missing tensor 'blk.64.ssm_conv1d.weight'`, because Ollama keeps its own tensor layout for that hybrid
architecture.

## OpenCode Go

pi ≥ 1.6 ships an `opencode-go` provider (the OpenCode Go subscription), so nothing goes in `models.json`.

1. Create a key in the [OpenCode Console](https://opencode.ai/console): account menu → **Account** → **Personal
   API keys** → **Add API key**, in the workspace that has the Go plan. It starts `oc_sk_` and is shown once. The
   opencode agent's own login is OAuth (short-lived tokens in `~/.local/share/opencode/opencode.db`), not a key,
   so there is nothing to copy from it.
2. In a terminal, not through Claude Code (the key would land in the transcript): `pi`, then `/login`, choose
   OpenCode Go and paste the key. pi stores it in `~/.pi/agent/auth.json` (0600, untracked). `OPENCODE_API_KEY`
   works too.
3. `pi --list-models opencode-go` lists the plan's models; `delegate --model opencode-go/<id> …` runs one.

pi 0.80 knew an older Go endpoint (`/zen/go/v1`, without the session header Go now requires); 1.6 works, and
`delegate`'s offline and live tests pass on it. `--offline` and `-ne` do not block the cloud provider.

## opencode harness

`delegate --harness opencode --model <provider>/<id> …` runs `opencode run --standalone --format json --auto`
in the clone instead of pi: a private server for the run, permissions auto-approved (a headless run cannot
answer a prompt), and the prompt (preamble, then the task; opencode has no system-prompt option) on stdin with
no message argument. The environment keeps it from loading `~/.claude` instructions and skills
(`OPENCODE_DISABLE_CLAUDE_CODE`), from updating itself, and from copying the clone into its own snapshot store
(`"snapshot": false`); `webfetch` and `websearch` are denied, as pi has no web tool. Models and
credentials are opencode's own (`opencode models`, `opencode auth login`), not pi's `models.json`, so there
is no Ollama warm-up or llama-server pre-flight. The JSON result has the same shape plus `harness`. Its stderr is
`opencode.err`, the prompt it was sent `prompt.md`.

- **No default model.** An opencode model id is a cloud model unless you configured otherwise; code must not
  leave the machine because a flag was forgotten. `--thinking` and `--tools` are refused; pick a reasoning
  variant with `#variant`.
- **`PWD` matters.** opencode takes its project directory from `$PWD`, not from the process's working
  directory. Before the fix, a run started from the real repository edited the real repository: `Popen(cwd=)`
  leaves `PWD` stale. `delegate` now sets `PWD` to the clone for every harness and for the check; an offline
  test reads the environment the fake opencode was given and fails on a stale value.
- **Never pass the prompt as an argument.** opencode 2.1 sends the text after `--` twice and wraps every
  argument containing a space in quotes, escaping each `"` inside it as `\"`. The first version of this harness
  did that: every task reached the model doubled, and with its quoted strings altered (found by the correctness
  review in opencode's own session store). Stdin is passed through unchanged; the fake opencode in the tests
  refuses any message argument and compares stdin byte for byte.
- **Weaker end-of-run signal than pi.** opencode has no end event and, once the session is idle, drops
  everything but the final text, so the last step's `step_finish` never arrives. `finished` therefore means exit
  0, at least one step and no `error` event; `stop_reason` is null unless an `error` event names it; `usage` is a
  lower bound. Provider failures (bad model, a 429 quota) arrive as an `error` event with exit 1 and become
  `status: error` with the provider's message.
- opencode records each run as a session in `~/.local/share/opencode/opencode.db` (pi runs with
  `--no-session`), and registers the repository as a project keyed by its root commit.
