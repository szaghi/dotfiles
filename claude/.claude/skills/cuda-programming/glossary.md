# CUDA Glossary

**Array (tile programming)** — mutable multidimensional container in device memory; has shape + dtype; partitioned into tiles via the *tile space* (Ch 4).
**Asynchronous barrier (`cuda::barrier`)** — split arrive/wait barrier with phases (arrival/countdown/completion/reset); supports transaction counts for async copies (Ch 15).
**Atomic** — read-modify-write that completes without interference at a given thread *scope*; `atomicAdd`, `atomicCAS`, `cuda::atomic_ref` (Ch 3, 24).
**Coalescing** — combining the global-memory accesses of a warp into the fewest 32-byte transactions; maximized when lane *i* hits consecutive addresses (Ch 3).
**Compute Capability (CC)** — `X.Y` feature/spec level of a GPU; maps to SM version `sm_XY` and PTX `compute_XY` (Ch 1, 20).
**Constant memory** — per-SM cached read-only global memory; `__constant__` (Ch 1, 3, 23).
**Cooperative Groups** — typed API for thread groups (block, tile, grid, cluster) with collective `sync`/`reduce`/scans (Ch 3, 13).
**cubin** — binary GPU code for a specific `sm_XY` (Ch 1).
**cuTile** — tile programming model: per-block code on immutable tiles, compiler maps to threads (Ch 1, 4).
**CUDA Graph** — DAG of operations defined once, instantiated, and launched repeatedly to cut launch overhead (Ch 11).
**Dynamic Parallelism (CDP)** — kernels launching child grids from the device; CDP2 is default on CC ≥ 9.0 (Ch 18).
**EGM (Extended GPU Memory)** — using host-NUMA system memory as GPU-addressable memory over NVLink/fabric (Ch 17).
**Event (`cudaEvent_t`)** — stream marker for timing (`cudaEventElapsedTime`) and cross-stream dependencies (Ch 5).
**Fatbin** — container holding multiple cubins + PTX for different targets (Ch 1, 7).
**FMA** — fused multiply-add `a*b+c` with single rounding; IEEE-754 compliant (Ch 24).
**Global memory** — GPU DRAM, visible to all SMs across the grid (Ch 1, 3).
**GPC (Graphics Processing Cluster)** — group of SMs; clusters co-schedule within one GPC (Ch 1).
**Green Context** — lightweight context owning a partition of SMs for concurrent low-latency workloads (Ch 14).
**Grid** — collection of equally-sized thread blocks launched by one kernel (Ch 1).
**HMM / ATS** — software (Heterogeneous Memory Management) vs hardware (Address Translation Services) coherence backends for unified memory (Ch 6, 10).
**IPC** — interprocess sharing of device memory via `cudaIpc*` handles or VMM OS handles (Ch 17).
**Kernel** — function executed on the GPU, launched as a grid; `__global__` (Ch 1, 2).
**Launch bounds (`__launch_bounds__`)** — compiler hint on max threads/block + min blocks/SM to control register use (Ch 23).
**Lazy Loading** — defer module/kernel load until first use; `CUDA_MODULE_LOADING=LAZY` (Ch 14, 21).
**LDGSTS** — async global→shared copy instruction underlying `memcpy_async` (Ch 15).
**Local memory** — per-thread global-memory spillover (register spills, large local arrays) (Ch 1, 3).
**Managed memory (`cudaMallocManaged`)** — unified allocation migrated between host/device by runtime/HW (Ch 2, 6, 10).
**Mapped (zero-copy) memory** — pinned host memory directly addressable from device over PCIe/NVLink (Ch 6).
**Memory pool** — backing store for `cudaMallocAsync`; reuses freed allocations stream-ordered (Ch 12).
**Memory synchronization domain** — partition of traffic so a fence in one domain doesn't order another's (Ch 16).
**Multicast object** — VMM object mapping one virtual address to memory on several GPUs; `multimem` ops (Ch 17).
**Occupancy** — ratio of active warps to max warps per SM; bounded by registers/shared mem/block limits (Ch 3).
**Page-locked (pinned) memory** — non-pageable host memory enabling async DMA; `cudaMallocHost`/`cudaHostAlloc` (Ch 6).
**Peer-to-peer (P2P)** — direct device-to-device access/copy when `cudaDeviceCanAccessPeer` (Ch 9).
**Pipeline (`cuda::pipeline`)** — multi-stage async copy orchestration (acquire/commit/wait/release) (Ch 15).
**Programmatic Dependent Launch (PDL)** — overlap of a primary and dependent kernel via `cudaTriggerProgrammaticLaunchCompletion` / `cudaGridDependencySynchronize` (Ch 8, 14).
**PTX** — Parallel Thread Execution virtual ISA; JIT-compiled to cubin; versioned `compute_XY` (Ch 1).
**Registers** — fastest per-thread storage; finite per SM, bounds occupancy (Ch 1, 3).
**Shared memory** — on-chip per-block scratchpad in 32 banks; `__shared__` (Ch 1, 3).
**SIMT** — Single-Instruction Multiple-Threads; a warp runs one instruction, lanes mask on divergence (Ch 1, 3).
**SM (Streaming Multiprocessor)** — core GPU compute unit: registers + unified data cache (L1/shared) + functional units (Ch 1).
**Stream** — ordered queue of GPU operations; independent streams may run concurrently (Ch 5).
**Stream capture** — recording stream operations into a CUDA graph (Ch 5, 11).
**Stream-ordered allocator** — `cudaMallocAsync`/`cudaFreeAsync` with stream-ordered lifetime (Ch 12).
**Thread block** — group of threads co-resident on one SM, sharing shared memory and `__syncthreads` (Ch 1).
**Thread block cluster** — CC ≥ 9.0 group of blocks co-scheduled on a GPC with distributed shared memory (Ch 1).
**Thread scope** — atomicity/visibility level: thread / block / device / system (Ch 3, 8, 24).
**Tile space** — conceptual partition of an array into equal non-overlapping tiles, indexed for load/store (Ch 4).
**TMA (Tensor Memory Accelerator)** — hardware engine for bulk async tensor copies; `cp_async_bulk*`, `cuTensorMapEncodeTiled` (Ch 15).
**Unified memory** — single allocation usable from host or device (Ch 1, 2, 6, 10).
**Unified virtual address space (UVA)** — single virtual address range across CPU + all GPUs (Ch 6).
**Virtual Memory Management (VMM)** — low-level `cuMemCreate`/`cuMemMap`/`cuMemSetAccess` reservation+mapping API (Ch 17).
**Warp** — 32 threads scheduled together in SIMT; lanes 0–31 (Ch 1, 3).
**Warp divergence** — threads in a warp taking different control-flow paths, serializing the branches (Ch 1, 3).
**Warp shuffle (`__shfl_sync`)** — register exchange between lanes of a warp without shared memory (Ch 24).
**Warp vote (`__ballot_sync`/`__any_sync`/`__all_sync`)** — warp-wide predicate reductions (Ch 24).
