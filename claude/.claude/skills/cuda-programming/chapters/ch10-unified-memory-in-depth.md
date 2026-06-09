# Chapter 10: Unified Memory In Depth

## Core Idea
Unified memory gives one pointer that both CPU and GPU dereference; the *behavior* splits into four paradigms by hardware capability. On **full-support** systems (Grace Hopper, or Linux + HMM) the device can touch *any* host allocation — `malloc`, stack, globals, file-backed, IPC. On **managed-only** systems (CC 6.x+, no pageable access) only `cudaMallocManaged` memory is shared. On **legacy** systems (CC < 6.0 / Windows, `concurrentManagedAccess = 0`) coherence is enforced crudely: the GPU owns *all* managed data while *any* kernel runs, so the CPU must synchronize before touching it. Performance is a paging story: keep data local, prefetch ahead, and advise the driver — but every hint costs host time, so only use one if it pays for itself.

## Frameworks Introduced
- **Allocators** (full support): `malloc`/`new`/`mmap`, `cudaMallocManaged`, `cudaMalloc`, `cudaMallocHost`/`cudaHostAlloc`/`cudaHostRegister`, memory pools (`cuMemCreate`, `cudaMemPoolCreate`, `cudaMallocAsync`).
- **`cudaMemPrefetchAsync(devPtr, count, cudaMemLocation, flags, stream)`**: stream-ordered migration of a range toward a processor (`cudaMemLocationTypeDevice`/`...Host`). Data is accessible while prefetching.
- **`cudaMemAdvise(devPtr, count, advice, location)`**: `cudaMemAdviseSetReadMostly` (read-duplicate), `...SetPreferredLocation`, `...SetAccessedBy` (establish mapping; on HW-coherent systems enables access-counter migration). Each has an `Unset` counterpart.
- **Memory discarding**: `cudaMemDiscardBatchAsync(dptrs, sizes, count, flags, stream)` — tell the driver a range's contents are dead so it won't migrate them on eviction/prefetch; `cudaMemDiscardAndPrefetchBatchAsync` fuses discard + prefetch.
- **Querying**: `cudaMemRangeGetAttribute[s]` — `ReadMostly`, `PreferredLocation[Type/Id]`, `AccessedBy`, `LastPrefetchLocation[Type/Id]`.
- **Stream association** (legacy): `cudaStreamAttachMemAsync(stream, ptr, length, flags)`; `cudaMallocManaged(..., cudaMemAttachHost)`.
- **Direct host access**: device attribute `cudaDevAttrDirectManagedMemAccessFromHost`; native atomics: `cudaDevAttrHostNativeAtomicSupported`.

## Key Concepts
- **HW-coherent vs SW-coherent**: combined CPU/GPU page table (Grace Hopper) → no coherency page faults, coherent at *cache-line* granularity. Separate page tables (SW-coherent) → page faults emulate coherency, migrate at *page* granularity (cost ∝ page size).
- **Page-size tradeoff**: small pages = less fragmentation, more TLB misses; large pages = fewer TLB misses, costlier migration. GPU TLB misses hurt far more than CPU. Tune *virtual* page size, never physical.
- **Oversubscription**: unified memory lets you allocate arrays larger than any single processor's RAM — out-of-core on one GPU.
- **Access-counter migration** (HW-coherent): driver tracks remote-access frequency and migrates the page to the hot processor.
- **Legacy exclusive ownership**: GPU is "active" whenever *any* kernel runs, regardless of what it touches.

## Mental Models
- **The four paradigms are a capability ladder.** Full support → device reads everything. Managed-only → only `cudaMallocManaged`. Legacy → whole-GPU exclusive ownership, manual sync. Check `concurrentManagedAccess`/`pageableMemoryAccess` before assuming behavior.
- **Hints are bets, not commands.** They never affect correctness, only performance, and each carries host-side cost. A hint that doesn't beat its own overhead is a net loss.
- **`ReadMostly` = replicate, others = migrate.** Prefetching a `ReadMostly` range to multiple GPUs *duplicates* it (each reads locally) instead of bouncing one copy around.
- **On legacy systems, "GPU is busy" is binary and total.** Touching *any* managed allocation from the CPU mid-kernel segfaults — even an allocation the kernel never names. Stream-attach narrows ownership from whole-GPU to per-stream.
- **CPU writes to GPU-resident memory are a trap.** Cache-hierarchy writes pull the line GPU→CPU first. Prefer CPU writes to CPU-resident memory + direct device reads.

