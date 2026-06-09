# Chapter 8: OpenMP — Directive-Based Shared-Memory Parallelism

## Core Idea
OpenMP parallelizes shared-memory C++ with **compiler directives** (`#pragma omp`) rather than explicit threads: annotate a loop or region and the runtime forks a team of threads. Correctness lives in the **data-sharing clauses**; the canonical mistakes are unprotected shared writes and serializing what should be a `reduction`.

## Frameworks Introduced

- **The fork–join model**: `#pragma omp parallel` forks a thread team; worksharing constructs split work; the team joins at an implicit barrier.

```cpp
#pragma omp parallel for reduction(+:sum) num_threads(8)
for (int i = 0; i < n; ++i)
    sum += a[i] * b[i];               // each thread accumulates privately, combined at end
```

- **Worksharing constructs**: `for` (distribute loop iterations), `sections` (distinct blocks), `single`/`master` (one thread), `task` (irregular/recursive work with `depend`), `simd` (vectorize). Combine: `parallel for simd`.

- **Data-sharing clauses** (the heart of correctness):
  - `shared(v)` — one instance for all threads (default for most variables).
  - `private(v)` — per-thread, uninitialized copy.
  - `firstprivate(v)` — private, initialized from the pre-region value.
  - `lastprivate(v)` — private, last iteration's value copied out.
  - `reduction(op:v)` — per-thread private copy combined with `op` at the end (the correct way to parallelize an accumulation).

- **Scheduling & synchronization**:
  - `schedule(static|dynamic|guided[,chunk])` — `static` for uniform work (low overhead), `dynamic`/`guided` for irregular (load-balances at cost).
  - `barrier`, `nowait` (drop an implicit barrier), `critical` (multi-statement mutual exclusion), `atomic` (single memory op, cheaper than critical), `collapse(n)` (merge nested loops).
  - **Tasks**: `#pragma omp task` inside a `single` region builds a task pool for irregular/recursive parallelism; `taskwait`/`depend` order them.

## Key Concepts
- **The default-sharing trap**: loop-body temporaries that should be `private` are often `shared` by default → data races. Use `default(none)` to force explicit classification and catch this at compile time.
- **`reduction` over `critical`**: a `critical`-guarded `sum += x` serializes; `reduction(+:sum)` is parallel and false-sharing-free.
- **`atomic` vs `critical`**: `atomic` covers one memory operation (cheap); `critical` covers a multi-statement block (a lock).
- **Loop-carried dependencies** block parallel `for` — rewrite so iterations depend only on the index, or use `reduction`/`ordered`.
- **GPU offload**: `#pragma omp target teams distribute parallel for map(...)` offloads to an accelerator — `map` (data movement) is separate from data-sharing.

## Mental Models
- **Always use `default(none)`** — it forces you to classify every variable shared/private and catches the most common OpenMP race at compile time.
- **Use `reduction` for any accumulation** — never hand-roll with `critical`; it's both slower and a correctness trap.
- **Match `schedule` to the workload** — `static` for balanced loops, `dynamic`/`guided` for irregular; the wrong choice shows up as load imbalance.
- **`atomic` for one shared counter, `critical` for a multi-statement region** — and `task` for irregular/recursive work.
- **Pin threads on NUMA machines** (`OMP_PROC_BIND` + first-touch) — keeps each thread's data local; ignoring affinity is a silent scaling cliff.

## Code Examples
```cpp
// Correct accumulation: reduction + default(none)
double sum = 0.0;
#pragma omp parallel for reduction(+:sum) default(none) shared(a, n)
for (int i = 0; i < n; ++i) sum += a[i];

// Irregular work: dynamic schedule + tasks
#pragma omp parallel
#pragma omp single
for (auto* node : worklist)
    #pragma omp task firstprivate(node)
    process(node);                          // task pool load-balances

// GPU offload (map = data movement, separate from sharing)
#pragma omp target teams distribute parallel for map(to: x[0:n]) map(tofrom: y[0:n])
for (int i = 0; i < n; ++i) y[i] = a*x[i] + y[i];
```
- **What it demonstrates**: `reduction`+`default(none)`, task-based irregular work, and `target` offload.

## Reference Tables

| Clause | Meaning |
|---|---|
| `shared` | one instance for all threads |
| `private` | per-thread, uninitialized |
| `firstprivate` | per-thread, init from outside |
| `reduction(op:v)` | private accumulate + combine |
| `schedule(static/dynamic/guided)` | iteration distribution |

| Construct | Use |
|---|---|
| `parallel for` | distribute iterations |
| `task` + `depend` | irregular/recursive work |
| `simd` | vectorization |
| `target`+`map` | GPU offload |
| `atomic` / `critical` | single-op / multi-op exclusion |

## Key Takeaways
1. OpenMP is directive-based fork–join: annotate loops/regions; the runtime manages the thread team.
2. Data-sharing clauses are where correctness lives — use `default(none)`; parallelize accumulations with `reduction`, not `critical`.
3. Match `schedule` (static/dynamic/guided) to workload regularity; use `task`+`depend` for irregular work.
4. `atomic` for one memory op, `critical` for a block; pin threads on NUMA (`OMP_PROC_BIND` + first-touch).
5. `target`/`teams`/`distribute` offload to GPUs; `map` (data movement) is distinct from thread data-sharing.

## Connects To
- **Ch 04 (Parallel patterns)**: the parallel-STL alternative to directives.
- **Ch 05 (Hardware)**: NUMA affinity, false sharing, SIMD.
- **Ch 07 (MPI)**: hybrid MPI+OpenMP (MPI across nodes, OpenMP within).
- **Ch 10 (Kokkos)**: performance-portable abstraction over OpenMP/CUDA backends.
