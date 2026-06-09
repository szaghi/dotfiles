# Patterns & Techniques — GPU & Multithreaded Programming

## PCAM design pass
**When to use**: any from-scratch parallel design.
**How**: Partition (finest tasks) → Communicate (build the dependency graph) → Agglomerate (group to cut comms) → Map (balance onto PEs).
**Trade-offs**: forces you to see the dependency graph before coding; agglomeration trades parallelism for locality.

## Geometric (domain) decomposition + halo exchange
**When to use**: grids, stencils, PDEs, image processing.
**How**: partition the array into tiles; each worker owns a tile and exchanges ghost cells with neighbors.
**Trade-offs**: larger tiles → better surface-to-volume (less comms per compute); the workhorse of MPI and GPU tiling.

## Master–worker / task farm
**When to use**: irregular, unpredictable, or data-dependent task durations.
**How**: a coordinator dispatches work units to idle workers; collect results.
**Trade-offs**: self-balancing; the coordinator can bottleneck at scale (then switch to work stealing).

## Roofline triage
**When to use**: "why is my kernel slow?"
**How**: compute arithmetic intensity (FLOPs/byte); below the ridge → memory-bound (optimize data movement), above → compute-bound (optimize math).
**Trade-offs**: tells you *what* to optimize before you spend effort; memory-bound kernels don't benefit from faster math.

## RAII locking
**When to use**: any shared-mutable-state access under threads.
**How**: `std::lock_guard`/`scoped_lock` (never raw lock/unlock); `scoped_lock` for multiple mutexes.
**Trade-offs**: exception-safe, deadlock-free multi-lock; the only correct locking discipline.

## Release/acquire publish-protect
**When to use**: one thread/process publishes data for another.
**How**: producer writes data then `store(flag, release)`; consumer spins on `load(flag, acquire)` then reads.
**Trade-offs**: cheaper than seq_cst; requires a happens-before proof. Default seq_cst otherwise.

## Parallel reduction via `reduction` clause
**When to use**: any accumulation (sum/max/min) across threads.
**How**: OpenMP `reduction(+:s)`, MPI `Allreduce`, GPU tree reduction — never a `critical`-guarded `+=`.
**Trade-offs**: parallel and correct; floating-point results reorder (not bitwise reproducible).

## Shared-memory tiling (GPU)
**When to use**: GPU kernels reusing data (stencils, matmul).
**How**: stage a tile of global memory into shared memory, `__syncthreads()`, compute from shared, repeat.
**Trade-offs**: raises arithmetic intensity, moves the kernel up the roofline; watch bank conflicts.

## Coalesced access / SoA layout
**When to use**: any GPU kernel (and vectorized CPU code).
**How**: lay out data Structure-of-Arrays so consecutive threads touch consecutive addresses.
**Trade-offs**: the single highest-impact GPU optimization; AoS often defeats coalescing/vectorization.

## Communication/computation overlap
**When to use**: MPI halo exchange, GPU copy+compute.
**How**: post nonblocking comms (`Isend`/`Irecv`, `cudaMemcpyAsync` on a stream), compute the interior, then wait and compute the boundary.
**Trade-offs**: hides latency; requires splitting interior/boundary work.

## CAS retry loop (lock-free)
**When to use**: a proven lock contention hotspot.
**How**: read current → compute desired → `compare_exchange_weak` in a loop.
**Trade-offs**: high concurrency, no blocking; complex, ABA-prone — earn it with profiler evidence.

## Synchronized benchmark harness
**When to use**: every parallel measurement.
**How**: warm up; synchronize (device sync / `MPI_Wait` / events) before stopping a monotonic clock; repeat; report variance vs an optimized baseline.
**Trade-offs**: prevents the "impossible >100× speedup" artifact from a missing synchronization.

## Static vs dynamic load balancing
**When to use**: static for predictable work on known hardware; dynamic for irregular work.
**How**: static = proportional/DLT partition up front; dynamic = master–worker or work stealing.
**Trade-offs**: static has zero overhead but can't adapt; dynamic adapts at coordination cost. Combine: static split + dynamic correction.
