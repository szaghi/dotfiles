<!-- bug-issue v1 -->
<!-- bug-issue:kind investigation -->
<!-- plan-issue:base HEAD -->

> **How this issue is used.** Kind: `investigation` (cause unknown), `defect` (cause known) or `upstream`
> (a report to another project). When an investigation finds its cause, it becomes a defect in this
> same issue: the kind marker changes, *Root cause* and *Fix plan* are added, and *Ruled out* and
> *Hypotheses* stay as the record. Every claim carries its tier: T0 narrative, T1 reproduced by a
> rerunnable script, T2 a test in the suite, T3 T2 reviewed by a human.

## Status

<!-- plan-issue:status:begin -->
| Step | Title | Status | Evidence |
|---|---|---|---|
| T1 | <the test that separates H1 from H2> | ⬜ | |
| F1 | <a test that fails on the bug> | ⬜ | |
| F2 | <the fix> | ⬜ | |
<!-- plan-issue:status:end -->

⬜ to do · 🔄 in progress · ✅ done · ⏸ blocked · ➖ dropped. `T` rows test hypotheses, `F` rows fix.

## Summary

<One paragraph: what goes wrong, where, how badly, and since when if known.>

## Environment

| | |
|---|---|
| Commit | `<sha>` (the base marker above) |
| Compilers | <exact versions and flags, e.g. nvfortran 26.9 `-O2 -acc`; gfortran 16.2.0> |
| Libraries | <MPI, HDF5, CUDA versions> |
| Machine | <WSL box, medooza node type, ranks x GPUs> |

## Observed

<What happens: messages, wrong numbers with their reference values, timings, the job id or log path.>

## Expected

<What should happen, and the source of that expectation: a reference solution, a previous commit, the standard.>

## Reproducer

<The smallest input that shows it, without unrelated features.>

```console
$ <commands>
<output>
```

Frequency: <every run | N of M runs | only at P ranks or above>.

## Evidence

| Claim | Tier | Evidence |
|---|---|---|
| <the bug appears at commit X and not at Y> | <T0-T3> | <script, job id, log, test name> |

## Ruled out

- <a cause excluded, and the measurement that excluded it>

## Hypotheses

- **H1** <a possible cause>. Predicts <an observation that differs from H2>. Tested by **T1**.
- **H2** <a possible cause>. Predicts <...>. Tested by **T1**.

## Root cause

<Defect only: the mechanism, at `path/file.F90:line`; the commit that introduced it (git bisect) if known.>

## Patch

<Upstream only: the change, as a diff or a link to a branch, and the version it was made against.>

## Test plan

#### T1 <the test that separates H1 from H2>

- **Goal:** <which hypothesis this keeps or rejects>
- **Changes:** <none, or the instrumentation added>
- **Gate:** `<commands>`; H1 holds if <a measurable outcome>, H2 if <the other outcome>.
- **Docs:** <none: an investigation step; or the page updated>
- **Commit:** <none, or the instrumentation commit>

## Fix plan

#### F1 <a test that fails on the bug>

- **Goal:** the reproducer as a test in the suite, failing before the fix (T2 for the bug)
- **Changes:** `<test file>`
- **Gate:** `<test command>`; fails with <the observed error>.
- **Docs:** <none, or the verification page>
- **Commit:** `test(<scope>): reproduce <the bug>`

#### F2 <the fix>

- **Goal:** <the fix>
- **Changes:** `<files>`
- **Gate:** `<test command>` passes; `<regression suite>` <bitwise | within tolerance> against the baselines.
- **Docs:** <the pages that described the wrong behaviour, or a changelog line>
- **Commit:** `fix(<scope>): <subject>`
- **Depends on:** F1

## Related

- <issues, commits, upstream tickets>
