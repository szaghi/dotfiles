# Patterns — OpenMP 6.0 idioms

Concrete techniques. Format: **When / How / Trade-offs.**

## Parallel loop with explicit data scoping
**When**: a data-parallel loop on CPU threads.
**How**: `#pragma omp parallel for default(none) shared(...) private(...) reduction(op:acc) schedule(...)`. (Ch7, 12, 13)
**Trade-offs**: `default(none)` forces correctness review; `schedule` tunes balance.

## Reduction over manual accumulation
**When**: accumulating into a shared scalar/array across iterations.
**How**: `reduction(+:sum)` (or user-defined via `declare reduction`); never `+=` into a shared var. (Ch7)
**Trade-offs**: correct and fast; `atomic` only for irregular scatter.

## GPU offload — canonical pattern
**When**: offloading a loop nest to an accelerator.
**How**: `#pragma omp target teams distribute parallel for map(...)`. (Ch12, 15)
**Trade-offs**: league of teams → distribute across teams → parallel-for within; the standard GPU idiom.

## Persistent device data (the #1 offload optimization)
**When**: iterative solver reusing arrays across many `target` kernels.
**How**: `target enter data map(to:...)` once, `present`/resident data in kernels, `target exit data map(from:...)` at end; `target update` for partial sync. (Ch15)
**Trade-offs**: eliminates per-kernel transfers — usually decides whether offload wins.

## Separate input/output mapping
**When**: any `target` region.
**How**: `map(to: inputs) map(from: outputs) map(alloc: scratch)` — never blanket `tofrom`. (Ch7, 15)
**Trade-offs**: halves transfer volume vs `tofrom` everywhere.

## Dependence-driven task DAG
**When**: irregular/pipelined parallelism with data flow.
**How**: generate tasks from `single`/`masked`; `task depend(out:x)` producer, `depend(in:x)` consumer — the runtime schedules the DAG. (Ch14)
**Trade-offs**: replaces fragile manual barriers; one generating thread.

## taskgraph record/replay (6.0)
**When**: the same task graph is regenerated every iteration (stable pattern).
**How**: wrap in `taskgraph`; record once, replay cheaply; `graph_reset` to re-record. (Ch14)
**Trade-offs**: amortizes task-creation overhead; antecedent tasks must agree on replayability (errata).

## Recursive tasking with cutoff
**When**: divide-and-conquer (sort, tree).
**How**: `task final(small) mergeable` at leaves + `taskwait`. (Ch14)
**Trade-offs**: `final` stops unbounded fine-grained task creation.

## NUMA-aware threading
**When**: bandwidth/latency-sensitive CPU code on multi-socket.
**How**: `OMP_PROC_BIND=spread|close` + `OMP_PLACES=cores`; `proc_bind` clause per region; allocator `partition(nearest|interleaved)`. (Ch4, 8, 12)
**Trade-offs**: `spread` for bandwidth, `close` for cache sharing; pins threads, prevents migration.

## High-bandwidth memory placement
**When**: bandwidth-bound data on HBM-equipped nodes.
**How**: build an `omp_high_bw_mem_alloc`-based allocator (or `OMP_ALLOCATOR`), `omp_alloc` hot arrays there. (Ch8)
**Trade-offs**: HBM is small; place only the hottest data.

## Host/device specialization without #ifdef
**When**: one source, different impls per target/ISA.
**How**: `metadirective when(target_device={kind(nohost)}: ...)` / `declare variant match(device={isa(...)})`. (Ch9)
**Trade-offs**: compiler resolves against real context; cleaner than preprocessor branching.

## Portable timing
**When**: benchmarking a parallel region.
**How**: `omp_get_wtime()` before/after, with synchronization (region barrier / `taskwait` / target `nowait` join) so async work completes first. (Ch17)
**Trade-offs**: never `cpu_time`/`clock()` (sums CPU across threads); a missing join fakes huge speedups.

## Atomic for irregular scatter
**When**: histogram/counter where `reduction` doesn't fit.
**How**: `#pragma omp atomic update` (or `atomic capture` for fetch-and-modify; 6.0 `atomic compare` for CAS). (Ch16)
**Trade-offs**: serializes contended locations; prefer `reduction` for true reductions.
