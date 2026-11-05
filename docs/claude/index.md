---
title: Claude Code
---

# Claude Code

The `claude` package holds the whole Claude Code configuration: global instructions, settings, hooks, agents,
slash commands, skills and the status line. Stow links it into `~/.claude`, so every machine and every account
runs the same setup. The shell wrappers that start Claude Code on different accounts and backends live in the
[bash](/packages/bash) package, in `bash/.bash/claude_code`.

## What the package holds

Source: `claude/.claude/`, deployed to `~/.claude/`.

| Path | Content |
|---|---|
| `CLAUDE.md` | Global instructions, loaded into every session |
| `CLAUDE-fortran.md` | Fortran rules: source files, kinds, modern syntax, OOP, `pure`, module wiring, I/O, OpenMP |
| `CLAUDE-gpu.md` | GPU rules: OpenACC directives, device variables, GPU/MPI coherence, FP64 trap, compiler pitfalls |
| `settings.json` | Permissions, default model, hooks, status line, enabled plugins, marketplaces |
| `settings.local.json` | Extra allow-list of WebFetch domains and Bash commands (tracked) |
| `statusline-command.sh` | The status line, see [Hooks, agents, status line](/claude/hooks#status-line) |
| `commands/` | Custom slash commands, see [Slash commands](/claude/commands) |
| `skills/` | Class-A skills, `manifest.toml`, `README.md`, see [Skills](/claude/skills) |
| `agents/` | Subagents, see [Hooks, agents, status line](/claude/hooks#agents) |
| `hooks/` | Hook scripts, see [Hooks, agents, status line](/claude/hooks) |

`CLAUDE-fortran.md` and `CLAUDE-gpu.md` are not loaded globally. The `load-context-by-cwd.sh` hook injects both
only when the session's project lives under `~/fortran`.

## Deploy

```bash
bash ~/dotfiles/dotify.sh claude
```

Before stowing `claude`, `dotify.sh` checks `~/.claude/settings.json` for drift (see below). Skills of class B
and C need a second step, `skills-apply install`: see [Skills](/claude/skills).

## settings.json drift

Claude Code rewrites `settings.json` (on `/model`, on plugin toggles) by replacing the file. The stow symlink
becomes a plain file and stow aborts with "existing target is neither a link nor a directory". `dotify.sh`
(`check_drift`) handles it before stowing:

| State of `~/.claude/settings.json` | Action |
|---|---|
| Symlink into the repo | Nothing |
| Plain file, identical to the dotfile | Removed and re-linked (prints `drift: ... re-linking`) |
| Plain file, different from the dotfile | Prints the `diff -u`, the two commands below, and exits 1 |

The dotfile is the source of truth. `dotify.sh` never overwrites it, since it can hold uncommitted edits.

```bash
# keep the live changes
cp ~/.claude/settings.json ~/dotfiles/claude/.claude/settings.json && rm ~/.claude/settings.json && bash ~/dotfiles/dotify.sh claude
# discard them
rm ~/.claude/settings.json && bash ~/dotfiles/dotify.sh claude
```

The check skips the file when its real path is inside the repo: on a host where stow folded `~/.claude` into a
single directory link, the "live" file is the tracked one, and removing it would delete it from the repo.

## Secrets

`.gitignore` excludes `claude/.claude/.credentials.json` (the OAuth login) and `claude/.claude/.env`. API keys
for third-party providers are read from files in `$HOME` (`~/.z-ai-key`, `~/.nvidia-api-key`,
`~/.huggingface-token`) or from the environment, never from the repo. See [Accounts and providers](/claude/wrappers).

## Accounts share one setup

The extra subscription accounts (`claude-iac`, `claude-cfd-cnr`, `claude-cfd-iac`, `claude-soma`) each run with
their own `CLAUDE_CONFIG_DIR` (`~/.claude-iac`, `~/.claude-cfd-cnr`, `~/.claude-cfd-iac`, `~/.claude-soma`). On
every call the wrapper links the shareable parts of `~/.claude` into that directory:

| Shared (symlink to `~/.claude`) | Per account |
|---|---|
| `CLAUDE.md`, `CLAUDE-fortran.md`, `CLAUDE-gpu.md`, `RTK.md` | `.credentials.json` |
| `commands`, `skills`, `agents`, `hooks`, `plugins` | `.claude.json` (OAuth identity) |
| `settings.json`, `settings.local.json`, `statusline-command.sh` | `history.jsonl` and the client's other state |
| `projects` (auto-memory and transcripts) | |

Because `projects/` is shared, `claude-cfd-cnr --resume` resumes a session started with plain `claude`.
Details: [Accounts and providers](/claude/wrappers#subscription-accounts).

## What the global CLAUDE.md instructs

`claude/.claude/CLAUDE.md` is short on purpose and delegates detail to the two topic files and to skills.
Read the file itself; this is the map.

| Section | Instruction in one line |
|---|---|
| Interaction Style | Analytic peer: unhedged honesty, challenge premises, steel-man before disagreeing, propose a better alternative. Review order: correctness, numerics, memory, MPI, GPU, architecture, portability; no style nits. |
| Repository Layout | Fortran repos in `~/fortran/`, Python in `~/python/`; verify a path with `ls` before using it. |
| Build System | FoBiS (`fobis`, 3.8+) with double-dash flags; no make/cmake unless asked; `fobis fetch`, not submodules. |
| Toolchains | nvfortran 26.9 and gfortran 16.2.0 + Open MPI 5.0.11; build clean after a compiler switch; cluster and WSL environment recipes. |
| CI/CD | Minimal workflow changes; no repo names hardcoded in reusable actions. |
| Documentation | VitePress, modelled on `~/fortran/StringiFor` or `~/fortran/PENF`. |
| WSL and Windows | `HDF5_USE_FILE_LOCKING=FALSE` for Windows readers of WSL files; map drives from a non-elevated prompt. |
| Fortran, GPU | Load `CLAUDE-fortran.md` / `CLAUDE-gpu.md`; consult the standard skills instead of answering from memory. |
| Verbatim-Edit, Verification | `verbatim-edit` skill for byte-exact edits; `ai-research-verification` skill for agent claims. |
| Commit Messages | Conventional Commits; never an AI `Co-authored-by`; never commit or amend unless asked; `/semantic-commit` only prints the message; no GPG from agents. |
| Python Conventions | Load the `python-conventions` skill before writing Python. |

## Pages in this section

| Page | Covers |
|---|---|
| [Accounts and providers](/claude/wrappers) | `claude-sonnet`, `claude-opus`, `claude-plan`, the account wrappers, `claude-zai`, `claude-nvidia`, `claude-help` |
| [Local LLM servers](/claude/local-llm) | `claude-local`, `llm-local-server`, the ollama/llama.cpp/HuggingFace utilities |
| [Skills](/claude/skills) | The three skill classes, `skills-apply`, the inventory |
| [Slash commands](/claude/commands) | `/semantic-commit`, `/capture-findings` |
| [Hooks, agents, status line](/claude/hooks) | Every registered hook, the subagents, the status line fields |
| [Night protocol](/claude/night-protocol) | Unattended overnight work and the `night` script |

## Things to know

- Hook and status-line commands in `settings.json` use absolute paths under `/home/stefano`. A host with another
  user name needs them edited.
- `settings.json` registers a SessionStart hook, `herdr-agent-state.sh`, that is not in the repo: the herdr
  installer writes it into `~/.claude/hooks/`, which is why that directory is real and its tracked hooks are
  linked file by file.
- After a plugin install or a `/model` change, `ls -l ~/.claude/settings.json` tells whether the file is still a
  link. If it is not, the change sits in the plain file and not in git until `dotify.sh claude` surfaces it.
