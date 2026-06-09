# Chapter 9: Multi-GPU Programming & Feature Tour

## Core Idea
Two halves. First, **multi-GPU**: a CUDA program scales past one device by managing multiple contexts (one current device per host thread), distributing data, and moving it between GPUs either by bulk **peer-to-peer copies** or fine-grained **peer load/store** over NVLink/PCIe — all unified under a single virtual address space. Second, a **map of the feature landscape**: every later-chapter feature sorted by the problem it solves — kernel throughput, launch latency, new functionality, interop, or fine-grained control. Use it as an index, not a tutorial.

## Frameworks Introduced
- **Device enumeration/selection**: `cudaGetDeviceCount`, `cudaGetDeviceProperties` (→ `cudaDeviceProp.major/.minor`), `cudaSetDevice(d)`. The *current device* (default 0) determines where allocations, launches, streams, and events land.
- **Peer-to-peer transfers**: `cudaMemcpyPeer()`, `cudaMemcpyPeerAsync()`, `cudaMemcpy3DPeer[Async]()`; or plain `cudaMemcpy` with `cudaMemcpyDeviceToDevice`/`cudaMemcpyDefault`.
- **Peer-to-peer access** (fine-grained load/store): gate with `cudaDeviceCanAccessPeer()`, enable with `cudaDeviceEnablePeerAccess()`. UVA means one pointer addresses memory on either device.
- **IPC / VMM**: CUDA IPC for intra-node cross-process buffer sharing; Virtual Memory Management APIs for per-allocation, intra- and multi-node sharing (Linux + Windows).
- **Feature-tour categories**: kernel-perf (async barriers, async copies+TMA, pipelines, cluster launch control work-stealing); latency (green contexts, stream-ordered alloc, CUDA graphs, PDL, lazy loading); functionality (EGM, dynamic parallelism); interop (graphics APIs, IPC); fine-grained (VMM, driver entry-point access, error-log management).

## Key Concepts
- **One current device per host thread**; multi-GPU patterns: one thread→N GPUs, N threads→N GPUs, N processes→N GPUs, or multi-node NVLink clusters.
- **Cross-device synchronization is `thread_scope_system`** — both for sync ops and the memory consistency domain.
- **Green contexts**: a context restricted to a *subset of SMs*; other contexts (including the primary) won't schedule onto those SMs → reserve SMs for latency-sensitive work. Runtime support CUDA 13.1+.
- **Cluster launch control (CC 10.0 Blackwell)**: a block can cancel a not-yet-started block/cluster, claim its index, and execute the stolen work → software work-stealing for irregular loads.
- **Stream-ordered allocation**: `cudaMallocAsync`/`cudaFreeAsync` sequence alloc/free *into a stream* (vs immediate `cudaMalloc`/`cudaFree`).
- **Lazy loading**: modules JIT-compiled on first use (default), not at startup; tunable via env var.
- **Extended GPU Memory (EGM)**: NVLink-C2C systems let a GPU efficiently reach all system memory.
- **Dynamic parallelism**: launch kernels from device code.

## Mental Models
- **The current device is global mutable state on the host thread.** Every `cudaMalloc`, launch, stream, and event silently binds to whatever `cudaSetDevice` last set. Forget it and a launch hits the wrong device or a foreign stream.
- **P2P access ≠ P2P copy.** Copy = bulk DMA between two buffers. Access = a kernel dereferencing a peer pointer directly. Access must be explicitly enabled and is the one with the scaling-cost footgun.
- **`cudaDeviceEnablePeerAccess` is global and taxes every allocation.** It makes *all* current and future allocations on the peer reachable, adding per-alloc cost that scales with peer count. VMM lets you opt in per-allocation instead.
- **The feature tour is a routing table.** "I have launch overhead" → graphs / PDL / green contexts. "My kernel stalls on memory" → async copies / TMA / pipelines. "Loads are uneven" → cluster launch control.

