---
title: Claude Code
prev:
  text: Per-host packages
  link: /packages/host-specific
---

# Claude Code

This dotfiles repository carries a complete Claude Code setup. The `claude` package is the configuration itself
(instructions, settings, skills, slash commands, hooks, agents, status line), linked into `~/.claude` and shared
by every account. The `bash` package adds one shell command per way of starting a session: the personal
subscription, four extra subscription accounts, two cloud providers and three local inference engines. On top
of those sit three skill-driven workflows (unattended nights, plans and bugs held in GitHub issues) and
`delegate`, which lets Opus hand mechanical tasks to a cheaper executor model.

The pages follow the order below; the sidebar and the *Next* link at the bottom of each page walk it.

## Quick start

```bash
bash ~/dotfiles/dotify.sh claude     # link ~/.claude (stops if settings.json drifted)
skills-apply install                 # plugins and third-party skills, once per host
claude-help                          # every session command and variable
claude                               # a session on the personal subscription
claude-cfd-cnr login                 # an extra account: log in once, then claude-cfd-cnr
claude-local                         # a session on a local model
```

## Map of the section

**Setup**: what is installed and how it reaches `~/.claude`.

| Page | Covers |
|---|---|
| [The claude package](/claude/package) | What `~/.claude` holds, deploying it, `settings.json` drift, secrets |
| [Global instructions](/claude/instructions) | What the global `CLAUDE.md` instructs, and the Fortran/GPU topic files |

**Starting sessions**: the shell commands of `bash/.bash/claude_code`.

| Page | Covers |
|---|---|
| [Session commands](/claude/sessions) | Every `claude-*` command; the Z.ai and NVIDIA providers |
| [Subscription accounts](/claude/accounts) | `claude-iac`, `claude-cfd-cnr`, `claude-cfd-iac`, `claude-soma`: login, what they share, the rename |
| [Local models](/claude/local-llm) | `claude-local` and `llm-local-server` over Ollama, llama.cpp and ik_llama.cpp |
| [Model utilities](/claude/model-tools) | `ollama-*`, `llama-*` and `hf-*` model tools; per-host overrides |
| [Environment reference](/claude/environment) | Every variable the wrappers read or set; the cluster variant |

**Extending Claude Code**: what the configuration adds to every session.

| Page | Covers |
|---|---|
| [Skills](/claude/skills) | The three skill classes, `skills-apply`, adding a skill, drift |
| [Skills inventory](/claude/skills-inventory) | Every installed skill, by class |
| [Slash commands](/claude/commands) | `/semantic-commit`, `/capture-findings`, the file format |
| [Hooks](/claude/hooks) | Every registered hook and what it enforces |
| [Agents](/claude/agents) | The subagents |
| [Status line](/claude/statusline) | Its fields and the weekly token count |

**Workflows**: longer processes, each a skill plus a script.

| Page | Covers |
|---|---|
| [Night protocol](/claude/night-protocol) | Unattended work, snapshot per step, committed in the morning by `night commit` |
| [Plan issues](/claude/plan-issue) | A step-by-step plan held in a GitHub issue, the `plan-issue` script |
| [Bug issues](/claude/bug-issue) | Investigations, defects, upstream reports and the compiler-bug tracker |

**Delegating to executors**: Opus as orchestrator, a cheaper model as executor.

| Page | Covers |
|---|---|
| [Delegating to an executor](/claude/delegate) | The `delegate` script: use, options, result, guarantees, tests |
| [Executors](/claude/executors) | Models and harnesses (pi, opencode), cost and data policy, setup |
| [Executor benchmarks](/claude/executor-benchmarks) | Engine speed, executor quality, a real paper ingestion |
