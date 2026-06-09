# Chapter 17 (§20–30): Runtime Library Routines

## Core Idea
The `omp_*` runtime API (~291 routines; C header `omp.h`, Fortran module `omp_lib`) — query/set ICVs, manage devices and device memory, allocators, locks, affinity, and tasking. The imperative complement to the directives.

> ⚠ **Errata (Nov 2025)** applied below at §20.12.1, §25.2.2, §27.11.

## Frameworks Introduced — by category
- **Parallel-region support** (§21): `omp_set/get_num_threads`, `omp_get_max_threads`, `omp_get_thread_num`, `omp_in_parallel`, `omp_get_level`/`omp_get_active_level`, `omp_get_ancestor_thread_num`, `omp_set/get_dynamic`, `omp_set/get_max_active_levels`, `omp_set/get_schedule`.
- **Teams** (§22): `omp_get_num_teams`, `omp_get_team_num`, `omp_set/get_num_teams`, `omp_get_teams_thread_limit`.
- **Tasking** (§23): `omp_in_final`, `omp_get_max_task_priority`, `omp_fulfill_event` (for `detach`).
- **Device info** (§24): `omp_get_num_devices`, `omp_get_default_device`/`omp_set_default_device`, `omp_get_device_num`, `omp_is_initial_device`, `omp_get_initial_device`, `omp_get_mapped_ptr`, `omp_get_device_from_uid`.
- **Device memory** (§25): `omp_target_alloc`/`omp_target_free`, `omp_target_memcpy`(`_rect`/`_async`), `omp_target_associate_ptr`/`omp_target_disassociate_ptr`, `omp_target_is_present`, **`omp_target_is_accessible`**.
- **Interoperability** (§26): `omp_get_interop_ptr`/`omp_get_interop_int`/`omp_get_interop_str` — extract foreign-runtime handles (e.g. the CUDA stream) from an `interop` object.
- **Memory management** (§27): `omp_alloc`/`omp_aligned_alloc`/`omp_calloc`/`omp_free`, `omp_init_allocator`/`omp_destroy_allocator`, `omp_get/set_default_allocator`, device/host memspace+allocator queries.
- **Locks** (§28): `omp_init_lock`/`omp_set_lock`/`omp_unset_lock`/`omp_test_lock`/`omp_destroy_lock` (+ `_nest_` variants, `omp_init_lock_with_hint`).
- **Affinity** (§29): `omp_get_proc_bind`, `omp_get_num_places`, `omp_get_place_num`, `omp_get_partition_*`, `omp_set/get_affinity_format`, `omp_display_affinity`.
- **Execution control** (§30): `omp_get_wtime`/`omp_get_wtick` (timing), `omp_pause_resource`/`omp_pause_resource_all`.
- **Tool control** (§31): `omp_control_tool`.

## Errata corrections (Nov 2025)
- **§20.12.1**: `omp_control_tool_max = INT32_MAX` added as the last enum value of the control-tool command enum.
- **§25.2.2 (`omp_target_is_accessible`)**: return rule corrected — "If `ptr` is NULL, returns zero" becomes "If `ptr` is NULL **or the implementation cannot guarantee accessibility**, returns zero." (Don't treat a nonzero return as the only "inaccessible" signal — NULL *or* unguaranteed accessibility → 0.)
- **§27.11**: the word "constant" removed from a restriction (a memory-management routine restriction is loosened — verify the exact routine in the spec).

## Key Concepts
- **`omp_get_wtime`** is the portable wall-clock timer — use it (not `cpu_time`) for OpenMP benchmark timing; pair with proper synchronization before/after the region.
- **`omp_target_memcpy`/`_async`** + `omp_target_alloc` give explicit device memory control for interop/custom staging.
- **`omp_get_interop_ptr`** is the bridge: get the underlying CUDA/HIP stream from an `interop` object to mix OpenMP with native device libraries.
- **Locks**: `omp_init_lock_with_hint` (uncontended/contended/speculative) tunes lock implementation; nestable variants for recursive locking.
- API `omp_set_*` affects *future* regions (ICV semantics, ch3), not the running one.

## Code Examples
```c
#include <omp.h>
double t0 = omp_get_wtime();
#pragma omp parallel for
for (int i = 0; i < n; ++i) a[i] = work(a[i]);
double elapsed = omp_get_wtime() - t0;     // portable wall-clock timing

// explicit device memory + async copy
double *d = omp_target_alloc(n*sizeof(double), dev);
omp_target_memcpy(d, a, n*sizeof(double), 0, 0, dev, omp_get_initial_device());
```
- **Demonstrates**: `omp_get_wtime` benchmarking and explicit device allocation + host→device `omp_target_memcpy`.

## Anti-patterns
- **`cpu_time`/`clock()` for parallel timing**: measures summed CPU across threads, not wall time — use `omp_get_wtime`.
- **Assuming `omp_set_num_threads` changes the current team**: it sets the ICV for *future* regions.
- **Treating `omp_target_is_accessible != 0` as guaranteed accessible without the NULL/unguaranteed cases** (post-errata): 0 also means "cannot guarantee."
- **Raw `omp_target_alloc`/`memcpy` when `map` suffices**: bypasses the mapping/reference-counter model — only for interop/custom staging.
- **Hardcoding device numbers**: query `omp_get_num_devices` / use `OMP_DEFAULT_DEVICE`.

## Key Takeaways
1. ~291 `omp_*` routines mirror the directives imperatively (query ICVs, devices, allocators, locks, affinity, tasking).
2. **`omp_get_wtime`** is the portable wall-clock timer for benchmarks — never `cpu_time`.
3. **Errata**: `omp_target_is_accessible` returns 0 for NULL *or* unguaranteed accessibility; `omp_control_tool_max` enum added; a §27.11 "constant" restriction loosened.
4. `omp_target_alloc`/`memcpy` + `omp_get_interop_ptr` enable CUDA/HIP interop.
5. `omp_set_*` affects future regions, not the running one (ICV semantics).

## Connects To
- **Ch 3**: ICVs these routines query/set.
- **Ch 8**: allocator routines (`omp_init_allocator`, `omp_alloc`).
- **Ch 15**: device-memory and interop routines for `target`.
- **Ch 18**: `omp_control_tool` and the OMPT interface.
- **feedback_gpu_benchmark_timing**: timing discipline — `omp_get_wtime` + sync.