## Anti-patterns
- **Accessing a `__host__` global directly in device code**: compile error; pass its *address* (valid only where `pageableMemoryAccess = 1`).
- **CPU touching managed data while a kernel runs on a legacy device**: segfault. Insert `cudaDeviceSynchronize()` (or use stream attach).
- **Atomics to file-backed memory on SW-coherent / HMM systems** (`hostNativeAtomicSupported = 0`): unsupported / UB.
- **`cudaMemcpy*` between two system-allocated pointers**: wasteful — launch a kernel or use `std::memcpy`. And prefer `cudaMemcpyDefault` over an *inaccurate* `cudaMemcpyKind` hint.
- **Frequent small CPU writes to GPU-resident unified memory**: cache misses thrash data CPU↔GPU. Pin to host with `SetPreferredLocation` + `SetAccessedBy`.
- **Reading a discarded range without an intervening write/prefetch**: indeterminate value; concurrent access during discard is UB.
- **Sprinkling hints reflexively**: every hint costs host time and can *degrade* performance if misapplied.

## Reference Tables

**Unified memory paradigms**

| Paradigm | Device can access | Sync model |
|---|---|---|
| Full (HW-coherent: Grace Hopper) | any host memory | cache-line coherent, fault-free |
| Full (SW-coherent: HMM) | any host memory | page-fault migration |
| Managed-only (CC 6.x+, no pageable) | only `cudaMallocManaged` | on-demand fault/migrate |
| Legacy (CC<6.0 / Windows, `concurrentManagedAccess=0`) | only managed, bulk-migrated at launch | whole-GPU exclusive; manual sync |

**`cudaMemAdvise` advices**

| Advice | Effect |
|---|---|
| `SetReadMostly` | read-duplicate; trade write BW for read BW |
| `SetPreferredLocation` | keep data at location.id (hint, overridable) |
| `SetAccessedBy` | pre-map for a processor; enables access-counter migration on HW-coherent |

**Key device attributes**: `cudaDevAttrConcurrentManagedAccess`, `cudaDevAttrDirectManagedMemAccessFromHost`, `cudaDevAttrHostNativeAtomicSupported`.

## Worked Example
Prefetch a managed range to the GPU, run, prefetch back — the canonical migration pattern that keeps data resident where it is used:

```cpp
void test_prefetch_managed(const cudaStream_t& s) {
  char *data;
  cudaMallocManaged(&data, dataSizeBytes);
  init_data(data, dataSizeBytes);                       // produced on CPU
  cudaMemLocation location = {.type = cudaMemLocationTypeDevice, .id = myGpuId};

  cudaMemPrefetchAsync(data, dataSizeBytes, location, 0, s);  // migrate → GPU
  const unsigned num_blocks = (dataSizeBytes + threadsPerBlock - 1) / threadsPerBlock;
  mykernel<<<num_blocks, threadsPerBlock, 0, s>>>(data, dataSizeBytes);

  location = {.type = cudaMemLocationTypeHost};
  cudaMemPrefetchAsync(data, dataSizeBytes, location, 0, s);  // migrate → CPU
  cudaStreamSynchronize(s);

  use_data(data, dataSizeBytes);                        // consumed on CPU
  cudaFree(data);
}
```
- **Demonstrates**: prefetch is stream-ordered (begins after prior stream ops, completes before later ones), data stays accessible during migration, and the produce-on-CPU → compute-on-GPU → consume-on-CPU round trip. On a full-support system, `malloc` would substitute for `cudaMallocManaged`.

## Key Takeaways
1. Four paradigms keyed to hardware: full support (any host memory), managed-only, and legacy (whole-GPU exclusive ownership) — query `concurrentManagedAccess`/`pageableMemoryAccess` before assuming.
2. HW-coherent (combined page table, cache-line granularity, fault-free) beats SW-coherent (page-fault migration) for concurrent CPU/GPU sharing and atomics.
3. Performance is paging: keep data local, prefetch with `cudaMemPrefetchAsync`, advise with `cudaMemAdvise` — but hints only ever affect performance and each costs host time.
4. `SetReadMostly` replicates; `SetPreferredLocation`/`SetAccessedBy` steer migration. Avoid frequent CPU writes to GPU-resident memory.
5. On legacy devices, any running kernel locks *all* managed data from the CPU; `cudaStreamAttachMemAsync` narrows ownership to per-stream for multithreaded host concurrency.
6. Unified memory enables oversubscription (arrays > one processor's RAM); `cudaMemDiscardBatchAsync` cuts redundant eviction traffic for dead ranges.

## Connects To
- **Ch 1**: the unified-memory and host/device memory model this chapter operationalizes.
- **Ch 8**: batched transfers (`cudaMemcpyBatchAsync`) share the `cudaMemLocation`/prefetch-hint vocabulary.
- **Ch 9**: multi-device managed memory and P2P — the cross-GPU sharing layer above this.
- **Ch 11**: graph memory nodes reuse stream-ordered allocation semantics.
- **§4.16 Virtual Memory Management**: the fine-grained allocator (`cuMemCreate`) referenced in the allocator table.
