# Chapter 14: Dependent Launch, Green Contexts & Lazy Loading

## Core Idea
Four host-side control features that shape *when* and *where* GPU work runs, with no kernel-algorithm changes. **Programmatic Dependent Launch** (CC ≥ 9.0) overlaps a primary kernel with a dependent secondary one — the secondary launches early and synchronizes only on the data it actually needs. **Green Contexts** statically partition a GPU's SMs and work queues so latency-sensitive work always has resources to start. **Lazy Loading** defers CUDA module loading until first use, cutting init time. **Error Log Management** turns opaque return codes into plain-English diagnostics.

## Frameworks Introduced

- **Programmatic Dependent Launch (PDL)**: primary kernel calls `cudaTriggerProgrammaticLaunchCompletion()` when the secondary may start; secondary calls `cudaGridDependencySynchronize()` before touching the primary's results. Secondary is launched via `cudaLaunchKernelEx` with attribute `cudaLaunchAttributeProgrammaticStreamSerialization`.
  - When to use: dependent kernels in one stream where the secondary has independent preamble work (zeroing buffers, loading constants).
- **Green Contexts (GC)**: a lightweight execution context provisioned at creation with specific SMs and work queues. Work on a GC's stream can only use its provisioned resources.
  - How: get resources → split SMs → generate descriptor → create GC → create stream → launch. Pure host-side change.
- **Lazy Loading**: load CUDA modules on demand; controlled by `CUDA_MODULE_LOADING` (`LAZY`/`EAGER`). Default-on since CUDA 12.3.
- **Error Log Management**: `CUDA_LOG_FILE` env var + `cuLogs*` driver APIs produce human-readable error logs and callbacks.

## Key Concepts
- **PDL is opportunistic, not guaranteed**: overlap may happen; *relying* on concurrent execution is unsafe and can deadlock. The secondary must *always* use `cudaGridDependencySynchronize` to confirm the primary's data is visible.
- **Implicit trigger**: if the primary never calls the trigger, completion fires after all its blocks exit.
- **PDL in graphs**: edge type `cudaGraphDependencyTypeProgrammatic` with from-port `cudaGraphKernelNodePortProgrammatic` (early, block-start) or `cudaGraphKernelNodePortLaunchCompletion`.
- **GC vs MIG vs MPS**: MIG statically partitions the whole GPU pre-launch across applications; MPS partitions at the process level (active-thread-%, any N SMs, time-varying); GC partitions *specific* N SMs *within a single process*, far more lightweight (structures shared with the primary context).
- **Work queues**: a second resource type — false dependencies arise when independent streams map to the same WQ; `wqConcurrencyLimit` hints the driver to avoid this (also bounded by `CUDA_DEVICE_MAX_CONNECTIONS`).
- **No concurrency guarantee**: even with separate SMs and WQs, GC only *removes interference factors*; it does not guarantee parallel execution.
- **Lazy-loading caveats**: it does not change the programming model, but exposes latent bugs in non-compliant code (concurrent-execution assumptions, full-VRAM-on-startup allocators, perf measurement).

## Mental Models
- Think of PDL as **"prefetching the next kernel's launch latency"** — the secondary's preamble runs in the shadow of the primary, then a barrier (`cudaGridDependencySynchronize`) gates only the truly dependent part.
- Think of a Green Context as **"a GPU-within-the-GPU you carve in software"** — like MIG but per-process, lightweight, and oversubscribable.
- Think of SM splitting as **resource accounting with alignment constraints**: you request groups, the driver rounds to architecture granularity (e.g. CC 9.0: min 8 SMs, multiple of 8), and hands back what it could actually carve.
- Think of Lazy Loading as **"don't pay for kernels you never call"** — pure init-time savings for library-heavy binaries.

## Anti-patterns
- **Relying on PDL concurrency for correctness**: unsafe, can deadlock. It's a perf opportunity only.
- **Configuring a secondary with PDL but skipping `cudaGridDependencySynchronize`**: secondary may read the primary's results before they're flushed — UB.
- **Using `cudaGraphAddKernelNode` for GC graph nodes**: it can't set the execution context. Use polymorphic `cudaGraphAddNode` with `cudaGraphNodeTypeKernel` and set `.ctx`.
- **Setting `cudaGreenCtxCreate` flags ≠ 0**: must be 0. Also init the primary context first (`cudaSetDevice`/`cudaInitDevice`) to avoid overhead.
- **Casual SM oversubscription across GCs**: defeats the isolation; use judiciously per-case.
- **Allocating all VRAM at startup with lazy loading on**: modules can't load at runtime → failure. Use `cudaMallocAsync` or preload kernels.
- **Benchmarking with lazy loading without a warmup**: module init leaks into the measured window.

## Reference Tables

**PDL device functions & attributes**

| Symbol | Role |
|---|---|
| `cudaTriggerProgrammaticLaunchCompletion()` | primary signals secondary may launch |
| `cudaGridDependencySynchronize()` | secondary blocks until primary results flushed |
| `cudaLaunchAttributeProgrammaticStreamSerialization` | launch attr enabling early secondary launch |
| `cudaLaunchAttributeProgrammaticEvent` (`triggerAtBlockStart`) | event-based variant (graphs) |

