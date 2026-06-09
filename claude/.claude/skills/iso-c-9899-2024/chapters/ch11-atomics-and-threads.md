# Chapter 11: Atomics & Threads (Clause 7.17 `<stdatomic.h>`, 7.28 `<threads.h>`)

## Core Idea
C11/C23 give a portable concurrency model: `_Atomic` objects with a six-level `memory_order` consistency lattice, plus a `<threads.h>` API (threads, mutexes, condition variables, thread-local storage, `call_once`). Both are **conditional features** — gated by `__STDC_NO_ATOMICS__` / `__STDC_NO_THREADS__`.

## Frameworks Introduced

- **The `memory_order` lattice** (§7.17.3) — strongest to weakest:
  - `memory_order_seq_cst` — single total order S across all seq_cst ops (default for non-`_explicit` calls). Strongest, simplest to reason about.
  - `memory_order_acq_rel` — for read-modify-write: combines acquire (on load) + release (on store).
  - `memory_order_release` — store side of a release/acquire pair; publishes prior writes.
  - `memory_order_acquire` — load side; sees writes released by the matching store.
  - `memory_order_consume` — weaker acquire, only orders dependency-carrying loads (rarely used; often promoted to acquire).
  - `memory_order_relaxed` — atomicity only, **no ordering** with other memory.
  - When to use: default to `seq_cst`; drop to acquire/release for a producer/consumer handoff; use `relaxed` only for counters where ordering is irrelevant.

- **The atomic operation set** (§7.17): `atomic_init`, `atomic_store[_explicit]`, `atomic_load[_explicit]`, `atomic_exchange`, `atomic_compare_exchange_strong/weak[_explicit]`, `atomic_fetch_add/sub/or/xor/and[_explicit]`, `atomic_flag_test_and_set` / `atomic_flag_clear`, `atomic_thread_fence`, `atomic_signal_fence`, `kill_dependency`.
  - `atomic_flag` is the **only** type guaranteed lock-free; probe others with `ATOMIC_*_LOCK_FREE`.

- **The threads API** (§7.28):
  - Threads: `thrd_create`, `thrd_join`, `thrd_detach`, `thrd_current`, `thrd_exit`, `thrd_sleep`, `thrd_yield`. Start function type `int (*)(void *)`.
  - Mutexes: `mtx_init` (`mtx_plain`/`mtx_recursive`/`mtx_timed`), `mtx_lock`, `mtx_trylock`, `mtx_timedlock`, `mtx_unlock`, `mtx_destroy`.
  - Condition variables: `cnd_init`, `cnd_wait`, `cnd_timedwait`, `cnd_signal`, `cnd_broadcast`, `cnd_destroy`.
  - Thread-local storage: `tss_create`, `tss_get`, `tss_set`, `tss_delete` (plus the `thread_local` keyword).
  - One-time init: `call_once(once_flag*, func)` — `func` runs exactly once across all callers.
  - Return codes: `thrd_success`, `thrd_busy`, `thrd_error`, `thrd_nomem`, `thrd_timedout`.

## Key Concepts
- **Data race = UB** (§5.1.2.4 / 6.2.x): two conflicting accesses to the same memory location, at least one non-atomic and not ordered, ⇒ undefined behavior.
- **Release/acquire synchronizes-with**: a release store synchronizes-with an acquire load that reads its value, establishing a happens-before edge that orders all prior writes.
- **`atomic_signal_fence`** orders only with respect to a signal handler in the same thread (no inter-thread fence cost).
- **`sig_atomic_t` and lock-free atomics** are the only signal-safe shared types.
- **Accessing a member of an atomic struct/union is UB** (§6.5.3.4) — operate on the whole object via the atomic API.

## Mental Models
- **Default to `seq_cst`; justify every weakening.** Relaxed/acquire/release are performance optimizations that demand a proof of correctness.
- **A flag handoff needs release on the writer and acquire on the reader** — that pair is the minimum that publishes the protected data.
- **`relaxed` gives you an atomic counter, not a synchronization point** — `fetch_add(relaxed)` is fine for statistics, wrong for "data is ready."

## Code Examples
```c
/* producer/consumer handoff with release/acquire */
atomic_int flag = 0;
int payload;

/* producer */ payload = 42;
               atomic_store_explicit(&flag, 1, memory_order_release);

/* consumer */ while (!atomic_load_explicit(&flag, memory_order_acquire)) ;
               int x = payload;   /* guaranteed to see 42 */

/* one-time init across threads */
static once_flag once = ONCE_FLAG_INIT;
call_once(&once, init_resources);
```
- **What it demonstrates**: the release/acquire publish-protect idiom and `call_once`.

## Reference Tables

| memory_order | Atomicity | Ordering | Typical use |
|---|---|---|---|
| relaxed | yes | none | counters/stats |
| consume | yes | dependency-only | (rare; ≈acquire) |
| acquire | yes | loads see released writes | reader side |
| release | yes | publishes prior writes | writer side |
| acq_rel | yes | both | RMW (CAS, fetch_add) |
| seq_cst | yes | single total order | default, safest |

## Key Takeaways
1. A data race (conflicting access, ≥1 non-atomic, unordered) is **undefined behavior**.
2. Default to `memory_order_seq_cst`; weaken only with a correctness argument.
3. Release-store + acquire-load is the canonical publish/protect handoff.
4. Only `atomic_flag` is guaranteed lock-free; check `ATOMIC_*_LOCK_FREE` for others.
5. Atomics and threads are conditional features — gate on `__STDC_NO_ATOMICS__` / `__STDC_NO_THREADS__`.

## Connects To
- **Ch 02 (Abstract machine)**: sequenced-before and the signal-interruption rules.
- **Ch 03 (`_Atomic`)**: the qualifier whose objects these operations act on.
- **Ch 08 (Feature macros)**: `__STDC_NO_ATOMICS__` / `__STDC_NO_THREADS__`.
- **MPI/OpenMP skills**: for distributed/loop-level parallelism beyond C threads.
