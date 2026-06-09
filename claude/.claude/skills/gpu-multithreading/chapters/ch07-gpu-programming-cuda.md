# Chapter 7: GPU Programming with CUDA

## Core Idea
CUDA exposes the GPU as a massively parallel SPMD machine: a **grid of thread blocks of threads** runs a **kernel**, executed by the hardware in **warps** of 32 lockstep threads across **streaming multiprocessors (SMs)**. Performance is won through three levers — enough parallelism to hide memory latency (occupancy), **coalesced** global-memory access, and reuse through fast on-chip **shared memory** — and is then scaled with **streams** and **graphs** for overlap.

## Frameworks Introduced

### The thread hierarchy and kernel launch
- **Thread → block → grid.** Threads in a block cooperate via shared memory and `__syncthreads()`; blocks are independent and may run in any order on any SM. Indices: `threadIdx`, `blockIdx`, `blockDim`, `gridDim` (each `.x/.y/.z`).
- **Global linear index**: `int i = blockIdx.x * blockDim.x + threadIdx.x;` — and always **guard** `if (i < n)` because grids are rounded up.
- **Function qualifiers**: `__global__` (kernel, launched from host, runs on device, returns `void`), `__device__` (callable only from device), `__host__` (host; combine `__host__ __device__` for dual compilation), `__constant__`, `__shared__`.
- **Launch syntax**: `kernel<<<gridDim, blockDim, sharedBytes, stream>>>(args);` — the third/fourth config params (dynamic shared-memory size, stream) are optional.

```cuda
__global__ void saxpy(int n, float a, const float* x, float* y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];          // guard against over-launch
}
int threads = 256;
int blocks  = (n + threads - 1) / threads;       // ceil division
saxpy<<<blocks, threads>>>(n, 2.0f, d_x, d_y);
cudaDeviceSynchronize();                          // kernel launch is ASYNC
```

### The execution model: SMs, warps, SIMT
- Blocks are assigned whole to SMs; an SM holds several resident blocks limited by **registers, shared memory, warp slots, and block slots**. Threads run in **warps of 32** in lockstep (SIMT).
- **Warp divergence**: when threads in a warp take different branches, the hardware *serializes* the taken paths and masks off inactive lanes — branch on warp-aligned conditions, not per-thread data, where possible.
- **Warp schedulers**: every SM since compute capability 3.0 has **4 warp schedulers**, so a block should be at least `4 × warpSize = 128` threads to feed them all; each scheduler can issue from a ready warp each cycle, hiding stalls by switching warps.

### Occupancy (latency hiding)
- **Occupancy** = active warps per SM ÷ the SM's maximum warps. More resident warps give the schedulers more to switch among, hiding memory latency.
- Occupancy is bounded by the *most* constraining resource:
  - **registers per thread** × threads per block ≤ SM register file,
  - **shared memory per block** ≤ SM shared memory,
  - threads per block ≤ `maxThreadsPerBlock` (typically 1024),
  - resident blocks ≤ block-slot limit.
- **Block-sizing heuristics**: make `blockDim` a **multiple of 32** (no partial warps); start at **128–256** threads; raise registers per thread to cut shared-memory traffic only if it doesn't drop occupancy below what hides your latency. *Maximum occupancy is not always fastest* — a smaller block with more registers/thread can win when it raises arithmetic intensity or instruction-level parallelism. Use `cudaOccupancyMaxPotentialBlockSize` to get a launch-config starting point, then measure.

## Key Concepts

### The memory hierarchy (where performance is decided)
| Space | Qualifier / API | Scope | Latency | Notes |
|---|---|---|---|---|
| Registers | (automatic) | thread | ~1 cycle | fastest; **spilling** to local (global) memory kills perf |
| Local | (automatic, on spill) | thread | global-tier | register spills + large per-thread arrays |
| **Shared** | `__shared__` | block | ~5–30 cycles | on-chip scratchpad; basis of tiling; 32 **banks** |
| **Global** | `cudaMalloc` | grid | ~400–800 cycles | device DRAM; **must coalesce** |
| Constant | `__constant__` + `cudaMemcpyToSymbol` | grid (RO) | cached | broadcast to a whole warp in one read |
| Texture/surface | texture objects | grid (RO) | cached | 2D spatial locality, interpolation |

