# Chapter 8: Advanced APIs, Kernel Programming & Driver API

## Core Idea
Three orthogonal "advanced" axes. (1) **Host-side launch control** beyond `<<<>>>`: `cudaLaunchKernelEx` carries an attribute list for clusters, programmatic dependent launch, and shared-memory carveout. (2) **Device-side performance machinery**: the SIMT/multithreading hardware model, thread *scopes*, scoped atomics, asynchronous barriers, pipelines, and async data copies (LDGSTS/TMA/STAS) — all about overlapping compute with data movement *inside* one kernel. (3) The **Driver API** (`cu*`): a lower, handle-based layer under the runtime, needed for PTX-JIT control, contexts, and virtual memory, and freely interoperable with the runtime.

## Frameworks Introduced
- **`cudaLaunchKernelEx(&config, kernel, args...)`**: extended launch. `cudaLaunchConfig_t` holds `gridDim`/`blockDim`/`dynamicSmemBytes`/`stream` *plus* `attrs`/`numAttrs` — an array of `cudaLaunchAttribute`. The extensibility point for every modern launch feature.
- **Cluster launch attributes**: `cudaLaunchAttributeClusterDimension` (required cluster size, set at runtime per-launch instead of compile-time `__cluster_dims__`); `cudaLaunchAttributePreferredClusterDimension` (CC ≥ 10.0, a *preferred* multiple of the minimum — kernel must run correctly at either size). Grid dims must be divisible by the cluster dims.
- **Programmatic Dependent Launch (PDL)**: overlap two stream-ordered kernels. Primary kernel calls `cudaTriggerProgrammaticLaunchCompletion()` when its produced data is flushed; secondary kernel does independent work then `cudaGridDependencySynchronize()` to wait; launch secondary with `cudaLaunchAttributeProgrammaticStreamSerialization` (`.programmaticStreamSerializationAllowed = 1`).
- **Batched transfers**: `cudaMemcpyBatchAsync()` / `cudaMemcpyBatch3DAsync()` — arrays of src/dst/sizes + `cudaMemcpyAttributes` (with index map) to amortize per-copy overhead and hand the driver location/ordering hints.
- **Thread scopes**: `thread` ⊂ `block`(.cta) ⊂ `cluster` ⊂ `device`(.gpu) ⊂ `system`(.sys) — each defines visibility and a point of coherency.
- **Scoped atomics** (`cuda::atomic<T, Scope>` or `__nv_atomic_*`): C++ memory ordering × CUDA scope.
- **Asynchronous barriers** (`cuda::barrier<Scope>`): split `arrive()`/`wait(token)`.
- **Pipelines** (`cuda::pipeline`): FIFO multi-stage producer/consumer for double-buffering.
- **Async data copies**: `cooperative_groups::memcpy_async` + `wait`; backed by LDGSTS (8.0+), TMA (9.0+), STAS (9.0+).
- **Driver API** (`cu*`): `cuInit`, `cuCtxCreate`, `cuModuleLoad`, `cuModuleGetFunction`, `cuLaunchKernel`.

## Key Concepts
- **SIMT hardware**: SM schedules in 32-thread warps; in-order issue, *no* branch prediction or speculation. Warps partitioned by consecutive thread IDs (warp 0 = thread 0+). Context lives on-chip → zero-cost warp switch.
- **Independent Thread Scheduling (CC ≥ 7.0)**: per-thread PC and call stack; threads diverge/reconverge at sub-warp granularity. Breaks implicit warp-synchronous code — use `__syncwarp()`.
- **Async thread / proxy**: an async op runs "as if" by a separate async thread. Generic-proxy ops (LDGSTS, STAS) order before-but-not-after; async-proxy ops (TMA, `tcgen05`, `wgmma`) need a **proxy fence** for ordering.
- **Carveout**: L1 and shared memory share the unified data cache; split is per-kernel.
- **Stream priorities**: hints, not guarantees; higher-priority pending work is picked first but never preempts running work.

## Mental Models
- **`cudaLaunchKernelEx` is the attribute bus.** Every feature that needs to whisper to the launcher rides an attribute, not a new launch function.
- **PDL = "I'm done with *your* data, finish the rest later."** Hoist the produce/consume boundary inside the kernels so launch overhead and tails overlap.
- **Scope is a tax.** Wider scope = farther coherency point = slower atomic. Pick the narrowest scope and weakest ordering that is still correct.
- **Async barrier splits "tell" from "wait".** `arrive()` never blocks; do useful work, then `wait(token)`. That gap is the whole point.
- **Driver API is the runtime with the lid off.** Same hardware, explicit context/module/function handles; the runtime's "primary context" is reachable from both.

