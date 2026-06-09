# C++ HPC Cheatsheet — Decision Rules & Tells

## The HPC workflow
1. **Correct first** — reproduce + sanitizers (ASan/TSan) before any speed work.
2. **Profile** — `perf` to find the dominant cost; never optimize unmeasured.
3. **Right algorithm** → **use a library** (BLAS/FFTW/PETSc) → only then hand-optimize.
4. **Pick the parallelism**: parallel-STL / OpenMP (shared) · MPI (distributed) · CUDA/Kokkos (GPU).
5. **Re-measure** against a baseline; keep a correctness test.

## Modern C++ rules
- RAII everything; `unique_ptr` default, `shared_ptr` only for real sharing.
- `std::move` large objects into hot paths; `noexcept` moves.
- const-correct; `auto` for template types; `constexpr` for compile-time.
- `std::array` fixed size, `std::vector` (with `reserve`) dynamic.
- Never test FP equality; `-Ofast`/`-ffast-math` breaks IEEE.

## Pick the parallel model
| Need | Use |
|---|---|
| shared-memory loop | parallel-STL (`par`/`par_unseq`) or OpenMP |
| distributed (multi-node) | MPI |
| single-vendor GPU | CUDA |
| portable CPU+GPU | Kokkos |
| irregular/dynamic/distributed tasks | actor model |

## Execution policy (parallel STL)
| Policy | Parallel | Vectorized | Body constraint |
|---|---|---|---|
| `seq` | no | no | none |
| `par` | yes | no | no data races |
| `par_unseq` | yes | yes | no locks, no iteration-deps |

## Shared-memory correctness
- Shared mutable state → atomic or lock (RAII `scoped_lock`); read-only/thread-local → free.
- OpenMP: `default(none)`; `reduction` not `critical` for accumulation; `atomic` (1 op) vs `critical` (block).
- Watch false sharing (pad per-thread data to 64 B); pin threads on NUMA (`OMP_PROC_BIND` + first-touch).

## MPI tells
- Two ranks exchanging → `MPI_Sendrecv` or nonblocking (blocking both-send = deadlock).
- Prefer collectives (`Bcast`/`Allreduce`) over point-to-point loops.
- Overlap: `Irecv`/`Isend` → compute interior → `Wait` → boundary.
- Derived datatypes + Cartesian topology for halos; maximize subdomain surface-to-volume.
- Strong scaling (Amdahl) vs weak scaling (Gustafson) — report separately.

## GPU optimization order (CUDA/Kokkos)
1. **Coalesce** global access (SoA, unit stride per warp / LayoutLeft).
2. **Tile** through shared memory / Kokkos scratch.
3. **Occupancy** — block size multiple of 32 (128–256).
4. Avoid **warp divergence**.
5. Minimize + overlap **host↔device transfer** (move once; streams).
- **Always `cudaDeviceSynchronize()` before timing** — async launches lie.
- FP64 ≈ 1:32–1:64 of FP32 on consumer GPUs — prefer float32.

## Kokkos portability
- `View` arrays + `parallel_for`/`reduce` + `KOKKOS_LAMBDA`; `RangePolicy`/`MDRangePolicy`/`TeamPolicy`.
- Let Kokkos choose layout (LayoutLeft GPU / LayoutRight CPU) → same loop coalesced + cache-friendly.
- Keep data in device Views; `deep_copy`/mirror only at boundaries; pick backend at build time.

## Numerical libraries (don't hand-roll)
| Task | Library |
|---|---|
| dense LA | BLAS-3 `gemm` / LAPACK |
| FFT | FFTW (plan once, execute many) |
| sparse distributed solve | PETSc (KSP + PC; preconditioner dominates) |
| portable distributed numerics | Trilinos/Tpetra (Kokkos) |

## Parallel I/O
- Never one-file-per-rank or raw binary at scale.
- Parallel HDF5/NetCDF: all ranks write hyperslabs of one shared file collectively.
- XDMF (XML) + HDF5 → ParaView/VisIt visualization.

## Debugging/profiling tools
| Symptom | Tool |
|---|---|
| crash/segfault | GDB + core; AddressSanitizer |
| data race | ThreadSanitizer |
| memory error (thorough) | Valgrind/Memcheck |
| CPU hotspot | `perf record`/`report` |
| cache misses | Cachegrind |
| GPU timeline / kernel | Nsight Systems / Compute |

## Build
- CMake + out-of-source (`cmake -B build`); `-O3 -march=native` (not portable across CPUs); `-O0 -g` to debug.
- Test the optimized build (high `-O` exposes latent UB); Spack/modules for cluster deps.
- git: version source + build recipe, NOT big data; record commit + env with results.
