# Patterns & Techniques — HPC Numerics

## Diagnose: problem or algorithm?
**When to use**: any inaccurate numerical result.
**How**: check conditioning first (κ large → ill-conditioned problem, reformulate); then stability (round-off growth → unstable algorithm, switch).
**Trade-offs**: prevents fixing the wrong thing; conditioning is the problem's fault, instability the algorithm's.

## Avoid catastrophic cancellation
**When to use**: any subtraction of nearly-equal quantities.
**How**: rewrite the formula — the stable quadratic (compute one root, get the other via the product), conjugate multiplication, `expm1`/`log1p`.
**Trade-offs**: the single highest-leverage numerical fix; turns O(ε) garbage into accurate results.

## Compensated summation
**When to use**: long sums of disparate magnitudes (conservation diagnostics, reductions).
**How**: Kahan/pairwise summation, or sort smallest-to-largest.
**Trade-offs**: recovers low-order bits lost to round-off; modest extra cost.

## Explicit vs implicit time-stepping
**When to use**: integrating an ODE/PDE in time.
**How**: non-stiff/smooth → explicit (cheap, but Δt < 2/λ or CFL); stiff → implicit (solve per step, unconditional stability).
**Trade-offs**: explicit cheap-but-capped, implicit costly-but-unconditional; stiffness decides.

## Sparse storage + iterative solve
**When to use**: large sparse systems (discretized PDEs) where LU fill-in is catastrophic.
**How**: store as CRS; solve with a Krylov method (CG for SPD, GMRES for general) using only matvecs.
**Trade-offs**: avoids fill-in; convergence depends on conditioning → needs preconditioning.

## Preconditioning
**When to use**: slow Krylov convergence.
**How**: M⁻¹Ax = M⁻¹b with M≈A cheap to invert — Jacobi → ILU → multigrid (optimal for elliptic PDEs).
**Trade-offs**: the dominant performance lever; preconditioner choice matters far more than the Krylov variant.

## Reorder to reduce fill-in
**When to use**: sparse direct factorization.
**How**: renumber unknowns (minimum-degree, nested dissection) via the matrix graph to minimize created nonzeros.
**Trade-offs**: same matrix, wildly different fill-in; preprocessing pays off hugely.

## Cache blocking / tiling
**When to use**: any loop with data reuse (especially dense linear algebra).
**How**: tile the loop so the working set fits in L1/L2 and is reused before eviction; reorder loops for unit stride.
**Trade-offs**: changes FP evaluation order (not compiler-legal automatically); reuse raises arithmetic intensity.

## Cast as BLAS-3
**When to use**: dense linear algebra performance.
**How**: restructure factorizations (LU/Cholesky/QR) into block algorithms where most work is gemm; call tuned BLAS-3/LAPACK.
**Trade-offs**: the only path to near-peak; never hand-code gemm or factorizations.

## Roofline triage
**When to use**: "why is this kernel slow?"
**How**: compute arithmetic intensity (FLOPs/byte); below ridge → memory-bound (optimize reuse), above → compute-bound (optimize arithmetic).
**Trade-offs**: tells you the ceiling and which lever before you optimize.

## Beat O(N²) with spatial structure (N-body)
**When to use**: particle/N-body simulation at scale.
**How**: cutoffs + cell lists (O(N) short-range), Barnes-Hut tree (O(N log N)), FMM (O(N) long-range); use Newton's third law.
**Trade-offs**: exploits spatial locality and physics to make large N tractable.

## Monte Carlo for high-dimensional integration
**When to use**: integrals where grid methods hit the curse of dimensionality.
**How**: random sampling (error ∝ 1/√N, dimension-independent); variance reduction to lower the constant; independent parallel RNG streams.
**Trade-offs**: slow √N rate but dimension-independent; embarrassingly parallel if the RNG is correct.
