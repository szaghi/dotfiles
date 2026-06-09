# Chapter 12: Cross-Cutting Optimization & Pitfalls

## Core Idea
Most parallel-performance problems are not algorithmic — they're **locality, contention, and measurement** problems that recur across every technology (threads, MPI, CUDA, OpenMP). This chapter is the triage checklist that applies regardless of the tool.

## Frameworks Introduced

- **The optimization triage order** (cheapest-to-find-first):
  1. **Measure correctly** — establish a representative baseline and a synchronized timing harness *before* changing anything.
  2. **Locate on the roofline** — is the kernel memory-bound or compute-bound? (Ch 3.) This decides what to optimize.
  3. **Fix locality** — coalescing/cache behavior, data layout (SoA vs AoS), tiling, NUMA placement.
  4. **Fix contention** — lock granularity, false sharing, atomic hotspots, collective vs point-to-point.
  5. **Fix load balance** — stragglers and idle workers (Ch 11).
  6. **Overlap** — communication/computation and copy/compute overlap last.

- **The recurring pitfall catalogue**:
  - **Data race** — unsynchronized shared write ⇒ UB (threads, OpenMP default-shared, GPU global writes).
  - **False sharing** — distinct variables on one cache line silently serialize; pad/align per-thread hot data.
  - **Uncoalesced / cache-hostile access** — the #1 GPU and a major CPU performance killer; restructure data layout.
  - **Deadlock** — circular lock acquisition (threads) or mismatched blocking send/recv (MPI).
  - **Excessive host↔device transfer** — PCIe dominates; minimize, batch, and overlap.
  - **Floating-point non-reproducibility** — parallel reductions reorder additions; results differ run-to-run/thread-count-to-thread-count.

## Key Concepts
- **Benchmark timing discipline**: GPU kernel launches and async MPI/CUDA calls are *asynchronous* — you must **synchronize** (device sync / `MPI_Wait` / events) before stopping the clock. Use a monotonic clock and warm up. A missing synchronization is the classic cause of an impossible ">100× speedup."
- **Representative baseline**: compare against an *optimized* serial version (vectorized, cache-friendly) — beating a deliberately slow baseline proves nothing.
- **Data layout**: Structure-of-Arrays (SoA) enables coalescing/vectorization; Array-of-Structures (AoS) often defeats it.
- **Arithmetic intensity**: raise it (tiling, fusion, fewer bytes) to move memory-bound kernels up the roofline.
- **Consumer-GPU FP64 trap**: gaming GPUs run FP64 at ~1:32–1:64 of FP32; FP32-store/FP64-compute hybrids are usually slower than honest FP64 — measure, don't assume.

## Mental Models
- **Measure before and after, with a synchronized harness — always.** Most reported parallel "wins" and "losses" are measurement artifacts. Synchronize, warm up, repeat, report variance.
- **Locality first, then contention, then overlap.** Locality fixes (coalescing, tiling, SoA) usually dominate; lock-free heroics and clever overlap are later, smaller wins.
- **A >N× speedup on N cores is a bug in your measurement, not a triumph** — almost always a missing synchronization or an unfair baseline.
- **Reproducibility is a deliberate choice in parallel FP** — if bitwise reproducibility matters, fix the reduction order or use compensated summation; otherwise document that results vary with thread/process count.
- **Profile, don't guess** — the bottleneck is rarely where intuition says; use a profiler (perf, Nsight, VTune, MPI tracing) to find it.

## Reference Tables

| Symptom | Likely cause | Fix |
|---|---|---|
| ">100× speedup" | missing sync before timing | device/event/`MPI_Wait` sync |
| scaling cliff at N threads | false sharing / NUMA | pad/align, pin threads + data |
| GPU slow despite occupancy | uncoalesced access | SoA, contiguous per warp |
| stalls between phases | host↔device transfer | minimize/overlap, unified mem |
| results vary run-to-run | FP reduction reorder | fixed order / Kahan |
| hangs | deadlock | lock order / `Sendrecv` |

| Optimize for | Lever |
|---|---|
| memory-bound | reuse, tiling, fewer bytes, coalesce |
| compute-bound | vectorize, FMA, ILP, occupancy |
| imbalanced | dynamic schedule, work stealing |

## Key Takeaways
1. Triage in order: measure correctly → roofline → locality → contention → load balance → overlap.
2. Always synchronize before timing async (GPU/MPI) work and compare against an optimized baseline — most "speedups" are measurement artifacts.
3. Locality (coalescing, tiling, SoA, NUMA placement) is usually the biggest lever; fix it before lock-free or overlap heroics.
4. The recurring pitfalls — data races, false sharing, uncoalesced access, deadlock, excess transfer, FP non-reproducibility — span every technology.
5. Parallel floating-point results vary with thread/process count unless you fix the reduction order; profile to find the real bottleneck rather than guessing.

## Connects To
- **Ch 03 (Roofline)**: the memory-vs-compute triage.
- **Ch 04 (Threads)**: data races, false sharing, deadlock.
- **Ch 07 (CUDA)**: coalescing, occupancy, transfer overlap, FP64 trap.
- **Ch 05 / Ch 09 (Reductions)**: floating-point reproducibility.
