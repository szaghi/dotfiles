# HPC Numerics Cheatsheet — Decision Rules & Tells

## Diagnose a bad numerical result
1. **Conditioning?** κ(A) large → ill-conditioned *problem*; no algorithm helps → reformulate/precondition.
2. **Stability?** round-off grows over steps/iterations → unstable *algorithm* → switch algorithm.
- Conditioning = problem's fault; instability = algorithm's fault. Separate them.

## Floating-point rules
- Never test `a == b`; use `|a − b| < tol` scaled to magnitudes.
- `(a+b)+c ≠ a+(b+c)` — reassociation (`-ffast-math`, parallel reductions) breaks bitwise reproducibility.
- Hunt cancellation in any subtraction of near-equal values → rewrite the formula.
- Long disparate sums → Kahan/pairwise or smallest-first.
- ε_mach ≈ 2.2e-16 (double), 1.2e-7 (single).

## Time-stepping picker
| Problem | Method |
|---|---|
| non-stiff, smooth | explicit (cheap, Δt < 2/λ or CFL) |
| stiff (separated timescales) | implicit (solve/step, unconditional) |
| need accuracy | higher-order (RK/BDF) — order ≠ stability |
- Blowing-up integration on a decaying problem = Δt exceeded the explicit stability limit, not a bug.

## PDE → linear algebra
- Discretize with stencils (5-point star = 2D Laplacian) → sparse block-tridiagonal system.
- Elliptic → one sparse solve; parabolic/hyperbolic → time-step (CFL-limited if explicit).
- Never store the PDE matrix densely.

## Linear solver picker
| System | Solver |
|---|---|
| small/moderate dense, many RHS | direct LU (LAPACK), **always pivot** |
| large sparse | iterative (Krylov), matvec-only |
| sparse SPD (e.g. Poisson) | CG + preconditioner |
| sparse general nonsymmetric | GMRES |
| elliptic PDE | multigrid (optimal O(N)) |
- Sparse direct → watch fill-in; reorder (min-degree/nested dissection) to cut it.
- **Preconditioner choice dominates** Krylov performance (Jacobi → ILU → multigrid).
- Convergence ∝ √κ(A) for CG; small residual on ill-conditioned A ≠ small error.

## BLAS levels (dense LA performance)
| Level | Op | Intensity | Bound |
|---|---|---|---|
| 1 | vector (axpy/dot) | O(1) | memory |
| 2 | matrix-vector (gemv) | O(1) | memory |
| 3 | **matrix-matrix (gemm)** | **O(n)** | **compute (peak)** |
- Cast dense LA as BLAS-3; never hand-code gemm/LU/Cholesky — call LAPACK.
- Sparse matvec is irreducibly memory-bound → caps iterative-solver speed.

## Roofline triage
- AI = FLOPs / bytes moved. Below ridge → memory-bound (reuse/tile/coalesce). Above → compute-bound (vectorize/FMA).
- Matrix-vector = O(1) AI (memory-bound); matrix-matrix = O(n) AI (compute-bound, near peak with blocking).

## Architecture / locality
- The memory wall, not the ALU, limits most scientific code (memory-bound).
- Spatial locality: unit stride, SoA, use whole cache line. Temporal: block/tile to reuse before eviction.
- Predictable sequential access lets prefetchers/pipelines help; scattered access defeats them.

## N-body & Monte Carlo
- N-body: never naive O(N²) at scale → cutoffs + cell lists (O(N) short-range), Barnes-Hut (O(N log N)), FMM (O(N)). Newton's 3rd law halves work.
- Monte Carlo: error ∝ 1/√N, **dimension-independent** → use for high-D integration; variance reduction lowers the constant; needs independent reproducible parallel RNG.

## Graph / combinatorial
- Best parallel algorithm ≠ best sequential parallelized (sorting networks: bitonic/odd-even over quicksort).
- Graph = adjacency matrix → BFS is sparse matvec; graph algorithms are memory-bound/irregular.
- Graph coloring exposes independent (parallel-safe) work.
