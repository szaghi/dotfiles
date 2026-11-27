---
title: Model utilities
---

# Model utilities

Shell functions in `bash/.bash/claude_code` that pull, alias, inspect and remove the models behind
[Local models](/claude/local-llm): Ollama models, GGUF files for llama.cpp and ik_llama.cpp, and HuggingFace
repositories.

## Ollama

| Command | Does |
|---|---|
| `ollama-pull [model]` | `ollama pull`, default `$OLLAMA_DEFAULT_MODEL` |
| `ollama-create [--ctx N] [model]` | Creates `<model>-<label>` with `num_ctx` N (default 64k). The label is the bucket N falls in (`32k`, `64k`, `128k`: `--ctx 40000` gives `-64k` with `num_ctx 40000`); above 131072 it is N itself |
| `ollama-models` | `ollama list` grouped by suffix: cloud, embedding, plan, exec, misc |
| `ollama-rename <old> <new>` | Re-creates the model from its Modelfile under the new name, then removes the old one |
| `ollama-rm <model>...` | Removes models; asks for confirmation when more than one is given |

## llama.cpp and ik_llama.cpp

Both read `$LLAMACPP_MODELS_DIR` (default `~/models`).

| Command | Does |
|---|---|
| `llama-models [--paths\|--raw]` | GGUFs in the models dir and the HuggingFace cache, grouped by basename and sorted by quant |
| `llama-alias <name> <path>` | Symlink `<name>` in the models dir to a GGUF |
| `llama-alias <name> <substr>...` | Same, to the unique GGUF matching every substring (case-insensitive) |
| `llama-alias <name>` | Remove the alias |
| `llama-rm <substr>... \| <path>` | Delete a GGUF and the aliases pointing at it; a file in the HF cache removes the whole repo revision (`hf cache rm`) |
| `llama-info [model]` | GGUF metadata and tensor-type summary |

## HuggingFace

The `hf-*` tools need the `hf` CLI (`huggingface_hub` 0.34 or newer). When `hf` is not logged in they log in
from `HF_TOKEN`, `HUGGING_FACE_HUB_TOKEN` or `~/.huggingface-token`.

| Command | Does |
|---|---|
| `hf-search <query> [--all] [--author NAME] [--limit N] [--raw]` | Search repos, GGUF-filtered unless `--all` |
| `hf-files <repo> [--all]` | List the files of a repo, GGUFs first |
| `hf-pick <repo>` | Pick a GGUF from a repo interactively and pull it |
| `hf-pull <repo> [file...]` | Download a repo or some files into `$LLAMACPP_MODELS_DIR`: a single `.gguf` lands flat in it, anything else in `<models dir>/<repo basename>/` |
| `hf-test <repo> [file]` | Pull, alias as the repo basename, start `ikllama`, send a one-token prompt, stop. Without `file` it downloads the whole repo (every quant) and aliases the first GGUF found |

## Machine overrides

`~/.bash/claude_code.local` is sourced at the end of `claude_code`, so it can override any variable. Each host
ships its own copy in its machine package (`bash-adam/.bash/claude_code.local`, `bash-quark/...`,
`bash-astrobit/...`, see [Per-host packages](/packages/host-specific)). The full variable list is in the
[environment reference](/claude/environment). An excerpt in the style of adam's file:

```bash
# GPU for `--gpus 1` (nvidia-smi -L)
export OLLAMA_GPU_ID="1"
export OLLAMA_FLASH_ATTENTION="1"       # needed for KV-cache quantisation
export OLLAMA_KV_CACHE_TYPE="q8_0"

OLLAMA_DEFAULT_MODEL="qwen3-coder-unsloth:30b-a3b-q4_K_M"

# prefer a local CUDA build over a system llama-server
[[ -x "$HOME/llama.cpp-master/build/bin/llama-server" ]] && LLAMACPP_BIN="$HOME/llama.cpp-master/build/bin/llama-server"
[[ -x "$HOME/ik_llama.cpp/build/bin/llama-server" ]]   && IKLLAMA_BIN="$HOME/ik_llama.cpp/build/bin/llama-server"

IKLLAMA_DEFAULT_MODEL="$HOME/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
IKLLAMA_CTX=32768
LLAMACPP_DEFAULT_MODEL="$HOME/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf"
LLAMACPP_CTX=32768                      # plain assignment: ${LLAMACPP_CTX:-...} here would change nothing
```

## Things to know

- A GGUF in the HuggingFace cache cannot be passed by name: create an alias with `llama-alias` first. The
  interactive picker lists only the models directory for that reason.
- Qwen3.5 hybrid SSM models have no CUDA kernel for their Mamba layers in ik_llama.cpp and fall back to CPU
  without warning (note in adam's `claude_code.local`).
- `scripts/.scripts/llama-anthropic-proxy.py` is a standalone Anthropic-to-OpenAI proxy (default port 4000,
  backend `127.0.0.1:8080`). No function in `claude_code` starts it; llama-server is used directly.