**Green Context creation (4 steps)**

| Step | API |
|---|---|
| 1. Get resources | `cudaDeviceGetDevResource(dev, &res, cudaDevResourceTypeSm)` |
| 2. Partition SMs | `cudaDevSmResourceSplitByCount` (homogeneous) / `cudaDevSmResourceSplit` (heterogeneous, discovery mode) |
| 2b. Add work queues | set `cudaDevResourceTypeWorkqueueConfig` fields (`wqConcurrencyLimit`, `sharingScope`) |
| 3. Generate descriptor | `cudaDevResourceGenerateDesc(&desc, &res, n)` |
| 4. Create GC | `cudaGreenCtxCreate(&gc, desc, dev, 0)` |
| Launch | `cudaExecutionCtxStreamCreate(&strm, gc, cudaStreamDefault, prio)` then `<<<...,strm>>>` |

**GC split fields (`cudaDevSmResourceGroupParams`)**: `smCount` (0 = discovery), `coscheduledSmCount` (cluster co-scheduling), `preferredCoscheduledSmCount` (CC 10.0 preferred cluster dim hint), `flags` (0 or `cudaDevSmResourceGroupBackfill`).

**Lazy loading (`CUDA_MODULE_LOADING`)**: `LAZY` / `EAGER`. Query: `cuModuleGetLoadingMode`. Force-load: `cuModuleGetFunction`/`cudaFuncGetAttributes`. Requires runtime ≥ 11.7, driver ≥ 515; managed-variable modules always load eagerly.

**Error logs**: `CUDA_LOG_FILE` (`stdout`/`stderr`/path). Format `[Time][TID][Source][Severity][API Entry Point] Message`. APIs: `cuLogsRegisterCallback`, `cuLogsCurrent`, `cuLogsDumpToFile`, `cuLogsDumpToMemory` (≤ 100 entries, ≤ 25600 bytes).

## Worked Example
The PDL contract — primary triggers, secondary synchronizes, launched via the extensible API with the serialization attribute:

```cpp
__global__ void primary_kernel() {
   // Initial work that should finish before starting secondary kernel
   cudaTriggerProgrammaticLaunchCompletion();   // Trigger the secondary kernel
   // Work that can coincide with the secondary kernel
}

__global__ void secondary_kernel() {
   // Independent work (the preamble that overlaps the primary)
   // Block until all primary kernels' results are flushed to global memory
   cudaGridDependencySynchronize();
   // Dependent work
}

cudaLaunchAttribute attribute[1];
attribute[0].id = cudaLaunchAttributeProgrammaticStreamSerialization;
attribute[0].val.programmaticStreamSerializationAllowed = 1;
configSecondary.attrs = attribute;
configSecondary.numAttrs = 1;

primary_kernel<<<grid_dim, block_dim, 0, stream>>>();
cudaLaunchKernelEx(&configSecondary, secondary_kernel);
```
- **What it demonstrates**: the secondary's independent preamble runs concurrently with the primary; `cudaGridDependencySynchronize()` is the *only* thing making the dependent part correct, because the secondary may otherwise observe the primary's writes before they are visible.

## Key Takeaways
1. PDL overlaps a primary with a dependent secondary; the secondary's independent preamble hides launch latency, but correctness *requires* `cudaGridDependencySynchronize` — concurrency itself is never guaranteed.
2. Green Contexts statically partition SMs (and work queues) per-process so latency-sensitive kernels always have SMs to start on — no kernel changes, just a different stream-creation API.
3. GC creation is 4 steps: get resources → split → generate descriptor → create; `cudaDevSmResourceSplit` adds heterogeneous partitions and discovery mode (`smCount = 0`).
4. SM splits round to architecture granularity (CC 9.0: min 8, multiple of 8); cluster support needs `coscheduledSmCount`.
5. For GC graph nodes use `cudaGraphAddNode` (sets `.ctx`), not `cudaGraphAddKernelNode`.
6. Lazy Loading (default since 12.3) cuts init time but surfaces latent bugs — preload concurrent kernels, avoid full-VRAM startup allocators, add benchmark warmups.
7. `CUDA_LOG_FILE` + `cuLogs*` give plain-English error diagnostics beyond the bare return code.

## Connects To
- **Ch 13 (Cooperative Groups)**: `cudaGridDependencySynchronize` complements grid-level CG sync; `cooperative_groups::invoke_one` is an alternative to single-thread election in launch-control patterns.
- **Ch 12 (Stream-Ordered Allocator)**: lazy loading explicitly recommends `cudaMallocAsync` over grab-all-VRAM allocators.
- **CUDA Graphs**: PDL via `cudaGraphDependencyTypeProgrammatic` edges; GC execution context set per graph node.
- **Ch 1 (SMs, GPCs, clusters)**: green-context SM partitioning and `coscheduledSmCount` build directly on the SM/GPC/cluster hardware model.
- **MIG / MPS**: complementary partitioning mechanisms; GC can be layered inside a MIG instance.
