# Chapter 7: Numerical Linear Algebra — LU, Pivoting & Sparse Fill-in

## Core Idea
Most scientific computing funnels into solving `Ax = b`. **Direct methods** (Gaussian elimination / LU factorization) solve it exactly in finite arithmetic — but require **pivoting** for stability and, for sparse matrices, suffer **fill-in** that can destroy sparsity. Understanding fill-in is what motivates iterative methods (Ch 8).

## Frameworks Introduced

- **LU factorization (Gaussian elimination)**: factor `A = LU` (lower × upper triangular), then solve by forward + back substitution. Cost is O(n³) for a dense n×n matrix — the workhorse direct solver, the basis of LAPACK's `gesv`.

- **Pivoting (for stability)**: during elimination, a **pivot** is the diagonal element you divide by.
  - A **zero pivot** breaks the factorization; a **small pivot** amplifies round-off (the unstable case from Ch 4).
  - **Partial pivoting**: swap rows to bring the largest-magnitude element into the pivot position. **Rule of thumb: always do row exchanges to get the largest remaining element into the pivot** — this makes Gaussian elimination backward-stable.
  - Full pivoting (row + column) is more stable but costlier; partial pivoting is the standard.

- **Sparse matrices & fill-in** (the sparse direct-solve problem):
  - PDE matrices are **sparse** (Ch 6) — stored compactly (e.g. **CRS / Compressed Row Storage**: values + column indices + row pointers), not as dense 2D arrays.
  - **Fill-in**: eliminating one variable creates new nonzeros where the original matrix had zeros. A sparse matrix's LU factors can be far denser than `A` itself — potentially destroying the sparsity that made the problem tractable.
  - **Fill-in via the matrix graph**: model the matrix as a graph (nonzero `aᵢⱼ` = edge i–j); eliminating a node connects all its neighbors → new edges = fill-in. The graph view makes fill-in visualizable and analyzable.
  - **Fill-in reduction**: renumbering the unknowns (reordering rows/columns) changes the fill-in dramatically — good orderings (e.g. minimum-degree, nested dissection) minimize it.

## Key Concepts
- **Direct vs iterative trade-off**: direct methods give an exact answer in a fixed number of operations but fill-in can make a sparse solve cost like a dense one in memory — *the* reason iterative methods (Ch 8) exist for large sparse systems.
- **The condition number κ(A)** (Ch 4) bounds the accuracy of the computed `x`; pivoting controls *added* round-off but can't fix an ill-conditioned `A`.
- **Banded matrices**: fill-in from LU stays within the original band — so banded direct solvers are efficient and fill-in-free outside the band (relevant to 1D and narrow-band 2D problems).
- **Reordering matters**: the *same* matrix under different unknown orderings can have wildly different fill-in; reordering is a preprocessing step, not an afterthought.

## Mental Models
- **Always pivot** — partial pivoting (largest element into the pivot) is what makes Gaussian elimination stable; never factor without it on a general matrix.
- **For sparse systems, fill-in is the enemy** — a naive sparse LU can fill in until it's as expensive as dense. Reorder to minimize fill-in, or switch to an iterative method that never factors at all.
- **Model sparsity as a graph** — fill-in, reordering, and parallelism all become graph problems on the matrix's adjacency structure (Ch 11).
- **Direct for small/moderate or repeated-RHS; iterative for large sparse** — direct solves amortize the factorization over many right-hand sides; iterative methods win when one factorization would fill in catastrophically.

## Reference Tables

| Aspect | Direct (LU) | Notes |
|---|---|---|
| cost (dense) | O(n³) factor, O(n²) solve | exact in finite arithmetic |
| stability | needs pivoting | partial pivoting = backward stable |
| sparse | fill-in | LU factors denser than A |
| reuse | factor once, many RHS | amortizes O(n³) |

| Sparse concept | Meaning |
|---|---|
| CRS storage | values + col indices + row pointers |
| fill-in | new nonzeros created during elimination |
| matrix graph | nonzero aᵢⱼ = edge i–j |
| reordering | renumber unknowns to cut fill-in |

## Key Takeaways
1. `Ax = b` is solved directly by LU factorization (Gaussian elimination), O(n³) dense, the basis of LAPACK direct solvers.
2. **Always pivot** (partial: largest element into the pivot position) — it's what makes elimination backward-stable; zero/small pivots break or destabilize it.
3. Sparse matrices (CRS storage) suffer **fill-in**: elimination creates new nonzeros, potentially destroying sparsity.
4. Model sparsity as the matrix graph — fill-in = edges created by eliminating a node; reordering unknowns minimizes it.
5. Catastrophic fill-in on large sparse systems is the central motivation for iterative methods (Ch 8); use direct for small/moderate or many-RHS problems.

## Connects To
- **Ch 04 (Conditioning)**: κ(A) bounds accuracy; pivoting is the stability device.
- **Ch 06 (PDEs)**: the sparse systems whose fill-in this analyzes.
- **Ch 08 (Iterative solvers)**: the alternative that avoids fill-in entirely.
- **Ch 10 (HP linear algebra)**: BLAS-3 blocking makes dense LU fast.
- **Ch 11 (Graph algorithms)**: the matrix-graph view of fill-in and reordering.
