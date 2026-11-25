---
name: plan-issue
description: Write, amend, execute and track a step-by-step implementation plan held in a GitHub issue, the plan's only source of truth. One skeleton (status table, decisions, standing gates, per-step Goal/Changes/Gate/Docs/Commit), a lint, and a script that patches only the status table, so a long body is never regenerated. Also the compiler-bug tracker issue (reproducer, workaround, vendor ticket). Use when the owner asks to "create/file/open/draft a GH issue with the plan", "well formatted step by step plan", "bullet proof plan", "roadmap issue", "with test gates / docs in sync / progress status", "update the plan issue", "is the issue updated", "check the status of the plan in #N", "implement #N" (revalidate first), or "file the compiler bugs in a GH issue".
---

# Plan issue

`PI=~/.claude/skills/plan-issue/scripts/plan-issue` (also `plan-issue` on the owner's PATH). The owner
is the only editor of these issues. REF is `owner/repo#N`, `#N` or the issue URL.

## Rules

1. **The issue is the only copy of the plan.** Draft the body in the scratchpad, never in the repository;
   delete the draft once the issue exists. No `PLAN.md`, no plan in `LOG.md` beyond the night's own steps.
2. **Filing a plan is not implementing it.** "Create the issue" means the issue. Code changes start only
   when the owner says so (or says to run it, e.g. in night-protocol).
3. **Never regenerate a body to update it.** Status changes go through `$PI set` or `$PI sync`, which touch
   only the table. Plan amendments: `$PI body REF > <scratch>/body.md`, change it with the Edit tool,
   `$PI edit REF <scratch>/body.md`. `edit` refuses removed rows, removed headings and done rows that
   are no longer done; `--force` only when the owner asked for that removal.
4. **Every gate can fail.** A gate is commands plus a pass criterion with a number or an exact outcome
   (counts, tolerances, timings against a named baseline). "Tests pass" or "docs updated" is not a gate.
5. **Docs move with the code.** Each step names the pages it changes and the figures or animations it
   produces (with the script that regenerates them). Docs left for "a final step" are not docs in sync.
6. Bodies stay under 40,000 characters (the lint warns; GitHub's hard limit is 65,536). Long rationale
   belongs in the repository docs, linked from the issue.

## Create

1. The plan comes from the conversation (brainstorm, audit, comparison). Before writing it, read the
   code it touches: §2 *Where the code stands* cites files and the base commit, not memory.
2. Fill [TEMPLATE.md](TEMPLATE.md) in the scratchpad. Status ids: `D<n>` decisions, `<phase>.<step>`
   steps, `G<n>` phase gates; each step id has a heading starting with it. Fill the standing gates from
   the repo (its CLAUDE.md, build modes, test runners, benchmark scripts); include the performance gate
   for any step on a hot path, and the regression gate whenever a baseline exists.
3. Unresolved choices go to §3 as `D` rows with a recommendation; do not decide them silently.
4. `$PI check <file>` until `ok` (fix warnings or say why they stay).
5. Show the owner the step list (ids, titles, gates in one line each) unless they asked to post directly.
6. From the repository root: `$PI create owner/repo <file> --title "<title>"`. It replaces
   `plan-issue:base HEAD` with the current commit. Print the URL, then delete the draft.

A plan for another repository's change (e.g. a FoBiS bug found in ADAM) is filed in that repository.

## Execute

1. **Revalidate first** when the plan is older than the last few commits: `$PI stale REF` lists the
   commits since the plan's base touching paths it names. Read them; if a step no longer matches the
   code, amend the plan (rule 3) and tell the owner before implementing.
2. Day work: when a step's commit exists (the owner committed it), `$PI set REF <id> done "<sha>"`;
   post the step log with `$PI comment REF <file>` and put its link in the evidence:
   `"<sha> · [log](<url>)"`. A started step is `wip`; a blocked one is `blocked` with the reason in a comment.
3. Night work (night-protocol): nothing is posted during the night. Write
   - `.night/current/issue`: the REF, one line;
   - `.night/current/NN-slug.plan`: the status ids that step completes, one per line (`<id> wip` when it
     only advances one);
   - the night's report as `.night/current/<topic>.comment.md` whose **first line** is
     `<!-- target: issue -->` (or `<!-- target: owner/repo#N -->` for another issue). Write
     `{{sha:NN-slug}}` where a step's commit SHA goes: the SHAs exist only after `night commit`.

   `night commit` runs `plan-issue sync` when it finishes: it posts the targeted drafts (renaming each
   `*.comment.posted.md`), then marks each committed step's rows with its SHA and the report link. Drafts
   without a target line stay for posting by hand. Preview: `$PI sync --dry-run`.

## Status questions

"Is the issue updated?", "status of the plan": `$PI status REF`, then compare with `git log` since the
last evidence SHA. Commits not reflected in the table are reported, and fixed with `$PI set`.

## Compiler bugs

One tracker issue per repository, one comment per bug: [COMPILER-BUGS.md](COMPILER-BUGS.md).

## Commands

```
$PI check FILE                     lint: skeleton, ids, step fields, size
$PI create REPO FILE --title T     check, resolve the base marker, open the issue
$PI body REF                       print the body
$PI edit REF FILE [--force]        replace the body, refusing silent losses
$PI status REF                     the table and its counts
$PI set REF ID STATUS [EVIDENCE]   STATUS: todo wip done blocked dropped
$PI comment REF FILE               post a comment, print its URL
$PI stale REF                      commits since the base touching the plan's paths
$PI sync [--night-dir D] [--dry-run]
```

Writes compare the issue's `updatedAt` before and after reading, so an edit made in the web UI in
between makes the write refuse instead of overwriting it.
