# Chapter 17: IPC, Virtual Memory Management & Extended GPU Memory

## Core Idea
Three layers of cross-process / cross-device memory sharing. **IPC** turns a device pointer or event into a *process-portable handle* you ship over OS IPC, then re-open as a local pointer in another process. **Virtual Memory Management (VMM)** is the low-level Driver API that decouples *virtual address reservation* from *physical allocation* and *mapping*, giving per-allocation control over peer access (vs the blunt `cudaEnablePeerAccess` that maps *everything*). **Extended GPU Memory (EGM)** lets GPU threads reach all system memory (CPU-attached + HBM) at NVLink/NVLink-C2C speed by allocating against NUMA host nodes.

## Frameworks Introduced

- **Legacy IPC API** (Linux-only): `cudaIpcGetMemHandle()` → ship handle via OS IPC → `cudaIpcOpenMemHandle()` in the peer process. Same pattern for events.
  - When to use: simplest single-node sharing of an existing `cudaMalloc` pointer.
- **VMM Driver API**: `cuMemCreate` (physical) + `cuMemAddressReserve` (virtual) + `cuMemMap` (bind) + `cuMemSetAccess` (rights). Separates address from memory.
  - When to use: large/growable allocations, fine-grained peer sharing, custom allocators (NCCL, NVSHMEM use it), multi-node fabric.
- **Multicast objects**: `cuMulticastCreate` + `cuMulticastAddDevice` + `cuMulticastBindMem`, then `multimem` PTX — one-to-many sharing leveraging NVLink SHARP in-fabric reductions/broadcasts.
- **EGM**: allocate against `CU_MEM_LOCATION_TYPE_HOST_NUMA` (VMM) or `cudaMemLocationTypeHostNuma` (mem pools) with a `numaId` so GPU access routes over NVLink-C2C.

## Key Concepts
- **Process-portable vs fabric handles**: OS-specific handles (`CU_MEM_HANDLE_TYPE_POSIX_FILE_DESCRIPTOR` / `CU_MEM_HANDLE_TYPE_WIN32`) = single-node only. Fabric handles (`CU_MEM_HANDLE_TYPE_FABRIC`, CUDA 12.4+) = single *and* multi-node NVLink, but require **IMEX channels** enabled by sysadmin.
- **IMEX channels**: internode memory exchange; a security/isolation mechanism (`/dev/nvidia-caps-imex-channels/channelN`) gating who can import a fabric handle.
- **Memory ≠ address in VMM**: reservation, allocation, and mapping are three separate calls. Mapping alone does *not* grant access — `cuMemSetAccess` is mandatory or the kernel crashes.
- **Granularity**: `cuMemCreate` sizes must be rounded up to `cuMemGetAllocationGranularity` (`CU_MEM_ALLOC_GRANULARITY_MINIMUM`).
- **Virtual aliasing**: multiple `cuMemMap` of the same physical memory; writes through one proxy are incoherent with another *until the writing device op completes* — order with streams/events, or use `fence.proxy.alias` (`cuda::ptx::fence_proxy_alias()`) within a kernel.
- **EGM uses NUMA IDs**: `CU_DEVICE_ATTRIBUTE_HOST_NUMA_ID` gives the closest host node; this is *not* the device ordinal. EGM pages are 2MB.

## Mental Models
- VMM = **`mmap`/`munmap` for the GPU**: `cuMemAddressReserve`≈reserve VA, `cuMemCreate`≈the physical pages, `cuMemMap`≈commit, `cuMemSetAccess`≈`mprotect`. Like `realloc`/`std::vector` growth without copying.
- `cudaEnablePeerAccess` = **opening every door in the building to a guest**; VMM access control = **handing out keys to specific rooms only** — minimal mapping overhead.
- Multicast object = **a conference bridge**: N GPUs each back one replica; one `multimem` op fans out to all replicas (NVLink SHARP does the reduction in the switch).
- EGM = **the whole machine's RAM is your global memory**, with remote bytes paid for at NVLink speed, routed (never PCIe) when mapped as EGM.

## Anti-patterns
- **IPC-sharing sub-2MiB `cudaMalloc` allocations**: they may be sub-allocated from a larger block, so the *whole* block is shared → cross-process information disclosure. Share only 2MiB-aligned sizes.
- **`cudaIpcOpenMemHandle` on `cudaMallocManaged` memory**: unsupported. IPC memory-sharing is also unsupported on Tegra.
- **Accessing a `cuMemMap`'d region without `cuMemSetAccess`**: guaranteed crash.
- **Releasing VMM out of order**: must be `cuMemUnmap` → `cuMemRelease` → `cuMemAddressFree`. Unmap the *entire* range before `cuMemAddressFree`.
- **Reading a virtual alias written in the same kernel without `fence.proxy.alias`**: undefined — `*B` may see old, new, or intermediate bytes.
- **Limiting devices with cgroups for EGM**: blocks NVLink routing → performance collapse. Use `CUDA_VISIBLE_DEVICES`.

## Reference Tables

**VMM unicast workflow (in order)**