### Global-memory coalescing
- The hardware services global access in **32-, 64-, or 128-byte aligned transactions**. When the 32 threads of a warp touch addresses falling within the same aligned segment, one transaction serves them all — **coalesced**. Scattered or misaligned access fans out into many transactions, collapsing effective bandwidth.
- **Rule**: thread `t` should access element `base + t` (unit stride per warp). Prefer **Structure-of-Arrays (SoA)** over Array-of-Structures (AoS) so each field is contiguous across threads. Align allocations (`cudaMalloc` is suitably aligned; for 2D use `cudaMallocPitch`).

### Shared-memory bank conflicts
- Shared memory is split into **32 banks**, 4 bytes wide, interleaved. A warp's 32 accesses are served in one cycle **iff** they hit 32 distinct banks (or all read the same address → **broadcast**). Two threads hitting different addresses in the **same bank** = an **N-way bank conflict**, serialized N ways.
- **Fix**: pad shared arrays by one column (`__shared__ float tile[TILE][TILE+1];`) to skew the stride and break conflicts on column access.

### Tiling (the canonical reuse pattern)
Stage a tile of global data into shared memory, `__syncthreads()`, compute from shared memory (reusing each loaded element many times), `__syncthreads()`, advance. This raises **arithmetic intensity** (FLOPs/byte) and moves a memory-bound kernel up the roofline.

```cuda
// Tiled matrix multiply C = A·B (square, TILE×TILE blocks)
__global__ void matmul(const float* A, const float* B, float* C, int N) {
    __shared__ float As[TILE][TILE], Bs[TILE][TILE+1];   // +1 pad: no bank conflict
    int row = blockIdx.y*TILE + threadIdx.y;
    int col = blockIdx.x*TILE + threadIdx.x;
    float acc = 0.0f;
    for (int t = 0; t < N/TILE; ++t) {
        As[threadIdx.y][threadIdx.x] = A[row*N + t*TILE + threadIdx.x];  // coalesced
        Bs[threadIdx.y][threadIdx.x] = B[(t*TILE + threadIdx.y)*N + col];
        __syncthreads();                                  // tile fully loaded
        for (int k = 0; k < TILE; ++k)
            acc += As[threadIdx.y][k] * Bs[k][threadIdx.x];   // reuse from shared
        __syncthreads();                                  // before overwriting tile
    }
    C[row*N + col] = acc;
}
```

### Host↔device transfer
- `cudaMalloc`/`cudaFree`, `cudaMemcpy(dst, src, bytes, kind)` with `kind` ∈ `{HostToDevice, DeviceToHost, DeviceToDevice}`.
- **Pinned (page-locked) host memory** (`cudaHostAlloc`/`cudaMallocHost`) enables true async DMA and higher PCIe bandwidth; pageable memory forces a staging copy.
- **Unified memory** (`cudaMallocManaged`) gives one pointer migrated on demand; convenient, but prefetch (`cudaMemPrefetchAsync`) and `cudaMemAdvise` to avoid page-fault thrashing.

### Streams: overlapping copy and compute
A **stream** is an ordered command queue; operations in *different* streams may run concurrently. The classic pattern overlaps H2D copy of chunk *k+1* with kernel execution on chunk *k* and D2H of chunk *k−1*:

```cuda
cudaStream_t s[NS];
for (int i = 0; i < NS; ++i) cudaStreamCreate(&s[i]);
for (int c = 0; c < nChunks; ++c) {
    int k = c % NS;
    cudaMemcpyAsync(d_x+off, h_x+off, bytes, cudaMemcpyHostToDevice, s[k]);
    kernel<<<gb, tb, 0, s[k]>>>(d_x+off, d_y+off, m);
    cudaMemcpyAsync(h_y+off, d_y+off, bytes, cudaMemcpyDeviceToHost, s[k]);
}
cudaDeviceSynchronize();   // requires pinned host memory for real overlap
```
- Synchronize selectively: `cudaStreamSynchronize(s)`, `cudaStreamWaitEvent(s, evt)` (cross-stream dependency), `cudaEventRecord`/`cudaEventElapsedTime` for timing.

