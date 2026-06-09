# Patterns & Techniques — C++ HPC

## RAII ownership
**When to use**: any resource (memory, file, lock).
**How**: own through `unique_ptr`/`vector`/RAII members; never `new`/`delete` by hand.
**Trade-offs**: automatic, exception-safe cleanup; `unique_ptr` default, `shared_ptr` only for real sharing.

## Move into hot paths
**When to use**: passing/returning large objects.
**How**: `std::move(x)` to steal resources; make move ctor/assign `noexcept` so containers use them.
**Trade-offs**: O(n) copy → O(1) steal; moved-from object is valid-but-unspecified.

## Algorithm + lambda over hand loop
**When to use**: any loop expressible as sort/find/transform/reduce.
**How**: `std::sort(v.begin(), v.end(), cmp)`; add an execution policy to parallelize.
**Trade-offs**: clearer, optimized, parallelizable; iterate half-open `[first, last)`.

## Parallel STL execution policy
**When to use**: shared-memory parallelizing a standard algorithm.
**How**: `std::for_each(std::execution::par, ...)`; `par_unseq` for parallel+vectorized (no locks/iteration-deps in body).
**Trade-offs**: no manual threading; `par_unseq` body must be race-free and lock-free.

## Reduction over critical
**When to use**: parallel accumulation (sum/max).
**How**: OpenMP `reduction(+:s)`, `std::reduce(par, ...)`, MPI `Allreduce`, Kokkos `parallel_reduce`.
**Trade-offs**: parallel + false-sharing-free; FP results reorder (not bitwise reproducible).

## SoA + unit-stride access
**When to use**: any vectorized CPU or GPU kernel.
**How**: lay data out Structure-of-Arrays so consecutive lanes/threads touch consecutive memory.
**Trade-offs**: enables auto-vectorization (CPU) and coalescing (GPU); AoS often defeats both.

## Cache/shared-memory tiling
**When to use**: kernels with data reuse (stencils, matmul).
**How**: block the loop / stage a tile into cache or `__shared__`/Kokkos scratch, reuse, advance.
**Trade-offs**: raises arithmetic intensity, moves a memory-bound kernel up the roofline.

## MPI domain decomposition + halo exchange
**When to use**: grids, stencils, PDEs across nodes.
**How**: partition into subdomains; exchange ghost cells with neighbors (derived datatypes + Cartesian topology); overlap with `Isend`/`Irecv` + interior compute.
**Trade-offs**: maximize subdomain surface-to-volume; the decomposition dominates scaling.

## Write once, run anywhere with Kokkos
**When to use**: one codebase targeting CPU and multiple GPU vendors.
**How**: `View` arrays + `parallel_for`/`parallel_reduce` with `KOKKOS_LAMBDA`; let Kokkos pick the layout; select backend at build time.
**Trade-offs**: portability without separate CUDA/OpenMP paths; keep data device-resident, `deep_copy` at boundaries.

## Use a numerical library
**When to use**: any standard kernel (GEMM, FFT, sparse solve).
**How**: BLAS-3 `gemm` for dense, FFTW (plan+execute) for transforms, PETSc (KSP+PC) for distributed sparse.
**Trade-offs**: faster + more correct than hand-rolling; for sparse solvers the preconditioner choice dominates.

## Parallel self-describing I/O
**When to use**: output at scale.
**How**: parallel HDF5/NetCDF — all ranks write hyperslabs of one shared file collectively; XDMF + HDF5 for visualization.
**Trade-offs**: scalable and portable; never one-file-per-rank or raw binary.

## Diagnose before optimizing
**When to use**: any bug or slowdown.
**How**: reproduce → run sanitizers (ASan/TSan) for bugs / `perf` for hotspots → fix the dominant cost → re-measure.
**Trade-offs**: prevents wasted effort; Amdahl caps the gain at the fraction you speed up.

## Synchronized GPU timing
**When to use**: timing any GPU/async work.
**How**: warm up, then `cudaDeviceSynchronize()`/events before stopping the clock; repeat; compare to an optimized baseline.
**Trade-offs**: skipping sync reports impossible ">100×" speedups.
