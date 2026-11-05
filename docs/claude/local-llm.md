---
title: Local LLM servers
---

# Local LLM servers

`claude-local` runs Claude Code against a model served on the local GPUs, so prompts and code never leave the
machine. `llm-local-server` manages the servers behind it. Both are defined in `bash/.bash/claude_code`, with
per-host settings in `~/.bash/claude_code.local`.

## Backends

| Backend | Engine | Address | Health probe | Log |
|---|---|---|---|---|
| `ollama` (default) | `ollama serve` | `127.0.0.1:11434` | `/api/tags` | `/tmp/ollama.log` |
| `llama` | mainline llama.cpp `llama-server` | `127.0.0.1:8080` | `/health` | `/tmp/llama-server.log` |
| `ikllama` | ik_llama.cpp `llama-server` | `127.0.0.1:8081` | `/health` | `/tmp/ikllama-server.log` |
| `nvidia` | `nvd-claude-nim` proxy to build.nvidia.com | `127.0.0.1:8787` | `/healthz` | `/tmp/nvidia-proxy.log` |

ik_llama.cpp is a llama.cpp fork with CPU/hybrid optimisations and extra quant types (IQ4_KS, IQ2_KS). It wins
on MoE models that spill to RAM. It loses on dense models with sliding-window attention (Gemma class) at tight
VRAM: mainline has the iSWA KV cache and automatic layer fitting across GPUs, so the same GGUF can fit on
`llama` and run out of memory on `ikllama`.

