# Chapter 15: Concurrency & Coroutines (Clause 33, §26.8)

## Core Idea
The concurrency library implements the **memory model** (Ch 1) with atomics, mutexes, and the **happens-before** synchronization that makes data-race-free programs well-defined. C++20/23 modernize it with `jthread` (auto-joining + cancellation), atomic synchronization (`wait`/`notify`), `latch`/`barrier`/`counting_semaphore`, and coroutines (`std::generator`).

## Frameworks Introduced

- **The `memory_order` lattice** (§33.5 `[atomics]`) — identical semantics to C:
  `relaxed` (atomicity only) ⊂ `acquire`/`release` (one-way fences, the publish-protect pair) ⊂ `acq_rel` (RMW) ⊂ `seq_cst` (single total order; the default and the safe choice).

- **Atomics**: `std::atomic<T>` (lock-free where `is_always_lock_free`), `std::atomic_ref<T>` (C++20 — atomic operations on a non-atomic object you don't own), `atomic_flag`. C++20 adds `.wait()`/`.notify_one()`/`.notify_all()` for atomic-based blocking without a condition variable.

- **Threading primitives**:
  - **`std::jthread`** (C++20): auto-joins in its destructor and carries a `std::stop_token` for cooperative cancellation — prefer over `std::thread` (which `terminate`s if neither joined nor detached).
  - **`std::stop_token`/`stop_source`/`stop_callback`** (§33.3): cooperative cancellation.
  - `mutex`/`recursive_mutex`/`shared_mutex`; RAII locks `lock_guard`/`unique_lock`/`scoped_lock` (deadlock-free multi-lock)/`shared_lock`.
  - **`std::latch`** (single-use countdown), **`std::barrier`** (reusable phase sync), **`std::counting_semaphore`/`binary_semaphore`** (C++20).
  - `std::condition_variable`; `std::async`/`future`/`promise`/`packaged_task`; `std::call_once`/`once_flag`.

- **Coroutines** (§26.8 `[coro.generator]`, language in Ch 5/17): `co_await`, `co_yield`, `co_return`. **`std::generator<T>`** (C++23) is a coroutine-based lazy range — `co_yield` values, consume as a view.

## Key Concepts
- **Data-race-free ⇒ defined**: if all conflicting accesses are ordered by happens-before (via atomics/mutexes), the program is well-defined; otherwise UB (Ch 1).
- **`scoped_lock` over `lock_guard` for multiple mutexes** — it locks all at once with deadlock avoidance.
- **`atomic_ref`** lets you apply atomic ops to data laid out for cache efficiency without making the whole array `atomic`.
- **Coroutine lifetime**: the coroutine frame is heap-allocated (unless elided); `std::generator` manages it — but a dangling `coroutine_handle` is UB.

## Mental Models
- **`jthread` over `thread`** — auto-join + built-in stop token eliminates the two most common `std::thread` bugs (forgot to join → terminate; no cancellation).
- **Default atomics to `seq_cst`; weaken only with a proof** (same discipline as C — see the C23 skill's memory_order picker).
- **`latch` for one-shot fan-in, `barrier` for repeated phase synchronization** — don't hand-roll with condition variables.
- **`std::generator` for lazy sequences** — write a `co_yield` loop, consume it as a range; cleaner than stateful iterator classes.

## Code Examples
```cpp
// C++20 jthread: auto-joining + cooperative cancellation
std::jthread worker([](std::stop_token st){
    while (!st.stop_requested()) do_work();
});   // destructor requests stop and joins — no manual cleanup

// C++23 generator coroutine as a lazy range
std::generator<int> fib() {
    int a = 0, b = 1;
    while (true) { co_yield a; std::tie(a, b) = std::pair{b, a + b}; }
}
for (int x : fib() | std::views::take(10)) std::print("{} ", x);

// release/acquire handoff (same model as C)
std::atomic<bool> ready{false};
data = produce();
ready.store(true, std::memory_order_release);     // publish
while (!ready.load(std::memory_order_acquire)) ;  // protect
consume(data);
```
- **What it demonstrates**: `jthread` with stop token, a C++23 `std::generator` lazy range, and a release/acquire handoff.

## Reference Tables

| Primitive | Use | Since |
|---|---|---|
| `jthread` | auto-join + cancellation | C++20 |
| `stop_token` | cooperative cancellation | C++20 |
| `latch` | one-shot countdown | C++20 |
| `barrier` | reusable phase sync | C++20 |
| `counting_semaphore` | resource counting | C++20 |
| `atomic_ref` | atomic ops on non-atomic data | C++20 |
| `std::generator` | coroutine lazy range | C++23 |

| memory_order | use |
|---|---|
| `relaxed` | counters/stats |
| `acquire`/`release` | publish-protect pair |
| `acq_rel` | RMW (CAS, fetch_add) |
| `seq_cst` | default, safest |

## Key Takeaways
1. Data-race-free (all conflicting accesses ordered by happens-before) ⇒ defined; otherwise UB.
2. Prefer `jthread` over `thread` — auto-joins and carries a `stop_token` for cancellation.
3. Default atomics to `seq_cst`; weaken to acquire/release only with a correctness argument.
4. Use `latch`/`barrier`/`counting_semaphore` and `scoped_lock` instead of hand-rolled CV/multi-lock code.
5. C++23 `std::generator` is a coroutine-based lazy range — `co_yield` and consume as a view.

## Connects To
- **Ch 01 (Memory model)**: happens-before and data-race UB.
- **Ch 14 (Ranges)**: `std::generator` is consumed as a view.
- **C23 skill (Atomics)**: identical `memory_order` semantics across C and C++.
- **MPI/OpenMP skills**: for distributed/loop-level parallelism beyond standard threads.
