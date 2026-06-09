---
name: cuda-programming
description: "Knowledge base from the \"CUDA Programming Guide\" (NVIDIA, Release 13.3). Use when writing/reading/debugging CUDA C++ or CUDA Python, applying CUDA frameworks for kernels, SIMT/tile programming, streams & graphs, unified memory, cooperative groups, async copies/TMA, multi-GPU, or referencing CUDA APIs, specifiers, intrinsics, and compute-capability specs."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, API/intrinsic name, or chapter number]
---

# CUDA Programming Guide
**Author**: NVIDIA Corporation | **Release**: 13.3 | **Pages**: ~698 | **Chapters**: 24 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core CUDA frameworks below for reference.
- **With a topic** — ask about `coalescing`, `streams`, `cuda graphs`, `unified memory`, `cooperative groups`, `TMA`, `atomics`, `nvcc`, etc.; I find and read the relevant chapter.
- **With a chapter** — ask for `ch11`; I load that chapter file.
- **With an API/intrinsic** — ask about `cudaMallocAsync`, `__shfl_sync`, `__launch_bounds__`, `cudaMemPrefetchAsync`; the Topic Index points to the chapter.
- **Browse** — ask "what chapters do you have?" for the full index.

When you ask about something beyond the Core Frameworks below, I read the relevant chapter file before answering.

> Scope note: this skill is the CUDA *programming guide* (concepts, model, host/device APIs, language extensions, appendices). For the **PTX ISA**, the **CUDA Runtime/Driver API function reference**, or library specifics (cuBLAS/cuFFT/cuDNN/CUTLASS), consult NVIDIA's dedicated docs. For OpenACC/OpenMP-offload on the same hardware, see the `openacc-3.4` / `openmp-6.0` skills.

---

## Core Frameworks & Mental Models

**The heterogeneous model.** Execution starts on the *host* (CPU); host code copies data to *device* (GPU) memory, *launches* kernels, and synchronizes. CPU and GPU run concurrently — overlap to win. A *kernel* is launched as a **grid → blocks → threads** hierarchy.

**SIMT execution.** Threads run in 32-wide **warps**; all lanes execute one instruction, divergent branches mask lanes (warp divergence serializes them). Make block size a multiple of 32. Memory **coalescing** (warp lanes hit consecutive addresses) is the #1 global-memory lever: 100% vs 12.5% bus utilization.

**Memory hierarchy** (fast→slow): registers (per-thread) → shared memory (per-block, on-chip, 32 banks) → L2 → global (device DRAM) → host. Locality dominates. `__shared__` tiling turns repeated global reads into one; pad shared arrays `[N+1]` to avoid bank conflicts.

**Two programming models:**
- **SIMT** (`__global__`, per-thread code, `<<<grid, block>>>`) — fine-grained control.
- **Tile / cuTile** (per-block code on immutable *tiles*, compiler maps to threads) — higher-level, architecture-portable. Choose per kernel.

**Asynchrony is the performance model.** Operations in one **stream** run in order; different streams overlap. Use **events** for timing (`cudaEventElapsedTime`) and dependencies. Reduce launch overhead with **CUDA Graphs** (capture once, launch many). Overlap copy/compute with **pinned memory** + async copies.

**Memory management spectrum:** explicit (`cudaMalloc`/`cudaMemcpy`) for control → **unified memory** (`cudaMallocManaged` + `cudaMemPrefetchAsync`/`cudaMemAdvise`) for simplicity → **stream-ordered** (`cudaMallocAsync`) for pipelined alloc/free.

**Synchronization & scope.** `__syncthreads()` (block), `__syncwarp()` (warp), Cooperative Groups (`group.sync()`, `cg::reduce`), `cuda::barrier`/`cuda::pipeline` (async copies). **Atomic scope** must match sharing: block / device / system — wrong-narrow = silent stale reads.

**Compatibility.** CC `X.Y` ↔ `sm_XY` (cubin) ↔ `compute_XY` (PTX). cubins run on same major / minor ≥ target; PTX JIT-runs forward to any higher CC. Ship cubins for your targets **plus** PTX for forward compatibility.

