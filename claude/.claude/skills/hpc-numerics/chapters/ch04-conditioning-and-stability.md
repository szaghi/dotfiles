# Chapter 4: Conditioning & Numerical Stability

## Core Idea
Two distinct things determine whether a computed answer is trustworthy: **conditioning** is a property of the *problem* (how sensitive the true answer is to input perturbations), and **stability** is a property of the *algorithm* (how much it amplifies round-off). A well-conditioned problem solved by a stable algorithm is safe; either failing dooms the result.

## Frameworks Introduced

- **Conditioning (problem sensitivity)**:
  - The **condition number** measures how a small relative perturbation in the input changes the output: `relative output error ≤ κ × relative input error`. A problem with large κ is **ill-conditioned** — *no* algorithm can compute it accurately, because the answer is intrinsically hypersensitive.
  - For solving `Ax = b`, the condition number is `κ(A) = ‖A‖·‖A⁻¹‖`. Large κ(A) means tiny errors in `b` (or in `A`) produce large errors in `x`.

- **Stability (algorithm behavior)**:
  - An algorithm is **stable** (backward-stable) if its computed answer is the *exact* answer to a slightly perturbed problem — i.e., it doesn't amplify round-off beyond what conditioning already forces. An **unstable** algorithm magnifies round-off even on well-conditioned problems.
  - The split: **conditioning is the problem's fault, instability is the algorithm's fault.** A stable algorithm on an ill-conditioned problem still gives a bad answer (the problem is the issue); an unstable algorithm ruins even a well-conditioned problem.

- **Stability for time-dependent problems** (Ch 5 preview): for ODEs/PDEs, a method is **stable** if errors don't grow unboundedly as the computation proceeds. A small perturbation in the initial value must not blow up — captured by stability criteria (e.g. the test equation `u' = λu` and the region of absolute stability).

## Key Concepts
- **The two-factor diagnosis**: a wrong numerical answer is *either* an ill-conditioned problem (reformulate the problem) *or* an unstable algorithm (choose a stable algorithm) — identify which before "fixing" anything.
- **Pivoting as a stability device** (Ch 7): Gaussian elimination is unstable without pivoting (a tiny pivot amplifies round-off); partial pivoting makes it stable. This is a concrete case of an unstable algorithm made stable.
- **Eigenvalue sensitivity**: eigenvalues of non-symmetric matrices can be extremely ill-conditioned — a perturbation of size ε in the matrix can shift eigenvalues by √ε or worse.
- **Error growth**: in iterative/time-stepping computations, the question is whether per-step round-off *accumulates* (unstable) or stays bounded (stable).

## Mental Models
- **Separate the problem from the algorithm** — ask first "is this problem ill-conditioned?" (κ large → no algorithm helps, reformulate) and only then "is my algorithm stable?" (instability → switch algorithms). Conflating the two leads to fixing the wrong thing.
- **Check κ before trusting a linear solve** — a large condition number warns that the computed `x` may be inaccurate no matter how careful the solver; precondition or reformulate.
- **A stable algorithm gives the right answer to nearly the right problem** — backward stability is the gold standard: you've solved a problem ε-close to the one asked.
- **Instability shows up as round-off growth** — if errors balloon as a computation proceeds (timesteps, iterations) on a benign problem, suspect the algorithm, not the data.

## Reference Tables

| Property | Of the | Measures | If bad |
|---|---|---|---|
| conditioning (κ) | problem | sensitivity to input perturbation | reformulate the problem |
| stability | algorithm | round-off amplification | choose a stable algorithm |

| Situation | Conditioning | Stability | Result |
|---|---|---|---|
| good problem, good algorithm | low κ | stable | accurate |
| bad problem, good algorithm | high κ | stable | inaccurate (problem's fault) |
| good problem, bad algorithm | low κ | unstable | inaccurate (algorithm's fault) |
| bad problem, bad algorithm | high κ | unstable | garbage |

## Key Takeaways
1. Conditioning is a property of the problem (sensitivity of the true answer to input perturbations); stability is a property of the algorithm (round-off amplification) — keep them distinct.
2. The condition number bounds achievable accuracy: `output error ≤ κ × input error`; an ill-conditioned problem (large κ) is inaccurate under *any* algorithm.
3. For `Ax = b`, `κ(A) = ‖A‖·‖A⁻¹‖`; check it before trusting a solve, and precondition/reformulate when it's large.
4. A backward-stable algorithm gives the exact answer to a slightly perturbed problem — the gold standard; pivoting is what makes Gaussian elimination stable.
5. Diagnose a bad numerical answer by asking *problem or algorithm*: ill-conditioning (reformulate) vs instability (switch algorithm).

## Connects To
- **Ch 03 (Arithmetic)**: round-off is the perturbation stability/conditioning amplify or contain.
- **Ch 05 (ODEs/PDEs)**: stability regions and CFL conditions for time-stepping.
- **Ch 07 (Numerical LA)**: pivoting for stability, κ(A) for solvability.
- **Ch 08 (Iterative solvers)**: conditioning drives convergence rate and preconditioning.
