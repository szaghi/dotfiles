# Chapter 4: Parallel Programming Patterns & the Parallel STL

## Core Idea
Parallelization starts with analyzing **loop dependence** — how data change across iterations — to decide what is safely parallel. Standard C++ then expresses shared-memory parallelism cleanly: **execution policies** on STL algorithms, plus `std::thread`/`std::async`/`std::atomic` primitives. The key question is always: *can iterations run independently?*

## Frameworks Introduced

- **Loop-dependence analysis** (the parallelizability test):
  - **Embarrassingly parallel**: no iteration depends on another's result — the whole loop parallelizes trivially (`y[i] = f(x[i])`). The ideal.
  - **Loop-carried dependence**: an iteration uses a value produced by a previous one (running sums, recurrences) — not directly parallel; rewrite so each iteration depends only on the index, or use a reduction/scan.
  - **Reductions**: combine values with an associative operator (sum/max) — parallel in O(log n) but order-sensitive for floating point.

- **The parallel STL** (C++17 execution policies): add a policy as the first argument to a standard algorithm and it runs in parallel — no manual thread management.
  - **`std::execution::seq`** — sequential (no parallelism).
  - **`std::execution::par`** — parallel across threads.
  - **`std::execution::par_unseq`** — parallel *and* vectorized (SIMD); iterations may interleave, so the body must be free of inter-iteration data races and unsequenced-unsafe operations.
  - Applies to `for_each`, `transform`, `reduce`, `sort`, `transform_reduce`, etc. Shared-memory only.

- **Concurrency primitives** (when algorithms aren't enough):
  - **`std::thread`** / **`std::jthread`** (auto-joining, C++20) for explicit threads.
  - **`std::async`/`std::future`** for value-returning tasks.
  - **`std::atomic<T>`** for race-free shared counters/flags; **`std::mutex`** + RAII `lock_guard`/`scoped_lock` for critical sections.
  - **Threading Building Blocks (TBB)** as a richer task-parallel backend (and the engine behind many parallel-STL implementations).

## Key Concepts
- **Data race = undefined behavior**: two threads access the same memory, ≥1 writes, unordered — UB. Protect shared mutable state with atomics or locks; read-only and thread-local data are race-free.
- **False sharing**: distinct variables on the same 64-byte cache line, written by different threads, silently serialize via cache-coherence traffic. Pad/align per-thread data.
- **`par` vs `par_unseq`**: `par` parallelizes across threads; `par_unseq` additionally vectorizes and may interleave within a thread — the body must not take locks or have iteration-order dependencies.
- **Floating-point reductions reorder** additions → not bitwise reproducible across thread counts; use a fixed order or compensated summation when reproducibility matters.

## Mental Models
- **First classify the loop: embarrassingly parallel, reducible, or dependent.** Independent → execution policy or thread-per-chunk; reducible → parallel reduction; dependent → rewrite or accept serial.
- **Reach for the parallel STL before hand-threading** — `std::for_each(par, ...)` parallelizes a loop with one policy argument and no thread bookkeeping.
- **Protect shared mutable state or make it atomic — there is no third safe option.** Most "parallel bug" reports are unprotected shared writes (data races) or false sharing.
- **`par_unseq` demands a clean body** — no locks, no inter-iteration dependence; if the body needs synchronization, use `par`, not `par_unseq`.

## Code Examples
```cpp
#include <algorithm>
#include <execution>
#include <numeric>

// Parallel + vectorized transform — one policy argument
std::transform(std::execution::par_unseq,
               x.begin(), x.end(), y.begin(),
               [a](double xi){ return a * xi; });    // independent → par_unseq safe

// Parallel reduction (order-sensitive for FP)
double total = std::reduce(std::execution::par, v.begin(), v.end(), 0.0);

// Explicit task with a future
auto fut = std::async(std::launch::async, [&]{ return heavy(input); });
auto result = fut.get();

// Race-free shared counter
std::atomic<long> count{0};
std::for_each(std::execution::par, data.begin(), data.end(),
              [&](const auto& d){ if (pred(d)) count.fetch_add(1); });
```
- **What it demonstrates**: parallel-STL policies, a parallel reduction, an async task, and an atomic shared counter.

## Reference Tables

| Loop type | Strategy |
|---|---|
| embarrassingly parallel | execution policy / thread-per-chunk |
| reduction | `std::reduce` / `transform_reduce` |
| loop-carried dependence | rewrite by index, or serial |

| Execution policy | Parallel? | Vectorized? | Body constraint |
|---|---|---|---|
| `seq` | no | no | none |
| `par` | yes | no | no data races |
| `par_unseq` | yes | yes | no locks, no inter-iteration dependence |

## Key Takeaways
1. Analyze loop dependence first — embarrassingly parallel, reducible, or dependent decides the strategy.
2. Use parallel-STL execution policies (`par`/`par_unseq`) to parallelize standard algorithms with no manual threading.
3. `par` parallelizes across threads; `par_unseq` also vectorizes and forbids locks / iteration-order dependence in the body.
4. Data races are UB — protect shared mutable state with atomics/locks; watch false sharing (pad per-thread data).
5. Parallel floating-point reductions reorder operations and aren't bitwise reproducible — fix the order when it matters.

## Connects To
- **Ch 03 (STL)**: the algorithms execution policies parallelize.
- **Ch 05 (Hardware)**: cache lines (false sharing), SIMD (`par_unseq`), NUMA.
- **Ch 08 (OpenMP)**: the directive-based alternative for shared-memory parallelism.
- **Ch 12 (Debugging)**: thread/race sanitizers catch the data races here.
