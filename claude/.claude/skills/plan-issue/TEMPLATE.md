<!-- plan-issue v1 -->
<!-- plan-issue:base HEAD -->

> **How this issue is used.** This issue is the only copy of the plan: no plan file lives in the
> repository. The status table below is the progress record, and `plan-issue` (the `plan-issue` skill)
> updates it. Each work session posts its log as a comment, and the table row links to that comment
> and to the commits. Edits to the plan change this body; decisions are recorded in §3.

## Status

<!-- plan-issue:status:begin -->
| Step | Title | Status | Evidence |
|---|---|---|---|
| D1 | <decision, one line> | ⬜ | |
| 1.1 | <step title> | ⬜ | |
| 1.2 | <step title> | ⬜ | |
| G1 | <gate: the claim this phase must prove> | ⬜ | |
| 2.1 | <step title> | ⬜ | |
<!-- plan-issue:status:end -->

⬜ to do · 🔄 in progress · ✅ done · ⏸ blocked · ➖ dropped (the reason in the step). Evidence: commit
SHAs and a link to the log comment.

## 1. Goal

<What exists when the plan is done, in two to five sentences. The release or milestone it serves.>

## 2. Where the code stands

<The audit in a few lines, against the base commit above: what exists, with `path/to/file.F90`
references, what is missing, what is wrong. Facts with their evidence, not intentions.>

## 3. Decisions

- **D1** <the question>. Options: **A** <...>, **B** <...>. Recommended: **A**, because <...>.
  Outcome: <empty until decided; then the option, the date and who decided>.

## 4. Standing gates (the definition of done for every step)

A step is ✅ only when all of these hold, plus its own gate:

| Gate | Command | Pass criterion |
|---|---|---|
| Build | `<fobis build --mode ...>` for each compiler in the matrix | no error, no new warning |
| Tests | `<the fast suite command>` | all pass, the count printed |
| Regression | `<command comparing with the frozen baselines>` | <tolerance, e.g. bitwise, or rel. err <= 1e-12> |
| Performance | `<benchmark command>` (only for steps touching hot paths) | <e.g. no slowdown > 3 % vs. base, timing per CLAUDE-gpu benchmark discipline> |
| Docs | `<docs build command>` | builds with no dead link; the step's pages updated |

## 5. Steps

### Phase 1 — <title>

#### 1.1 <step title>

- **Goal:** <the one outcome of this step>
- **Changes:** `<files or modules touched>`
- **Gate:** `<exact commands>`; pass when <a criterion that can fail: counts, tolerances, timings>.
- **Docs:** <pages created or updated in this same step; figures or animations, and the script that produces them>
- **Commit:** `<type(scope): subject>`
- **Depends on:** <step ids, or none>

#### 1.2 <step title>

- **Goal:**
- **Changes:**
- **Gate:**
- **Docs:**
- **Commit:**
- **Depends on:** 1.1

#### G1 <the phase gate>

- **Goal:** <the claim the phase must prove before phase 2 starts>
- **Gate:** `<commands>`; pass when <criterion>.
- **Docs:** <where the result is published>
- **Commit:** <none, or the commit that records the result>

### Phase 2 — <title>

#### 2.1 <step title>

- **Goal:**
- **Changes:**
- **Gate:**
- **Docs:**
- **Commit:**
- **Depends on:** G1

## 6. Risks

| Risk | Affects | Mitigation |
|---|---|---|
| <...> | <steps> | <...> |

## 7. Out of scope

- <what this plan does not do, with the reason and the issue that tracks it, if any>
