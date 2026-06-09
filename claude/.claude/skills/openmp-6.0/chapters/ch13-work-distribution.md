# Chapter 13: Work-Distribution Constructs

## Core Idea
Constructs that **divide work across the threads of a team** (or teams of a league): the worksharing-loop (`for`/`do`), `sections`, `single`, `workshare` (Fortran), `distribute` (across teams), `scan` (prefix sums), and the unifying `loop` construct.

## Frameworks Introduced
- **worksharing-loop** (`for` / `do`): partition canonical-loop iterations across the team. Clauses: **`schedule(kind[, chunk])`**, `collapse(n)`, `ordered`, `nowait`, `reduction`, `lastprivate`, `linear`, `order(concurrent)`.
  - **schedule kinds**: `static` (round-robin chunks, low overhead, predictable), `dynamic` (threads grab chunks on demand, load-balances irregular work), `guided` (shrinking chunks), `auto` (compiler/runtime decides), `runtime` (from `run-sched-var`/`OMP_SCHEDULE`). Modifiers: `monotonic`/`nonmonotonic`, `simd`.
- **`sections`**: each `section` block runs once, on one thread (independent task-like blocks).
- **`single`**: exactly one thread runs the block; implicit barrier at end unless `nowait`; `copyprivate` broadcasts the result.
- **`workshare`** (Fortran): parallelize array-syntax / `FORALL` / `WHERE` statements.
- **`distribute`**: partition loop iterations across the **teams** of a league (the device-offload counterpart of worksharing-loop); combined as `distribute parallel for`.
- **`scan`** + `reduction(inscan, op: x)`: compute inclusive/exclusive **prefix sums** in parallel.
- **`loop`** construct: a *descriptive* worksharing — "these iterations are concurrent, you choose the mapping" (binds to teams/parallel/single per context); `order(concurrent)` and `bind(...)`.

## Key Concepts
- **`schedule` choice is the main loop-tuning lever**: `static` for uniform iterations (cache-friendly, no runtime overhead); `dynamic`/`guided` for irregular/imbalanced work (load-balances at the cost of contention).
- **`nowait`** removes the implicit end barrier — chain independent worksharing regions without forcing all threads to rendezvous.
- **`loop` vs `for`**: `loop` asserts concurrency and lets the implementation map it (more portable across host/device); `for` is the explicit thread-worksharing form.
- **`distribute` needs `teams`**; `distribute parallel for` is the two-level GPU split (across teams, then across threads).

## Reference Tables
### schedule kinds
| Kind | Behavior | Use when |
|---|---|---|
| `static[,chunk]` | fixed round-robin chunks | uniform iterations; predictable, cache-friendly |
| `dynamic[,chunk]` | grab chunk on completion | irregular/imbalanced work |
| `guided[,chunk]` | shrinking chunks | imbalanced, fewer scheduling ops than dynamic |
| `auto` | implementation decides | trust the runtime |
| `runtime` | from `OMP_SCHEDULE` | tune without recompiling |

## Code Examples
```c
#pragma omp parallel for schedule(dynamic, 16) reduction(+: sum) nowait
for (int i = 0; i < n; ++i) sum += expensive_irregular(i);

#pragma omp parallel
{
  #pragma omp sections
  { #pragma omp section
    phase_a();
    #pragma omp section
    phase_b(); }            // a and b run on (up to) two threads
}

// prefix sum
#pragma omp parallel for reduction(inscan, +: running)
for (int i = 0; i < n; ++i) { running += a[i]; #pragma omp scan inclusive(running) b[i] = running; }
```
- **Demonstrates**: `schedule(dynamic)` + `reduction` + `nowait` for irregular work, `sections` for task-parallel phases, and `scan` for a parallel prefix sum.

## Anti-patterns
- **`schedule(static)` for highly irregular iterations**: load imbalance — use `dynamic`/`guided`.
- **`schedule(dynamic, 1)` for cheap iterations**: scheduling overhead dominates — increase chunk size.
- **`nowait` then reading another region's output without synchronization**: removes the barrier you needed — only use when regions are independent.
- **Worksharing construct outside a `parallel` region (orphaned) without understanding binding**: it binds to the enclosing team at runtime; an orphaned `for` with no team runs serially.
- **`distribute` without `teams`**: ill-formed; pair them.

## Key Takeaways
1. `schedule` is the loop-tuning lever: `static` (uniform), `dynamic`/`guided` (irregular), `runtime` (`OMP_SCHEDULE`).
2. `nowait` drops the implicit end barrier — only when regions are independent.
3. `loop` (descriptive, portable) vs `for` (explicit thread worksharing); `distribute` splits across teams.
4. `sections` for heterogeneous parallel phases; `single`+`copyprivate` for one-thread-then-broadcast.
5. `scan` + `reduction(inscan,...)` computes parallel prefix sums.

## Connects To
- **Ch 12**: `parallel`/`teams` create the threads/teams this distributes work across.
- **Ch 7**: `reduction`/`lastprivate` data handling.
- **Ch 6**: canonical loop nest + `collapse`.
- **Ch 3**: `run-sched-var` feeds `schedule(runtime)`.
