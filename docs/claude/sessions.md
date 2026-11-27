---
title: Session commands
---

# Session commands

`bash/.bash/claude_code` defines one shell function per way of starting Claude Code: a model on the personal
subscription, an extra subscription account, a third-party provider or a local model. `~/.bashrc` sources it
on every interactive shell; machine overrides come from `~/.bash/claude_code.local`, sourced at its end.

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
| `claude-local` | Local inference, see [Local models](/claude/local-llm) |

Every function passes its remaining arguments to `claude`, so `claude-opus --resume` works.

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
Measured on 2026-09-15: the catalog endpoint answered in 0.19 s every time, while the same
short completion took a few seconds, then gave no response in 55 s; a request with tools gave no response in
190 s. An interactive agent sends many sequential requests, and one multi-minute stall makes a session
unworkable. Tool calling through the proxy is therefore untested. Keep it for one-off, non-interactive
questions to models too large for the local GPUs; use `claude-local` for daily work.

## Things to know

- `claude-zai` always reads its first argument as the model: `claude-zai --resume` starts a session with model
  `--resume`. Name a model first.
- `claude-plan` uses the `opusplan` model alias: Opus while in plan mode, Sonnet once you leave it.
- The status line shows the account name and its login for subscription sessions, and nothing for proxied
  or local backends (any `ANTHROPIC_BASE_URL` other than api.anthropic.com).
