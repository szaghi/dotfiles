# Chapter 3 (§2.5): Compute constructs — parallel, serial, kernels

## Core Idea
The three constructs that launch device execution: **`parallel`** (programmer-controlled gangs), **`kernels`** (compiler decides parallelization), and **`serial`** (one gang/worker/lane). The choice determines who is responsible for correctness and parallelization.

## Frameworks Introduced
- **`parallel`** (§2.5.1): launches a fixed number of gangs/workers/vector-lanes; each gang starts in **gang-redundant (GR) mode** — code outside a gang-worksharing `loop` runs redundantly in every gang. Implicit barrier at the end unless `async`. The programmer asserts parallelism.
- **`kernels`** (§2.5.3): the region becomes a *sequence of kernels*; the **compiler** analyzes dependencies and chooses gang/worker/vector mapping per loop. Safer for correctness, less control.
- **`serial`** (§2.5.2): exactly **one gang, one worker, vector length 1** — sequential on the device. Use to run sequential code where data is already resident, avoiding a host round-trip.
- **Parentage**: *parent procedure* (nearest enclosing proc whose expressions evaluate when called), *parent compute construct*, *parent compute scope* — used by data-attribute and `routine` rules.

## Key Concepts
- **`num_gangs` / `num_workers` / `vector_length`**: set launch geometry (parallel/kernels only; **not** serial).
- **`reduction(op : vars)`**: combine per-gang/worker/lane partial results (`+ * max min & | ^ && ||`).
- **`private` / `firstprivate`**: per-gang private copies (firstprivate initialized from host value).
- **`default(none | present)`**: `none` forces explicit data clauses for every variable (discipline); `present` assumes data is already on device.
- **`if(cond)` / `self[(cond)]`**: run on device conditionally / run on local thread (host) instead.
- **`async` / `wait`**: queue the region instead of blocking (ch7).

## parallel vs kernels — the central decision
| | `parallel` | `kernels` |
|---|---|---|
| Parallelization | programmer asserts (you guarantee independence) | compiler analyzes & decides |
| Granularity | one region = one launch geometry | region → multiple kernels, each tuned |
| Control | full (`num_gangs` etc., `loop` clauses) | compiler-driven |
| Risk | wrong assertion → races | conservative; may under-parallelize |
| Use when | you know the loop nest is parallel | exploring, or trusting the compiler |

## Code Examples
```c
// parallel: you assert independence; control geometry
#pragma acc parallel loop num_gangs(256) vector_length(128) \
            reduction(+:sum) present(a,b)
for (int i = 0; i < n; ++i) sum += a[i]*b[i];

// kernels: compiler parallelizes each loop in the block as it sees fit
#pragma acc kernels copyin(a[0:n],b[0:n]) copyout(c[0:n])
{
  for (int i = 0; i < n; ++i) c[i] = a[i] + b[i];
  for (int i = 0; i < n; ++i) c[i] *= 2.0;
}
```
```fortran
!$acc serial present(state)      ! sequential on device, no host round-trip
  state%step = state%step + 1
!$acc end serial
```
- **Demonstrates**: `parallel loop` with explicit geometry + reduction; `kernels` letting the compiler split a multi-loop block; `serial` for device-resident sequential work.

## Worked Example — why `parallel` runs redundantly without `loop`
```c
#pragma acc parallel num_gangs(4)     // 4 gangs, all in GR mode
{
  x = 0;                              // executed by ALL 4 gangs redundantly!
  #pragma acc loop                    // NOW partitioned across gangs
  for (int i = 0; i < n; ++i) y[i] = i;
}
```
Code in a `parallel` region but *outside* a gang-worksharing `loop` executes once **per gang** (GR mode). Forgetting the `loop` directive is the classic "why did my serial statement run 4×" bug. `parallel loop` (combined) is the safe common case.

## Anti-patterns
- **`parallel` without an inner `loop`**: the body runs redundantly in every gang (GR mode) — almost never intended for the work itself.
- **Asserting `parallel` on a loop with dependencies**: data races / wrong results — use `kernels` (compiler checks) or fix the dependency.
- **`num_gangs`/`vector_length` on `serial`**: not permitted.
- **Omitting `reduction`** on an accumulator across iterations: race; the partial-sum-per-lane must be reduced.
- **Not using `default(none)`**: hides accidental implicit copies — adopt it like `implicit none`.

## Key Takeaways
1. `parallel` = you assert parallelism + control geometry; `kernels` = compiler decides; `serial` = one gang/worker/lane.
2. In a `parallel` region, code **outside** a gang-worksharing `loop` runs **redundantly per gang** (GR mode) — use `parallel loop`.
3. `serial` avoids a host round-trip for sequential work on already-resident data.
4. `reduction`, `private`/`firstprivate`, `default(none)` are the correctness-critical clauses.
5. `num_gangs`/`num_workers`/`vector_length` apply to parallel/kernels, not serial.

## Connects To
- **Ch 1**: execution model — GR/GP modes, gang/worker/vector.
- **Ch 5**: loop construct — `gang`/`worker`/`vector`/`seq` worksharing within these regions.
- **Ch 4**: data clauses — `copy`/`copyin`/`copyout`/`present`/`create` shared across compute constructs.
- **Ch 7**: async behavior — `async`/`wait` on compute constructs.