## Anti-patterns
- **Assuming warp-lockstep on CC ≥ 7.0** (synchronization-free intra-warp reductions): wrong under independent thread scheduling. Insert `__syncwarp()`.
- **System-scoped atomics for block-local counters**: pays L2+ coherency for nothing. Use `thread_scope_block`.
- **Passing an ephemeral (stack) pointer to a batch copy with the wrong order**: the async API may dereference it after return. Use `cudaMemcpySrcAccessOrderDuringApiCall` for ephemeral sources.
- **Reusing a non-recorded event in a wait/query**: a never-`cudaEventRecord`-ed event always returns success — silent no-op.
- **`cudaFuncSetCacheConfig` between interleaved kernels**: hard requirement serializes launches behind reconfigurations. Prefer the hint `cudaFuncSetAttribute(..., cudaFuncAttributePreferredSharedMemoryCarveout, ...)`.
- **Static shared arrays > 48 KB/block**: illegal. Must be dynamic `extern __shared__` + opt-in via `cudaFuncAttributeMaxDynamicSharedMemorySize`.
- **Shipping only cubin for forward targets via the driver API**: load PTX — cubin is architecture-locked.

## Reference Tables

**Thread scopes**

| C++ scope | PTX | Visible to | Coherency |
|---|---|---|---|
| `thread_scope_thread` | — | local thread only | — |
| `thread_scope_block` | `.cta` | block | L1 |
| (cluster) | `.cluster` | cluster | L2 |
| `thread_scope_device` | `.gpu` | whole GPU | L2 |
| `thread_scope_system` | `.sys` | CPU + other GPUs | L2 + connected caches |

**Async-copy mechanisms**

| Mechanism | CC | Path |
|---|---|---|
| LDGSTS | 8.0+ | global → shared::cta (small) |
| TMA (bulk) | 9.0+ | global ↔ shared::cta/cluster, multi-dim tensors |
| STAS | 9.0+ | registers → shared::cluster |

**Host synchronization options**

| | Specific stream | Specific event | Whole device |
|---|---|---|---|
| Non-blocking (poll) | `cudaStreamQuery()` | `cudaEventQuery()` | N/A |
| Blocking | `cudaStreamSynchronize()` | `cudaEventSynchronize()` | `cudaDeviceSynchronize()` |

**Driver API objects**: `CUdevice`, `CUcontext` (≈ process), `CUmodule` (≈ DLL), `CUfunction` (kernel), `CUdeviceptr`, `CUstream`, `CUevent`.

## Worked Example
Programmatic Dependent Launch — overlap the tail of `primary` with the head of `secondary`:

```cpp
__global__ void primary_kernel() {
    // Initial work that should finish before starting secondary kernel
    cudaTriggerProgrammaticLaunchCompletion();   // data is flushed to global mem
    // Work that can coincide with the secondary kernel
}
__global__ void secondary_kernel() {
    // Initialization, independent work, etc.
    cudaGridDependencySynchronize();              // block until primary's data is ready
    // Dependent work
}

cudaLaunchAttribute attribute[1];
attribute[0].id = cudaLaunchAttributeProgrammaticStreamSerialization;
attribute[0].val.programmaticStreamSerializationAllowed = 1;

cudaLaunchConfig_t config = {0};
config.gridDim = grid_dim;  config.blockDim = block_dim;
config.dynamicSmemBytes = 0; config.stream = stream;
config.attrs = attribute;   config.numAttrs = 1;

primary_kernel<<<grid_dim, block_dim, 0, stream>>>();
cudaLaunchKernelEx(&config, secondary_kernel);
```
- **Demonstrates**: the three PDL pieces — trigger, grid-dependency sync, the serialization attribute — and that the dependent kernel must launch via `cudaLaunchKernelEx` to carry the attribute.

## Key Takeaways
1. `cudaLaunchKernelEx` + `cudaLaunchAttribute` is the single extensible launch path; clusters, PDL, and carveout all ride it.
2. PDL overlaps producer-tail with consumer-head: `cudaTriggerProgrammaticLaunchCompletion` / `cudaGridDependencySynchronize` / the serialization attribute.
3. Pick the narrowest thread scope and weakest memory ordering that is correct — scope width is a latency tax (block atomics ≫ system atomics).
4. Async barriers split arrive from wait; async data copies (LDGSTS/TMA/STAS) overlap global↔shared movement with compute inside one kernel.
5. Configure L1/shared with `cudaFuncSetAttribute` (a hint), not `cudaFuncSetCacheConfig` (a hard requirement that serializes launches); >48 KB shared needs dynamic opt-in.
6. The driver API (`cu*`) is the handle-based layer under the runtime; load PTX for forward compatibility, and the two APIs interoperate via the primary context and castable `CUdeviceptr`.

## Connects To
- **Ch 1**: SIMT model, warps, clusters, PTX — the foundation this chapter deepens.
- **Ch 9**: feature tour reframes async barriers, TMA, PDL, and stream-ordered allocation as latency/throughput tools.
- **Ch 11**: CUDA Graphs — the other concurrency mechanism, combinable with streams and PDL.
- **§4.9/4.10/4.11**: full treatments of barriers, pipelines, and async copies (incl. TMA).
- **`openmp-6.0` / `openacc-3.4`**: directive-level analogues of async data movement and scoped synchronization.
