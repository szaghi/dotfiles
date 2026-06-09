# Chapter 4: Shared-Memory Concurrency with C++ Threads

## Core Idea
Shared-memory parallelism in standard C++ is built from `std::thread`, synchronization primitives (`mutex`, `condition_variable`), and the `std::atomic` memory model. The central hazard is the **data race** (UB); the central discipline is protecting shared mutable state and reasoning about **happens-before** ordering.

## Frameworks Introduced

- **Thread lifecycle** (`<thread>`): construct with a callable + args (`std::thread t(f, a, b)`), then **`join()`** (wait) or **`detach()`** (fire-and-forget). A thread that is neither joined nor detached at destruction calls `std::terminate`. Prefer **`std::jthread`** (C++20) — auto-joins and carries a `std::stop_token` for cooperative cancellation.

- **The data-race vs race-condition distinction**:
  - **Data race** = two threads access the same memory location, ≥1 writes, unordered, ≥1 non-atomic ⇒ **undefined behavior**.
  - **Race condition** = a *correctness* bug from timing-dependent interleaving (can exist even without a data race, e.g. check-then-act on atomics).
  - Fix data races with synchronization; fix race conditions with correct atomic protocols or coarser locks.

- **Synchronization toolkit**:
  - **Mutexes**: `mutex`, `recursive_mutex`, `shared_mutex` (reader/writer), `timed_mutex`. Always lock via RAII: **`lock_guard`** (simple), **`unique_lock`** (deferred/movable, needed for CVs), **`scoped_lock`** (multiple mutexes, deadlock-free).
  - **Condition variables**: `condition_variable` with a predicate — `cv.wait(lock, pred)` to avoid lost/spurious wakeups; `notify_one`/`notify_all`.
  - **Atomics**: `std::atomic<T>` with a `memory_order` (default `seq_cst`); `compare_exchange_*`, `fetch_add`; `atomic_ref` for atomic ops on non-atomic storage (C++20).
  - **Futures**: `std::async`/`future`/`promise`/`packaged_task` for value-returning tasks; `std::call_once`/`once_flag` for one-time init.
  - **C++20**: `latch` (one-shot countdown), `barrier` (reusable phase sync), `counting_semaphore`.

## Key Concepts
- **happens-before** = sequenced-before (within a thread) + synchronizes-with (a release store paired with an acquire load, or mutex unlock→lock). It's what makes data-race-free programs well-defined.
- **`memory_order`**: `seq_cst` (default, single total order) → `acq_rel` (RMW) → `release`/`acquire` (publish/protect pair) → `relaxed` (atomicity only, no ordering).
- **Deadlock conditions** (Coffman): mutual exclusion + hold-and-wait + no preemption + circular wait. Break circular wait by **always locking multiple mutexes in a global order** (or use `scoped_lock`).
- **False sharing**: two threads writing different variables that share a cache line — invisible serialization. Pad/align hot per-thread data to a cache line.

## Mental Models
- **Protect shared mutable state or make it atomic — there is no third safe option.** Read-only shared data needs no lock; thread-local data needs no lock; everything else does.
- **Always use RAII locks (`lock_guard`/`scoped_lock`)** — never raw `lock()`/`unlock()`; an exception between them deadlocks.
- **`cv.wait` always takes a predicate** — bare `wait()` is a lost-wakeup bug waiting to happen.
- **Default atomics to `seq_cst`; weaken only with a proof** — relaxed/acquire-release are optimizations that demand a correctness argument.
- **`jthread` over `thread`** — eliminates forgot-to-join terminate and gives cancellation for free.

## Code Examples
```cpp
// RAII locking + CV with predicate
std::mutex m; std::condition_variable cv; std::queue<Task> q;
void producer(Task t) { { std::lock_guard lk(m); q.push(t); } cv.notify_one(); }
void consumer() {
    std::unique_lock lk(m);
    cv.wait(lk, [&]{ return !q.empty(); });   // predicate: no lost/spurious wakeup
    auto t = q.front(); q.pop();
}

// release/acquire publish-protect
std::atomic<bool> ready{false}; Data d;
void produce() { d = build(); ready.store(true, std::memory_order_release); }
void consume() { while(!ready.load(std::memory_order_acquire)); use(d); }

// deadlock-free multi-lock
std::scoped_lock lk(mutexA, mutexB);   // locks both atomically, no ordering bug
```
- **What it demonstrates**: predicate CV wait, release/acquire handoff, and deadlock-free multi-lock.

## Reference Tables

| Primitive | Use | Note |
|---|---|---|
| `jthread` | worker thread | auto-join + stop_token (C++20) |
| `lock_guard` | one mutex, scope | simplest RAII |
| `scoped_lock` | many mutexes | deadlock-free |
| `unique_lock` | CV / deferred | movable |
| `shared_mutex` | reader/writer | many readers, one writer |
| `atomic<T>` | lock-free counter/flag | pick memory_order |
| `latch`/`barrier` | phase sync | C++20 |

| memory_order | use |
|---|---|
| `seq_cst` | default, safest |
| `acquire`/`release` | publish/protect pair |
| `acq_rel` | read-modify-write |
| `relaxed` | counters/stats only |

## Key Takeaways
1. A data race is UB; protect shared mutable state with a mutex or make it atomic — read-only and thread-local data are race-free.
2. Always lock via RAII (`lock_guard`/`scoped_lock`); use `scoped_lock` or a global lock order to avoid deadlock.
3. `condition_variable::wait` must take a predicate to survive spurious/lost wakeups.
4. Default atomics to `seq_cst`; weaken to acquire/release only with a happens-before argument.
5. Prefer `jthread` (auto-join, cancellation); watch for false sharing on per-thread hot data.

## Connects To
- **Ch 05 (Parallel data structures)**: lock-free and concurrent containers built on atomics.
- **Ch 09 (OpenMP)**: a higher-level shared-memory model over the same hardware.
- **Ch 12 (Optimization)**: false sharing and contention diagnosis.
