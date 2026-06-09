# Glossary — C++ HPC

**actor** — concurrency primitive with private state, processing messages serially (Ch 14).
**AddressSanitizer (ASan)** — fast detector of OOB/use-after-free/leaks (`-fsanitize=address`) (Ch 12).
**Amdahl's law** — strong-scaling speedup bound 1/((1−α)+α/N); serial fraction is the wall (Ch 7).
**arithmetic intensity** — FLOPs per byte moved; locates a kernel on the roofline (Ch 5).
**auto** — compile-time type deduction (Ch 2).
**BLAS** — Basic Linear Algebra Subprograms; levels 1/2/3 (gemm = level 3) (Ch 13).
**cache line** — unit of memory transfer (commonly 64 bytes) (Ch 5).
**coalescing** — consecutive GPU threads accessing consecutive addresses → one transaction (Ch 9).
**collective** — MPI op all ranks participate in (Bcast/Reduce/Alltoall) (Ch 6).
**const-correctness** — marking non-mutating entities `const` (Ch 2).
**constexpr** — compile-time computation (Ch 2).
**data race** — unsynchronized conflicting access (≥1 write) ⇒ UB (Ch 4).
**deadlock** — circular wait (locks) or mismatched blocking send/recv (MPI) (Ch 6).
**deep_copy** — Kokkos transfer between memory spaces (Ch 10).
**derived datatype** — MPI description of non-contiguous data (Ch 7).
**domain decomposition** — partition data/grid across workers; geometric pattern (Ch 7).
**execution policy** — `seq`/`par`/`par_unseq` on parallel-STL algorithms (Ch 4).
**execution space** — Kokkos: where code runs (Cuda/OpenMP/Serial) (Ch 10).
**false sharing** — distinct vars on one cache line, serialized by coherence (Ch 4, 5).
**FFTW** — Fastest Fourier Transform in the West; plan + execute (Ch 13).
**functor** — struct with `operator()`; a callable object (Ch 3, 10).
**gemm** — BLAS-3 matrix-matrix multiply; near-peak FLOPS (Ch 13).
**GDB** — interactive debugger (breakpoints, backtrace, watch) (Ch 12).
**half-open range** — `[first, last)`; last is one-past-the-end (Ch 3).
**HDF5** — hierarchical self-describing data format; parallel via MPI-IO (Ch 11).
**hyperslab** — a rank's sub-region selection of a global HDF5 dataset (Ch 11).
**Kokkos** — C++ performance-portability programming model (Ch 10).
**KOKKOS_LAMBDA** — lambda annotated to compile for the device (Ch 10).
**Krylov solver** — iterative sparse solver (GMRES/CG) in PETSc (Ch 13).
**layout (Kokkos)** — LayoutLeft (GPU/column-major) vs LayoutRight (CPU/row-major) (Ch 10).
**loop-carried dependence** — iteration uses a prior iteration's result; blocks naive parallelism (Ch 4).
**map clause** — OpenMP host↔device data movement (separate from data-sharing) (Ch 8).
**memory space** — Kokkos: where data lives (CudaSpace/HostSpace) (Ch 10).
**move semantics** — `std::move` steals resources instead of copying (Ch 2).
**MPI** — Message Passing Interface; SPMD distributed-memory model (Ch 6, 7).
**NetCDF** — self-describing array format; NetCDF-4 on HDF5 (Ch 11).
**NUMA** — non-uniform memory access; local memory faster on multi-socket nodes (Ch 5).
**occupancy** — resident warps ÷ SM max; hides GPU memory latency (Ch 9).
**parallel_for/reduce/scan** — Kokkos parallel dispatch patterns (Ch 10).
**perf** — low-overhead sampling CPU profiler (Ch 12).
**PETSc** — distributed sparse solvers (Vec/Mat/KSP/PC) over MPI (Ch 13).
**preconditioner** — accelerates Krylov convergence (ILU/multigrid) (Ch 13).
**RAII** — acquire in ctor, release in dtor; automatic exception-safe cleanup (Ch 2).
**rank** — a process's id within an MPI communicator (Ch 6).
**reduction** — associative combine; parallel O(log n), FP-order-sensitive (Ch 4, 8).
**roofline** — model classifying kernels memory- vs compute-bound (Ch 5).
**Rule of Zero/Five** — declare no special members, or consider all five (Ch 2).
**shared_ptr** — reference-counted shared ownership (atomic count) (Ch 2).
**SIMD** — single instruction, multiple data; vector registers (Ch 5).
**SoA** — Structure-of-Arrays layout; enables SIMD/coalescing (Ch 5).
**SPMD** — single program, multiple data; MPI/GPU-kernel model (Ch 6, 9).
**STL** — Standard Template Library: containers + iterators + algorithms (Ch 3).
**tiling** — staging a data tile into fast memory for reuse (Ch 9).
**ThreadSanitizer (TSan)** — data-race detector (`-fsanitize=thread`) (Ch 12).
**Trilinos / Tpetra** — Kokkos-backed GPU-portable distributed numerics (Ch 13).
**unique_ptr** — unique ownership smart pointer; zero overhead (Ch 2).
**Valgrind** — thorough memory-error detector (Memcheck/Cachegrind) (Ch 12).
**View (Kokkos)** — portable multidimensional array, space+layout parameterized (Ch 10).
**VTK** — Visualization Toolkit format for ParaView/VisIt (Ch 11).
**warp** — group of 32 GPU threads in lockstep (SIMT) (Ch 9).