| Step | API |
|---|---|
| Allocate physical | `cuMemCreate` (+ `cuMemGetAllocationGranularity`) |
| Export handle | `cuMemExportToShareableHandle` |
| Import handle | `cuMemImportFromShareableHandle` |
| Reserve VA | `cuMemAddressReserve` |
| Map | `cuMemMap` |
| Grant access | `cuMemSetAccess` (`CU_MEM_ACCESS_FLAGS_PROT_READWRITE`) |
| Release | `cuMemUnmap` → `cuMemRelease` → `cuMemAddressFree` |

**Support queries (`cuDeviceGetAttribute`)**

| Attribute | Checks |
|---|---|
| `CU_DEVICE_ATTRIBUTE_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED` | VMM |
| `CU_DEVICE_ATTRIBUTE_HANDLE_TYPE_FABRIC_SUPPORTED` | fabric memory |
| `CU_DEVICE_ATTRIBUTE_MULTICAST_SUPPORTED` | multicast objects |
| `CU_DEVICE_ATTRIBUTE_GENERIC_COMPRESSION_SUPPORTED` | compressible memory |
| `CU_DEVICE_ATTRIBUTE_HOST_NUMA_ID` | EGM closest NUMA node |

**Advanced VMM flags**: `CUmemAllocationProp::allocFlags::compressionType = CU_MEM_ALLOCATION_COMP_GENERIC` (compressible — verify via `cuMemGetAllocationPropertiesFromHandle`); `requestedHandleTypes` selects POSIX FD / WIN32 / FABRIC.

## Worked Example
EGM single-node multi-GPU: allocate host-NUMA physical memory via VMM, reserve+map, then grant both the host node and the GPU read/write — the canonical "extend a GPU into CPU memory at NVLink speed" pattern:

```cpp
CUmemAllocationProp prop{};
prop.type          = CU_MEM_ALLOCATION_TYPE_PINNED;
prop.location.type = CU_MEM_LOCATION_TYPE_HOST_NUMA;   // EGM: host NUMA node
prop.location.id   = numaId;                            // from CU_DEVICE_ATTRIBUTE_HOST_NUMA_ID
size_t granularity = 0;
cuMemGetAllocationGranularity(&granularity, &prop, MEM_ALLOC_GRANULARITY_MINIMUM);
size_t padded_size = ROUND_UP(size, granularity);
CUmemGenericAllocationHandle allocHandle;
cuMemCreate(&allocHandle, padded_size, &prop, 0);

CUdeviceptr dptr;
cuMemAddressReserve(&dptr, padded_size, 0, 0, 0);
cuMemMap(dptr, padded_size, 0, allocHandle, 0);

CUmemAccessDesc accessDesc[2]{{}};
accessDesc[0].location.type = CU_MEM_LOCATION_TYPE_HOST_NUMA;
accessDesc[0].location.id   = numaId;
accessDesc[0].flags         = CU_MEM_ACCESS_FLAGS_PROT_READWRITE;
accessDesc[1].location.type = CU_MEM_LOCATION_TYPE_DEVICE;
accessDesc[1].location.id   = currentDev;
accessDesc[1].flags         = CU_MEM_ACCESS_FLAGS_PROT_READWRITE;
cuMemSetAccess(dptr, size, accessDesc, 2);              // mapping alone is NOT enough
```
- **What it demonstrates**: granularity rounding, the reserve→map→set-access sequence, and that access must be granted explicitly to *each* location (host NUMA node and GPU).

## Key Takeaways
1. Legacy IPC (`cudaIpcGetMemHandle`/`OpenMemHandle`) is the quick single-node path — Linux-only, no managed memory, share 2MiB-aligned to avoid disclosure.
2. VMM separates virtual address (`cuMemAddressReserve`) from physical (`cuMemCreate`) from binding (`cuMemMap`) from rights (`cuMemSetAccess`) — fine-grained peer control, no global peer-mapping cost.
3. Release order is strict: unmap → release → address-free.
4. Fabric handles (`CU_MEM_HANDLE_TYPE_FABRIC`) unlock multi-node NVLink sharing but need IMEX channels; OS handles stay single-node.
5. Multicast objects + `multimem` PTX exploit NVLink SHARP for in-fabric collectives — library-builder territory (NCCL/NVSHMEM); apps should use those libraries.
6. EGM allocates against host NUMA nodes (`numaId`, not device ordinal) so GPU access to system memory routes over NVLink-C2C; 2MB pages.
7. Virtual aliasing requires explicit ordering or `fence.proxy.alias`; incoherent across proxies mid-operation otherwise.

## Connects To
- **Ch 16**: memory sync domains and async-proxy fences — `fence.proxy.alias` shares the proxy-ordering machinery.
- **Streams & events chapters**: virtual-aliasing legality and IPC event sharing depend on stream/event ordering.
- **MPI / NCCL / NVSHMEM**: the higher-level libraries built on these primitives — prefer them over raw multicast/VMM for app code (`mpi-5.0`).
- **Ch 18 (Dynamic Parallelism)** and graphics interop: other consumers of the Driver API resource model.
