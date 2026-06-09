# Chapter 7 (§2.15–2.17): routine directive, asynchronous behavior, Fortran-specific

## Core Idea
Calling procedures from device code (**`routine`**), overlapping device work with the host and itself via **`async`/`wait`** activity queues, and Fortran-specific binding rules. The async model is the key to hiding transfer/compute latency.

## Frameworks Introduced
- **`routine`** (§2.15.1): compile a procedure for the device so it can be **called from a compute region**. Must declare its maximum parallelism level so the compiler maps callers correctly:
  - `gang` / `worker` / `vector` / `seq` — the level of parallelism the routine contains (a `seq` routine is callable from any level; a `gang` routine only at gang level).
  - `bind(name)` — call a differently-named device implementation; `nohost` — don't compile a host version; `device_type`.
  - Named (`routine(foo)`) or unnamed (immediately before the definition).
- **Asynchronous model** (§2.16): `async[(async-argument)]` enqueues operations on an **activity queue** instead of blocking.
  - **Same async-value → same queue → executed in encounter order.**
  - **Different async-values → may be different queues → may overlap / reorder.**
  - Special values: `acc_async_sync` (synchronous — local thread waits), `acc_async_noval`/`acc_async_default` (use `acc-default-async-var`).
  - **`wait[(args)] [async(q)]`** — wait for queue(s), or enqueue a dependency from one queue onto another (no host block).
- **Fortran-specific** (§2.17): assumed-shape/pointer/allocatable array handling, common-block names in data clauses (`/blockname/`), `declare` in modules, descriptor handling for derived types.

## Key Concepts
- **Activity queue = ordering domain**: think of each async-value as an independent in-order stream; concurrency comes from using *different* values.
- **`wait` without `async`** blocks the host; **`wait(q1) async(q2)`** makes queue q2 wait for q1 *on the device* (host continues) — the primitive for building dependency graphs.
- **routine parallelism level** must match or exceed how it's called; mismatches are nonconforming.
- **async data ≠ async compute inheritance**: `async` on a `data` construct overlaps only its transfers and is not inherited (ch4).
- Per-device: number of real queues and the async-value→queue mapping is implementation-defined.

## Code Examples
```c
// device-callable routine declaring its parallelism level
#pragma acc routine seq
double square(double x) { return x*x; }     // callable from any loop level

#pragma acc parallel loop
for (int i = 0; i < n; ++i) y[i] = square(x[i]);
```
```c
// overlap: independent queues run concurrently; wait builds the join
#pragma acc parallel loop async(1) present(a)
for (...) a[i] = f(a[i]);
#pragma acc parallel loop async(2) present(b)   // may run concurrently with queue 1
for (...) b[i] = g(b[i]);
#pragma acc wait(1,2)                            // host joins both
```
```fortran
!$acc routine(mykernel) seq
!$acc update device(/commonblock/)    ! Fortran common block in a data clause
```
- **Demonstrates**: `routine seq` for device-callable functions, two independent async queues overlapping then joined by `wait`, and Fortran common-block data clause syntax.

## Worked Example — pipelining transfer and compute
```c
for (int b = 0; b < nblocks; ++b) {
  int q = (b % 2) + 1;                          // alternate queues 1,2
  #pragma acc update device(chunk[b][0:sz]) async(q)   // H2D on queue q
  #pragma acc parallel loop present(chunk[b]) async(q) // compute waits for its own H2D
  for (int i = 0; i < sz; ++i) chunk[b][i] = work(chunk[b][i]);
  #pragma acc update self(chunk[b][0:sz]) async(q)     // D2H on queue q
}
#pragma acc wait
```
Same-queue ops (H2D → compute → D2H for block b) execute in order; alternating queues lets block b+1's transfer overlap block b's compute — classic double-buffering. The final `wait` joins everything.

## Anti-patterns
- **Calling a non-`routine` function from device code**: link/compile error — every device-called procedure needs `routine` with the right level.
- **Wrong routine level**: a `gang` routine called from a vector loop is nonconforming.
- **Assuming `async` ops are done without `wait`**: results unready; reading them races. Always `wait` (or chain via `wait async`) before host use.
- **Using one async-value everywhere then expecting overlap**: same value = same queue = serialized. Use distinct values to overlap.
- **GPU benchmark timing without a `wait`**: async kernels return immediately — `>100×` "speedups" are usually a missing `wait`/`!$acc wait` before the clock (verify with `system_clock`, not `cpu_time`).

## Key Takeaways
1. `routine [gang|worker|vector|seq]` makes a procedure device-callable; the level must match the call site (`seq` is universal).
2. Async queues: **same value = ordered in one queue; different values = may overlap** — concurrency is opt-in via distinct values.
3. `wait` blocks the host; `wait(q1) async(q2)` builds a device-side dependency without blocking — use for double-buffering pipelines.
4. Always synchronize (`wait`) before reading async results — and **before timing** (a missing wait fakes huge speedups).
5. Fortran: common blocks (`/name/`), assumed-shape/allocatable arrays, and module `declare` have specific rules in §2.17.

## Connects To
- **Ch 1**: execution model — activity queues, host-directed enqueue.
- **Ch 3/4**: `async`/`wait` clauses on compute and data constructs.
- **Ch 8**: runtime library — `acc_async_test`, `acc_wait`, `acc_wait_async`.
- **CLAUDE-gpu.md / feedback_gpu_benchmark_timing**: the missing-`wait` timing trap.
