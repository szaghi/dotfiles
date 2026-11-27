---
title: Agents
---

# Agents

Subagent definitions Claude can delegate to in a fresh context. Definitions in `claude/.claude/agents/`, linked to `~/.claude/agents/`; Claude Code discovers them there,
with no entry in `settings.json`.

## The agents

| Agent | Tools | Purpose |
|---|---|---|
| `blog-code-checker` | Read, Bash, Glob, Grep | Checks every code block, command and API claim of a blog post against the real repos under `~/fortran` and `~/python`; returns verified or BLOCKING per claim, with the correct version from the repo. No prose review. |
| `blog-prose-reviewer` | Read, Edit, Skill | Reviews the prose of a post after the code check: removes AI tells, hedging and filler with the `stop-slop` skill, uses `scientific-writing` for technical voice; returns line-level edits. |
| `correctness-reviewer` | Read, Grep, Glob, Bash | Reviews a diff it did not write, after implementation: correctness, precision, memory, MPI, GPU coherence, architecture, never style. Each finding has file:line, a failure scenario and a tier (T0 reasoned, T1 reproduced). It fixes nothing. |

The two blog agents are driven by the `blog` skill.
