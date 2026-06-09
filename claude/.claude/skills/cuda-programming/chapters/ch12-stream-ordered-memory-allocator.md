# Chapter 12: Stream-Ordered Memory Allocator

## Core Idea
`cudaMalloc`/`cudaFree` synchronize the *whole* GPU across all streams — a hidden global barrier on every alloc/free. The **stream-ordered memory allocator** (`cudaMallocAsync`/`cudaFreeAsync`) ties allocation and deallocation to a stream's execution timeline like any other queued operation, so they never block the host or other streams. On top of that it adds **memory pools** that cache physical pages (avoiding OS round-trips) and reuse freed blocks within stream-order semantics, plus secure cross-process sharing via IPC pools.

## Frameworks Introduced

- **Stream-ordered alloc/free**: `cudaMallocAsync(&ptr, size, stream)` returns an allocation that becomes valid *at that point in the stream*; `cudaFreeAsync(ptr, stream)` releases it *at that point in the stream*. Both are queued, not synchronous.
  - When to use: any code with frequent alloc/free, or that currently calls `cudaMalloc` in hot loops.
- **Memory pools** (`cudaMemPool_t`): encapsulate virtual-address + physical-memory resources with attributes (release threshold, IPC handle type, reuse policies). Every `cudaMallocAsync` draws from a pool — the stream's device current pool by default.
  - How: `cudaDeviceSetMempool`/`cudaDeviceGetMempool` set/query the current pool; `cudaMallocFromPoolAsync` allocates from an explicit pool without making it current.
- **Default/implicit pools** vs **explicit pools** (`cudaMemPoolCreate`): default pools are non-migratable, device-local, always accessible from their device, and do *not* support IPC. Explicit pools add IPC, max-size, CPU-NUMA residency.
- **IPC pools**: share GPU memory across processes securely — share pool access first (export/import shareable handle), then share specific allocations (export/import pointer + IPC event).

## Key Concepts
- **Allocation device is determined by pool/stream, not the current context** — `cudaMallocAsync` ignores the current device/context.
- **Cross-stream access rule**: accessing an allocation from a stream other than the allocating stream requires the access to be ordered *after* the allocation (use events / `cudaStreamWaitEvent`); otherwise UB.
- **Free-ordering rule**: the free must be ordered after the allocation *and all uses*; any use after the free starts is UB.
- **Interop**: `cudaMalloc` memory can be freed by `cudaFreeAsync`; `cudaMallocAsync` memory can be freed by `cudaFree` (driver assumes all access complete — you must synchronize first).
- **Release threshold** (`cudaMemPoolAttrReleaseThreshold`): bytes the pool holds before returning memory to the OS on the next sync. `UINT64_MAX` = never shrink after sync.
- **Reuse policies**: control how freed blocks are recycled before hitting the OS.

## Mental Models
- Think of `cudaMallocAsync` as **"malloc as a stream node"** — it has a position in the stream timeline exactly like a kernel launch, and inherits the same ordering obligations.
- Think of a **pool as a private heap with a high-water cache**: set the release threshold high and the pool stops calling the OS, trading footprint for latency.
- Think of **IPC sharing as two-level security**: the OS enforces access at the *pool* level once; individual allocation pointers can then travel by any mechanism (no per-allocation kernel bookkeeping).

## Anti-patterns
- **Calling `cudaMalloc`/`cudaFree` in a hot loop**: each is a full-GPU sync. Replace with async + a pool.
- **Accessing an async allocation from another stream without ordering it after the alloc**: UB. Use an event.
- **`cudaFree`-ing an async allocation without synchronizing first**: the driver does *no* sync on `cudaFree`; the GPU may still touch the memory.
- **`cudaPointerGetAttributes` after `cudaFreeAsync`**: UB even if the pointer still looks accessible from some stream.
- **`cudaGraphAddMemsetNode` on stream-ordered allocations**: does not work (memsets can be stream-captured instead).
- **Setting VRAM limits with `ulimit -v`** with the SOMA APIs: unsupported.
- **Changing pool accessibility for a GPU frequently**: once a pool is accessible from a GPU, keep it accessible for the pool's lifetime.

## Reference Tables

**Core API**

