# Chapter 5 (§2.8–2.11): loop, host_data, cache, combined constructs

## Core Idea
The **`loop`** construct — how iterations map to gang/worker/vector parallelism — plus three helpers: `host_data` (expose device addresses to host code), `cache` (hint data into fast memory), and combined constructs (`parallel loop` etc.).

## Frameworks Introduced
- **`loop`** (§2.9): applies to the immediately-following loop; declares the parallelism type and private/reduction data. Clauses:
  - **`gang` / `worker` / `vector` / `seq`**: which level worksharing uses (or none).
  - **`independent`**: assert iterations are independent (the programmer's parallel-safety guarantee; implied on `parallel`).
  - **`auto`**: let the compiler decide independence/mapping.
  - **`collapse([force:]n)`**: fuse `n` tightly-nested loops into one iteration space (more parallelism).
  - **`tile(sizes)`**: block the iteration space for locality.
  - **`private` / `reduction(op:vars)`**: per-iteration privates / cross-iteration reduction.
- **Worksharing nesting rule** (critical): a `gang`/`worker`/`vector` loop must **not** lexically enclose another loop of *equal or higher* level (within the same compute scope). Order must be gang ⊃ worker ⊃ vector, outer→inner. At most one `gang` clause per loop.
- **`host_data`** (§2.8): makes the **device address** of present data available to the host code in the region (via `use_device`) — for passing device pointers to CUDA kernels / device-aware MPI / cuBLAS.
- **`cache`** (§2.10): hints that the listed array elements should be kept in the highest level of cache for the loop body.
- **Combined constructs** (§2.11): `parallel loop`, `kernels loop`, `serial loop` — shorthand fusing a compute construct with an immediately-following loop; the common, recommended form.

## Key Concepts
- **orphaned loop**: a `loop` with no lexically-enclosing compute construct (e.g. inside a `routine`); mapping resolved at the call site.
- **`independent` vs `auto` vs `seq`**: assert-parallel / let-compiler-decide / force-sequential. On a `parallel` construct, loops are `independent` by default; on `kernels`, the compiler analyzes.
- **DO CONCURRENT interaction**: a `loop` on a Fortran `do concurrent` applies per concurrent-header index — bridges native-parallel Fortran (F2023, see fortran-2023-standard ch11) with OpenACC mapping.
- **`gang(dim:d)`**: target a specific gang grid dimension (1–3).

## Code Examples
```c
// collapse a 2D nest, map to gang+vector, reduce
#pragma acc parallel loop collapse(2) gang vector reduction(+:err) present(u,unew)
for (int j = 1; j < ny-1; ++j)
  for (int i = 1; i < nx-1; ++i) {
    unew[j][i] = 0.25*(u[j][i-1]+u[j][i+1]+u[j-1][i]+u[j+1][i]);
    err += fabs(unew[j][i]-u[j][i]);
  }

// explicit three-level mapping
#pragma acc parallel loop gang
for (k...)             // gangs
  #pragma acc loop worker
  for (j...)           // workers
    #pragma acc loop vector
    for (i...) ...     // vector lanes
```
```c
// host_data: hand a device pointer to a CUDA/MPI call
#pragma acc host_data use_device(a)
  cudaMemcpy(dst, a, n*sizeof(double), cudaMemcpyDeviceToDevice);
```
- **Demonstrates**: `collapse` + multi-level mapping + reduction in one combined construct; explicit gang⊃worker⊃vector nesting; `host_data use_device` for interop.

## Worked Example — the nesting rule that bites
```c
#pragma acc parallel loop gang        // OK: gang outer
for (int i = 0; i < n; ++i)
  #pragma acc loop vector             // OK: vector inner (lower level)
  for (int j = 0; j < m; ++j) ...
// ILLEGAL: vector loop enclosing a worker loop (worker is higher than vector)
// ILLEGAL: two gang loops nested in the same compute scope
```
The hardware hierarchy is gang → worker → vector, outermost to innermost. Inverting the order (or repeating a level) within one compute scope is nonconforming — the compiler will reject or misbehave.

## Anti-patterns
- **Inverting gang/worker/vector nesting**: must be outer→inner gang⊃worker⊃vector; equal/higher level nested inside is illegal.
- **`independent` on a loop with real dependencies**: races. Use `auto`/`seq` or fix the dependency.
- **Over-collapsing**: `collapse(n)` requires *tightly* nested, rectangular loops with no intervening code — otherwise illegal/wrong.
- **Passing a host pointer to a device library**: wrap in `host_data use_device(...)` to get the device address.
- **Relying on `cache` for correctness**: it's a hint; never a synchronization or coherence guarantee.

## Key Takeaways
1. `loop` maps iterations to `gang`/`worker`/`vector` (or `seq`); nesting must follow gang⊃worker⊃vector outer→inner.
2. `independent` asserts parallel-safety (default on `parallel`); `auto` defers to the compiler; `seq` forces sequential.
3. `collapse(n)` fuses tight nests for more parallelism; `tile` blocks for locality.
4. `host_data use_device(v)` exposes the device address — the bridge to CUDA/cuBLAS/device-aware MPI.
5. Prefer combined `parallel loop`/`kernels loop` for the common case.

## Connects To
- **Ch 1**: execution model — gang/worker/vector levels and modes.
- **Ch 3**: compute constructs — `loop` worksharing happens inside parallel/kernels/serial.
- **Ch 4**: data clauses — `present`/`copyin` feed the loop's data; `host_data` exposes device addrs.
- **fortran-2023-standard ch11**: DO CONCURRENT, which a `loop` can annotate.
