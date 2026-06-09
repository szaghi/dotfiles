# Chapter 12: Parallelism Generation and Control

## Core Idea
The constructs that *create* parallelism: **`parallel`** (a team of threads), **`teams`** (a league of teams, for device offload), **`simd`** (vectorization), and **`masked`** (restrict to some threads). Plus the clauses that size and bind them.

## Frameworks Introduced
- **`parallel`** (§12.1): forms a team; encountering thread becomes the **primary thread**; implicit barrier at the end. Clauses: `num_threads(list)`, `proc_bind(primary|close|spread)`, `if([parallel:] cond)`, `default`, `shared`/`private`/`firstprivate`/`reduction`/`copyin`, `allocate`, and **`safesync`** (6.0 — assert sync safety on non-host devices).
- **`teams`** (§12.x): creates a **league** of initial teams (each its own contention group), typically inside `target` for GPU offload. Clauses: `num_teams(lb:ub)`, `thread_limit`, data clauses. Teams may execute concurrently or not (unspecified) — no portable cross-team sync.
- **`simd`**: execute loop iterations concurrently across SIMD lanes. Clauses: `simdlen`, `safelen`, `aligned`, `linear`, `reduction`, `nontemporal`, `order(concurrent)`.
- **`masked [filter(thread-num)]`** (replaces `master`): only the filtered thread(s) execute the block. No implicit barrier.
- **Thread-count algorithm** (Algorithm 12.1): resolves the actual team size from `num_threads`, ICVs (`nthreads-var`, `thread-limit-var`, `dyn-var`), nesting level, and `max-active-levels-var`.

## Key Concepts
- **`num_threads` is a *request*** — `dyn-var` (dynamic adjustment) and limits may grant fewer. For an exact count, `OMP_DYNAMIC=false`.
- **`proc_bind`**: `close` packs threads near the primary (cache sharing), `spread` distributes them (bandwidth), `primary` co-locates with the primary thread. Pairs with `OMP_PLACES`.
- **`teams` is the GPU launch primitive**: `target teams distribute parallel for` is the canonical offload pattern (league of teams → distribute across teams → parallel-for within each team).
- **`masked filter(n)`** generalizes the old `master` (thread 0 only) to any thread set.
- **`safesync`** (6.0): asserts that synchronization within the parallel region is safe on the device — required for some non-host barriers.

## Code Examples
```c
// CPU: exact thread count, spread for bandwidth
#pragma omp parallel num_threads(8) proc_bind(spread) default(none) shared(a)
{ /* ... */ }

// GPU offload: the canonical teams pattern
#pragma omp target teams distribute parallel for \
            num_teams(256) thread_limit(128) map(tofrom: a[0:n])
for (int i = 0; i < n; ++i) a[i] = f(a[i]);

#pragma omp parallel
#pragma omp masked filter(0)        // only thread 0; no barrier
  printf("primary only\n");
```
- **Demonstrates**: a bound CPU team, the `target teams distribute parallel for` GPU idiom, and `masked` replacing `master`.

## Anti-patterns
- **Assuming `num_threads(n)` guarantees n threads**: dynamic adjustment/limits may reduce it — set `OMP_DYNAMIC=false` for exact counts.
- **Cross-team synchronization in `teams`**: unspecified concurrency → deadlock; sync only within a team.
- **Using deprecated `master`**: replaced by `masked` (which also takes `filter`).
- **`teams` without `distribute`**: the league runs the region redundantly per team (analogous to OpenACC bare `parallel`).
- **Ignoring `proc_bind`/`OMP_PLACES` on NUMA**: threads migrate, killing locality.

## Key Takeaways
1. `parallel` = team + end barrier; `teams` = league of teams (GPU offload); `simd` = vector lanes; `masked` = thread subset.
2. `num_threads` is a request; `OMP_DYNAMIC=false` for an exact count; resolution follows Algorithm 12.1.
3. **`target teams distribute parallel for`** is the canonical GPU offload pattern.
4. `proc_bind(close|spread|primary)` + `OMP_PLACES` control affinity; essential on NUMA.
5. `masked filter(n)` replaces `master`; `safesync` (6.0) asserts device sync safety.

## Connects To
- **Ch 13**: `distribute` + worksharing-loop combine with `teams`/`parallel`.
- **Ch 15**: `target` wraps `teams` for offload.
- **Ch 3/4**: ICVs/env vars (`OMP_NUM_THREADS`, `OMP_PROC_BIND`) feeding these.
- **Ch 16**: barriers/synchronization within a team.
