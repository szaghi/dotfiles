# Chapter 8: Memory Management

## Core Idea
Allocate variables in specific **memory spaces** (high-bandwidth, low-latency, large-capacity, constant) via **allocators** with tunable traits — for placing hot data in fast memory (e.g. HBM) on heterogeneous systems.

> ⚠ **Errata (Nov 2025)** applied below at §8.4 (`allocator` clause).

## Frameworks Introduced
- **Predefined memory spaces** (§8.1): `omp_default_mem_space`, `omp_large_cap_mem_space` (capacity), `omp_const_mem_space` (read-only, init at allocation), `omp_high_bw_mem_space` (bandwidth, e.g. HBM), `omp_low_lat_mem_space` (latency, e.g. scratchpad). Actual mapping is implementation-defined.
- **Memory allocators** (§8.2): request contiguous storage from a memory space. Predefined handles `omp_default_mem_alloc`, `omp_high_bw_mem_alloc`, `omp_low_lat_mem_alloc`, etc.
- **Allocator traits** (Table 8.2): `alignment`, `pool_size`, `fallback` (`abort_fb`/`allocator_fb`/`null_fb`/`default_mem_fb`), `fb_data`, `pinned`, `partition` (`environment`/`nearest`/`blocked`/`interleaved`), `sync_hint`, `access`. Build a custom allocator with `omp_init_allocator(space, ntraits, traits)`.
- **`allocate` directive / `allocate` clause** (§8.4): direct a variable's storage to a given allocator/space. The clause form on a construct privatizes-and-allocates; the directive form applies to declared variables.
- **`omp_alloc`/`omp_free`** + aligned/calloc variants (runtime API, ch17).

## Errata correction (Nov 2025)
- **§8.4 (`allocator` clause)**: added restriction — *the memory-allocator specified by `allocator` at the directive where the clause appears must be the **same** as the memory-allocator specified at the declaration of the variables being allocated.* (You can't allocate with one allocator and declare with a different one.)

## Key Concepts
- **`partition` trait** is the NUMA knob: `nearest` (allocate near the accessing thread), `interleaved` (spread across nodes for bandwidth), `blocked`.
- **`fallback`** controls what happens when the space can't satisfy the request: abort, use a fallback allocator, return null, or fall back to default memory.
- **`omp_const_mem_space` is write-once**: initialized at allocation, never written — for lookup tables/constants the device can cache.
- Allocators interact with `firstprivate`/`private` (where do privatized copies live?) and with `target` (device-side allocation).

## Code Examples
```c
omp_alloctrait_t traits[] = {
  {omp_atk_partition, omp_atv_interleaved},
  {omp_atk_alignment, 64}
};
omp_allocator_handle_t hbm =
  omp_init_allocator(omp_high_bw_mem_space, 2, traits);

double *a = omp_alloc(n*sizeof(double), hbm);   // place in HBM, interleaved
// ... use a ...
omp_free(a, hbm);
omp_destroy_allocator(hbm);
```
```c
// allocate clause: privatized copies go in low-latency memory
#pragma omp parallel allocate(omp_low_lat_mem_alloc: scratch) private(scratch)
```
- **Demonstrates**: building an HBM allocator with NUMA-interleave + alignment traits, and steering privatized storage to low-latency memory.

## Anti-patterns
- **Ignoring memory spaces on heterogeneous nodes**: leaving bandwidth-bound data in default memory wastes HBM; place it with `omp_high_bw_mem_alloc`.
- **Mismatched allocator at declaration vs use** (post-errata): now explicitly forbidden — keep them the same.
- **Writing to `omp_const_mem_space`**: not permitted; it's read-only after init.
- **Forgetting `omp_destroy_allocator`** for custom allocators: leaks allocator handles.
- **Default `partition` on NUMA**: set `nearest`/`interleaved` deliberately rather than relying on first-touch alone.

## Key Takeaways
1. Five memory spaces (default/large/const/high-bw/low-lat); allocators draw from them with traits.
2. The `partition` trait is the NUMA placement knob (`nearest`/`interleaved`/`blocked`).
3. **Errata**: the `allocator` clause's allocator must match the one at the variable's declaration.
4. `omp_const_mem_space` is write-once; build custom allocators with `omp_init_allocator`.
5. `fallback` trait defines behavior when a space can't satisfy the request.

## Connects To
- **Ch 3/4**: `def-allocator-var` / `OMP_ALLOCATOR` set the default allocator.
- **Ch 7**: `allocate` interacts with `private`/`firstprivate` storage.
- **Ch 17**: `omp_alloc`/`omp_free`/`omp_init_allocator` runtime API.
- **CLAUDE-gpu.md / consumer-GPU notes**: HBM vs default memory placement for bandwidth-bound kernels.
