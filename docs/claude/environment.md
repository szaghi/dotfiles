---
title: Environment reference
---

# Environment reference

Every variable `bash/.bash/claude_code` reads or sets. Assignments written `${VAR:-default}` also take a value
exported before the file is sourced. Every variable can be overridden in `~/.bash/claude_code.local`, which is
sourced last, but only with a plain assignment (`VAR=value`): by then the base file has already set the
variable, so a `${VAR:-value}` in `.local` changes nothing.

## Accounts and cloud providers

| Variable | Default | Role |
|---|---|---|
| `CLAUDE_IAC_DIR` | `~/.claude-iac` | Config dir of `claude-iac` |
| `CLAUDE_CFD_CNR_DIR` | `~/.claude-cfd-cnr` | Config dir of `claude-cfd-cnr` |
| `CLAUDE_CFD_IAC_DIR` | `~/.claude-cfd-iac` | Config dir of `claude-cfd-iac` |
| `CLAUDE_SOMA_DIR` | `~/.claude-soma` | Config dir of `claude-soma` |
| `CLAUDE_IAC_EMAIL`, `CLAUDE_CFD_CNR_EMAIL`, `CLAUDE_CFD_IAC_EMAIL`, `CLAUDE_SOMA_EMAIL` | empty | Pre-filled `--email` for `login` |
| `CLAUDE_CONFIG_DIR` | set per call | Set by the account wrappers for the `claude` process |
| `ZAI_API_KEY` | `~/.z-ai-key` | Z.ai key |
| `ZAI_DEFAULT_MODEL` | `glm-5-turbo` | Model of `claude-zai` without argument (plain assignment: override in `.local`) |
| `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY` | set per call | For the `claude` process only: all three by `claude-zai` and `claude-nvidia`; `claude-local` sets `ANTHROPIC_BASE_URL`, and the two token variables only for `--backend nvidia` |

## NVIDIA proxy

| Variable | Default | Role |
|---|---|---|
| `NVIDIA_API_KEY` | `~/.nvidia-api-key` | Catalog key, handed to the proxy |
| `NVIDIA_PROXY_VENV` | `~/.local/share/claude-nvidia-proxy` | Proxy venv |
| `NVIDIA_PROXY_HOST` | `127.0.0.1` | Proxy address |
| `NVIDIA_PROXY_PORT` | `8787` | Proxy port |
| `NVIDIA_DEFAULT_MODEL` | `deepseek-ai/deepseek-v4-flash-0731` | Default model |
| `NVIDIA_PROXY_HEALTH_PATH` | `/healthz` | Liveness probe of the proxy |
| `PROXY_HOST`, `PROXY_PORT`, `DEFAULT_NVIDIA_MODEL` | from the above | Set for the proxy process only |

## Local inference

| Variable | Default | Role |
|---|---|---|
| `LOCAL_DEFAULT_BACKEND` | `ollama` | Backend when `--backend` is omitted |
| `OLLAMA_HOST` | `127.0.0.1:11434` | Exported; Ollama address |
| `OLLAMA_KEEP_ALIVE` | `10m` | Exported |
| `OLLAMA_NUM_PARALLEL` | `1` | Exported |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | Exported |
| `OLLAMA_DEFAULT_MODEL` | `qwen2.5-coder:7b` | Default Ollama model (plain assignment: override in `.local`) |
| `OLLAMA_GPU_UUID`, `OLLAMA_GPU_ID` | `0` | GPU for `--gpus 1` (UUID wins over index) |
| `CUDA_VISIBLE_DEVICES` | set per call | Set for `ollama serve` when `--gpus` is not `all`/`2` |
| `CLAUDE_LOCAL_GPUS` | set per call | GPU count shown by the status line |
| `LLAMACPP_BIN` | `llama-server` | llama.cpp server binary |
| `LLAMACPP_HOST` | `127.0.0.1` | Plain assignment: override in `.local` |
| `LLAMACPP_PORT` | `8080` | |
| `LLAMACPP_MODELS_DIR` | `~/models` | GGUF directory, shared with ik_llama.cpp and the `hf-*` tools |
| `LLAMACPP_DEFAULT_MODEL` | empty | Default GGUF path or alias |
| `LLAMACPP_GGUF_PY` | `<llama.cpp tree>/gguf-py` | gguf-py used by `llama-info`, derived from `LLAMACPP_BIN` |
| `LLAMACPP_GPU_LAYERS` | `-1` | `--n-gpu-layers` (all) |
| `LLAMACPP_CTX` | `131072` | `--ctx-size` |
| `IKLLAMA_BIN` | `llama-server` | ik_llama.cpp server binary |
| `IKLLAMA_HOST` | `127.0.0.1` | Plain assignment: override in `.local` |
| `IKLLAMA_PORT` | `8081` | |
| `IKLLAMA_GPU_LAYERS` | `99` | ik_llama.cpp reads `-1` as 0 layers, hence a large sentinel |
| `IKLLAMA_CTX` | `131072` | |
| `IKLLAMA_MODELS_DIR`, `IKLLAMA_DEFAULT_MODEL` | fall back to `LLAMACPP_*` | Resolved at call time |
| `HF_HOME` | `~/.cache/huggingface` | HuggingFace cache scanned by `llama-models` and `llama-rm` |
| `HF_TOKEN`, `HUGGING_FACE_HUB_TOKEN` | `~/.huggingface-token` | Token for the auto-login of the `hf-*` tools |

## HPC clusters

`bash/.bash/claude_code_cluster` is a minimal alternative for cluster nodes, sourced by hand
(`source ~/.bash/claude_code_cluster`); `~/.bashrc` does not load it. It installs nothing: it points `NVM_DIR`,
`PATH` (Node) and `OLLAMA_MODELS` at a hard-coded scratch directory, `/scratch_local/szaghi`, to keep them off the
home quota, and exports Ollama settings (one parallel request, one loaded model, flash attention, `q8_0` KV
cache). It defines `claude-local [model] [args]` (default model `qwen3-coder-next:q8_0`) against an Ollama you
start yourself with `ollama-start` (`ollama-stop`, `ollama-status`, `ollama-models`), plus its own
`claude-help`. GPU allocation is left to the scheduler.

## Things to know

- `claude-help` reports `IKLLAMA_GPU_LAYERS` as defaulting to `-1`; the source sets `99`. Trust the source.
- `claude-help` also omits `nvidia` from the `LOCAL_DEFAULT_BACKEND` values and never mentions `ZAI_API_KEY`.
- `OLLAMA_FLASH_ATTENTION` and `OLLAMA_KV_CACHE_TYPE` are not set by `claude_code`: adam's `.local` and the
  cluster file export them, and `ollama serve` reads them.