**Correctness/perf rules worth memorizing:**
- Guard `if (i < n)` when the grid is rounded up.
- Kernels are async → check `cudaGetLastError()` (launch) *and* a sync's return (execution); errors are sticky.
- Time GPU work with events + sync, never host wall-clock around an async launch (>100× "speedups" = a missing sync).
- FMA is default and IEEE-compliant (single rounding); `--use_fast_math` trades ULP accuracy for speed.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-introduction-and-platform.md) | Introduction & Platform | host/device, grid/block/thread, SIMT, CC/PTX/cubin/fatbin |
| [ch02](chapters/ch02-cuda-cpp-python-basics.md) | CUDA C++ & Python Basics | kernels, `<<<>>>`, cudaMalloc/Memcpy, error checking, specifiers |
| [ch03](chapters/ch03-writing-simt-kernels.md) | Writing SIMT Kernels | memory spaces, coalescing, bank conflicts, atomics, occupancy |
| [ch04](chapters/ch04-writing-tile-kernels.md) | Writing Tile Kernels (cuTile) | tiles, tile-space load/store, primitives, GEMM, hints |
| [ch05](chapters/ch05-asynchronous-execution.md) | Asynchronous Execution | streams, events, callbacks, default-stream behavior |
| [ch06](chapters/ch06-unified-and-system-memory.md) | Unified & System Memory | UVA, managed memory, pinned/mapped memory |
| [ch07](chapters/ch07-nvcc-compiler.md) | NVCC — The CUDA Compiler | workflow, `-arch`/`-gencode`, LTO, separate compilation |
| [ch08](chapters/ch08-advanced-apis-and-driver.md) | Advanced APIs & Driver API | cudaLaunchKernelEx, PTX, hardware model, scoped atomics, driver API |
| [ch09](chapters/ch09-multi-gpu-and-feature-tour.md) | Multi-GPU & Feature Tour | device mgmt, P2P, feature routing map |
| [ch10](chapters/ch10-unified-memory-in-depth.md) | Unified Memory In Depth | UM paradigms, prefetch, advise, oversubscription |
| [ch11](chapters/ch11-cuda-graphs.md) | CUDA Graphs | nodes/edges, capture, update, conditional nodes, memory nodes |
| [ch12](chapters/ch12-stream-ordered-memory-allocator.md) | Stream-Ordered Allocator | cudaMallocAsync, memory pools, IPC pools |
| [ch13](chapters/ch13-cooperative-groups.md) | Cooperative Groups | group handles, partitions, collectives, grid-wide sync |
| [ch14](chapters/ch14-launch-control-green-contexts-lazy-loading.md) | Dependent Launch, Green Contexts & Lazy Loading | PDL, SM partitioning, lazy module load |
| [ch15](chapters/ch15-async-barriers-pipelines-data-copies.md) | Async Barriers, Pipelines & Data Copies (TMA) | cuda::barrier/pipeline, LDGSTS, TMA, STAS |
| [ch16](chapters/ch16-l2-cache-and-memory-domains.md) | Cluster Launch Control, L2 Cache & Sync Domains | work stealing, persistent L2, mem-sync domains |
| [ch17](chapters/ch17-ipc-vmm-egm.md) | IPC, Virtual Memory Mgmt & EGM | IPC handles, cuMemCreate/Map, multicast, extended GPU memory |
| [ch18](chapters/ch18-dynamic-parallelism.md) | Dynamic Parallelism | CDP2, child grids, tail/fire-and-forget launch |
| [ch19](chapters/ch19-interop-and-driver-entry-point.md) | API Interop & Driver Entry Point | OpenGL/D3D/Vulkan/NVSCI interop, cuGetProcAddress |
| [ch20](chapters/ch20-compute-capabilities.md) | Compute Capabilities & Specs | CC query, feature sets, per-CC spec tables |
| [ch21](chapters/ch21-environment-variables.md) | Environment Variables | CUDA_VISIBLE_DEVICES, JIT cache, module loading vars |
| [ch22](chapters/ch22-cpp-language-support.md) | C++ Language Support | C++11–23 features, libcu++, device lambdas, restrictions |
| [ch23](chapters/ch23-language-extensions.md) | C/C++ Language Extensions | specifiers, built-in vars, `__launch_bounds__`, `__syncthreads*` |
| [ch24](chapters/ch24-fp-intrinsics-memory-execution-model.md) | FP, Intrinsics, Memory & Execution Models | IEEE/FMA/fast-math, shuffle/vote, memory model, scopes |

## Topic Index

- **atomics** → ch03, ch08, ch24
- **bank conflicts** → ch03
- **coalescing** → ch03
- **compute capability** → ch01, ch20
- **conditional graph nodes** → ch11
- **cooperative groups** → ch03, ch13
- **CUDA graphs** → ch05, ch11
- **dynamic parallelism (CDP)** → ch18
- **environment variables** → ch21
- **error checking** → ch02
- **events / timing** → ch05
- **extended GPU memory (EGM)** → ch17
- **fast math / FMA / IEEE** → ch24
- **green contexts** → ch14
- **interop (OpenGL/D3D/Vulkan/NVSCI)** → ch19
- **intrinsics (shuffle/vote/math)** → ch24
- **IPC** → ch17
- **kernels & launch (`<<<>>>`)** → ch02, ch23
- **L2 cache control** → ch16
- **lazy loading** → ch14, ch21
- **launch bounds / occupancy** → ch03, ch23
- **memory model & scopes** → ch24, ch08
- **memory spaces (global/shared/registers/constant)** → ch01, ch03, ch23
- **memory sync domains** → ch16
- **multi-GPU / P2P** → ch09
- **nvcc / compilation** → ch07
- **PTX** → ch01, ch08
- **pinned / mapped memory** → ch06
- **pipelines / async copies** → ch15, ch08
- **programmatic dependent launch (PDL)** → ch08, ch14
- **SIMT / warps / divergence** → ch01, ch03
- **specifiers (`__global__`/`__device__`/`__shared__`)** → ch02, ch23
- **streams** → ch05
- **stream-ordered allocation (`cudaMallocAsync`)** → ch12
- **thread block clusters** → ch01, ch08
- **tile programming (cuTile)** → ch01, ch04
- **TMA (Tensor Memory Accelerator)** → ch15
- **unified memory** → ch01, ch02, ch06, ch10
- **virtual memory management (VMM)** → ch17
- **work stealing / cluster launch control** → ch16

## Supporting Files

- [glossary.md](glossary.md) — key CUDA terms with definitions and chapter pointers
- [patterns.md](patterns.md) — concrete techniques (grid-stride, tiling, reduction, stream overlap, graphs, async copy pipelining…)
- [cheatsheet.md](cheatsheet.md) — decision tables: block sizing, memory choice, sync/atomic scope, compatibility, smells

---

## Scope & Limits

Covers the CUDA Programming Guide (Release 13.3) content: programming model, host/device APIs, language extensions, and technical appendices. Not a substitute for the PTX ISA reference, the full Runtime/Driver API function reference, or NVIDIA library docs. For hands-on tuning, combine with Nsight Compute/Systems profiling on your actual hardware. Note: §2.3.2's Python intrinsic descriptions in the source are copy-swapped — ch03 uses the corrected semantics.