| API | Action |
|---|---|
| `cudaMallocAsync(&p, sz, stream)` | stream-ordered allocation from stream's current pool |
| `cudaMallocFromPoolAsync` / `cudaMallocAsync` (C++ overload) | allocate from an explicit pool |
| `cudaFreeAsync(p, stream)` | stream-ordered free |
| `cudaMemPoolCreate(&pool, &props)` | create explicit pool |
| `cudaDeviceGetDefaultMempool` / `cudaDeviceGetMempool` / `cudaDeviceSetMempool` | implicit/current pool handles |
| `cudaMemPoolSetAccess` / `cudaMemPoolGetAccess` | multi-GPU accessibility |
| `cudaMemPoolSetAttribute` / `cudaMemPoolGetAttribute` | tune/query attributes |
| `cudaMemPoolTrimTo(pool, minBytesToKeep)` | explicitly shrink footprint |

**Pool attributes**

| Attribute | Meaning |
|---|---|
| `cudaMemPoolAttrReleaseThreshold` | bytes held before releasing to OS on sync (`UINT64_MAX` = never) |
| `cudaMemPoolAttrReservedMemCurrent` / `...High` | physical mem reserved (current / watermark) |
| `cudaMemPoolAttrUsedMemCurrent` / `...High` | mem allocated & not reusable (current / watermark) |
| `cudaMemPoolReuseFollowEventDependencies` | reuse cross-stream memory via event deps |
| `cudaMemPoolReuseAllowOpportunistic` | reuse freed blocks once stream-order point passed |
| `cudaMemPoolReuseAllowInternalDependencies` | insert a dependency to reuse not-yet-free memory |

**Support queries** (`cudaDeviceGetAttribute`)

| Device attribute | Tells you |
|---|---|
| `cudaDevAttrMemoryPoolsSupported` | SOMA supported (driver ≥ 11020) |
| `cudaDevAttrMemoryPoolSupportedHandleTypes` | which IPC handle types (driver ≥ 11030) |

## Worked Example
The fundamental pattern — and the cross-stream synchronization it demands when an allocation is touched outside its allocating stream:

```cpp
// Basic: alloc, use, free all on the same stream — no host/GPU sync.
void *ptr;
size_t size = 512;
cudaMallocAsync(&ptr, size, cudaStreamPerThread);
kernel<<<..., cudaStreamPerThread>>>(ptr, ...);
cudaFreeAsync(ptr, cudaStreamPerThread);

// Cross-stream: the free must be ordered after the allocation AND every use.
cudaMallocAsync(&ptr, size, stream1);
cudaEventRecord(event1, stream1);
cudaStreamWaitEvent(stream2, event1);          // stream2 waits for the alloc
kernel<<<..., stream2>>>(ptr, ...);
cudaEventRecord(event2, stream2);
cudaStreamWaitEvent(stream3, event2);          // stream3 waits for the use
cudaFreeAsync(ptr, stream3);
```
- **What it demonstrates**: the free is just another stream operation; correctness comes entirely from ordering it after the allocation and all accesses, which across streams means explicit events.

## Key Takeaways
1. `cudaMallocAsync`/`cudaFreeAsync` are *queued* operations — no global sync, unlike `cudaMalloc`/`cudaFree`.
2. The allocating device comes from the pool/stream, not the current context.
3. Cross-stream access and the free both require explicit ordering after the allocation (and uses) — events, not luck.
4. Pools cache pages: set `cudaMemPoolAttrReleaseThreshold` high to stop OS round-trips; `cudaMemPoolTrimTo` to reclaim on demand.
5. Default pools are device-local and non-IPC; explicit pools add IPC, NUMA residency, max size.
6. IPC is two-step (share pool, then share allocations) and secured at the pool level.
7. Query support with `cudaDevAttrMemoryPoolsSupported` after a driver-version check to avoid `cudaErrorInvalidValue`.

## Connects To
- **Ch 11 (Virtual Memory Management)**: pool accessibility mirrors VMM accessibility — neither follows `cudaDeviceEnablePeerAccess`; both use explicit set-access + `cudaDeviceCanAccessPeer`.
- **CUDA Graphs**: SOMA integrates with capture; but `cudaGraphAddMemsetNode` is incompatible (capture memsets instead).
- **Ch 14 (Lazy Loading)**: lazy loading recommends `cudaMallocAsync` over allocators that grab all VRAM at startup.
- **Multi-GPU / IPC events**: free-before-export ordering in IPC pools reuses the same event machinery as `cudaIpcEventHandle_t`.
