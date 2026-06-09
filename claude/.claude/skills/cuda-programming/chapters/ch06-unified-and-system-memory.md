# Chapter 6: Unified & System Memory

## Core Idea
A heterogeneous system has many physical memories (CPU DRAM + one DRAM per GPU); performance is best when data lives in the memory of the processor touching it. CUDA layers two conveniences on top of explicit `cudaMemcpy` management: a **single unified virtual address space** (every allocation — CUDA or system — has a unique pointer range, so the runtime can infer location and copy direction), and **unified (managed) memory** that the driver *automatically migrates* between CPU and GPU on demand. What unified memory actually does is **paradigm-dependent** (OS, Linux kernel version, GPU, interconnect) — you must *query* the device to know which behavior you get. Separately, **page-locked (pinned) host memory** is the prerequisite for async transfers and for **mapped (zero-copy)** direct host access from kernels.

## Frameworks Introduced

- **Unified Virtual Address Space (UVA)**: one virtual address range covers all host and all device memory in a process. `cudaPointerGetAttributes()` resolves where a pointer lives; `cudaMemcpyDefault` infers direction from the pointers — no need to spell out HostToDevice etc.
- **Unified / managed memory**: allocations accessible from CPU *or* GPU, auto-migrated. Allocate via `cudaMallocManaged`, `cudaMallocFromPoolAsync` (pool with `cudaMemAllocationTypeManaged`), or `__managed__` global variables. On HMM/ATS systems, *all* system memory is implicitly managed.
- **Memory hints**: `cudaMemAdvise` (placement/migration policy) and `cudaMemPrefetchAsync` (proactively migrate an allocation, e.g. before a kernel needs it, overlapping the move with other GPU work).
- **Page-locked (pinned) host memory**: `cudaMallocHost` / `cudaHostAlloc` allocate it; `cudaHostRegister` pins existing (e.g. `malloc`/`mmap`/3rd-party) memory. Required for async H↔D copies, speeds sync copies, enables mapping.
- **Mapped memory** (formerly *zero-copy*): host memory accessed directly from a kernel over the interconnect. Always page-locked. A correctness tool, **not** a bandwidth strategy.

## Key Concepts
- **Four paradigms**, selected by three device attributes:
  - `cudaDevAttrConcurrentManagedAccess` — 1 = full support, 0 = limited.
  - `cudaDevAttrPageableMemoryAccess` — 1 = *all* system memory is unified; 0 = only CUDA-allocated managed memory is unified.
  - `cudaDevAttrPageableMemoryAccessUsesHostPageTables` — 1 = hardware coherence (ATS), 0 = software coherence (HMM).
- **HMM** (Heterogeneous Memory Management): Linux-kernel feature (≥ 6.1.24 / 6.2.11 / 6.3) giving *software*-coherent full unified memory to PCIe GPUs. Check with `nvidia-smi -q | grep Addressing` → `Addressing Mode : HMM`.
- **ATS** (Address Translation Services): *hardware* coherence on NVLink C2C systems (Grace Hopper, Grace Blackwell). With ATS, `cudaMallocManaged` data resident on GPU is CPU-accessible without migration (`cudaDevAttrDirectManagedMemAccessFromHost`=1), native atomics work (`cudaDevAttrHostNativeAtomicSupported`=1). ATS supersedes and disables HMM.
- **Migration granularity**: pages (software coherence) or cache lines (hardware coherence). First-touch placement; migrate on access from another processor; **oversubscription** of GPU memory is allowed under full support.
- **Limited support** (Windows, WSL, some Tegra): managed memory starts in CPU memory, migrates in coarse granularity to the GPU when it runs, **CPU must not touch it while the GPU is active**, migrates back on sync, **no oversubscription**, only explicit managed allocations are unified.
- **Mapped-memory caveats**: atomics on mapped host memory are *not* atomic w.r.t. the host or other GPUs; naturally-aligned 1/2/4/8/16-byte loads/stores are preserved as single accesses.

## Mental Models
- Think of UVA as **"the pointer carries its own address book"** — the runtime reads location off the pointer value, so `cudaMemcpyDefault` just works.
- Think of unified memory as **demand paging across the PCIe/NVLink boundary**: cheap to program, but the *first* access pays a migration. Prefetch + advise are how you hide that.
- Think of mapped memory as **"reaching across the bus on every access"** — fine for a few cold values, ruinous as a kernel's main working set.
- Think **query, don't assume**: the same source runs on a Grace-Hopper (hardware-coherent) box and a Windows laptop (limited) with completely different migration semantics. Branch on the three attributes.

