# Chapter 5: Parallel & Concurrent Data Structures

## Core Idea
A data structure shared by threads must be made *thread-safe* without serializing all access. The spectrum runs from **coarse locking** (simple, low-concurrency) through **fine-grained locking** to **lock-free** structures built on atomic compare-and-swap — each trading complexity for scalability.

## Frameworks Introduced

- **The concurrency-control spectrum**:
  - **Coarse-grained locking** — one mutex guards the whole structure. Correct and trivial, but every operation serializes; fine for low contention.
  - **Fine-grained locking** — separate locks per node/bucket/region (e.g. hand-over-hand list locking, per-bucket hash map). More concurrency, but deadlock and complexity risk.
  - **Lock-free** — atomic operations (CAS loops) guarantee *system-wide progress* without locks; no thread can block all others. Complex and ABA-prone, but scales and is interrupt/signal-safe.
  - **Wait-free** — every thread completes in bounded steps (strongest, rarest).
  - When to use: start coarse; move finer only when profiling shows lock contention is the bottleneck.

- **Lock-free building blocks**:
  - **Compare-and-swap (CAS)** — `compare_exchange_strong/weak(expected, desired)`: the atomic primitive behind lock-free stacks/queues/counters. The canonical loop: read, compute new value, CAS; retry on failure.
  - **The ABA problem** — a value changes A→B→A between your read and CAS, so CAS wrongly succeeds. Mitigate with tagged pointers (version counters) or hazard pointers.
  - **Memory reclamation** — freeing a node another thread may still reference is use-after-free; solved by hazard pointers, epoch-based reclamation, or RCU.

## Key Concepts
- **Concurrent containers**: thread-safe queues (SPSC/MPMC), stacks, hash maps; bounded vs unbounded; blocking vs lock-free variants.
- **Producer–consumer queue**: the workhorse for pipelines and task farms — a bounded concurrent queue with backpressure.
- **Parallel prefix sum (scan)**: a fundamental parallel primitive — exclusive/inclusive scan computes running aggregates in O(log N) depth; the basis for stream compaction, sorting, and allocation.
- **Reduction**: combine N values with an associative operator in O(log N) depth (tree reduction) — but floating-point reductions are *not* bitwise-reproducible because reassociation changes rounding.

## Mental Models
- **Start with coarse locking; earn fine-grained or lock-free with profiler evidence.** Lock-free code is hard to get right and harder to debug; most contention is solved by reducing critical-section size first.
- **A CAS loop is the lock-free idiom** — read current, compute desired, `compare_exchange_weak` in a loop; `weak` is correct (and faster) inside a retry loop.
- **Floating-point parallel reductions change results** — tree reduction reorders additions; if you need reproducibility, fix the reduction order or use compensated (Kahan/pairwise) summation.
- **Scan is the hidden primitive** — many "inherently serial" loops (running sums, compaction, histogram offsets) are parallel scans in disguise.

## Code Examples
```cpp
// Lock-free counter via CAS loop
std::atomic<long> counter{0};
void add(long v) {
    long cur = counter.load(std::memory_order_relaxed);
    while (!counter.compare_exchange_weak(cur, cur + v,
            std::memory_order_relaxed)) { /* cur reloaded on failure */ }
}

// Reduce critical-section size: compute outside, commit inside
auto result = expensive_pure_compute(input);   // no lock held
{ std::lock_guard lk(m); shared.push_back(result); }   // tiny critical section
```
- **What it demonstrates**: the CAS retry loop and shrinking the critical section instead of jumping to lock-free.

## Reference Tables

| Strategy | Concurrency | Complexity | Use |
|---|---|---|---|
| coarse lock | low | trivial | low contention |
| fine-grained | medium-high | high | hot structure |
| lock-free (CAS) | high | very high | proven hotspot |
| wait-free | highest | extreme | hard-realtime |

| Parallel primitive | Depth | Use |
|---|---|---|
| reduction | O(log N) | sum/min/max |
| scan (prefix sum) | O(log N) | compaction, offsets |
| sort | O(log² N)+ | ordering |

## Key Takeaways
1. Choose concurrency control by contention: coarse lock by default, fine-grained or lock-free only with profiler evidence.
2. CAS loops are the lock-free idiom; beware the ABA problem and safe memory reclamation (hazard pointers/epochs).
3. Concurrent producer–consumer queues are the backbone of pipelines and task farms.
4. Scan (prefix sum) and reduction are O(log N) parallel primitives that unlock "serial-looking" loops.
5. Parallel floating-point reductions reorder operations and are not bitwise-reproducible — use fixed order or compensated summation when it matters.

## Connects To
- **Ch 04 (Threads)**: atomics and `memory_order` underpin lock-free structures.
- **Ch 02 (Pipeline pattern)**: concurrent queues connect pipeline stages.
- **Ch 10 (Thrust)**: scan/reduce/sort as ready-made GPU primitives.
- **Ch 03 (Performance)**: reduction order vs floating-point reproducibility.
