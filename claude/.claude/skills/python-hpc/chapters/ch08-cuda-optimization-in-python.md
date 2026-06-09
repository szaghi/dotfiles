# Chapter 8: Optimizing CUDA Kernels in Python

## Core Idea
A correct kernel is rarely a fast kernel. Performance comes from feeding the hardware: **maximizing occupancy** (enough resident warps to hide memory latency), **coalescing** global-memory access, exploiting fast **shared memory** for reuse, and **avoiding warp divergence**. The same levers as native CUDA, reached through Numba-CUDA.

## Frameworks Introduced

- **How a kernel executes** (the hardware reality): blocks are scheduled onto streaming multiprocessors (SMs); each SM runs threads in **warps of 32**; warp schedulers hide stalls by switching to another ready warp. The **memory hierarchy** — registers (fastest) → shared (on-chip, per block) → global (device DRAM, slow) — is where data travels, and minimizing global traffic is the goal.

- **Maximizing occupancy**: occupancy = resident warps ÷ SM maximum. More resident warps give the schedulers more to switch among, hiding global-memory latency. Bounded by the most-constraining resource per block: **registers/thread**, **shared memory/block**, and threads/block. Numba reports register and shared-memory usage; tune block size and per-thread work to keep occupancy high enough to hide latency — but past that point, more registers/thread or ILP can win (max occupancy ≠ max speed).

- **Efficient global memory access (coalescing)**: the hardware services global access in aligned segments; when the 32 threads of a warp touch consecutive addresses, one transaction serves them all. Scattered/strided access fans out into many transactions, collapsing bandwidth. **Rule**: thread `i` accesses element `base + i` (unit stride per warp); lay data out so consecutive threads read consecutive memory.

- **Shared memory for reuse (avoid repeated global access)**: stage a tile of global data into `cuda.shared.array(shape, dtype)`, `cuda.syncthreads()`, then compute from shared memory — reusing each loaded element many times. This is the highest-leverage transformation for data-reuse kernels (stencils, matmul, convolution). Watch **bank conflicts**: shared memory has 32 banks; pad arrays (`[T][T+1]`) so a warp's accesses hit distinct banks.

- **Avoiding warp divergence**: when threads in a warp take different branches, the paths **serialize** with inactive lanes masked. Structure conditionals so a whole warp takes the same path, or make the work branchless.

- **Advanced levers**: **loop unrolling** for instruction-level parallelism (ILP), **warp-shuffle** (`cuda.shfl_sync`) to exchange register data within a warp without shared memory, **cooperative groups** for grid-wide sync instead of multiple kernel launches, and **intrinsics/libdevice** for fast math.

## Key Concepts
- **Memory-bound vs compute-bound**: profile to classify. Memory-bound kernels need better data movement (coalescing, shared-memory reuse); compute-bound need more ILP/occupancy/intrinsics. (Arithmetic intensity = FLOPs/byte locates the kernel.)
- **Coalesced vs non-coalesced**: the single biggest global-memory factor; a strided or transposed access pattern can cost 10× bandwidth.
- **Bank conflict**: two threads in a warp hitting different addresses in the same shared-memory bank serialize N-way; padding breaks the stride.
- **Latency hiding**: the GPU doesn't cache its way out of latency like a CPU — it hides it with many warps; that's why occupancy matters.

## Mental Models
- **Coalesce global access first** — it's the most common and highest-impact GPU performance bug; structure data so warp lane `i` reads element `i`.
- **Use shared memory to turn repeated global reads into one** — load a tile once, reuse it from on-chip memory; pad to avoid bank conflicts.
- **Hide latency with occupancy, not caches** — give the schedulers enough warps; tune block size against register/shared-memory limits.
- **Keep a warp on one branch** — divergent conditionals serialize 32 lanes; regroup work or go branchless.
- **Classify memory-bound vs compute-bound before optimizing** — the fix is different, and optimizing the wrong axis wastes effort.

## Code Examples
```python
from numba import cuda

# Shared-memory tiling: load once, reuse from on-chip memory
TPB = 16
@cuda.jit
def matmul_tiled(A, B, C):
    sA = cuda.shared.array((TPB, TPB),     dtype=cuda.float32)
    sB = cuda.shared.array((TPB, TPB + 1), dtype=cuda.float32)   # +1 pad: no bank conflict
    x, y = cuda.grid(2)
    tx, ty = cuda.threadIdx.x, cuda.threadIdx.y
    acc = 0.0
    for t in range((A.shape[1] + TPB - 1) // TPB):
        sA[ty, tx] = A[y, t*TPB + tx]      # coalesced load
        sB[ty, tx] = B[t*TPB + ty, x]
        cuda.syncthreads()                 # tile fully loaded
        for k in range(TPB):
            acc += sA[ty, k] * sB[k, tx]    # reuse from shared memory
        cuda.syncthreads()                 # before overwriting tile
    if y < C.shape[0] and x < C.shape[1]:
        C[y, x] = acc
```
- **What it demonstrates**: shared-memory tiling with a padded array to avoid bank conflicts and coalesced global loads — the core optimization pattern.

## Reference Tables

| Lever | Symptom of getting it wrong | Fix |
|---|---|---|
| coalescing | low achieved DRAM bandwidth | unit stride per warp, SoA |
| occupancy | schedulers stall | tune block size, cap registers/shmem |
| shared-mem reuse | repeated global reads | tile into `cuda.shared.array` |
| bank conflicts | shared-mem stalls | pad `[T][T+1]` |
| divergence | serialized warp paths | warp-uniform branches |

| Optimize for | Levers |
|---|---|
| memory-bound | coalesce, shared-memory reuse |
| compute-bound | ILP/unroll, occupancy, intrinsics, warp shuffle |

## Key Takeaways
1. Coalesce global-memory access (unit stride per warp, SoA layout) — the highest-impact GPU optimization.
2. Use `cuda.shared.array` tiling to turn repeated global reads into one on-chip load; pad arrays to avoid 32-bank conflicts.
3. Maximize occupancy to hide latency (the GPU hides latency with warps, not caches) — tune block size against register/shared limits; max occupancy isn't always fastest.
4. Avoid warp divergence — keep all 32 lanes on the same branch or go branchless.
5. Classify memory-bound vs compute-bound first; advanced levers are loop unrolling, warp shuffle, cooperative groups, and intrinsics/libdevice.

## Connects To
- **Ch 07 (Kernels)**: the kernels these optimizations apply to.
- **Ch 12 (GPU profiling)**: Nsight metrics confirm coalescing, occupancy, divergence.
- **Ch 09 (Streams)**: overlap as the next lever once a kernel is tuned.
