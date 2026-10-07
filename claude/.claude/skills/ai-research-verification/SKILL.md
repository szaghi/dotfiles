---
name: ai-research-verification
description: "Verification discipline for AI/agent-produced research results in computational science (CFD, HPC numerics, Fortran solvers), distilled from OpenAI's Oct-2026 math release (722 manuscripts, Lean + Comparator) and its Navier–Stokes claim. Use when: delegating a numerics/solver feature, a convergence study, a proof sketch or a literature claim to an agent and deciding how far to trust the result; designing acceptance tests an agent must not be able to game (MMS observed-order, golden outputs, frozen test specs); tiering claims (agent narrative vs reproduced vs harness-verified vs human-reviewed); writing the spec/prompt for a long agent attempt; or assessing a claimed AI math/physics breakthrough (e.g. 'AI solved Navier–Stokes', Crouzeix, Boltzmann nonuniqueness) for relevance to CFD/HPC. Also holds a dated triage of the 2026 AI-math results relevant to CFD/HPC (references/openai-math-2026.md). Not for generic unit-testing (use tdd) or bug hunting (use diagnose)."
allowed-tools:
  - Read
  - Grep
argument-hint: [a result/claim to assess, or a task to spec for an agent]
---

# AI Research Verification — trust agent output the way Lean trusts a proof

**Origin.** OpenAI's math release (github.com/openai/math, 2026-10-06) is the largest public body of model-produced research: about 4,000 problems posed, about 3 h of compute each, filtered to 722 manuscripts in 372 families. A subset is Lean-formalized and checked by **Comparator**. What carries over to computational science is the *verification architecture*, not the mathematics. Evidence is in `references/openai-math-2026.md`.

## The core distinction: statement fidelity ≠ proof correctness

Comparator checks that a Lean proof proves **exactly** a frozen challenge statement (`theorem … := sorry`), using only whitelisted axioms (`propext, Quot.sound, Classical.choice`). It does **not** check that the challenge statement says what the paper's English says. That gap is closed only by a human reading the statement. The release's own catalogue marks the agent-made formalizations `review: unchecked`.

Code analogue:

| Math (Comparator) | CFD / numerics |
|---|---|
| challenge statement with `sorry` | **acceptance spec**: PDE, BCs, norms, target order, tolerances, test cases |
| axiom whitelist | **escape-hatch whitelist**: what the agent may *not* touch (tests/, tolerances, CFL, limiter, MMS source terms) |
| proof | the implementation |
| Comparator run | the harness run in CI or by you (not reported by the agent) |
| human reads the statement | **you** review the spec. This cannot be delegated |

The dominant failure mode is a **correct proof of the wrong statement**. For code that means a passing harness that tests the wrong thing, or a harness the agent quietly edited, e.g. "fixing" an MMS failure by regenerating the manufactured source with the bug baked in.

## Rules

1. **Freeze the spec before the attempt.** Write the acceptance criteria first: equations, BCs, the norm (L2/L∞, cell-average vs point), refinement ladder, expected observed order with a band (e.g. p_obs ≥ p − 0.1 over the last 2 of 3 levels), and golden-output tolerances (bitwise / ulp / relative). Keep them **outside the agent's write scope**: a separate commit, a read-only path, or a hook that rejects a diff touching `tests/` and `src/` together.
2. **Machine-checkable acceptance over narrative.** Prefer, in order:
   - MMS with an observed-order assertion
   - exact solutions or reductions: 1-D Sod/Riemann, Couette/Poiseuille, Taylor–Green decay rate, free-stream preservation on curvilinear/overset grids
   - conservation to round-off: sum of fluxes, mass over the domain
   - cross-implementation agreement: CPU reference vs OpenACC kernel, 1 rank vs N ranks bitwise or to a stated ulp bound
   - only then plots and "looks right"
3. **Tier every claim and never let tiers blur.**
   - **T0** agent narrative ("converges at 2nd order")
   - **T1** reproduced by a script you can rerun
   - **T2** passes the frozen harness
   - **T3** T2 plus a human-reviewed spec

   Report the tier next to the claim. Agent summaries are T0 until rerun. The release states the same about itself: "some of the unformalized results could have issues."
4. **Scope notes are mandatory.** Copy the release's habit of writing "X is outside this selected statement". Example: "2nd order verified on smooth periodic MMS; shock/limiter regime, stretched grids, overset fringe and N×M decompositions unverified." An unscoped "verified" is a T0 claim.
5. **Put your domain traps in the spec.** The release's prompts pre-empted known cheats, e.g. "a finitely presented group with unproved word equalities is not a certificate", and a restriction must be stated "instead of silently extending it". For CFD, write:
   - do not change CFL, limiter, tolerances, or the MMS source to make a test pass
   - state which BCs the ghost-cell fill assumes
   - state any uniform-spacing or periodicity assumption
   - state the nondimensionalization
6. **Hypothesis matching is the real work.** Most of the Vlasov–Maxwell trace went into fitting the data to a cited criterion's hypotheses: an H⁵ regularity gap and a 4π normalization. When an agent invokes a theorem, a CFL bound or a library routine, check its preconditions explicitly: stencil width near boundaries, halo depth, OpenACC data presence, kind/precision, units.
7. **Conditional language is an open obligation.** Grep agent reports for `assuming|should|expected to|conditional|in principle|rests on` and turn each hit into a test or a TODO. The release's own trace ends with "That assertion rests on … estimates" for a result that only Lean later closed.
8. **Many attempts, hard filter, review only survivors.** About 4,000 posed became 372 families, with a fixed budget per problem. For parallel agent attempts, give each the same frozen spec and budget. Discard by tier, then spend human review on the T2 survivors. Verification, not generation, is the cost centre.
9. **Organize by family.** Keep a feature, its verification cases, its alternative implementation (the "alternative proof", e.g. a CPU reference) and its benchmark notes in one tracked unit.
10. **Do not copy the no-computation stance.** The math prompts discouraged brute force for presentation reasons. In numerics, small-case checks are cheap and decisive: a 2×2 matrix, N=8, one time step against hand arithmetic.
11. **Pin the toolchain for verification runs.** The release pins Lean v4.34.1 and patches every dependency. Pin compiler, MPI and NVHPC versions plus flags. Verify per family, not the monolith.

## Assessing a claimed AI breakthrough for CFD/HPC relevance

Ask in order:
1. **What exactly is the statement?** Forced or unforced; R³ or T³; the data class.
2. **What tier is it?** Preprint only, Lean on a selected statement, or refereed.
3. **Does the formal statement match the headline?** Read the Lean scope note, not the press.
4. **Is it quantitative?** Are there constants or rates a code could use, or is it pure existence?
5. **Does it change a decision?** Scheme choice, a stability limit, a V&V protocol, a resolution requirement.

Most results fail question 4 or 5. That is normal. Say so plainly instead of overselling.

## Files
- `references/openai-math-2026.md`: dated triage of the 2026 AI-math results that touch CFD/HPC (Crouzeix → `hpc-numerics` ch13; Navier–Stokes; Boltzmann; Vlasov–Maxwell; matrix multiplication, FFT, integer multiplication), with verification tiers, plus facts about the release's process.
