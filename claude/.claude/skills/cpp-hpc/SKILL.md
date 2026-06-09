---
name: cpp-hpc
description: "Practitioner knowledge base for high-performance computing in C++ — the full toolchain, language idioms, parallel programming models, and HPC ecosystem. Use when building or optimizing C++ HPC software: the toolchain (Linux/cluster, git, CMake/Spack, compiler flags, SLURM); modern C++ for performance (RAII, smart pointers, move semantics, auto, constexpr, const-correctness, the STL containers/algorithms/iterators); shared-memory parallelism (parallel-STL execution policies, std::thread/atomic, OpenMP fork-join/clauses/tasks/offload); distributed-memory MPI (point-to-point, collectives, derived datatypes, communicators, RMA, scaling, halo exchange); GPU programming (CUDA thread hierarchy, coalescing, shared-memory tiling, occupancy); performance portability with Kokkos (Views, execution/memory spaces, layouts, parallel_for/reduce); HPC hardware (memory hierarchy, cache, SIMD, NUMA, roofline, accelerators); parallel I/O (HDF5, NetCDF, VTK, MPI-IO); debugging and profiling (GDB, AddressSanitizer/ThreadSanitizer, Valgrind, perf, Cachegrind, Nsight); numerical libraries (BLAS/LAPACK/gemm, FFTW, PETSc, Trilinos/Kokkos); or the actor model of concurrency. Self-contained with concrete APIs, code, and parameter tables for hands-on C++ HPC work."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, technology (mpi/openmp/cuda/kokkos), or chapter (e.g. ch10)]
---

# C++ High-Performance Computing
**Scope**: toolchain · modern C++ · STL & parallel patterns · hardware · MPI · OpenMP · CUDA · Kokkos · parallel I/O · debugging/profiling · numerical libraries · actor model | **Chapters**: 14 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core workflow and decision rules below.
- **With a topic** — ask about `RAII`, `parallel STL`, `coalescing`, `Kokkos View`, `PETSc`, `halo exchange`; I find and read the relevant chapter.
- **With a technology** — ask about `MPI`, `OpenMP`, `CUDA`, `Kokkos`; I load that chapter.
- **With a chapter** — ask for `ch10`; I load that file.

When you ask about something not in the Core section, I read the relevant chapter (and `cheatsheet.md` / `patterns.md` / `glossary.md`). Every chapter carries concrete APIs and code for hands-on work.

## Core Workflow & Decision Rules

### The HPC performance ladder (Ch 12, 13, then everything else)
1. **Correct first** — reproduce, run sanitizers (ASan/TSan), fix bugs before speed.
2. **Profile** — `perf` to find the dominant cost; never optimize unmeasured (Amdahl caps the gain at the fraction you speed up).
3. **Right algorithm**, then **use a library** (BLAS-3 `gemm`, FFTW, PETSc) — don't hand-roll standard kernels.
4. **Pick the parallel model**, then **optimize locality**.
5. **Re-measure** against a baseline; keep a correctness test.

### Modern C++ for HPC (Ch 2, 3)
RAII everything (`unique_ptr` default, `shared_ptr` only for real sharing); `std::move` large objects into hot paths with `noexcept` moves; const-correct; `auto`/`constexpr`. Prefer STL algorithms + lambdas over hand loops (parallelizable via execution policies). Never test FP equality; `-Ofast` breaks IEEE.

### Pick the parallel model (Ch 4, 6, 8, 9, 10, 14)
Shared-memory → **parallel-STL** (`par`/`par_unseq`) or **OpenMP**. Distributed/multi-node → **MPI**. Single-vendor GPU → **CUDA**. Portable CPU+GPU → **Kokkos**. Irregular/dynamic/distributed tasks → **actor model**. Real HPC node = hybrid (MPI across nodes + OpenMP/GPU within).

### Shared-memory correctness (Ch 4, 8)
Data race = UB — protect shared mutable state with atomics/locks (read-only/thread-local are free). OpenMP: `default(none)`, `reduction` not `critical`, `atomic` (1 op) vs `critical` (block). Watch false sharing (pad to 64 B) and pin threads on NUMA.

### GPU / portability optimization order (Ch 9, 10)
Coalesce global access (SoA / LayoutLeft) → tile through shared memory/scratch → occupancy (block multiple of 32) → avoid warp divergence → minimize+overlap host↔device transfer. Always `cudaDeviceSynchronize()` before timing; FP64 ≈ 1:32–1:64 of FP32 on consumer GPUs. Kokkos: write once, let it choose the layout, pick the backend at build time.

### Hardware & roofline (Ch 5)
The memory hierarchy dominates — engineer locality (cache lines = 64 B). Use arithmetic intensity + roofline to classify memory-bound (fix data movement) vs compute-bound (fix arithmetic). SoA enables SIMD/coalescing.

