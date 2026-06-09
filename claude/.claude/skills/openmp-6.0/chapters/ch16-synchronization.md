# Chapter 16 (§17–19): Synchronization, Cancellation, Composition

## Core Idea
The constructs that order and coordinate threads — `barrier`, `critical`, `atomic`, `ordered`, `flush`, `taskwait`/`taskgroup`, `depend` — built on the OpenMP **memory model** (release/acquire flushes establishing happens-before). Plus cancellation and the composition rules for combined constructs.

## Frameworks Introduced
- **Memory model** (§17.1, 17.8.7): visibility between threads requires **synchronizing flushes**. A **release flush** (on the writer) before an **acquire flush** (on the reader) of the same data establishes **happens-before**. Many constructs (`barrier`, `critical` exit/entry, `atomic` with memory order, task scheduling) imply flushes.
- **`barrier`**: all team threads rendezvous; implies a flush. Implicit at the end of `parallel` and worksharing (unless `nowait`).
- **`critical [(name)] [hint(...)]`**: mutual exclusion — only one thread (per name) in the region at a time. Names are global; unnamed critical regions all share one lock. **Must not be nested** in a same-name critical.
- **`atomic [read|write|update|capture|compare] [memory-order] [hint]`**: lock-free single-location atomicity. Memory orders: `seq_cst`, `acq_rel`, `acquire`, `release`, `relaxed`. 6.0 adds `compare` (CAS) and `weak`/`fail(...)`.
- **`ordered [(n)] [clauses]`**: enforce source order within a worksharing-loop (for ordered output or cross-iteration dependences via `doacross` `depend(sink/source)`).
- **`flush [(list)] [acq_rel|acquire|release]`**: explicit memory fence.
- **`depend`** (§17.9.5): the task-dependence clause (shared with tasking, ch14).
- **Cancellation** (§18): `cancel` (activate cancellation of `parallel`/`sections`/`for`/`taskgroup`) + `cancellation point` (where threads check). Requires `OMP_CANCELLATION=true`.
- **Composition** (§19): rules for combined/composite constructs (`parallel for`, `target teams distribute parallel for`) — clause application and nesting legality.

## Reference Tables
### Synchronization mechanism choice
| Need | Construct |
|---|---|
| all threads rendezvous | `barrier` |
| mutual exclusion (region) | `critical` |
| atomic update of one location | `atomic` |
| source-order / loop-carried dep | `ordered` |
| explicit fence | `flush` |
| wait for child tasks | `taskwait` / `taskgroup` |
| data-flow ordering | `depend` |

### atomic memory orders
| Order | Meaning |
|---|---|
| `seq_cst` | sequential consistency (default-ish, strongest) |
| `acq_rel` | acquire on read part, release on write part |
| `acquire` / `release` | one-sided ordering |
| `relaxed` | atomicity only, no ordering |

## Code Examples
```c
#pragma omp parallel for
for (int i = 0; i < n; ++i) {
  #pragma omp atomic update            // race-free accumulation (vs reduction)
  hist[bin[i]]++;
}

// CAS loop (6.0 atomic compare)
#pragma omp atomic compare
if (max < val) max = val;

#pragma omp parallel
{
  work();
  #pragma omp barrier                  // all threads sync + flush here
  use_results();
}
```
- **Demonstrates**: `atomic update` for scatter, 6.0 `atomic compare` (CAS), and `barrier` for phase separation.

## Anti-patterns
- **Assuming shared writes are visible without a flush/sync construct**: the weak memory model needs release→acquire ordering; otherwise stale reads.
- **`critical` for a single-variable update**: use `atomic` (lock-free) — `critical` serializes a whole region.
- **Unnamed `critical` everywhere**: all share one global lock → false contention; name them or use `atomic`.
- **`reduction` replaced by manual `critical`/`atomic` accumulation in a loop**: prefer `reduction` for performance.
- **Cross-gang/team or busy-wait locks**: deadlock (ch1) — OpenMP sync is within a team/contention group.
- **Forgetting `OMP_CANCELLATION=true`**: `cancel` is a no-op without it.

## Key Takeaways
1. Visibility requires synchronizing flushes (release→acquire = happens-before); most sync constructs imply them.
2. `atomic` (lock-free, one location) vs `critical` (region mutex); prefer `atomic`, and `reduction` over both for accumulation.
3. 6.0 `atomic compare` adds CAS (`weak`/`fail`); memory orders span `seq_cst`…`relaxed`.
4. `barrier` (team rendezvous), `ordered` (source order / doacross), `taskwait`/`taskgroup` (task sync), `depend` (data-flow).
5. `cancel` needs `OMP_CANCELLATION=true`; synchronization is scoped within a team/contention group.

## Connects To
- **Ch 2**: the memory-model terms (flush, happens-before, acquire/release).
- **Ch 14**: `depend`, `taskwait`, `taskgroup` task synchronization.
- **Ch 13**: implicit barriers and `nowait` on worksharing.
- **Ch 1**: cancellation flow; no portable cross-team synchronization.
