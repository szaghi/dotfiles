# Chapter 16: Cluster Launch Control, L2 Cache Control & Memory Sync Domains

## Core Idea
Three orthogonal hardware-level scheduling/memory controls for modern GPUs: **Cluster Launch Control** (Blackwell, CC 10.0) lets a running block *cancel* an unstarted block and steal its index — dynamic load balancing without giving up preemption. **L2 cache control** (CC 8.0+) lets you reserve part of L2 and tag a global-memory window as *persisting* so hot data stays resident. **Memory synchronization domains** (Hopper, CC 9.0+) shrink the "net" a fence casts so a local kernel's flush doesn't stall on a peer's slow NVLink/PCIe traffic.

## Frameworks Introduced

- **Cluster Launch Control (work stealing)**: combines the load-balancing/preemption of *fixed work per block* with the reduced-overhead of *fixed number of blocks*. A block tries to cancel another not-yet-started block; on success it adopts that block's index and does its work. Exposed via libcu++ `cuda::ptx` intrinsics, synchronized with an mbarrier like an async copy.
  - When to use: variable-cost work, want both preemption and prologue-amortization.
- **L2 set-aside + access policy window** (CC 8.0+): reserve a fraction of L2 (`cudaDeviceSetLimit(cudaLimitPersistingL2CacheSize, ...)`), then tag a `[ptr..ptr+num_bytes)` window via a stream/graph-node attribute with `hitProp`/`missProp`/`hitRatio`. Persisting accesses get prioritized retention.
  - Alternative API: `cuda::annotated_ptr` (libcu++, CUDA 11.5+).
- **Memory synchronization domains** (CC 9.0+): each launch gets a domain ID; a fence only orders writes of its own domain. Cross-domain ordering requires *system-scope* fencing; within-domain *device-scope* suffices.

## Key Concepts
- **Three launch strategies**: *Fixed work per block* (good load balancing + preemption, high per-block overhead); *Fixed number of blocks* / grid-stride (low overhead, no preemption/balancing); *Cluster Launch Control* (all three benefits).
- **try_cancel async pattern**: `ptx::clusterlaunchcontrol_try_cancel(&result, &bar)` is an async proxy op; complete it with `mbarrier_try_wait_parity`, decode with `clusterlaunchcontrol_query_cancel_is_canceled` and `..._get_first_ctaid_x/y/z`.
- **Cumulativity**: a system-scope release must flush not just the issuing thread's writes but all writes visible to it — forcing a conservatively wide fence net, the source of interference.
- **hitRatio**: probability (~) that an access in the window gets `hitProp`; sub-1.0 avoids cache-line thrashing between concurrent windows.
- **Logical vs physical domains**: `cudaLaunchMemSyncDomainDefault`/`...Remote` are logical; a map attribute binds them to physical domain numbers. Hopper has 4 physical domains; pre-9.0 reports count 1.

## Mental Models
- Cluster launch control = **a block stealing an un-dealt card** from the scheduler's deck. Succeeds only if a card is still face-down (block not started) and no higher-priority kernel has claimed the table.
- L2 set-aside = a **VIP lounge** in L2; persisting accesses get reserved seats, streaming accesses use them only when empty. Forgetting to reset = VIPs who never leave, starving later kernels.
- Domains = **mail sorted by zip code**: a fence is a "wait for all my mail" call; without domains it waits on everyone's mail (including the slow NVLink courier). Tag traffic by domain and your fence only waits on yours.

## Anti-patterns
- **Submitting another `try_cancel` after observing a previously failed one** → undefined behavior. Either don't observe between requests, or stop after a failure.
- **Reading the cancelled block index of a failed request** → UB; only read it when `is_canceled` is true.
- **Multi-thread cancellation without unique `__shared__` result pointers and adjusted barrier counts** → data races / multiple cancelled blocks.
- **Leaving persisting L2 lines un-reset** → they linger long after use, shrinking effective L2 for later normal/streaming kernels.
- **Over-subscribing the set-aside L2** beyond its capacity → persistence benefit collapses; net utilization is the *sum* of all concurrent kernels' windows.
- **Cross-domain ordering with only device-scope fencing** → broken cumulativity; cross-domain requires system scope.

## Reference Tables

**Launch-strategy trade-offs**

| | Fixed work/block | Fixed #blocks | Cluster Launch Control |
|---|:---:|:---:|:---:|
| Reduced overheads | ✗ | ✓ | ✓ |
| Preemption | ✓ | ✗ | ✓ |
| Load balancing | ✓ | ✗ | ✓ |

**L2 access properties**

