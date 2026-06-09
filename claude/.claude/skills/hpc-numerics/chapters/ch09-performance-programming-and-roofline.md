# Chapter 9: Programming for Performance — Cache Blocking, Tiling & Roofline

## Core Idea
Peak floating-point performance is almost never achieved because the **memory wall** (Ch 2) starves the ALUs. The fix is **data reuse**: restructure loops so data, once loaded into cache, serves many operations before eviction. **Cache blocking/tiling** is the central technique, and the **roofline model** tells you whether a kernel is even capable of approaching peak.

## Frameworks Introduced

- **Peak vs achieved performance**: theoretical peak = (FP results/cycle) × clock × cores. Almost nothing reaches it — the chapter is essentially a catalogue of what stands between your code and peak, and the answer is overwhelmingly **insufficient data reuse**.

- **The roofline model** (can this kernel reach peak?):
  - Plot attainable FLOP/s vs **arithmetic intensity** (also "operational intensity") = FLOPs per byte of memory traffic.
  - Two ceilings: a slanted **memory-bandwidth roof** (intensity × bandwidth) at low intensity, a flat **peak-compute roof** at high intensity. The **ridge point** is where they meet.
  - **Below the ridge** → memory-bound (the kernel can't possibly reach peak; optimize data movement/reuse). **Above** → compute-bound (optimize arithmetic throughput).
  - The roofline is the first triage: it tells you the *ceiling* and *which lever* before you optimize.

- **Cache blocking / tiling** (the reuse technique):
  - Restructure a loop so the data it touches fits in a fast cache level, and reuse it fully before moving on. **Loop tiling**: split a loop into an outer loop over blocks and an inner loop within a block sized so the block's data fits in L1 (or L2).
  - **Loop ordering / interchange**: the order of nested loops changes which array is accessed with unit stride and how input/output data is reused — reorder for locality (e.g. matrix-vector product loop order changes reuse of `x` vs `y`).
  - **Loop unrolling**: expose more independent operations to the pipeline (fills the n½ requirement, Ch 2).

## Key Concepts
- **Arithmetic intensity is the key number**: it determines the roofline ceiling. Raising it (more operations per loaded byte) is how you move a memory-bound kernel toward compute-bound. Tiling and fusion raise it.
- **Reuse at the highest cache level you can**: L1 reuse beats L2 beats L3 beats DRAM. Block so the working set fits as high in the hierarchy as possible — L1 reuse gives the best performance, L2 reuse less.
- **Blocking changes evaluation order → not always compiler-legal**: because floating-point arithmetic isn't associative (Ch 3), reordering/blocking can change results, so the compiler can't always do it automatically — you must do it explicitly (and accept the reproducibility implications).
- **Matrix-matrix product is the canonical near-peak kernel**: it has O(n³) operations on O(n²) data → high arithmetic intensity, so with proper blocking it approaches peak. Matrix-vector (O(n²) ops, O(n²) data) is memory-bound — low intensity, can't reach peak.

## Mental Models
- **Locate the kernel on the roofline first** — it tells you the ceiling and whether to optimize memory (below ridge) or compute (above). Optimizing the wrong axis is wasted effort; this is the single best triage.
- **Optimization = engineering data reuse** — tile/block so loaded data serves many operations before eviction; the more operations per byte (arithmetic intensity), the closer to peak you can get.
- **Reorder loops for locality** — the nested-loop order decides unit-stride access and reuse; the right order can be several times faster with identical operation count.
- **High arithmetic intensity is the goal, and it's structural** — a matrix-vector product is fundamentally memory-bound (you can't tile your way past O(1) reuse); a matrix-matrix product is fundamentally compute-bound (O(n) reuse) — recognize which regime your kernel is in.

## Code Examples
```text
Arithmetic intensity (AI) = FLOPs / bytes moved
Roofline ceiling          = min(peak_FLOPs, AI × peak_bandwidth)

Matrix-vector y = Ax:   2n² flops, ~n² data  →  AI ≈ O(1)   → MEMORY-bound
Matrix-matrix C = AB:   2n³ flops, ~3n² data →  AI ≈ O(n)   → COMPUTE-bound (near peak with blocking)

Cache blocking (tile the matrix-matrix product so a tile fits in L1):
    for ii in 0..n step B:           # outer: blocks
      for jj in 0..n step B:
        for kk in 0..n step B:
          for i in ii..ii+B:         # inner: tile reused from cache
            for j in jj..jj+B:
              for k in kk..kk+B:
                C[i,j] += A[i,k]*B[k,j]
```
- **What it demonstrates**: arithmetic intensity separating memory- from compute-bound, and the tiled matrix-matrix product.

## Reference Tables

| Kernel | Arithmetic intensity | Regime |
|---|---|---|
| vector add / matrix-vector | O(1) | memory-bound |
| matrix-matrix product | O(n) | compute-bound (near peak) |

| Technique | Effect |
|---|---|
| cache blocking / tiling | reuse data in fast cache → raise intensity |
| loop interchange | unit-stride access + better reuse |
| loop unrolling | fill the pipeline (n½) |
| fusion | fewer passes over data |

## Key Takeaways
1. Peak performance is rarely achieved because the memory wall starves the ALUs — optimization is overwhelmingly about data reuse.
2. The roofline model (attainable FLOP/s vs arithmetic intensity) triages a kernel as memory-bound (below ridge, optimize data movement) or compute-bound (above, optimize arithmetic).
3. Cache blocking/tiling restructures loops so working data fits and is reused in the highest cache level possible (L1 best).
4. Arithmetic intensity is structural: matrix-vector is memory-bound (O(1) reuse), matrix-matrix is compute-bound (O(n) reuse, near peak with blocking).
5. Blocking/reordering changes floating-point evaluation order, so compilers can't always do it — do it explicitly, mindful of reproducibility.

## Connects To
- **Ch 02 (Architecture)**: the memory hierarchy and locality this exploits.
- **Ch 10 (HP linear algebra)**: BLAS-3 blocking is the production form of this.
- **Ch 03 (Arithmetic)**: why blocking isn't a free compiler transformation (non-associativity).
- **Ch 08 (Iterative solvers)**: the sparse matvec is memory-bound — roofline explains its ceiling.
