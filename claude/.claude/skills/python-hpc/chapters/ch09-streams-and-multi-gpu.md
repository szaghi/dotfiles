# Chapter 9: Concurrency & Scaling — CUDA Streams and Multiple GPUs

## Core Idea
Once a kernel is tuned, the next levers are **overlap** (hide host↔device transfer behind compute using streams) and **scale-out** (spread work across multiple GPUs). Streams expose the GPU's ability to run copies and kernels concurrently; multi-GPU frameworks (Numba device selection, Dask-CUDA, JAX) partition work across devices.

## Frameworks Introduced

- **CUDA streams** (concurrency within a GPU):
  - A **stream** is an ordered queue of operations; work in *different* streams may overlap. The default (null) stream serializes; explicit streams enable concurrency.
  - **Asynchronous transfers**: `cuda.to_device(arr, stream=s)` and async copies let a transfer on one stream overlap a kernel on another. Requires **pinned (page-locked) host memory** for true async DMA.
  - The classic pipeline: split the input into chunks and, per chunk, overlap H2D copy of chunk *k+1*, kernel on chunk *k*, and D2H of chunk *k−1* across streams — hiding PCIe behind compute.

- **CUDA events** (timing and cross-stream sync):
  - `cuda.event()` records timestamps on a stream; `event.elapsed_time(other)` gives accurate GPU timing (kernel launches are async — you *must* synchronize before measuring). Events also express cross-stream dependencies (`stream.wait_event`).

- **Multi-GPU strategies**:
  - **Numba device selection**: `cuda.select_device(i)` / `cuda.gpus[i]` to target a specific GPU; partition the data and run per-device, then combine. Manual but explicit.
  - **Dask-CUDA**: spin up a cluster of GPU workers (one per device, local or multi-node) and distribute array/DataFrame work with the familiar Dask API + dashboard — the scale-out path for data-parallel GPU pipelines.
  - **JAX `pmap`**: single-program-multiple-device parallelism — map one function across devices with collective communication (used for distributed ML training).

- **Parallelism strategies**: **data parallelism** (same kernel, each GPU a data shard — the common case) vs **model/task parallelism** (different work per GPU). NCCL handles fast inter-GPU collectives (all-reduce) under the hood of the high-level frameworks.

## Key Concepts
- **Implicit synchronization**: certain operations (default-stream work, some allocations) serialize everything — structure code to keep independent work in separate non-default streams.
- **Pinned memory** is required for transfer/compute overlap; pageable host memory forces a synchronous staging copy.
- **GPU work queue**: the driver queues stream operations; oversubscribing one stream serializes, while spreading across streams exposes concurrency.
- **Multi-GPU data movement**: peer-to-peer (NVLink/PCIe) or via host; minimize cross-device traffic just as you minimize host↔device traffic.

## Mental Models
- **Overlap transfer with compute via streams + pinned memory** — once a kernel is tuned, the next win is hiding PCIe behind work; chunk the data and pipeline across streams.
- **Always synchronize (events/`cuda.synchronize()`) before timing** — async launches make an untuned timer report impossible speedups.
- **Scale data-parallel work with Dask-CUDA or `pmap`, not hand-rolled multi-GPU** — let the framework handle device placement, collectives, and failure; reserve manual `select_device` for fine control.
- **Minimize cross-device traffic** — partition so each GPU works on its shard with little inter-GPU communication, the same surface-to-volume logic as distributed CPU work.

## Code Examples
```python
from numba import cuda
import numpy as np

# Overlap copy + compute across streams (pinned host memory)
s1, s2 = cuda.stream(), cuda.stream()
h = cuda.pinned_array(n, dtype=np.float32)          # page-locked for async DMA
d1 = cuda.to_device(h[:n//2], stream=s1)
d2 = cuda.to_device(h[n//2:], stream=s2)
kernel[bpg, tpb, s1](d1)                              # runs on s1 while s2 copies
kernel[bpg, tpb, s2](d2)

# Accurate GPU timing with events (async-safe)
start, end = cuda.event(), cuda.event()
start.record(); kernel[bpg, tpb](d); end.record(); end.synchronize()
ms = start.elapsed_time(end)

# Explicit multi-GPU partition
for gpu_id in range(len(cuda.gpus)):
    cuda.select_device(gpu_id)
    run_on_shard(shard[gpu_id])
```
- **What it demonstrates**: stream overlap with pinned memory, event-based timing, and explicit multi-GPU partitioning.

## Reference Tables

| Goal | Tool |
|---|---|
| overlap copy + compute | streams + pinned memory |
| accurate kernel timing | `cuda.event` + `elapsed_time` |
| target a specific GPU | `cuda.select_device` |
| scale data-parallel GPU | Dask-CUDA / JAX `pmap` |
| fast inter-GPU collectives | NCCL (under frameworks) |

## Key Takeaways
1. Streams let copies and kernels overlap; pipeline chunked work across streams (with pinned memory) to hide PCIe transfer behind compute.
2. Kernel launches are async — use `cuda.event`/`synchronize` before timing.
3. Avoid implicit synchronization (default stream) — keep independent work in separate non-default streams.
4. Scale data-parallel GPU work with Dask-CUDA or JAX `pmap`; use explicit `select_device` only for fine control.
5. Partition multi-GPU work to minimize cross-device traffic; NCCL handles collectives under the high-level frameworks.

## Connects To
- **Ch 08 (Optimization)**: tune the kernel first, then overlap.
- **Ch 05 (Concurrency)**: Dask-CUDA mirrors CPU Dask's distributed model.
- **Ch 11 (JAX)**: `pmap`/`vmap` for device and batch parallelism.
- **Ch 12 (Profiling)**: events and Nsight Systems visualize the overlapped timeline.