### CUDA graphs (launch-overhead amortization)
For many small, repeated launches, per-launch overhead dominates. A **graph** captures a DAG of operations once and replays it cheaply. Build by **stream capture**:
```cuda
cudaGraph_t g; cudaGraphExec_t gx;
cudaStreamBeginCapture(s, cudaStreamCaptureModeGlobal);
kernelA<<<.,.,0,s>>>(...); kernelB<<<.,.,0,s>>>(...);   // recorded, not run
cudaStreamEndCapture(s, &g);
cudaGraphInstantiate(&gx, g, nullptr, nullptr, 0);
for (int it = 0; it < steps; ++it) cudaGraphLaunch(gx, s);  // cheap replay
```
Note: non-stream calls (e.g. `cudaMalloc`) cannot be captured — allocate outside the capture region.

### Synchronization & atomics
- `__syncthreads()` — barrier across a *block* (all threads must reach it; never inside divergent control flow). `__syncwarp(mask)` — warp-level.
- Device atomics: `atomicAdd/Sub/Min/Max/CAS/Exch` on global or shared memory; `atomicAdd(double*)` requires CC ≥ 6.0. Warp-level primitives `__shfl_sync`, `__ballot_sync`, `__reduce_add_sync` enable register-level reductions without shared memory.

## Mental Models
- **Launch far more threads than cores and let the schedulers hide latency** — an undersized grid leaves the GPU stalled on memory. Oversubscription is the point, not a problem.
- **Coalesce global access before anything else** — uncoalesced loads are the single most common GPU performance bug. Lay data out SoA so warp lane `t` touches byte `base + t·stride_min`.
- **Tile through shared memory to raise arithmetic intensity** — this is the GPU form of agglomeration; pad shared arrays to dodge bank conflicts.
- **Max occupancy ≠ max speed** — past the point where latency is hidden, more registers/thread or more ILP can beat more warps. Measure both.
- **Overlap with streams + pinned memory; amortize many launches with graphs** — and on consumer GPUs remember FP64 runs at ~1:32–1:64 of FP32, so FP32-store/FP64-compute hybrids are usually a net loss.
- **Always synchronize before timing** — kernel launches are asynchronous; timing without `cudaDeviceSynchronize()`/events makes the GPU look impossibly fast (the classic ">100× speedup" artifact).

## Reference Tables

| Lever | Symptom of getting it wrong | Fix |
|---|---|---|
| coalescing | low achieved DRAM bandwidth | SoA, unit stride per warp, align |
| occupancy | schedulers stall, low util | ≥128 threads, multiple of 32, cap registers/shmem |
| bank conflicts | shared-mem-bound stalls | pad arrays `[N][N+1]` |
| divergence | serialized warp paths | branchless / regroup by warp |
| transfer | PCIe-bound, no overlap | pinned mem + async + streams |
| launch overhead | many tiny kernels dominate | CUDA graphs |

| API | Purpose |
|---|---|
| `cudaMalloc`/`cudaMemcpy` | explicit device memory + transfer |
| `cudaMallocManaged` | unified memory (on-demand migration) |
| `cudaHostAlloc` | pinned host memory (async DMA) |
| `cudaMemcpyAsync` + stream | overlapped transfer |
| `cudaStreamWaitEvent` | cross-stream dependency |
| `cudaEventElapsedTime` | accurate GPU timing |
| `cudaGraphLaunch` | replay a captured DAG |

## Key Takeaways
1. CUDA is SPMD over grid→block→thread, executed in 32-thread warps on SMs with 4 warp schedulers each; size blocks as a multiple of 32, start at 128–256.
2. Coalesce global access (SoA, unit stride per warp, aligned) — the highest-impact optimization; transactions are 32/64/128-byte aligned segments.
3. Tile through shared memory to raise arithmetic intensity; pad shared arrays `[N][N+1]` to avoid 32-bank conflicts.
4. Occupancy hides latency but isn't the sole target — registers/thread and ILP trade against it; profile.
5. Overlap copy/compute with streams + pinned memory; amortize many small launches with CUDA graphs; FP64 is ~1:32–1:64 of FP32 on consumer GPUs.
6. Kernel launches are async — synchronize (device/stream/event) before timing.

## Connects To
- **Ch 01 (Hardware)**: the GPU throughput model and SM hierarchy.
- **Ch 03 (Roofline)**: coalescing and tiling raise arithmetic intensity.
- **Ch 08 (OpenCL)**: the portable, vendor-neutral counterpart with the same model.
- **Ch 10 (Thrust)**: high-level primitives generating these kernels.
- **Ch 12 (Optimization)**: the synchronized benchmark-timing discipline and FP64 trap.
