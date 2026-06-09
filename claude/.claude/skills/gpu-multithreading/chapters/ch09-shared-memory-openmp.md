# Chapter 9: Directive-Based Shared-Memory Programming with OpenMP

## Core Idea
OpenMP parallelizes shared-memory code through **compiler directives** (`#pragma omp` in C/C++, `!$omp` in Fortran) rather than explicit thread management: annotate a loop or region and the runtime forks a team of threads. The same source compiles serially on a non-OpenMP compiler (directives become comments). Correctness lives in the **data-sharing clauses**; performance lives in scheduling, affinity, and avoiding false sharing.

## Frameworks Introduced

### The fork–join model
A `parallel` region forks a team of threads; worksharing constructs divide work among them; the team joins at an implicit barrier at the region's end.

```c
#pragma omp parallel num_threads(8)
{
    int id = omp_get_thread_num();      // 0 .. omp_get_num_threads()-1
    work(id);
}                                        // implicit barrier (join)
```
Runtime API: `omp_get_thread_num()`, `omp_get_num_threads()`, `omp_get_max_threads()`, `omp_set_num_threads()`, `omp_get_wtime()` (timing). Control via `OMP_NUM_THREADS`, `OMP_SCHEDULE`, `OMP_PROC_BIND`, `OMP_PLACES`.

### Worksharing constructs
- **`for`** (Fortran `do`) — distribute loop iterations:
  ```c
  #pragma omp parallel for schedule(dynamic, 64)
  for (int i = 0; i < n; ++i) heavy(i);
  ```
- **`sections`** — distinct code blocks run by different threads.
- **`single`** / **`master`** — one thread executes (`single` has an implicit barrier + `nowait` option; `master` does not).
- **`task`** — irregular/recursive parallelism via a task pool, with `depend(in:/out:/inout:)` for dependencies.
- **`simd`** — request vectorization; combine: `#pragma omp parallel for simd`.
- **`teams` / `distribute` / `target`** — the offload stack (below).

### Data-sharing clauses (the heart of correctness)
| Clause | Semantics |
|---|---|
| `shared(v)` | one instance, all threads (default for most vars) |
| `private(v)` | per-thread, **uninitialized** copy |
| `firstprivate(v)` | private, initialized from the value before the region |
| `lastprivate(v)` | private, value from the logically last iteration copied out |
| `reduction(op:v)` | per-thread private copy + combine with `op` at region end |
| `default(none)` | force explicit classification of every variable |

The canonical correctness progression for a parallel accumulation:
1. **Manual partitioning** — split the range by thread id; works but verbose.
2. **Shared accumulator without protection** — *data race* (the bug).
3. **`critical` / `atomic`** — correct but serializes the update (performance-sapping).
4. **`reduction(+:sum)`** — correct *and* parallel: each thread accumulates a private copy (initialized per the operator: 0 for `+`, 1 for `*`, `-INF` for `max`), combined at the end.

```c
double sum = 0.0;
#pragma omp parallel for reduction(+:sum) default(none) shared(a, n)
for (int i = 0; i < n; ++i) sum += a[i];      // each thread private, combined at end

double mx = -DBL_MAX;
#pragma omp parallel for reduction(max:mx) shared(a, n)
for (int i = 0; i < n; ++i) mx = a[i] > mx ? a[i] : mx;
```

### Scheduling (load balance vs overhead)
`schedule(kind[, chunk])` on a `for`:
| Kind | Behavior | Use |
|---|---|---|
| `static` | iterations split into equal contiguous chunks up front | uniform work (lowest overhead) |
| `dynamic` | threads grab `chunk` iterations as they finish | irregular/variable work |
| `guided` | dynamic with shrinking chunk sizes | irregular, fewer scheduling ops |
| `auto` | runtime/compiler decides | trust the implementation |
| `runtime` | from `OMP_SCHEDULE` | tune without recompiling |

### Synchronization
- **`barrier`** — explicit team barrier. **`nowait`** — drop the implicit barrier at the end of a worksharing construct.
- **`critical [name]`** — mutual exclusion over a multi-statement block (serializes; name to allow independent critical regions).
- **`atomic`** — a single read-modify-write to one memory location; far cheaper than `critical` but covers only one operation (`#pragma omp atomic update/read/write/capture`).
- **`ordered`** — execute a loop region in iteration order; **`flush`** — the memory-consistency point.
- **Locks**: `omp_lock_t` with `omp_init/set/unset/destroy_lock` for fine-grained control.

