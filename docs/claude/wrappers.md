---
title: Accounts and providers
---

# Accounts and providers

`bash/.bash/claude_code` defines one shell function per way of starting Claude Code: a model on the personal
subscription, an extra subscription account, or a third-party provider. `~/.bashrc` sources it on every
interactive shell; machine overrides come from `~/.bash/claude_code.local`, sourced at its end. Local inference
backends are on their own page, [Local LLM servers](/claude/local-llm).

## Quick reference

```bash
claude-help                 # prints the full quick reference
```

| Command | Runs |
|---|---|
| `claude` | Personal subscription, default model (`opus[1m]` from `settings.json`) |
| `claude-sonnet` | `claude --model sonnet` |
| `claude-opus` | `claude --model opus` |
| `claude-plan` | `claude --permission-mode plan --model opusplan` |
| `claude-iac` | IAC institute team, shared seat, config in `~/.claude-iac` |
| `claude-cfd-cnr` | IAC CNR CFD HPC team, `cnr.it` seat, config in `~/.claude-cfd-cnr` |
| `claude-cfd-iac` | IAC CNR CFD HPC team, `iac.cnr.it` seat, config in `~/.claude-cfd-iac` |
| `claude-soma` | SOMA srl, config in `~/.claude-soma` |
| `claude-zai [model]` | Z.ai GLM models through its Anthropic-compatible endpoint |
| `claude-zai-fast`, `-turbo`, `-premium` | `claude-zai` with `glm-4.5-air`, `glm-5-turbo`, `glm-5.1` |
| `claude-nvidia [model]` | NVIDIA hosted catalog through a local translation proxy (parked) |
| `nvidia-models [filter]` | Model ids served by the NVIDIA catalog |
| `claude-local` | Local inference, see [Local LLM servers](/claude/local-llm) |

Every function passes its remaining arguments to `claude`, so `claude-opus --resume` works.

## Subscription accounts

