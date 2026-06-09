# Chapter 15: Device Directives and Interoperability

## Core Idea
Offload to accelerators: the **`target`** construct family creates device data environments and executes regions on a device, with explicit data lifetime control (`target data`, `target enter/exit data`, `target update`) and device-resident declarations (`declare target`). Plus **`interop`** for bridging to foreign runtimes (CUDA/HIP streams).

## Frameworks Introduced
- **`target`** (§15.x): generate a **target task** enclosing a region executed on a device. Data environment from `map` clauses + data-environment ICVs. Clauses: `map`, `device([device-modifier:] num)`, `if([target:] cond)`, `nowait`, `depend`, `private`/`firstprivate`, `is_device_ptr`, `has_device_addr`, `defaultmap`. Falls back to host if device unavailable or `if(false)`.
- **Structured device data** (`target data` region) vs **unstructured** (`target enter data` / `target exit data` directives) — lexical vs arbitrary-lifetime device data (mirrors OpenACC `data` vs `enter/exit data`).
- **`target update`**: synchronize already-mapped data between host and device (`to(...)` H→D, `from(...)` D→H) without changing its lifetime.
- **`declare target`** (+ paired `begin/end declare target`): mark functions/variables for device compilation/residence; `enter`/`link`/`device_type` modifiers.
- **`device` clause modifiers**: `device_num` (default), `ancestor` (reverse-offload to a parent device — only on `target`, needs `requires reverse_offload`).
- **`interop`** (§16.1): retrieve interoperability properties (`init`/`use`/`destroy` actions, `interop-type` `targetsync`/`target`) to hand OpenMP-managed device context to a foreign runtime (e.g. get the CUDA stream).

## Key Concepts
- **map lifetime hoisting** = the dominant offload optimization (same as OpenACC): `target enter data map(to:...)` once, kernels use the resident data, `target exit data map(from:...)` at the end — avoid per-kernel transfers.
- **`target` + `teams distribute parallel for`** is the canonical GPU pattern (ch12).
- **`is_device_ptr` / `has_device_addr`**: pass an existing device pointer / a variable already having a device address into a `target` region (interop with CUDA-allocated memory). *(Errata sharpens their array-base rules — see ch07.)*
- **`requires unified_shared_memory`** (ch10) collapses the data model — `map` becomes largely optional.
- **`nowait` on `target`** makes the target task asynchronous; synchronize via `depend`/`taskwait`.

## Code Examples
```c
// hoist data, then run kernels against resident data (no per-kernel transfers)
#pragma omp target enter data map(to: a[0:n], b[0:n]) map(alloc: c[0:n])
for (int t = 0; t < nsteps; ++t) {
  #pragma omp target teams distribute parallel for
  for (int i = 0; i < n; ++i) c[i] = a[i]*b[i] + c[i];
}
#pragma omp target exit data map(from: c[0:n]) map(delete: a[0:n], b[0:n])

// device-resident function + variable
#pragma omp begin declare target
double kernel_helper(double x) { return x*x; }
#pragma omp end declare target

// async offload joined by dependence
#pragma omp target nowait depend(out: a) map(tofrom: a[0:n]) { /* ... */ }
#pragma omp taskwait depend(in: a)
```
- **Demonstrates**: data-lifetime hoisting with `target enter/exit data`, `declare target` for device functions, and async `target` joined via `depend`/`taskwait`.

## Anti-patterns
- **`map(tofrom:)` on every `target`**: re-transfers each launch — hoist with `target enter/exit data` + resident data.
- **Forgetting array bounds in `map`**: `map(a)` on a pointer is ambiguous — `map(tofrom: a[0:n])`.
- **Silent host fallback**: a `target` region runs on host if the device is absent — set `OMP_TARGET_OFFLOAD=MANDATORY` to catch it.
- **`ancestor` device-modifier off a non-`target` directive**: illegal; reverse-offload needs `requires reverse_offload`.
- **Async `target nowait` without a join**: reading results before the target task completes races — use `depend`/`taskwait`.

## Key Takeaways
1. `target` offloads a region to a device; `map` controls host↔device data; fallback to host if unavailable.
2. **Hoist data** with `target enter/exit data` + `target update` — avoid per-kernel transfers (the key perf lever).
3. `declare target` marks device-resident functions/variables; `target teams distribute parallel for` is the GPU idiom.
4. `is_device_ptr`/`has_device_addr` + `interop` bridge to CUDA/HIP; `interop` exposes the device stream.
5. `OMP_TARGET_OFFLOAD=MANDATORY` turns silent host-fallback into a hard error.

## Connects To
- **Ch 7**: `map`/`defaultmap` and the `is_device_ptr`/`has_device_addr` errata.
- **Ch 12**: `teams distribute parallel for` inside `target`.
- **Ch 10**: `requires unified_shared_memory`/`reverse_offload`.
- **Ch 17 (runtime)**: `omp_target_alloc`/`omp_target_memcpy`/`omp_target_is_accessible` device-memory API.
- **openacc-3.4**: the analogous `acc data`/`acc parallel` offload model.
