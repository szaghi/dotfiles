# Chapter 6 (§2.12–2.14): atomic, declare, executable directives

## Core Idea
Three groups: **`atomic`** (race-free single-location updates inside parallel regions), **`declare`** (associate a device copy with a variable's scope), and the **executable directives** (`update`, `wait`, `init`, `shutdown`, `set`, `enter/exit data`) that run as statements rather than wrapping a region.

## Frameworks Introduced
- **`atomic`** (§2.12): ensures one storage location is read/written atomically across gangs/workers/vector threads. Clauses:
  - `read` (`v = x;`), `write` (`x = expr;`), `update` (default: `x++`, `x binop= expr`, `x = x binop expr`), `capture` (atomically update *and* return old/new value via a structured block).
  - Optional `if(condition)`.
- **`declare`** (§2.13): in a Fortran module/subprogram declaration section or after a C/C++ declaration; gives a var a **visible device copy** for the implicit data region of the enclosing scope (or program lifetime). Clauses: `copy`/`copyin`/`copyout`/`create`/`present`/`deviceptr`/`device_resident`/`link`. The idiom for module/global data that should live on the device.
- **`update`** (§2.14.4): synchronize already-resident data **without** changing its lifetime:
  - `self`/`host(vars)` — copy device→host; `device(vars)` — copy host→device.
  - `if_present` — skip silently if the var isn't on the device (no error).
  - `async`/`wait`/`if`/`device_type`.
- **Other executable directives** (§2.14): `init`/`shutdown` (device setup/teardown), `set` (set ICVs: device_type/num/default_async), `wait` (queue synchronization, ch7), `enter data`/`exit data` (unstructured lifetimes, ch4).

## Key Concepts
- **`atomic capture`** is the building block for parallel histograms, counters, and lock-free reductions where `reduction` doesn't fit.
- **`update` ≠ data lifetime**: it refreshes values both ways but neither allocates nor frees — pair with `enter data`/`declare`.
- **`device_resident`** (declare): the var lives *only* on the device (no host copy maintained); **`link`** defers allocation for large global data.
- **`if_present`** makes `update` safe when you're unsure data was staged.

## Code Examples
```c
// atomic update / capture
#pragma acc parallel loop
for (int i = 0; i < n; ++i) {
  #pragma acc atomic update
  hist[bin[i]] += 1;                 // race-free histogram
}
int old;
#pragma acc atomic capture
{ old = counter; counter += 1; }     // atomic fetch-add
```
```c
// update: refresh halo on host between async kernels
#pragma acc update self(u[0:nhalo])      // D2H
mpi_exchange(u);
#pragma acc update device(u[0:nhalo])    // H2D
```
```fortran
module fields
  real, allocatable :: u(:,:)
  !$acc declare create(u)        ! device copy tied to module/program lifetime
end module
```
- **Demonstrates**: `atomic update`/`capture` for race-free accumulation, `update self`/`device` for partial host↔device sync (halo exchange), and `declare create` for module-scope device data.

## Anti-patterns
- **Plain `+=` across iterations instead of `atomic update` or `reduction`**: data race.
- **`atomic` as a general lock**: it protects one location, not a critical section — don't build cross-thread locks (ch1: likely deadlock).
- **`update` to "load" data that was never allocated**: it doesn't allocate — use `enter data`/`copyin` first, or `if_present` to no-op safely.
- **Forgetting to `update` after host-side modification**: device keeps stale values; refresh with `update device`.
- **Overusing `atomic`**: serializes contended locations — prefer `reduction` when the pattern is a reduction.

## Key Takeaways
1. `atomic` (read/write/update/capture) makes single-location updates race-free; `capture` = atomic fetch-and-modify.
2. `declare create`/`device_resident` ties a device copy to a variable's scope — ideal for module/global fields.
3. `update self`/`device` synchronizes resident data both ways without changing its lifetime; `if_present` makes it safe when unsure.
4. Executable directives (`init`/`shutdown`/`set`/`update`/`wait`/`enter data`/`exit data`) run as statements.
5. For accumulation: prefer `reduction`; use `atomic` only for irregular scatter (histograms, counters).

## Connects To
- **Ch 3**: reduction clause — the structured alternative to atomic accumulation.
- **Ch 4**: data environment — `enter/exit data`, and `declare` for scoped device data.
- **Ch 7**: async behavior — `wait`, and `update async`.
- **Ch 8**: runtime library — `acc_init`/`acc_shutdown`/`acc_update_*` API equivalents.
