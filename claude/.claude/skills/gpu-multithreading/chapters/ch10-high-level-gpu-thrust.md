# Chapter 10: High-Level GPU Programming with Template Libraries (Thrust)

## Core Idea
A template library like Thrust raises GPU programming from hand-written kernels to **STL-style parallel algorithms** over device containers. You express *what* (transform, reduce, sort, scan) over `device_vector`s; the library generates tuned kernels — trading fine control for productivity and portability.

## Frameworks Introduced

- **Containers + algorithms (the STL-on-GPU model)**:
  - **`thrust::host_vector<T>`** / **`thrust::device_vector<T>`** — host and device storage; assignment between them performs the host↔device copy transparently.
  - **Parallel algorithms**: `transform`, `reduce`, `transform_reduce`, `inclusive_scan`/`exclusive_scan`, `sort`/`sort_by_key`, `copy_if` (stream compaction), `gather`/`scatter`, `count`, `find`. Each launches an optimized kernel.
  - **Functors**: operations are expressed as function objects (`struct f { __host__ __device__ T operator()(...) }`) passed to algorithms.

- **Fancy iterators (the zero-copy composition trick)**: `counting_iterator` (index sequence), `constant_iterator`, `transform_iterator` (apply a function lazily), `zip_iterator` (iterate tuples of sequences), `permutation_iterator`. They let you fuse operations and avoid materializing intermediate arrays.

- **Execution policies**: `thrust::device` / `thrust::host` (and CUDA-stream-bound policies) select where an algorithm runs — the same call retargets CPU or GPU.

## Key Concepts
- **Kernel fusion via iterators**: chaining `transform_iterator`/`zip_iterator` into a single `reduce` avoids writing intermediate results to global memory — the high-level analogue of raising arithmetic intensity.
- **`transform_reduce`**: the fused map-then-reduce — the idiomatic dot-product / norm primitive.
- **Backends**: Thrust dispatches to CUDA, TBB, or OpenMP backends — the same code runs on GPU or multicore CPU.
- **Interop**: `thrust::raw_pointer_cast` and `device_ptr` bridge to hand-written CUDA kernels when you need to drop down.

## Mental Models
- **Reach for the library primitive before writing a kernel** — `sort`, `reduce`, and `scan` in a tuned library beat almost any hand-rolled version and are far less bug-prone.
- **Fuse with fancy iterators instead of materializing temporaries** — `transform_reduce(zip(...), ...)` does in one pass what naive code does in three allocations.
- **Drop to raw CUDA only at proven hotspots** — use `raw_pointer_cast` to hand a `device_vector`'s storage to a custom kernel where the library's generality costs you.
- **The same floating-point reproducibility caveat applies** — library `reduce`/`scan` reorder operations.

## Code Examples
```cpp
// STL-style: copy to device, transform, reduce — no explicit kernels
thrust::device_vector<float> x = h_x;          // host→device copy
thrust::device_vector<float> y(x.size());
thrust::transform(x.begin(), x.end(), y.begin(), saxpy_functor(a));

// Fused dot product — one pass, no intermediate array
float dot = thrust::transform_reduce(
    thrust::make_zip_iterator(thrust::make_tuple(x.begin(), y.begin())),
    thrust::make_zip_iterator(thrust::make_tuple(x.end(),   y.end())),
    [] __host__ __device__ (auto t) { return thrust::get<0>(t) * thrust::get<1>(t); },
    0.0f, thrust::plus<float>());
```
- **What it demonstrates**: container-based transform and a fused `transform_reduce` over a `zip_iterator` — no hand-written kernel, no temporaries.

## Reference Tables

| Primitive | Does |
|---|---|
| `transform` | element-wise map |
| `reduce` / `transform_reduce` | fold / fused map-fold |
| `inclusive/exclusive_scan` | prefix sum |
| `sort` / `sort_by_key` | ordering |
| `copy_if` | stream compaction |
| `gather` / `scatter` | indexed move |

| Fancy iterator | Purpose |
|---|---|
| `counting_iterator` | index sequence (no storage) |
| `transform_iterator` | lazy element transform |
| `zip_iterator` | iterate tuples of arrays |
| `permutation_iterator` | indexed view |

## Key Takeaways
1. High-level GPU libraries give STL-style `transform`/`reduce`/`sort`/`scan` over `device_vector`s — prefer them over hand-written kernels.
2. Host↔device copies happen transparently on `host_vector`↔`device_vector` assignment.
3. Fancy iterators (`zip`/`transform`/`counting`) fuse operations and eliminate intermediate arrays — the productivity form of raising arithmetic intensity.
4. Execution policies / backends retarget the same code to GPU, multicore (OpenMP/TBB), or CPU.
5. Drop to raw CUDA via `raw_pointer_cast` only at profiled hotspots; library reductions still reorder floating-point.

## Connects To
- **Ch 07 (CUDA)**: the kernels these primitives generate; interop for hotspots.
- **Ch 05 (Parallel primitives)**: scan/reduce/sort as the underlying algorithms.
- **Ch 03 (Arithmetic intensity)**: iterator fusion is reuse without materialization.