| Property | Effect |
|---|---|
| `cudaAccessPropertyStreaming` | preferentially evicted (touch-once data) |
| `cudaAccessPropertyPersisting` | preferentially retained in set-aside L2 |
| `cudaAccessPropertyNormal` | resets prior persisting status to normal |

**Key L2 device properties / limits** (`cudaDeviceProp` via `cudaGetDeviceProperties`)

| Field / API | Meaning |
|---|---|
| `l2CacheSize` | total L2 on the GPU |
| `persistingL2CacheMaxSize` | max set-aside size (upper bound on the limit) |
| `accessPolicyMaxWindowSize` | max `num_bytes` of a window |
| `cudaLimitPersistingL2CacheSize` | the limit set/queried via `cudaDeviceSetLimit`/`cudaDeviceGetLimit` |
| `cudaCtxResetPersistingL2Cache()` | drop all persisting lines |

**Domain caveats**: MIG mode disables L2 set-aside; under MPS the set-aside is fixed at server startup via `CUDA_DEVICE_DEFAULT_PERSISTING_L2_CACHE_PERCENTAGE_LIMIT`. Domain count via `cudaDevAttrMemSyncDomainCount`.

## Worked Example
Setting an L2 persisting access window on a stream, exercising it, then resetting — the canonical "make hot data sticky" pattern:

```cpp
cudaDeviceProp prop;
cudaGetDeviceProperties(&prop, device_id);
size_t size = min(int(prop.l2CacheSize * 0.75), prop.persistingL2CacheMaxSize);
cudaDeviceSetLimit(cudaLimitPersistingL2CacheSize, size);   // set-aside 3/4 of L2

size_t window_size = min(prop.accessPolicyMaxWindowSize, num_bytes);

cudaStreamAttrValue stream_attribute;
stream_attribute.accessPolicyWindow.base_ptr  = reinterpret_cast<void*>(data1);
stream_attribute.accessPolicyWindow.num_bytes = window_size;
stream_attribute.accessPolicyWindow.hitRatio  = 0.6;        // ~60% get hitProp
stream_attribute.accessPolicyWindow.hitProp   = cudaAccessPropertyPersisting;
stream_attribute.accessPolicyWindow.missProp  = cudaAccessPropertyStreaming;
cudaStreamSetAttribute(stream, cudaStreamAttributeAccessPolicyWindow, &stream_attribute);

for (int i = 0; i < 10; i++)
    cuda_kernelA<<<grid_size,block_size,0,stream>>>(data1);  // reused -> benefits
cuda_kernelB<<<grid_size,block_size,0,stream>>>(data1);

stream_attribute.accessPolicyWindow.num_bytes = 0;          // disable window
cudaStreamSetAttribute(stream, cudaStreamAttributeAccessPolicyWindow, &stream_attribute);
cudaCtxResetPersistingL2Cache();                            // drop persisting lines
cuda_kernelC<<<grid_size,block_size,0,stream>>>(data2);     // full L2, normal mode
```
- **What it demonstrates**: query → reserve set-aside → tag window with hit/miss props and `hitRatio` → reuse → disable (`num_bytes = 0`) and reset.

## Key Takeaways
1. Cluster Launch Control (CC 10.0) gives work stealing: cancel an unstarted block, steal its index — preemption *and* load balancing *and* low overhead.
2. The `try_cancel` API is an async-proxy op: request → mbarrier sync → decode `is_canceled` / `get_first_ctaid_x`; never re-request after observing a failure.
3. Cluster variant uses `try_cancel_multicast`, `scope_cluster` fences, and `cg::cluster_group::sync()` to guarantee all blocks exist; add the local block index to the decoded ctaid.
4. L2 control (CC 8.0+): reserve set-aside, tag a window persisting, tune `hitRatio` to avoid thrashing — and *always reset* (`cudaAccessPropertyNormal` or `cudaCtxResetPersistingL2Cache`).
5. Memory sync domains (CC 9.0+) cut fence interference: tag local vs remote/comm traffic into different domains; cross-domain ordering needs system-scope fences. Default domain 0 keeps old code correct.

## Connects To
- **Ch 1**: thread block clusters and the SM/GPC hierarchy the cluster cancellation builds on.
- **Async copy / mbarrier chapters**: `try_cancel` reuses the async-proxy + mbarrier synchronization pattern.
- **Streams & graphs chapters**: access-policy windows and domain attributes are set as stream / graph-node launch attributes (`cudaLaunchKernelEx`).
- **Ch 3 / memory consistency**: cumulativity, release/acquire, thread scopes — the model domains modify.