Each extra account runs Claude Code with `CLAUDE_CONFIG_DIR` set to its own directory. Login state never
collides with `~/.claude`, while everything account-agnostic is shared through symlinks (list in the
[Overview](/claude/#accounts-share-one-setup)).

```bash
claude-cfd-iac login            # first use: authenticate this config dir
claude-cfd-iac login --no-sso   # same, for a plain subscription without SSO
claude-cfd-iac status           # which account the config dir is logged into
claude-cfd-iac logout
claude-cfd-iac                  # a session on that account
claude-cfd-iac --resume         # any other argument goes to claude
```

The same subcommands exist for `claude-iac`, `claude-cfd-cnr` and `claude-soma`. All four go through
`_claude_account`:

| Argument | Runs |
|---|---|
| `login [--no-sso] [args]` | `claude auth login --email <EMAIL> --sso`, with `--email` only when the account's email variable is set |
| `status [args]` | `claude auth status --text` |
| `logout [args]` | `claude auth logout` |
| anything else | `claude "$@"` |

Before any of these, `_claude_account_bootstrap` creates the directory and links `CLAUDE.md`,
`CLAUDE-fortran.md`, `CLAUDE-gpu.md`, `RTK.md`, `commands`, `skills`, `agents`, `hooks`, `plugins`,
`projects`, `settings.json`, `settings.local.json` and `statusline-command.sh` from `~/.claude`. An item
already present there as a real file or directory is reported and left alone: merge it by hand, remove it,
re-run.

::: warning Log in from a clean browser
The OAuth page reuses the Claude session your browser already holds, so a plain login binds the personal
account. `login` pre-fills the email and forces SSO, and prints a reminder: open the URL in an incognito window
or a browser profile not signed into the personal claude.ai.
:::

Set the four email variables in `~/.bash/claude_code.local` (it is per host and lives in the host's
`bash-<host>` package):

```bash
CLAUDE_IAC_EMAIL="..."
CLAUDE_CFD_CNR_EMAIL="..."
CLAUDE_CFD_IAC_EMAIL="..."
CLAUDE_SOMA_EMAIL="..."
```

### Renamed accounts

On 2026-10-14 `claude-cnr` became `claude-cfd-cnr` and `claude-cnr-iac` became `claude-cfd-iac`.

- The old names are kept as functions that print the new name and return 1. They are never aliases, so they
  cannot start a session on another account.
- The first run of a new name moves the old directory (`~/.claude-cnr`, `~/.claude-cnr-iac`) to the new path
  and leaves a symlink at the old one, so sessions started before the rename keep writing to the same files.
- If both the old and the new directory exist as real directories, the wrapper refuses: keep the logged-in one,
  remove the other, re-run.
- `~/.claude-science` belongs to another tool and is not an account directory.

## Z.ai

```bash
claude-zai                       # glm-5-turbo
claude-zai glm-5.1 --resume      # model first, then claude arguments
claude-zai-fast                  # glm-4.5-air
```

`claude-zai` sets `ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic`, puts the key in
`ANTHROPIC_AUTH_TOKEN` and blanks `ANTHROPIC_API_KEY`. The key comes from `ZAI_API_KEY`, else from
`~/.z-ai-key`; with neither it stops with an error.

## NVIDIA (parked)

The hosted catalog at build.nvidia.com speaks only the OpenAI API (`/v1/messages` returns 404), so
`claude-nvidia` runs through a local Anthropic-to-OpenAI proxy, `nvd-claude-nim`, managed as the `nvidia`
backend of `llm-local-server` on port 8787. `claude-nvidia` is a thin call to
`claude-local --backend nvidia`.

```bash
claude-nvidia                                  # $NVIDIA_DEFAULT_MODEL
claude-nvidia deepseek-ai/deepseek-v4-flash-0731
claude-nvidia --model <id> -- --resume         # explicit form
claude-nvidia --no-autostop                    # leave the proxy running
nvidia-models deepseek                         # list served ids matching "deepseek"
```

| Flag | Effect |
|---|---|
| `--model ID` or first positional | Model id (default `deepseek-ai/deepseek-v4-flash-0731`) |
| `--no-autostop` | Keep the proxy running after Claude exits |
| `--` | Everything after it goes to `claude` |
| other `-x` flags | Passed to `claude` |

The key comes from `NVIDIA_API_KEY`, else from `~/.nvidia-api-key`. On first use the proxy installs itself into
a venv at `~/.local/share/claude-nvidia-proxy`. Claude Code talks to the proxy with a dummy
`ANTHROPIC_AUTH_TOKEN` and a blank `ANTHROPIC_API_KEY`; only the proxy holds the NVIDIA key.

**Why parked.** The harness works end to end; the blocker is latency on NVIDIA's shared NVCF capacity.
Measured on 2026-09-15 (README, "Latency"): the catalog endpoint answered in 0.19 s every time, while the same
short completion took a few seconds, then gave no response in 55 s; a request with tools gave no response in
190 s. An interactive agent sends many sequential requests, and one multi-minute stall makes a session
unworkable. Tool calling through the proxy is therefore untested. Keep it for one-off, non-interactive
questions to models too large for the local GPUs; use `claude-local` for daily work.

## Environment reference

Every variable `bash/.bash/claude_code` reads or sets. Assignments written `${VAR:-default}` also take a value
exported before the file is sourced; every variable can be overridden in `~/.bash/claude_code.local`, which is
sourced last.

### Accounts and cloud providers

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
| `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY` | set per call | Set by `claude-zai`, `claude-nvidia` and `claude-local` for the `claude` process only |

### NVIDIA proxy

| Variable | Default | Role |
|---|---|---|
| `NVIDIA_API_KEY` | `~/.nvidia-api-key` | Catalog key, handed to the proxy |
| `NVIDIA_PROXY_VENV` | `~/.local/share/claude-nvidia-proxy` | Proxy venv |
| `NVIDIA_PROXY_HOST` | `127.0.0.1` | Proxy address |
| `NVIDIA_PROXY_PORT` | `8787` | Proxy port |
| `NVIDIA_DEFAULT_MODEL` | `deepseek-ai/deepseek-v4-flash-0731` | Default model |
| `NVIDIA_PROXY_HEALTH_PATH` | `/healthz` | Liveness probe of the proxy |
| `PROXY_HOST`, `PROXY_PORT`, `DEFAULT_NVIDIA_MODEL` | from the above | Set for the proxy process only |

### Local inference

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
(`source ~/.bash/claude_code_cluster`); `~/.bashrc` does not load it. It installs Node and Ollama models under a
scratch directory, and defines `claude-local [model] [args]` against an Ollama you start yourself
(`ollama-start`, `ollama-stop`, `ollama-status`, `ollama-models`) plus its own `claude-help`. GPU allocation is
left to the scheduler.

## Things to know

- `claude-zai` always reads its first argument as the model: `claude-zai --resume` starts a session with model
  `--resume`. Name a model first.
- `claude-plan` uses the `opusplan` model alias: Opus while in plan mode, Sonnet once you leave it.
- The status line shows the account name and its login for subscription sessions, and nothing for proxied
  or local backends (any `ANTHROPIC_BASE_URL` other than api.anthropic.com).
- `claude-help` reports `IKLLAMA_GPU_LAYERS` as defaulting to `-1`; the source sets `99`. Trust the source.
