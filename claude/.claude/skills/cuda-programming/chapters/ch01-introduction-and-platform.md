# Chapter 1: Introduction to CUDA — Programming Model & Platform

## Core Idea
CUDA exposes the GPU as a throughput machine: a heterogeneous host+device system where you launch a **kernel** as a **grid of thread blocks**, each block running on one **SM**, with threads grouped into 32-wide **warps** executing in **SIMT**. The platform layers (compute capability → SM version → PTX → cubin/fatbin) determine what runs where and what's forward-compatible.

## Frameworks Introduced

- **Heterogeneous host/device model**: CPU = *host*, its RAM = *host/system memory*; GPU = *device*, its RAM = *device/global memory*. Execution **always starts on the host**; host code copies data, launches kernels, and waits. CPU and GPU run concurrently — maximize utilization of both.
  - When to use: the mental baseline for every CUDA program.
- **Grid → Block → Thread hierarchy**: A kernel launch = a *grid* of equally-sized *thread blocks* (1/2/3-D), each block = many *threads*. Built-in variables give each thread its identity (`blockIdx`, `blockDim`, `threadIdx`, `gridDim`).
  - How: pick block dims (multiple of 32), compute grid dims = ⌈problem / block⌉.
- **SIMT (Single-Instruction Multiple-Threads)**: threads in a 32-thread *warp* execute the same instruction; divergent branches mask off lanes. Unlike SIMD, each thread may follow its own control-flow path (no fixed data width).
  - Why it matters: warp divergence and memory coalescing are both warp-level effects.
- **Thread Block Clusters** (CC ≥ 9.0, optional): groups of adjacent blocks co-scheduled on one **GPC**, enabling cross-block sync and **distributed shared memory**.
- **Tile programming model** (alternative to SIMT): write *per-block* code on multidimensional **tiles**; the compiler maps tile ops to threads. No warp divergence (single block-level control flow). Coexists with SIMT per-kernel.

## Key Concepts
- **SM (Streaming Multiprocessor)**: hardware unit with register file, unified data cache (= L1 + shared memory, runtime-configurable split), functional units. Organized into **GPCs**.
- **Warp**: 32 threads, lanes 0–31, scheduled in lockstep (programming-model view).
- **Global memory**: GPU DRAM, visible to all SMs. **Shared memory**: on-chip, per-block. **Registers**: per-thread.
- **Unified Memory**: allocation accessible from CPU *or* GPU; runtime/hardware migrates pages. Keep migration minimal for performance.
- **Compute Capability (CC)** `X.Y`: feature + hardware-parameter level; maps to SM version `sm_XY`.
- **PTX**: virtual ISA / high-level GPU assembly; versioned as `compute_XY`; JIT-compiled to cubin.
- **cubin**: binary for a specific `sm_XY`. **fatbin**: container holding multiple cubins + PTX.

## Mental Models
- Think of the GPU as **"transistors spent on ALUs, not caches/control"** — opposite of a CPU. Throughput over latency.
- Think of a grid as **architecture-agnostic work**: the model *requires* blocks be runnable in any order, serial or parallel, so the same grid scales from 1 SM to thousands. → No cross-block data dependencies (except clusters/cooperative groups).
- Think of **PTX as forward-compatibility insurance**: ship PTX and it JIT-compiles to GPUs that didn't exist at build time.

## Anti-patterns
- **Relying on inter-block scheduling order or results**: blocks may not be co-resident; a block can't wait on another block's output (outside clusters/cooperative kernels).
- **Block size not a multiple of 32**: the tail warp wastes lanes → suboptimal ALU/memory utilization.
- **Exploiting observed hardware warp mapping** beyond the SIMT contract: undefined behavior that differs across GPUs.
- **Treating mapped (zero-copy) host memory as a perf substitute for unified memory**: access goes over PCIe/NVLink; latency can't be hidden.

## Reference Tables

**Memory spaces**

| Space | Scope | Location | Lifetime |
|---|---|---|---|
| Registers | per-thread | on-chip SM | thread |
| Shared memory | per-block (or cluster) | on-chip SM | block |
| Global memory | all SMs / grid | device DRAM | application/alloc |
| Constant cache | per-SM read-only | on-chip | kernel |
| Host/system memory | CPU | host DRAM | application |

**Compatibility rules**

| Form | Rule |
|---|---|
| cubin binary | runs on same major CC, minor ≥ target (e.g. `sm_86` → 8.6, 8.9; NOT 8.0, NOT 9.0) |
| PTX | JIT-compiles to any CC ≥ its `compute_XY` (forward compatible) |
| Binary-compat promise | only for NVIDIA-tool output (nvcc); voided by any manual edit |

## Worked Example
Per-thread global index — the canonical "what data am I responsible for" computation that every SIMT kernel opens with:

```cpp
// 1-D: each thread handles one element of a length-N array
__global__ void axpy(float a, const float* x, float* y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;  // unique global id
    if (i < n)                                       // guard the tail
        y[i] = a * x[i] + y[i];
}
// Host launch: choose block multiple of 32, grid = ceil(n / block)
int block = 256;
int grid  = (n + block - 1) / block;
axpy<<<grid, block>>>(2.0f, d_x, d_y, n);
```
- **What it demonstrates**: grid/block index arithmetic, the boundary guard `if (i < n)` (because grid is rounded up), and the `<<<grid, block>>>` execution configuration.

## Key Takeaways
1. Host starts everything; device runs kernels; both run concurrently — overlap to win.
2. A kernel is a grid of blocks of threads; blocks are independent and order-free by design (that's what makes CUDA scale).
3. Warps are 32 threads in SIMT; divergence and coalescing are warp-level. Size blocks as multiples of 32.
4. Memory hierarchy speed: registers > shared > L2 > global > host. Locality dominates performance.
5. CC ↔ `sm_XY` ↔ PTX `compute_XY`: ship cubins for your targets *plus* PTX for forward compatibility.
6. Tile programming is a higher-level per-block alternative to SIMT; choose per kernel.

## Connects To
- **Ch 2**: kernels, memory management, and error checking in CUDA C++/Python — these abstractions made concrete.
- **Ch 3**: SIMT memory spaces, coalescing, atomics (deep dive on §2.3 concepts).
- **Ch 4**: tile kernels (cuTile) — the tile model in practice.
- **Ch 20**: compute-capability feature/spec tables (the §5.1 appendix referenced here).
- **OpenACC/OpenMP-offload**: same hardware target, higher-level directive models (see `openacc-3.4`, `openmp-6.0`).
