# Chapter 13: Applied GPU Patterns — Stencils, N-Body, Imaging, Deep Learning

## Core Idea
Most real GPU workloads reduce to a handful of recurring computational patterns. Recognizing which pattern your problem fits tells you the decomposition, the memory strategy, and the right library — turning "how do I GPU-accelerate this?" into a known recipe.

## Frameworks Introduced

- **Stencil / finite-difference (PDE solvers, e.g. heat equation)**:
  - Discretize a field on a grid; each point updates from its neighbors each timestep (finite differences). This is **geometric/domain decomposition** — one thread per grid point.
  - Memory strategy: **load the halo region into shared memory** so each point's neighbor reads come from on-chip memory, not repeated global access. Mind the **CFL condition** (timestep stability) and boundary conditions.
  - Pattern: high data reuse → shared-memory tiling is the key optimization.

- **N-body / particle simulation (molecular dynamics)**:
  - Each particle interacts with others via a potential (e.g. **Lennard-Jones**); compute forces, then integrate motion (**Verlet** integrator). Parallelize the **force calculation** across particles (one thread per particle or per pair).
  - Memory strategy: tile particle data into shared memory; use atomics or careful partitioning for force accumulation. Often compute-bound → maximize occupancy and ILP.

- **Image processing / computer vision**:
  - Images are 2D arrays; convolution filters (blur, **Sobel edge detection**) are stencils over pixels — one thread per pixel. Use **CUDA streams** to pipeline multiple images (overlap transfer + compute), and high-level libraries (CuPy/cuDF, cuCIM) for standard filters. Classification combines hand kernels with CNNs.

- **Deep learning / transformers**:
  - The heavy operations are **batched matrix multiplies** and **attention** (scaled dot-product) — dominated by `@`/GEMM, which the frameworks dispatch to tuned libraries (cuBLAS) and tensor cores. Build with JAX/PyTorch rather than hand kernels; `vmap`/batching and `jit` fusion do the work.
  - Pattern: don't write GEMM kernels — use the optimized library; spend effort on data pipeline, batching, and memory.

## Key Concepts
- **Pattern → strategy mapping**: stencil → shared-memory tiling; N-body → occupancy + tiling + atomics; imaging → per-pixel + streams; DL → library GEMM + batching.
- **Data reuse determines shared-memory payoff**: stencils and tiled matmul reuse loaded data many times (tile it); elementwise ops don't (don't bother).
- **Compute- vs memory-bound by pattern**: stencils/imaging are usually memory-bound (optimize data movement); N-body force loops and GEMM are compute-bound (occupancy, tensor cores).
- **Use the right abstraction level**: kernels (Numba-CUDA) for custom stencils/forces; array libraries (CuPy) for vectorizable math; frameworks (JAX/PyTorch) for DL.

## Mental Models
- **Identify the pattern first, then apply its known recipe** — most GPU problems are a stencil, an N-body, a per-pixel map, or a GEMM in disguise; each has a settled decomposition and memory strategy.
- **Tile when there's reuse, stream when there are many independent inputs** — shared memory pays off for stencils/matmul; streams pay off for batches of images.
- **Don't hand-write what a tuned library already does** — GEMM, FFT, standard filters, and attention have optimized implementations (cuBLAS, cuFFT, cuDNN); reserve custom kernels for genuinely custom math.
- **Profile to confirm the bound** — a stencil you assumed compute-bound is usually memory-bound; let Nsight, not intuition, pick the lever.

## Reference Tables

| Pattern | Decomposition | Memory strategy | Bound | Tooling |
|---|---|---|---|---|
| stencil / PDE | one thread / grid point | halo into shared memory | memory | Numba-CUDA / CuPy |
| N-body / MD | one thread / particle | tile particles, atomics | compute | Numba-CUDA |
| imaging / convolution | one thread / pixel | streams for many images | memory | CuPy / cuCIM / kernels |
| deep learning | batched GEMM / attention | library + tensor cores | compute | JAX / PyTorch |

## Key Takeaways
1. Most GPU workloads are one of a few patterns — stencil, N-body, per-pixel imaging, or batched GEMM — each with a known decomposition and memory strategy.
2. Stencils and tiled matmul have high data reuse → shared-memory tiling (load halo/tile once); elementwise ops don't.
3. N-body force loops and GEMM are compute-bound (occupancy, tensor cores); stencils and imaging are usually memory-bound (data movement).
4. Use streams to pipeline batches of independent inputs (e.g. many images).
5. Don't hand-write GEMM/FFT/attention — use cuBLAS/cuFFT/cuDNN via the frameworks; reserve custom kernels for custom math, and profile to confirm the bound.

## Connects To
- **Ch 08 (Optimization)**: shared-memory tiling and occupancy realize these patterns.
- **Ch 09 (Streams)**: pipelining batches of inputs.
- **Ch 11 (JAX)**: the DL pattern's `jit`/`vmap`/autodiff foundation.
- **Ch 02 (Decomposition mindset)**: stencils/N-body are geometric decomposition on the GPU.
