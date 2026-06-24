---
name: blog
description: >
  Write and review technical developer blog posts as version-controlled
  markdown. Use this skill when the user wants to draft, write, or review a
  blog post / dev write-up / release note / tutorial about their code —
  typically HPC, Fortran, Python, or scientific-computing work. Orchestrates a
  draft pass and two verification agents: blog-code-checker (verifies every
  code block, command, and API claim against the real repos under ~/fortran and
  ~/python) and blog-prose-reviewer (strips AI tells and enforces technical
  voice). Output is a single markdown file under ./posts/ with minimal YAML
  frontmatter. Trigger on "/blog", "write a blog post", "draft a post about
  <repo/feature>", or "review this post". Do NOT trigger for academic
  manuscripts — use scientific-writing for those.
allowed-tools: Read Write Edit Bash Glob Grep Agent Skill
license: MIT license
---

# blog — technical dev-post writer

A small orchestrator for technical blog posts. The unit of value is a
**code-accurate** post: fluent prose is cheap, prose whose code blocks compile
and whose API claims match the actual repo is not. The two agents exist for
that reason, not for SEO.

## Scope

- **In scope**: dev write-ups, release notes, design notes, tutorials,
  build/tooling walkthroughs about the user's own code (Fortran/Python/HPC).
- **Out of scope**: academic papers/manuscripts (→ `scientific-writing`),
  marketing/SEO content (not a goal of this skill — do not optimize for
  rankings or keyword density).

## Commands

| Command | Action |
|---|---|
| `/blog draft <topic>` | Draft a new post → `./posts/<slug>.md`, then run both review agents |
| `/blog review <file>` | Run both review agents over an existing post, apply fixes |
| `/blog check <file>` | Run **only** the code-checker over an existing post |

`<topic>` is free text; `<file>` is a path to an existing `.md`. Output and
edits always land in `./posts/` relative to the current working directory.

## Draft pipeline

1. **Locate the subject code.** If the topic names a repo or feature
   (e.g. "PENF kind handling", "a FoBiS multi-mode build"), resolve the repo
   under `~/fortran/` or `~/python/` per the user's global conventions:
   `ls ~/fortran` / `ls ~/python`, then Glob/Grep by name. **Never guess a
   path.** If it can't be resolved unambiguously, ask before drafting — a post
   built on the wrong file is worse than a delayed one.
2. **Read before writing.** Read the actual source for any symbol, command,
   build mode, or output you intend to show. Do not reconstruct code from
   memory — copy it from the repo.
3. **Draft** into `./posts/<slug>.md` using `templates/post.md` for the
   frontmatter + skeleton, and `references/structure.md` for section shape and
   `references/style.md` for voice. `mkdir -p ./posts` first.
4. **Verify code** — delegate to the `blog-code-checker` agent (see below).
   Apply every BLOCKING finding before continuing. A code block that doesn't
   compile or a command that doesn't exist is a hard stop, not a footnote.
5. **Review prose** — delegate to the `blog-prose-reviewer` agent. Apply its
   findings.
6. **Report** the final path and a one-line summary of what each agent changed.

## Delegating to the agents

Use the `Agent` tool with the matching agent type. Pass the post's path and the
repo paths you used so the checker knows what to verify against:

- `blog-code-checker` — give it the post path and the resolved repo path(s).
  It returns a verdict list: each code block / command / API claim marked
  `verified` or `BLOCKING` with the discrepancy and a corrected version.
- `blog-prose-reviewer` — give it the post path. It invokes the `stop-slop`
  skill and, for technical-voice questions, `scientific-writing`, then returns
  concrete edits.

Run them in **either order for `/blog review`**, but for `/blog draft` always
run the code-checker **first** — there's no point polishing prose around a code
block that's about to be rewritten.

## Rules

- One post = one markdown file under `./posts/`. No HTML, no SEO sidecar files,
  no schema markup.
- Minimal frontmatter only (see template). Don't invent fields.
- Code blocks are copied from the repo, never paraphrased. If you must
  abbreviate, mark the elision explicitly (`! ...`) and say so in prose.
- The skill orchestrates; the *verification* lives in the agents. Don't inline
  the code-check — delegate it, so the post and its audit stay separable.