## Anti-patterns
- **Launching a kernel into a stream not associated with the current device**: fails. (A *memcpy* into a foreign stream succeeds — asymmetric, easy to trip on.)
- **`cudaEventRecord` across mismatched event/stream devices, or `cudaEventElapsedTime` across two devices**: both fail.
- **Blanket `cudaDeviceEnablePeerAccess` on many peers**: multiplicative per-allocation overhead. Prefer VMM peer-accessible regions allocated as needed.
- **IOMMU enabled on Linux bare metal with P2P**: silent device-memory corruption. Disable IOMMU on bare metal; enable it + VFIO only for VM PCIe pass-through (Windows is exempt).
- **Ignoring PCI ACS**: ACS reroutes P2P traffic through the CPU root complex, gutting bisection bandwidth.
- **Exceeding eight peer connections per device** on non-NVSwitch systems: unsupported.

## Reference Tables

**Multi-device stream/event behavior**

| Operation | Cross-device rule |
|---|---|
| Kernel launch into stream | FAILS if stream not on current device |
| Memory copy into stream | succeeds even if stream is foreign |
| `cudaEventRecord(event, stream)` | FAILS if event/stream on different devices |
| `cudaEventElapsedTime(e1,e2)` | FAILS if events on different devices |
| `cudaEventSynchronize/Query` | succeeds for foreign-device event |
| `cudaStreamWaitEvent` | succeeds cross-device → use to sync devices |

**Feature → problem map (later-chapter pointers)**

| Goal | Feature | §  |
|---|---|---|
| Kernel throughput | async barriers / async copies+TMA / pipelines / cluster launch control | 4.9 / 4.11 / 4.10 / 4.12 |
| Launch latency | green contexts / stream-ordered alloc / graphs / PDL / lazy loading | 4.6 / 4.3 / 4.2 / 4.5 / 4.7 |
| Functionality | EGM / dynamic parallelism | 4.17 / 4.18 |
| Interop | graphics-API sharing / CUDA IPC | 4.19 / 4.15 |
| Fine control | VMM / driver entry-point access / error-log mgmt | 4.16 / 4.20 / 4.8 |

## Worked Example
Enabling fine-grained peer access so a kernel on device 1 dereferences device 0's pointer (UVA makes `p0` valid on both):

```cpp
cudaSetDevice(0);                   // device 0 current
float* p0;
size_t size = 1024 * sizeof(float);
cudaMalloc(&p0, size);              // allocate on device 0
MyKernel<<<1000, 128>>>(p0);        // run on device 0

cudaSetDevice(1);                   // device 1 current
cudaDeviceEnablePeerAccess(0, 0);   // device 1 may now access device 0's memory

// This launch runs on device 1 but reads device 0 memory at address p0
MyKernel<<<1000, 128>>>(p0);
```
- **Demonstrates**: the current-device switch, that the *consuming* device enables access to the *producer*, and the UVA property that the same pointer is dereferenceable across devices. Gate with `cudaDeviceCanAccessPeer()` first in production.

## Key Takeaways
1. The current device (`cudaSetDevice`) is per-host-thread state controlling all allocations, launches, streams, and events — multi-GPU is fundamentally context management.
2. Kernel launches reject foreign streams; many event/stream ops fail across devices — but `cudaStreamWaitEvent` works cross-device and is the tool for inter-GPU sync.
3. P2P *copy* (`cudaMemcpyPeer*`) is bulk DMA; P2P *access* (`cudaDeviceEnablePeerAccess`) is direct peer dereference and must be explicitly enabled — and it taxes every peer allocation, so VMM per-allocation is more scalable.
4. Cross-device coherency is `thread_scope_system`; mind IOMMU (disable on Linux bare metal) and PCI ACS (bandwidth killer).
5. The feature tour is an index: match the problem (throughput / latency / functionality / interop / control) to the feature and jump to its dedicated section.

## Connects To
- **Ch 1**: unified virtual addressing and the device/host memory model that P2P builds on.
- **Ch 8**: async barriers, TMA, PDL, stream-ordered allocation — the kernel-side mechanics the tour catalogs.
- **Ch 10**: multi-device managed (unified) memory — the higher-level alternative to explicit P2P copies.
- **Ch 11**: CUDA Graphs, the launch-latency feature most cross-referenced here.
- **`mpi-5.0` / NCCL / NVSHMEM**: higher-level multi-GPU collectives CUDA itself does not provide.
