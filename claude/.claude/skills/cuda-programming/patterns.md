# CUDA Patterns & Techniques

## Grid-Stride Loop
**When to use**: process an array larger than the grid, or decouple grid size from problem size for tuning/occupancy.
**How**: `for (int i = blockIdx.x*blockDim.x + threadIdx.x; i < n; i += gridDim.x*blockDim.x)`.
**Trade-offs**: one kernel handles any `n`; lets you size the grid to the device, not the data. Slightly more index arithmetic per element.

## Boundary-Guarded Kernel
**When to use**: always, when grid is rounded up (`ceil(n/block)`) so the tail block over-runs.
**How**: compute global index, then `if (i < n) { ... }`.
**Trade-offs**: avoids OOB access; the tail warp partially masks (cheap).

## Coalesced Access
**When to use**: every global-memory read/write in a SIMT kernel.
**How**: arrange so lane *i* of a warp touches element `base + i` (consecutive). Use Structure-of-Arrays, not Array-of-Structures. Cast to vector types (`float4`) for wider transactions.
**Trade-offs**: 100% vs 12.5% bus utilization. The single biggest memory-perf lever.

## Shared-Memory Tiling (blocked GEMM/stencil/transpose)
**When to use**: data reused by multiple threads of a block (matmul, convolution, transpose).
**How**: cooperatively load a tile to `__shared__`, `__syncthreads()`, compute from shared, `__syncthreads()` before reuse. Pad the second dimension `[N][N+1]` to dodge bank conflicts.
**Trade-offs**: turns repeated global reads into one; requires correct double-barrier placement. Shared mem caps occupancy.

## Bank-Conflict-Free Shared Layout
**When to use**: column-wise or strided shared-memory access (transpose, reductions).
**How**: pad the leading stride by 1 element (`__shared__ float t[32][33]`) so column accesses hit distinct banks.
**Trade-offs**: tiny extra shared memory, removes up to 32-way serialization.

## Parallel Reduction
**When to use**: sum/max/min across a block or grid.
**How**: tree reduction in shared memory with `__syncthreads`; or `cg::reduce(group, val, op)` (Cooperative Groups); or warp-level via `__shfl_down_sync`.
**Trade-offs**: cooperative-groups/shuffle versions avoid shared memory and bank conflicts; manual tree is more explicit.

## Stream Overlap (copy/compute)
**When to use**: hide H2D/D2H transfers behind kernel execution.
**How**: pinned host memory + multiple streams; `cudaMemcpyAsync` + kernel + `cudaMemcpyAsync` each on its own stream; chunk the work.
**Trade-offs**: requires pinned memory and non-default streams; biggest win when transfer ≈ compute time.

## Event Timing
**When to use**: measuring GPU kernel/transfer time correctly.
**How**: `cudaEventRecord(start,s); kernel<<<...,s>>>(); cudaEventRecord(stop,s); cudaEventSynchronize(stop); cudaEventElapsedTime(&ms,start,stop);`.
**Trade-offs**: device-side timing that respects async execution — never time async work with host `cpu_time`/wall clock without a sync. (See `feedback_gpu_benchmark_timing`.)

## CUDA Graph for Repeated Launch
**When to use**: a fixed sequence of kernels/copies relaunched many times (iterative solvers, inference).
**How**: capture a stream into a graph (`cudaStreamBeginCapture`/`EndCapture`) or build with the Graph API; `cudaGraphInstantiate` once; `cudaGraphLaunch` per iteration; update params with node-update APIs.
**Trade-offs**: amortizes per-launch CPU overhead across the whole DAG; instantiation cost paid once. Update limitations on topology.

## Stream-Ordered Allocation
**When to use**: frequent alloc/free inside a pipeline.
**How**: `cudaMallocAsync(&p, n, s)` / `cudaFreeAsync(p, s)`; tune pool release threshold to retain memory.
**Trade-offs**: reuses freed blocks without device sync; pool can hold memory until threshold/trim.

## Unified Memory + Prefetch
**When to use**: large working sets, oversubscription, simpler code than explicit copies.
**How**: `cudaMallocManaged`; `cudaMemPrefetchAsync(p, n, dev, s)` before use; `cudaMemAdvise` (ReadMostly/PreferredLocation/AccessedBy) to steer placement.
**Trade-offs**: removes manual copies; un-prefetched access faults and migrates on demand (slow). Prefetch + advise to recover explicit-copy performance.

## Async Copy Pipelining (memcpy_async / TMA)
**When to use**: overlap global→shared staging with compute on CC ≥ 8.0 (LDGSTS) / ≥ 9.0 (TMA).
**How**: `cuda::memcpy_async` + `cuda::pipeline` stages, or `cp_async_bulk_tensor` with `cuTensorMapEncodeTiled` + `cuda::barrier` transaction counts.
**Trade-offs**: hides memory latency behind compute; correct barrier/transaction accounting is required or you read stale data.

## Producer-Consumer Warp Specialization
**When to use**: deep software pipelines where some warps stage data and others compute.
**How**: split warps by role; coordinate via `cuda::barrier`/`cuda::pipeline` with arrival counts.
**Trade-offs**: maximizes overlap and ALU utilization; complex; needs careful barrier phase tracking.

## Scoped Atomics for Correct Visibility
**When to use**: cross-block or cross-device communication via global flags.
**How**: choose the right scope — `cuda::atomic_ref<T, cuda::thread_scope_device>` (or `_system` for multi-GPU/host) — plus appropriate `memory_order`.
**Trade-offs**: too-narrow scope = silent stale reads; too-wide scope = slower. Match scope to the actual sharing.

## Persistent L2 for Hot Data
**When to use**: a region of global memory reused across many accesses (e.g. lookup tables).
**How**: set aside L2 (`cudaDeviceSetLimit(cudaLimitPersistingL2CacheSize,...)`), set a stream access-policy window with `hitProp=cudaAccessPropertyPersisting`; reset afterward.
**Trade-offs**: keeps hot data resident in L2; over-reserving starves normal traffic. Always reset.
