# Chapter 9: CUDA / GPU Programming

## Core Idea
CUDA programs the GPU as a massively parallel SPMD machine: a **grid of blocks of threads** runs a **kernel**, executed by the hardware in **warps** of 32 lockstep threads. Performance comes from massive parallelism to hide latency, **coalesced** memory access, and reuse via fast on-chip **shared memory** — while minimizing host↔device transfer.

## Frameworks Introduced

- **The thread hierarchy & kernel launch**:
  - **Thread → block → grid.** Threads in a block share memory and synchronize (`__syncthreads()`); blocks are independent. Global index: `int i = blockIdx.x * blockDim.x + threadIdx.x;` — always **guard** `if (i < n)`.
  - Qualifiers: `__global__` (kernel, host-launched, returns void), `__device__` (device-only), `__host__ __device__` (both). Launch: `kernel<<<gridDim, blockDim>>>(args);`.

```cuda
__global__ void saxpy(int n, float a, const float* x, float* y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a*x[i] + y[i];            // guard against over-launch
}
int threads = 256, blocks = (n + threads - 1) / threads;
saxpy<<<blocks, threads>>>(n, 2.0f, d_x, d_y);
cudaDeviceSynchronize();                          // launch is ASYNC — sync before using results
```

- **The execution model**: blocks schedule onto streaming multiprocessors (SMs); threads run in **warps of 32** (SIMT). **Warp divergence** (threads in a warp taking different branches) serializes the paths. **Occupancy** (resident warps ÷ SM max) hides memory latency.

- **The memory hierarchy** (where performance is won):
  - **Global** (device DRAM, slow) — access must be **coalesced** (consecutive threads → consecutive addresses) or bandwidth collapses.
  - **Shared** (`__shared__`, fast on-chip per-block) — basis of **tiling**: stage a tile of global data into shared memory, `__syncthreads()`, reuse it.
  - **Registers** (fastest, per-thread); **constant** (cached read-only).

- **Host↔device data movement**: `cudaMalloc`/`cudaMemcpy(dst, src, bytes, kind)` (kind ∈ HostToDevice/DeviceToHost), or **unified memory** (`cudaMallocManaged`, migrated on demand). PCIe transfer is the slow path — move data once, run many kernels, copy back once.

## Key Concepts
- **Kernel launches are asynchronous** — `cudaDeviceSynchronize()` (or events) before timing or using results; skipping this is the classic ">100× speedup" benchmarking error.
- **Coalescing**: structure data Structure-of-Arrays so warp lane `i` touches contiguous bytes; uncoalesced access is the #1 GPU performance bug.
- **Block sizing**: `blockDim` a multiple of 32 (start 128–256); `gridDim = ceil(n / blockDim)`.
- **Atomics** (`atomicAdd`, …) for race-free concurrent updates (histograms, reductions); `__syncthreads()` for block-wide cooperation (never in divergent control flow).
- **Consumer-GPU FP64 caveat**: gaming GPUs run double precision at ~1:32–1:64 of single-precision throughput — prefer float32 unless precision demands otherwise.

## Mental Models
- **Launch far more threads than cores and let the scheduler hide latency** — undersized grids leave the GPU idle on memory.
- **Coalesce global access first** — SoA layout, unit stride per warp; it's the highest-impact optimization.
- **Tile through shared memory to raise arithmetic intensity** — load a tile once, reuse it; the GPU form of cache blocking.
- **Minimize and overlap host↔device transfer** — move once, compute many kernels, copy back once; use streams for overlap.
- **Always synchronize before timing** — async launches make an untuned timer report impossible speedups.

## Code Examples
```cuda
// Allocate, transfer once, launch, copy back once
float *d_x, *d_y;
cudaMalloc(&d_x, n*sizeof(float)); cudaMalloc(&d_y, n*sizeof(float));
cudaMemcpy(d_x, h_x, n*sizeof(float), cudaMemcpyHostToDevice);
saxpy<<<blocks, threads>>>(n, 2.0f, d_x, d_y);
cudaMemcpy(h_y, d_y, n*sizeof(float), cudaMemcpyDeviceToHost);
cudaFree(d_x); cudaFree(d_y);

// Shared-memory tiling skeleton
__global__ void stencil(const float* in, float* out) {
    __shared__ float tile[TILE + 2];
    // load halo + interior into tile, then:
    __syncthreads();                          // all loads visible
    // compute from fast shared memory
}
```
- **What it demonstrates**: the allocate/transfer-once/launch/copy-back pattern and shared-memory tiling.

## Reference Tables

| Memory | Scope | Speed | Use |
|---|---|---|---|
| register | thread | fastest | locals |
| shared (`__shared__`) | block | fast | tiling, reduction |
| global (`cudaMalloc`) | grid | slow | main data (coalesce!) |
| constant | grid (RO) | cached | read-only lookups |

| Performance lever | Fix |
|---|---|
| uncoalesced access | SoA, contiguous per warp |
| low occupancy | more blocks/threads, fewer registers |
| warp divergence | branchless / regroup |
| PCIe stalls | unified memory / async streams |

## Key Takeaways
1. CUDA is SPMD over grid→block→thread in 32-thread warps; index with `blockIdx*blockDim+threadIdx` and **guard `if (i < n)`**.
2. Coalesce global access (SoA, unit stride per warp) — the highest-impact GPU optimization.
3. Tile through shared memory to raise arithmetic intensity; size blocks as a multiple of 32 (128–256).
4. Move data host↔device once (or use unified memory); minimize and overlap PCIe transfer.
5. Kernel launches are async — `cudaDeviceSynchronize()` before timing; FP64 is ~1:32–1:64 of FP32 on consumer GPUs.

## Connects To
- **Ch 05 (Hardware)**: the GPU throughput model and PCIe transfer.
- **Ch 08 (OpenMP)**: `target` offload as the directive-based GPU alternative.
- **Ch 10 (Kokkos)**: performance-portable abstraction generating CUDA kernels.
- **Ch 12 (Profiling)**: Nsight + the synchronized-timing discipline for kernels.