### Tasks (irregular & recursive parallelism)
```c
#pragma omp parallel
#pragma omp single                   // one thread spawns the task tree
{
    for (auto* node : worklist)
        #pragma omp task firstprivate(node)
        process(node);               // task pool load-balances across the team
}                                     // implicit taskwait at end of region
```
Use `#pragma omp taskwait` to wait for child tasks; `depend` clauses to express a task DAG (`depend(out: x)` → `depend(in: x)` orders them).

### GPU / accelerator offload (OpenMP 4.0+)
**Data-mapping** (`map`) moves data across the host/device boundary and is **separate** from thread data-sharing — conflating them is the top offload bug.
```c
#pragma omp target teams distribute parallel for \
        map(to: x[0:n]) map(tofrom: y[0:n])
for (int i = 0; i < n; ++i) y[i] = a*x[i] + y[i];
```
- `target` offloads a region; `teams` creates leagues (≈ CUDA blocks); `distribute` splits across teams; `parallel for` splits within a team. `map(to:)`/`map(from:)`/`map(tofrom:)`/`map(alloc:)` control transfer direction.

## Key Concepts
- **Default data-sharing trap**: loop-body temporaries that should be `private` are often `shared` by default → races. `default(none)` forces you to classify every variable and catches this at compile time.
- **Loop-carried dependencies** block parallel `for` — an iteration must not depend on another's result. Rewrite to make values depend only on the loop index (e.g. closed-form instead of running accumulation), or use `reduction`/`ordered`.
- **False sharing** (8.12.2): threads writing distinct variables on the same cache line silently serialize via coherence traffic. Pad/align per-thread accumulators to a cache line, or use `reduction` (which gives each thread a private copy).
- **Thread affinity** (`OMP_PROC_BIND`, `OMP_PLACES`): pinning threads to cores/sockets controls NUMA locality and stops the OS migrating threads away from their data — often a large, free speedup on multi-socket nodes.

## Mental Models
- **Always use `default(none)`** — it forces explicit shared/private classification and catches the most common OpenMP race at compile time.
- **Use `reduction` for any accumulation** — never `critical { s += x; }`; the reduction clause is both parallel and false-sharing-free, where the critical version serializes.
- **`atomic` for one shared memory op, `critical` for a multi-statement region** — `atomic` is much cheaper but narrower.
- **Match `schedule` to the workload** — `static` for balanced loops (lowest overhead), `dynamic`/`guided` for irregular; the wrong choice shows up as load imbalance or scheduling overhead.
- **Pin threads on NUMA machines** — `OMP_PROC_BIND=close/spread` + first-touch allocation keeps each thread's data local; ignoring affinity is a silent scaling cliff.
- **GPU offload `map` ≠ thread `shared`** — keep data-mapping (host↔device) and data-sharing (thread visibility) as distinct concepts.

## Reference Tables

| Construct | Use |
|---|---|
| `parallel for` | distribute loop iterations |
| `task` + `depend` | irregular / DAG parallelism |
| `simd` | vectorization |
| `target`+`teams`+`distribute` | GPU/accelerator offload |
| `critical` / `atomic` | multi-op / single-op exclusion |
| `barrier` / `nowait` | add / remove synchronization |

| Reduction op | Identity |
|---|---|
| `+`, `-` | 0 |
| `*` | 1 |
| `min` | +∞ |
| `max` | −∞ |
| `&`, `&&` | ~0, 1 |
| `|`, `||`, `^` | 0 |

## Key Takeaways
1. OpenMP is directive-based fork–join: annotate regions/loops; the runtime manages the thread team.
2. Data-sharing clauses are where correctness lives — use `default(none)`; the right way to parallelize an accumulation is `reduction`, not a `critical`-guarded `+=`.
3. Match `schedule` (static/dynamic/guided) to workload regularity; use `task` + `depend` for irregular/DAG work.
4. Avoid false sharing (pad per-thread data or use `reduction`) and pin threads on NUMA machines (`OMP_PROC_BIND` + first touch).
5. GPU offload via `target`/`teams`/`distribute` keeps data-*mapping* (`map`) distinct from thread data-*sharing* — conflating them is the top offload bug.

## Connects To
- **Ch 04 (C++ threads)**: the lower-level shared-memory model OpenMP sits above.
- **Ch 05 (Reductions)**: `reduction` and the floating-point reproducibility caveat.
- **Ch 06 (MPI)**: OpenMP is the within-node layer of hybrid MPI+OpenMP.
- **Ch 12 (Optimization)**: false sharing, NUMA affinity, and timing discipline.
