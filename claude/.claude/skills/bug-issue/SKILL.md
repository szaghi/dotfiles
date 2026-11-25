---
name: bug-issue
description: File, investigate, fix and track a bug as a GitHub issue with an evidence-first skeleton - environment with exact versions, observed vs expected, minimal reproducer, claims with tiers (T0-T3), and, by kind, ruled-out causes and ranked hypotheses with a test plan (investigation), root cause and a test-first fix plan (defect), or a self-contained report for another project (upstream). An investigation that finds its cause becomes a defect in the same issue. Also the per-repo compiler-bug tracker (reproducer, standard rule, workaround, vendor ticket). Uses plan-issue's script for lint and status. Use when the owner asks to "create/open/file a GH issue for the bug", "report the bug with details and minimal reproducer", "issue with evidence and step by step fix (TDD)", "issue to investigate the hangs / the slowdown / the discrepancy", "report it on the <project> repo", "is the bug saved in any GH issue", or "file the compiler bugs".
---

# Bug issue

`PI=~/.claude/skills/plan-issue/scripts/plan-issue`: the same script as the plan-issue skill; read that
skill's rules 1-3 and 6, they hold here too (the issue is the only copy, filing is not fixing, never
regenerate a body, size). Skeleton: [TEMPLATE.md](TEMPLATE.md). Compiler bugs: [COMPILER-BUGS.md](COMPILER-BUGS.md).

## Kinds

| Kind | When | Sections beyond the core | Status table |
|---|---|---|---|
| `investigation` | cause unknown (hangs, slowdowns, discrepancies) | Ruled out, Hypotheses, Test plan (`T` rows) | yes |
| `defect` | cause known, in one of the owner's repos | Root cause, Fix plan (`F` rows) | yes |
| `upstream` | a report to another project | Patch (optional) | no |

Core, every kind: Summary, Environment, Observed, Expected, Reproducer, Evidence. A compiler bug goes to the
repository's compiler-bug tracker instead, one comment per bug.

## Rules

1. **Search before filing.** `gh issue list -R <repo> --state all --search "<symptom words>"`, and the
   compiler tracker. A match gets a comment with the new evidence, not a new issue.
2. **Reproduce before claiming.** Every row of *Evidence* has a tier: T0 narrative, T1 reproduced by a script
   you can rerun, T2 a test in the suite, T3 T2 reviewed by the owner (ai-research-verification skill). A
   hypothesis is never written as a cause; *Root cause* needs T1 at least.
3. **Minimal means minimal.** The reproducer drops every feature the bug does not need, and says how often
   it fails (every run, N of M, from P ranks on). For `upstream`, it must run without the owner's code.
4. **Test first.** A fix plan starts with **F1**: the reproducer as a test that fails on the bug. The fix
   step follows, gated by that test passing and the regression suite against the baselines.
5. **One issue per bug, through its whole life.** When an investigation finds the cause: change the kind
   marker to `defect`, add *Root cause* (with the commit that introduced it when `git bisect` finds it) and
   *Fix plan* with its `F` rows, mark the hypotheses kept or rejected with their test, and leave *Ruled out*
   and *Hypotheses* as the record. Amend with `$PI body` → Edit → `$PI edit` (rule 3 of plan-issue).
6. **Investigation steps are cheap to log, expensive to repeat.** Each `T` step's result goes in a comment
   with job ids and numbers, linked from its row, so a ruled-out cause is never tested twice.

## Create

1. Gather the facts from the session (logs, job ids, outputs) and rerun what is not yet T1.
2. Fill [TEMPLATE.md](TEMPLATE.md) in the scratchpad: set the kind, delete the sections of the other kinds
   (and the status block for `upstream`), keep the base marker (the commit where it was reproduced).
3. `$PI check <file>` until `ok`; then from the repository root `$PI create owner/repo <file> --title
   "<symptom, where>"`, print the URL, delete the draft. A bug in another of the owner's repos is filed there.

## Execute, status, nights

As in the plan-issue skill: `$PI set` and `$PI comment` in the day, `issue` / `NN-slug.plan` / targeted
drafts in a night, synced by `night commit`; `$PI status REF` for "where is the bug at".