### MPI at scale (Ch 6, 7)
SPMD over ranks; communication is the bottleneck — minimize, batch, overlap (`Isend`/`Irecv` + interior compute). Collectives over point-to-point loops; `Sendrecv`/nonblocking to avoid deadlock; derived datatypes + Cartesian topology for halos; report strong vs weak scaling separately.

### Parallel I/O (Ch 11)
Never one-file-per-rank or raw binary at scale — parallel HDF5/NetCDF, all ranks writing hyperslabs of one shared file collectively.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-hpc-software-toolchain.md) | HPC Software Toolchain | Linux/cluster, git, CMake/Spack, compiler flags, SLURM |
| [ch02](chapters/ch02-modern-cpp-for-hpc.md) | Modern C++ for HPC | RAII, smart pointers, move semantics, auto, constexpr |
| [ch03](chapters/ch03-the-stl.md) | The STL | containers, iterators, algorithms, half-open ranges |
| [ch04](chapters/ch04-parallel-patterns-and-parallel-stl.md) | Parallel Patterns & Parallel STL | execution policies, loop dependence, atomics, false sharing |
| [ch05](chapters/ch05-hpc-hardware.md) | HPC Hardware | memory hierarchy, cache, SIMD, NUMA, roofline, accelerators |
| [ch06](chapters/ch06-mpi-fundamentals.md) | MPI Fundamentals | SPMD, point-to-point, collectives, deadlock, overlap |
| [ch07](chapters/ch07-advanced-mpi.md) | Advanced MPI | derived datatypes, communicators, Cartesian topology, RMA, scaling |
| [ch08](chapters/ch08-openmp.md) | OpenMP | fork-join, data-sharing clauses, reduction, tasks, target offload |
| [ch09](chapters/ch09-cuda-gpu-programming.md) | CUDA / GPU Programming | grid/block/warp, coalescing, shared-memory tiling, occupancy |
| [ch10](chapters/ch10-kokkos-performance-portability.md) | Kokkos | Views, execution/memory spaces, layouts, parallel_for/reduce |
| [ch11](chapters/ch11-parallel-io.md) | Parallel I/O | HDF5, NetCDF, VTK, hyperslabs, MPI-IO |
| [ch12](chapters/ch12-debugging-and-profiling.md) | Debugging & Profiling | GDB, ASan/TSan, Valgrind, perf, Cachegrind, Nsight |
| [ch13](chapters/ch13-numerical-libraries.md) | Numerical Libraries | BLAS/LAPACK/gemm, FFTW, PETSc, Trilinos |
| [ch14](chapters/ch14-actor-model.md) | The Actor Model | actors, messages, mailboxes, fault tolerance |

## Topic Index

- **actor model / message passing** → ch14
- **auto / constexpr / type deduction** → ch02
- **BLAS / LAPACK / gemm** → ch13
- **cache / memory hierarchy / roofline** → ch05
- **CMake / build / compiler flags** → ch01
- **coalescing / shared-memory tiling** → ch09
- **collectives (Bcast/Allreduce)** → ch06
- **CUDA (grid/block/warp)** → ch09
- **data race / false sharing** → ch04, ch05
- **debugging (GDB / sanitizers)** → ch12
- **derived datatypes / communicators / RMA** → ch07
- **domain decomposition / halo exchange** → ch07
- **execution policies (par/par_unseq)** → ch04
- **FFTW** → ch13
- **git / version control** → ch01
- **HDF5 / NetCDF / VTK / parallel I/O** → ch11
- **Kokkos (View / spaces / layout)** → ch10
- **move semantics / smart pointers / RAII** → ch02
- **MPI (point-to-point / scaling)** → ch06, ch07
- **NUMA / SIMD / accelerators** → ch05
- **OpenMP / clauses / tasks / offload** → ch08
- **PETSc / Trilinos / sparse solvers** → ch13
- **profiling (perf / Cachegrind / Nsight)** → ch12
- **reduction** → ch04, ch08, ch10
- **scaling (strong/weak/Amdahl/Gustafson)** → ch07, ch05
- **STL (containers/algorithms/iterators)** → ch03
- **toolchain / SLURM / Spack** → ch01

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete techniques (RAII, parallel-STL, tiling, halo exchange, Kokkos portability, library use, diagnosis)
- [cheatsheet.md](cheatsheet.md) — decision rules: performance ladder, parallel-model picker, GPU optimization order, MPI tells, debugging-tool picker, build flags

---

## Scope & Limits

Covers C++ HPC end to end — toolchain, modern-C++ idioms, the STL and parallel patterns, hardware, MPI, OpenMP, CUDA, Kokkos, parallel I/O, debugging/profiling, numerical libraries, and the actor model — with concrete APIs and code. It targets the durable techniques and decision rules; specific library APIs and compiler/spec versions evolve, so verify exact signatures against current documentation. Related skills: **gpu-multithreading** (cross-language parallel/GPU design methodology and deeper OpenMP-offload/CUDA/MPI references), **python-hpc** (the Python performance path), and **iso-cpp-2023** / **iso-c-9899-2024** (language-standard and memory-model details).
