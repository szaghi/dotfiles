# Chapter 10: High-Performance Linear Algebra — BLAS Levels & Block Algorithms

## Core Idea
Dense linear algebra reaches near-peak performance only by being expressed in terms of **BLAS-3** (matrix-matrix) operations, which have enough arithmetic intensity to overcome the memory wall. **Block algorithms** restructure factorizations (LU, Cholesky, QR) so the bulk of the work becomes matrix-matrix products — the reason LAPACK is fast and you should never hand-code these kernels.

## Frameworks Introduced

- **The BLAS levels** (the arithmetic-intensity ladder):
  - **Level 1** — vector operations (`axpy` y←αx+y, `dot`): O(n) flops on O(n) data → **arithmetic intensity O(1)**, memory-bound.
  - **Level 2** — matrix-vector (`gemv` y←αAx+βy): O(n²) flops on O(n²) data → **O(1) intensity**, still memory-bound.
  - **Level 3** — matrix-matrix (`gemm` C←αAB+βC): O(n³) flops on O(n²) data → **O(n) intensity**, compute-bound, **reaches near-peak**.
  - The lesson: only BLAS-3 can be fast. Restructure algorithms to spend their work in `gemm`.

- **Block algorithms** (turning factorizations into BLAS-3):
  - Naive LU/Cholesky/QR are sequences of BLAS-1/2 operations → memory-bound, far from peak.
  - **Blocked** versions partition the matrix into sub-blocks and express most of the work as matrix-matrix products on those blocks (a small "panel" factorization plus large `gemm` updates). The `gemm` updates dominate and run at near-peak — this is how LAPACK achieves its speed.
  - The block size is tuned to the cache hierarchy (the tile must fit and be reused, Ch 9).

- **The optimized-`gemm` microkernel**: a high-performance `gemm` (OpenBLAS/MKL/BLIS, the Goto/van de Geijn approach) is built from a tiny hand-tuned **microkernel** that keeps a sub-tile of C in registers while streaming A and B from cache, surrounded by blocking loops that feed it from each cache level. This is the most-optimized kernel in scientific computing.

## Key Concepts
- **Cast everything as BLAS-3**: the universal performance principle for dense linear algebra — if your algorithm's inner work is matrix-matrix, it can hit peak; if it's matrix-vector or vector, it's memory-bound regardless of effort.
- **Block size tied to cache**: the blocking that makes algorithms BLAS-3 is the cache-tiling of Ch 9 applied to linear algebra; block dimensions are chosen so tiles fit in L1/L2.
- **Why LAPACK over hand code**: LAPACK's blocked factorizations + a tuned BLAS-3 are the result of decades of expert tuning per architecture — you cannot match them by hand.
- **Sparse is different**: the sparse matrix-vector product (the core of iterative solvers, Ch 8) is irreducibly BLAS-2-like and memory-bound — no blocking makes it compute-bound, which caps iterative-solver performance.

## Mental Models
- **Restructure dense linear algebra into matrix-matrix products** — it's the only path to near-peak; a factorization expressed as BLAS-1/2 leaves most of the hardware idle. Block it so the work lands in `gemm`.
- **Never hand-code GEMM, LU, Cholesky, or QR** — call a tuned BLAS-3 / LAPACK; the optimized `gemm` microkernel is more carefully tuned than anything you'd write, and the blocked factorizations are decades of expertise.
- **Know your kernel's BLAS level** — BLAS-1/2 = memory-bound (accept it or restructure); BLAS-3 = compute-bound (achievable peak). This tells you the ceiling before you start.
- **Sparse iterative solvers are memory-bound by nature** — the sparse matvec is BLAS-2-like; their speed is limited by memory bandwidth, not FLOPs, so optimize data layout and reuse, not arithmetic.

## Reference Tables

| BLAS level | Operation | Flops / data | Intensity | Bound |
|---|---|---|---|---|
| 1 | `axpy`, `dot` (vector) | O(n)/O(n) | O(1) | memory |
| 2 | `gemv` (matrix-vector) | O(n²)/O(n²) | O(1) | memory |
| 3 | `gemm` (matrix-matrix) | O(n³)/O(n²) | **O(n)** | **compute (near peak)** |

| Algorithm | Naive | Blocked (BLAS-3) |
|---|---|---|
| LU / Cholesky / QR | BLAS-1/2, memory-bound | panel + `gemm` updates, near-peak |

## Key Takeaways
1. Only BLAS-3 (matrix-matrix, `gemm`) has high enough arithmetic intensity (O(n)) to reach near-peak; BLAS-1/2 are memory-bound.
2. Block algorithms restructure LU/Cholesky/QR so most work becomes `gemm` updates on cache-sized tiles — the reason LAPACK is fast.
3. The universal dense-LA principle: cast the algorithm's inner work as matrix-matrix products.
4. Never hand-code `gemm` or blocked factorizations — call tuned BLAS-3/LAPACK (OpenBLAS/MKL/BLIS); the microkernel is decades of per-architecture tuning.
5. The sparse matrix-vector product is irreducibly memory-bound (BLAS-2-like), which caps iterative-solver performance — optimize layout/reuse, not arithmetic.

## Connects To
- **Ch 09 (Performance)**: blocking/tiling and the roofline that explain why BLAS-3 wins.
- **Ch 07 (Numerical LA)**: the factorizations that block algorithms accelerate.
- **Ch 08 (Iterative solvers)**: the sparse matvec's memory-bound ceiling.
- **Ch 02 (Architecture)**: the memory hierarchy the microkernel is tuned against.
