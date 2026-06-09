# Cheatsheet — OpenMP 6.0

## Errata (Nov 2025) — applied corrections
| Section | Correction |
|---|---|
| §7.5.9 `has_device_addr` | array section/element base must be a base-language identifier |
| §7.5.10 `is_device_ptr` | "array section **or an array element**" |
| §7.9.9 `defaultmap` | `implicit-behavior=private` → data-sharing attribute `private` |
| §8.4 `allocator` clause | allocator at directive must match allocator at variable declaration |
| §10.5 `requires` | "must appear lexically" → "must **NOT** appear lexically" (sign fix) |
| §14.3 `taskgraph` | antecedent tasks across constructs: both replayable or both not |
| §14.3.2 `graph_reset` | default property → **optional** |
| §14.6 `replayable` | default property → **unique** |
| §20.12.1 control-tool enum | add `omp_control_tool_max = INT32_MAX` |
| §25.2.2 `omp_target_is_accessible` | returns 0 if ptr NULL **or** accessibility not guaranteed |
| §27.11 | word "constant" removed from a restriction |

## New in 6.0 (vs 5.2)
Loop-transform constructs (`tile`/`unroll`/`reverse`/`interchange`/`fuse`/`split`/`stripe`) + `apply` clause · `taskgraph` record/replay (`replayable`/`graph_reset`) · free-agent threads · `safesync` · `masked` (replaces `master`) · expanded memory allocators/spaces + device allocator routines · `groupprivate` · richer `metadirective`/`declare variant` · device-UID routines · `atomic compare` (CAS) · `_OPENMP=202411`.

## Decision rules

### Data-sharing — classify every variable (use `default(none)`)
| Need | Clause |
|---|---|
| one shared instance | `shared` |
| per-thread, uninitialized | `private` |
| per-thread, init from original | `firstprivate` |
| private + export last value | `lastprivate` |
| accumulate across iterations | `reduction(op:var)` |

### Data-mapping (device) — never blanket `tofrom`
`to`=input · `from`=output · `tofrom`=both · `alloc`=scratch · `release`/`delete`=exit. Hoist with `target enter/exit data`; refresh with `target update`.

### schedule kind
- uniform iterations → `static` (cache-friendly, no overhead)
- irregular/imbalanced → `dynamic`/`guided`
- tune without recompile → `runtime` (`OMP_SCHEDULE`)
- chunk too small (`dynamic,1`) → overhead; too big → imbalance.

### Which parallelism construct?
- CPU thread team → `parallel` (+ worksharing `for`/`sections`/`single`)
- GPU offload → `target teams distribute parallel for`
- vectorize → `simd`
- one/few threads → `masked filter(...)` (not `master`)
- irregular/recursive/data-flow → `task` + `depend`

### Synchronization
- one-location update → `atomic` (not `critical`, not manual)
- accumulation → `reduction`
- region mutex → `critical(name)`
- team rendezvous → `barrier`
- task wait → `taskwait`/`taskgroup`
- visibility → relies on flushes (release→acquire); most sync constructs imply them.

## Defaults & knobs
- `OMP_NUM_THREADS` + `OMP_PROC_BIND=spread|close` + `OMP_PLACES=cores` — core HPC trio.
- `OMP_DYNAMIC=false` for an exact thread count.
- `OMP_TARGET_OFFLOAD=MANDATORY` — fail instead of silent host fallback.
- `OMP_DISPLAY_ENV=VERBOSE` — dump effective ICVs at startup.
- `OMP_SCHEDULE` feeds `schedule(runtime)`; `OMP_ALLOCATOR` sets default allocator.

## Tells & smells
- **`cpu_time`/`clock()` for parallel timing** → wrong; sums CPU across threads. Use `omp_get_wtime` + sync. (feedback_gpu_benchmark_timing)
- **`map(tofrom:)` per `target`** → re-transfers each launch; hoist with `target enter/exit data`.
- **`map(a)` no bounds** → ambiguous; `map(tofrom: a[0:n])`.
- **Manual `+=` into shared var** → race; use `reduction`.
- **Tasks generated outside `single`/`masked`** → duplicated by every thread.
- **`omp_set_num_threads` not taking effect "now"** → it sets future regions, not the running one.
- **Silent slowdown after "offload"** → host fallback (device absent); set `OMP_TARGET_OFFLOAD=MANDATORY`.
- **Cross-team / busy-wait sync** → deadlock; sync only within a team.
- **Stale shared reads** → missing flush/sync; weak memory model needs release→acquire.
- **Consumer NVIDIA GPU, FP64 slow** → 1:64 FP64:FP32; FP32-store/FP64-compute is a trap. (reference_consumer_gpu_fp64_trap)

## MPI + OpenMP (hybrid)
- Pin: one rank per socket/NUMA, `OMP_NUM_THREADS` = cores/rank, `OMP_PROC_BIND=close`, `OMP_PLACES=cores`.
- `MPI_THREAD_FUNNELED`/`_MULTIPLE` per how threads call MPI; isolate MPI to `single`/`masked` unless `_MULTIPLE`.
- `target` + device-aware MPI: get the device pointer via `is_device_ptr`/`omp_get_mapped_ptr`.
