# Chapter 4 (§2.6–2.7): Data environment and data clauses

## Core Idea
The most performance-critical part of OpenACC: managing the **device data environment** — when data is allocated/copied/freed, the **reference-counter** model that prevents premature deallocation, and the data clauses (`copy`/`copyin`/`copyout`/`create`/`present`/`no_create`/`deviceptr`/`attach`) that express it. Minimizing host↔device transfers is the central optimization.

## Frameworks Introduced
- **Data attribute determination** (§2.6.1–2.6.2):
  - **predetermined**: loop control variables → private; etc. (cannot override).
  - **implicitly determined**: a variable in a compute construct with no data clause is treated as `copy` (aggregate) or `firstprivate` (scalar), unless `default(none)` forces an explicit clause.
- **Data lifetime models** (§2.6.3):
  - **structured** — `data` construct / compute-construct region: created on entry, deleted on exit (lexically scoped).
  - **unstructured** — `enter data` / `exit data` directives: lifetime spans arbitrary program points (e.g. across function boundaries), decoupled from lexical scope.
- **Reference counters** (§2.6.7): each device variable has a **structured** and a **dynamic** reference counter. Data is allocated when a counter goes 0→1 and freed when both return to 0. This is why nested `data`/`enter data` regions don't double-allocate or prematurely free.
- **Attachment counter** (§2.6.8) + **attach/detach** (§2.7): for pointer members of structs/derived types — translates host pointers to device addresses so device code can follow them.
- **Data clause modifiers** (§2.7.4): e.g. `readonly`, `zero`, `always`, `capture`, `alloc`/`delete` — qualify when/how the copy happens.

## Data clauses — what each does
| Clause | On entry | On exit | Use when |
|---|---|---|---|
| `copy(v)` | alloc + copy H→D | copy D→H + free | in/out, lifetime = region |
| `copyin(v)` | alloc + copy H→D | free | read-only input |
| `copyout(v)` | alloc (no copy) | copy D→H + free | write-only output |
| `create(v)` | alloc (no copy) | free | device-only scratch |
| `no_create(v)` | use if present, else local | — | reuse existing device copy, no alloc |
| `present(v)` | assert already on device (error if not) | — | data managed elsewhere |
| `deviceptr(v)` | v is already a device pointer | — | interop with CUDA/explicit alloc |
| `attach(v)` | attach pointer to device target | detach | pointer members |

## Key Concepts
- **`enter data`/`exit data`** (§2.6.6): unstructured lifetime; `enter data copyin/create`, `exit data copyout/delete`. The idiom for data that lives across many kernels/functions (e.g. allocate fields once at solver init, free at finalize).
- **`if(cond)` on `data`**: false → *no* allocation/movement at all.
- **`async` on `data`** affects only the *transfers*, **not** the structured block's execution (stays synchronous) — and is **not inherited** by nested constructs. Mixing async data with sync compute is a race source.
- **array shape syntax**: `a[start:length]` (C) / `a(lb:ub)` (Fortran) — you must specify the slice for non-scalar pointers.

## Worked Example
The persistent-data idiom (the single biggest OpenACC optimization):
```c
// BAD: copies every iteration of the outer loop
for (int t = 0; t < nsteps; ++t) {
  #pragma acc parallel loop copy(u[0:n])   // alloc+H2D+D2H+free EACH step!
  for (int i = 1; i < n-1; ++i) u[i] = 0.5*(u[i-1]+u[i+1]);
}

// GOOD: data resident for the whole time loop, compute uses present
#pragma acc enter data copyin(u[0:n])
for (int t = 0; t < nsteps; ++t) {
  #pragma acc parallel loop present(u[0:n])  // no transfer
  for (int i = 1; i < n-1; ++i) u[i] = 0.5*(u[i-1]+u[i+1]);
}
#pragma acc exit data copyout(u[0:n])
```
Fortran derived-type with pointer (attach):
```fortran
!$acc enter data copyin(grid)            ! copies the descriptor
!$acc enter data copyin(grid%x(1:n))     ! copies the array
!$acc enter data attach(grid%x)          ! fix grid%x to point at the device array
```
- **Demonstrates**: hoisting transfers out of the time loop with `enter data` + `present` (eliminates per-step H2D/D2H), and the attach step for pointer members.

## Anti-patterns
- **`copy` inside a hot loop**: re-allocates and transfers every iteration — hoist to `enter data`/`data` + `present`.
- **Forgetting `present`** on data you already staged: triggers an implicit `copy`, silently re-transferring.
- **`async` on `data` expecting the block to overlap**: only transfers are async; the block runs synchronously and nested constructs don't inherit `async` → data races.
- **Copying a pointer value instead of `attach`**: device follows a host address → crash/garbage; attach the pointer to its device target.
- **Omitting array bounds** for a pointer (`copyin(a)` with no `[0:n]`): undefined extent.
- **Relying on implicit `copy`**: use `default(none)` and explicit clauses to make every transfer visible.

## Key Takeaways
1. **Hoist data out of loops**: `enter data copyin` once + `present` in kernels + `exit data copyout` — the dominant optimization (eliminates per-iteration transfers).
2. Clause cheat: `copyin`=input, `copyout`=output, `copy`=both, `create`=scratch, `present`=already there.
3. Reference counters (structured + dynamic) make nested/repeated data regions safe — alloc at 0→1, free at →0.
4. `attach`/`detach` is mandatory for pointer members of structs/derived types.
5. `async` on `data` overlaps only transfers and is not inherited — a classic race source; synchronize deliberately.

## Connects To
- **Ch 3**: compute constructs carry the same data clauses; implicit attributes from §2.6.2.
- **Ch 7**: async behavior — `async`/`wait` on data movement.
- **Ch 8**: runtime library — `acc_copyin`/`acc_copyout`/`acc_create`/`acc_attach` API equivalents.
- **Ch 6**: declare directive — static device data for module/global variables.
