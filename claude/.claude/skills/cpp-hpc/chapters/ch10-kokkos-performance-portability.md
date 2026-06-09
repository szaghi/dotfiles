# Chapter 10: Kokkos — Performance Portability

## Core Idea
Kokkos is a C++ programming model that lets you write a kernel **once** and run it efficiently on CPUs, NVIDIA/AMD/Intel GPUs, or multicore — by abstracting *where* code runs (**execution space**), *where* data lives (**memory space**), and *how* arrays are laid out (**layout**). The compiler specializes the same source to each backend.

## Frameworks Introduced

- **Parallel dispatch patterns** (the computation): `Kokkos::parallel_for`, `Kokkos::parallel_reduce`, `Kokkos::parallel_scan`, and `Kokkos::fence` (synchronize). The body is a **functor** or a `KOKKOS_LAMBDA` (a lambda annotated to compile for the device).

```cpp
Kokkos::initialize(argc, argv);                 // like MPI: all Kokkos calls between init/finalize
{
    Kokkos::View<double*> data("data", N);      // device-resident array
    Kokkos::parallel_for("init", N, KOKKOS_LAMBDA(int i) {
        data(i) = i;                            // runs on the default execution space
    });
    double sum = 0.0;
    Kokkos::parallel_reduce("sum", N, KOKKOS_LAMBDA(int i, double& acc) {
        acc += data(i);                         // reduction: thread-private acc, combined
    }, sum);
}
Kokkos::finalize();
```

- **Execution policies** (how to iterate): `Kokkos::RangePolicy` (1D range), `Kokkos::MDRangePolicy` (multi-dimensional nested loops), `Kokkos::TeamPolicy` (hierarchical: teams of threads with shared scratch — the league/team/thread model, ≈ CUDA blocks/threads).

- **`Kokkos::View`** (the portable multidimensional array): a reference-counted, layout- and space-parameterized array. `View<double**, LayoutLeft, CudaSpace>` is a 2D column-major array in GPU memory. Indexing `v(i, j)`. Memory is managed (RAII) — no manual free.

- **Execution & memory spaces**:
  - **Execution space** — *where code runs*: `Kokkos::Cuda`, `Kokkos::OpenMP`, `Kokkos::Serial`, `Kokkos::HIP`, etc.
  - **Memory space** — *where data lives*: `CudaSpace` (GPU), `HostSpace` (CPU), `CudaUVMSpace` (unified).
  - **`deep_copy`** moves data between spaces; **mirror views** (`create_mirror_view`) pair a device View with a host-accessible copy for transfer.

## Key Concepts
- **Layout matters for portability**: `LayoutLeft` (column-major) is optimal on GPUs (coalescing across threads), `LayoutRight` (row-major) on CPUs (cache lines). Kokkos picks the layout matching the default execution space — so the *same* indexed loop is coalesced on GPU and cache-friendly on CPU.
- **Functor vs `KOKKOS_LAMBDA`**: a struct with `operator()` (reusable, stateful) or an inline annotated lambda (concise); both compile to device code.
- **Reductions**: `parallel_reduce` gives each thread a private accumulator combined at the end — built-in and correct (the same FP-reordering caveat applies).
- **One source, many backends**: choose the backend at build time (CMake `-DKokkos_ENABLE_CUDA=ON`); the kernel source is unchanged.

## Mental Models
- **Write the kernel once against Views and parallel dispatch; let the backend specialize it** — this is the whole value proposition: no separate CUDA/OpenMP code paths.
- **Let Kokkos choose the layout** — don't hardcode row/column-major; the default layout for the execution space gives coalescing on GPU and cache-friendliness on CPU automatically.
- **Keep data in device memory via Views; `deep_copy` only at boundaries** — like CUDA, the transfer is the cost; mirror views handle host↔device cleanly.
- **`TeamPolicy` for hierarchical algorithms** — when you need block-level shared scratch and cooperation (tiling, segmented reductions), it maps onto teams of threads.

## Code Examples
```cpp
// Portable 2D kernel: same source, coalesced on GPU AND cache-friendly on CPU
Kokkos::View<double**> A("A", M, N);            // layout chosen for the execution space
Kokkos::parallel_for("fill",
    Kokkos::MDRangePolicy<Kokkos::Rank<2>>({0,0}, {M,N}),
    KOKKOS_LAMBDA(int i, int j) { A(i, j) = i*N + j; });

// Host↔device via mirror view
auto h_A = Kokkos::create_mirror_view(A);       // host-accessible copy
Kokkos::deep_copy(h_A, A);                        // device → host, only at the boundary

// Hierarchical TeamPolicy (teams of threads with shared scratch)
Kokkos::parallel_for(Kokkos::TeamPolicy<>(num_teams, Kokkos::AUTO),
    KOKKOS_LAMBDA(const Kokkos::TeamPolicy<>::member_type& team) {
        int t = team.league_rank();
        Kokkos::parallel_for(Kokkos::TeamThreadRange(team, work),
            [&](int k){ /* per-thread work */ });
    });
```
- **What it demonstrates**: a layout-agnostic MDRange kernel, mirror-view transfer, and the hierarchical TeamPolicy.

## Reference Tables

| Concept | Kokkos | ≈ CUDA |
|---|---|---|
| parallel loop | `parallel_for` | kernel launch |
| reduction | `parallel_reduce` | tree reduction |
| array | `View<T*>` | `cudaMalloc` array |
| where it runs | execution space | device |
| where data lives | memory space | global memory |
| host↔device copy | `deep_copy` / mirror | `cudaMemcpy` |
| hierarchical | `TeamPolicy` | blocks/threads |

| Layout | Optimal on |
|---|---|
| `LayoutLeft` (column-major) | GPU (coalescing) |
| `LayoutRight` (row-major) | CPU (cache lines) |

## Key Takeaways
1. Kokkos writes a kernel once and runs it on CPU/GPU backends by abstracting execution space, memory space, and layout.
2. Use `View` for portable arrays, `parallel_for`/`parallel_reduce`/`parallel_scan` with `KOKKOS_LAMBDA` or functors, and `RangePolicy`/`MDRangePolicy`/`TeamPolicy` for iteration.
3. Let Kokkos choose the layout (LayoutLeft on GPU, LayoutRight on CPU) so the same indexed loop is coalesced and cache-friendly.
4. Keep data device-resident in Views; transfer host↔device only at boundaries via `deep_copy`/mirror views.
5. Select the backend at build time (CMake) — the kernel source is unchanged; `TeamPolicy` handles hierarchical/shared-scratch algorithms.

## Connects To
- **Ch 09 (CUDA)**: Kokkos generates CUDA kernels; the same coalescing/occupancy levers apply underneath.
- **Ch 08 (OpenMP)**: the multicore backend; Kokkos abstracts over both.
- **Ch 03 (STL)**: `parallel_for`/`View` generalize STL algorithm/container patterns to the device.