The `nvidia` backend is a translation proxy for a cloud catalog, not a local engine; see
[Accounts and providers](/claude/wrappers#nvidia-parked).

## claude-local

```bash
claude-local                                 # ollama, $OLLAMA_DEFAULT_MODEL
claude-local --backend llama                 # llama.cpp, picks a GGUF interactively
claude-local --backend ikllama --ctx 32k
claude-local --model qwen3-coder:latest --gpus 1
claude-local --no-autostop -- --resume       # keep the server, pass --resume to claude
```

| Flag | Effect |
|---|---|
| `--backend ollama\|llama\|ikllama\|nvidia` | Engine (default `$LOCAL_DEFAULT_BACKEND`, `ollama`) |
| `--model NAME` | Ollama model name, or GGUF path/alias for llama/ikllama, or NVIDIA model id |
| `--ctx N\|32k\|64k\|128k` | Context size, applied when llama/ikllama is started. Ollama ignores it: use `ollama-create` |
| `--gpus 1\|2\|all` | GPUs for Ollama (default `all`) |
| `--no-autostart` | Do not start a server; fail if it is not running |
| `--no-autostop` | Leave the server running after Claude exits |
| `--` | Everything after it goes to `claude` |

Unknown arguments are passed to `claude` as well.

What one call does:

1. Probes all three local engines.
2. Stops every local engine other than the requested one, to free VRAM. The `nvidia` proxy is exempt: it holds
   no VRAM, so it neither evicts nor is evicted.
3. Starts the requested backend if it is not up (skipped with `--no-autostart`).
4. Runs `claude --model <m>` with `ANTHROPIC_BASE_URL` pointing at the server. The model defaults to
   `$OLLAMA_DEFAULT_MODEL` for ollama, to the server alias `llama` / `ikllama` for the llama.cpp family (the GGUF
   was chosen at start), and to `$NVIDIA_DEFAULT_MODEL` for nvidia.
5. Stops the backend when Claude exits (skipped with `--no-autostop`).

A server that is already running is reused as is: `--model` and `--ctx` take effect only when the server is
started. Restart it to change model.

## llm-local-server

```bash
llm-local-server start   --backend llama --ctx 128k
llm-local-server start   --backend ollama --gpus 1
llm-local-server stop    --backend ikllama
llm-local-server restart --backend llama
llm-local-server status                       # all four backends + nvidia-smi
llm-local-server status  --backend nvidia     # one backend
```

| Command | Options |
|---|---|
| `start` | `--backend`, `--model`, `--ctx`, `--gpus` (Ollama only); further arguments, or arguments after `--`, go to the server binary |
| `stop` | `--backend` |
| `restart` | `--backend`, plus start arguments; stop, wait 1 s, start |
| `status` | `--backend` to narrow to one; without it, all four plus a `nvidia-smi` GPU summary |

The backend is always a flag. `llm-local-server start llama` stops with
`backend must be given as "--backend llama", not positionally`.

Start details:

- **ollama**: `--gpus all` or `2` uses every GPU; `--gpus 1` sets `CUDA_VISIBLE_DEVICES` to `$OLLAMA_GPU_UUID`,
  else `$OLLAMA_GPU_ID`, else `0`; any other value is passed to `CUDA_VISIBLE_DEVICES` as is.
- **llama / ikllama**: runs `$LLAMACPP_BIN` / `$IKLLAMA_BIN` with `--alias <backend> --n-gpu-layers
  --ctx-size --flash-attn on --jinja`. Without `--model` on a terminal it shows a numbered picker of the GGUFs and
  aliases in the models directory, with the default as the Enter choice. A model resolves as a path, then
  `<models dir>/<name>`, then `<models dir>/<name>.gguf`. `stop` finds the process by its `--alias`, so the two
  forks can run side by side.
- **nvidia**: bootstraps the proxy venv on first use and needs an API key.

The start waits for the health probe to return 200: 60 s for ollama and nvidia, 120 s for the llama.cpp family.
It aborts early when the log tail shows a terminal failure (out of memory, `cudaMalloc failed`,
`unable to load model`, `GGML_ASSERT`, a Python traceback, `address already in use`, 401/403), and prints the
matching lines.

## Model utilities

### Ollama

| Command | Does |
|---|---|
| `ollama-pull [model]` | `ollama pull`, default `$OLLAMA_DEFAULT_MODEL` |
| `ollama-create [--ctx N] [model]` | Creates `<model>-32k`/`-64k`/`-128k` with `num_ctx` set (default 64k) |
| `ollama-models` | `ollama list` grouped by suffix: cloud, embedding, plan, exec, misc |
| `ollama-rename <old> <new>` | Re-creates the model from its Modelfile under the new name, then removes the old one |
| `ollama-rm <model>...` | Removes models; asks for confirmation when more than one is given |

### llama.cpp and ik_llama.cpp

Both read `$LLAMACPP_MODELS_DIR` (default `~/models`).

| Command | Does |
|---|---|
| `llama-models [--paths\|--raw]` | GGUFs in the models dir and the HuggingFace cache, grouped by basename and sorted by quant |
| `llama-alias <name> <path>` | Symlink `<name>` in the models dir to a GGUF |
| `llama-alias <name> <substr>...` | Same, to the unique GGUF matching every substring (case-insensitive) |
| `llama-alias <name>` | Remove the alias |
| `llama-rm <substr>... \| <path>` | Delete a GGUF and the aliases pointing at it; a file in the HF cache removes the whole repo revision (`hf cache rm`) |
| `llama-info [model]` | GGUF metadata and tensor-type summary |

### HuggingFace

The `hf-*` tools need the `hf` CLI (`huggingface_hub` 0.34 or newer). When `hf` is not logged in they log in
from `HF_TOKEN`, `HUGGING_FACE_HUB_TOKEN` or `~/.huggingface-token`.

| Command | Does |
|---|---|
| `hf-search <query> [--all] [--author NAME] [--limit N] [--raw]` | Search repos, GGUF-filtered unless `--all` |
| `hf-files <repo> [--all]` | List the files of a repo, GGUFs first |
| `hf-pick <repo>` | Pick a GGUF from a repo interactively and pull it |
| `hf-pull <repo> [file...]` | Download a repo or some files into `$LLAMACPP_MODELS_DIR` |
| `hf-test <repo> [file]` | Pull, alias as the repo basename, start `ikllama`, send a one-token prompt, stop |

## Machine overrides

`~/.bash/claude_code.local` is sourced at the end of `claude_code`, so it can override any variable. Each host
ships its own copy in its machine package (`bash-adam/.bash/claude_code.local`, `bash-quark/...`,
`bash-astrobit/...`, see [Per-host packages](/packages/host-specific)). The full variable list is in the
[environment reference](/claude/wrappers#environment-reference). An excerpt in the style of adam's file:

```bash
# GPU for `--gpus 1` (nvidia-smi -L)
export OLLAMA_GPU_ID="1"
export OLLAMA_FLASH_ATTENTION="1"       # needed for KV-cache quantisation
export OLLAMA_KV_CACHE_TYPE="q8_0"

OLLAMA_DEFAULT_MODEL="qwen3-coder:latest"

# prefer a local CUDA build over a system llama-server
[[ -x "$HOME/llama.cpp-cuda/build/bin/llama-server" ]] && LLAMACPP_BIN="$HOME/llama.cpp-cuda/build/bin/llama-server"
[[ -x "$HOME/ik_llama.cpp/build/bin/llama-server" ]]   && IKLLAMA_BIN="$HOME/ik_llama.cpp/build/bin/llama-server"

IKLLAMA_DEFAULT_MODEL="$HOME/models/Qwen2.5-Coder-14B-Instruct-Q5_K_M.gguf"
IKLLAMA_CTX=32768
```

## Things to know

- Only one local engine runs at a time when you go through `claude-local`. `llm-local-server start` does not
  evict: two engines started by hand both stay up.
- `--gpus all` and `--gpus 2` are the same: the code assumes two GPUs and reports `2` to the status line.
- Ollama runs in user mode (`ollama serve` in the background, logging to `/tmp/ollama.log`), not as a systemd
  service. `stop` uses `pkill -f "ollama serve"`.
- A GGUF in the HuggingFace cache cannot be passed by name: create an alias with `llama-alias` first. The
  interactive picker lists only the models directory for that reason.
- Qwen3.5 hybrid SSM models have no CUDA kernel for their Mamba layers in ik_llama.cpp and fall back to CPU
  without warning (note in adam's `claude_code.local`).
- `scripts/.scripts/llama-anthropic-proxy.py` is a standalone Anthropic-to-OpenAI proxy (default port 4000,
  backend `127.0.0.1:8080`). No function in `claude_code` starts it; llama-server is used directly.