## Anti-patterns
- **Assuming unified memory behaves identically everywhere**: Windows/WSL/Tegra are *limited* — CPU access during GPU execution is illegal, no oversubscription.
- **Using mapped memory for a kernel's bulk working set**: every access crosses PCIe/NVLink (high latency, low bandwidth); will not saturate GPU compute.
- **Relying on atomics on mapped host memory for cross-device consistency**: not atomic from host/other-GPU view.
- **Page-faulting on first access in a hot loop instead of prefetching**: use `cudaMemPrefetchAsync` to migrate ahead of the kernel.
- **Using the host pointer in a kernel after `cudaHostRegister`**: you must fetch and use the *device* pointer from `cudaHostGetDevicePointer()` (unlike `cudaMallocHost`/`cudaHostAlloc`, whose host pointer is directly usable).

## Reference Tables

**Unified-memory paradigm decision table**

| Paradigm | `ConcurrentManagedAccess` | `PageableMemoryAccess` | `...UsesHostPageTables` |
|---|---|---|---|
| Limited (Windows/WSL/Tegra) | 0 | — | — |
| Full, explicit managed only | 1 | 0 | — |
| Full, all allocations, software coherence (HMM) | 1 | 1 | 0 |
| Full, all allocations, hardware coherence (ATS) | 1 | 1 | 1 |

**Pinned / mapped memory API**

| Function | Role |
|---|---|
| `cudaMallocHost` | allocate page-locked host memory (auto-mapped) |
| `cudaHostAlloc(..., flags)` | like above + flags (e.g. `cudaHostAllocMapped`) |
| `cudaFreeHost` | free `cudaMallocHost`/`cudaHostAlloc` memory |
| `cudaHostRegister(ptr, sz, 0)` | page-lock existing (malloc/mmap) memory |
| `cudaHostGetDevicePointer(&dev, host, 0)` | get device pointer for registered memory |
| `cudaMallocManaged` | allocate managed (unified) memory |
| `cudaMemAdvise` | placement/migration hint |
| `cudaMemPrefetchAsync` | proactively migrate an allocation |

## Worked Example
Mapping registered host memory into a kernel via `cudaHostRegister` + `cudaHostGetDevicePointer` — the path when ATS/HMM are absent and the buffer came from a plain `malloc`:

```cpp
__global__ void copyKernel(float* a, float* b) {
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    a[idx] = b[idx];
}

void usingRegister() {
  float* a = nullptr;
  float* b = nullptr;
  float* devA = nullptr;
  float* devB = nullptr;

  a = (float*)malloc(vLen*sizeof(float));
  b = (float*)malloc(vLen*sizeof(float));
  CUDA_CHECK(cudaHostRegister(a, vLen*sizeof(float), 0 ));
  CUDA_CHECK(cudaHostRegister(b, vLen*sizeof(float), 0 ));

  CUDA_CHECK(cudaHostGetDevicePointer((void**)&devA, (void*)a, 0));
  CUDA_CHECK(cudaHostGetDevicePointer((void**)&devB, (void*)b, 0));

  initVector(b, vLen);
  memset(a, 0, vLen*sizeof(float));

  int threads = 256;
  int blocks = vLen/threads;
  copyKernel<<<blocks, threads>>>(devA, devB);   // device pointers, NOT a/b
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());
}
```
- **What it demonstrates**: the load-bearing distinction — registered memory must be touched in the kernel through the **device** pointer (`devA`/`devB`), whereas `cudaMallocHost`/`cudaHostAlloc(cudaHostAllocMapped)` buffers can be passed by their host pointer directly. Either way the kernel reaches host DRAM over the interconnect.

## Key Takeaways
1. One unified virtual address space → `cudaPointerGetAttributes` locates pointers and `cudaMemcpyDefault` infers direction.
2. Unified memory removes manual copies but migrates on demand; *which* semantics you get is paradigm-dependent — query the three `cudaDevAttr*` attributes.
3. ATS (hardware, NVLink C2C) > HMM (software, Linux kernel) > limited (Windows/WSL/Tegra). ATS disables HMM.
4. Under limited support: no oversubscription, no CPU access during GPU execution. Under full support: oversubscription allowed, first-touch + on-access migration.
5. Use `cudaMemAdvise` + `cudaMemPrefetchAsync` to hide migration latency.
6. Page-locked host memory (`cudaMallocHost`/`cudaHostAlloc`/`cudaHostRegister`) is required for async copies and for mapping.
7. Mapped memory is a correctness convenience, not a performance path — bulk kernel accesses belong in device or migrated unified memory.

## Connects To
- **Ch 1**: the memory-space hierarchy (registers > shared > global > host) and the "keep migration minimal" guidance — quantified here.
- **Ch 5**: pinned memory is the prerequisite `cudaMemcpyAsync` needs to actually overlap; `cudaMemPrefetchAsync` overlaps migration with stream work.
- **Atomic Functions (Ch 3)**: why mapped-memory atomics are not cross-device atomic.
- **Compute Capabilities (§5.1)**: which devices expose ATS/HMM and the `cudaDevAttr*` values.
- **OpenACC/OpenMP managed memory**: directive models lean on the same unified-memory driver (`-gpu=managed`, `requires unified_shared_memory`) — see `openacc-3.4`, `openmp-6.0`.
