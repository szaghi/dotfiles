# Chapter 5: HPC Hardware — Memory Hierarchy, SIMD, Accelerators & Clusters

## Core Idea
Performance is bounded by hardware, and the dominant facts are the **memory hierarchy** (each level ~10× slower than the last) and **parallelism at every scale** (SIMD lanes → cores → sockets → accelerators → nodes). Writing fast code is mostly engineering **locality** and keeping every level of parallelism fed.

## Frameworks Introduced

- **The memory hierarchy** (where time actually goes):
  - Registers → **L1** (split L1i/L1d) → L2 → L3 → DRAM → (PCIe to device memory) → network/parallel filesystem. Each level is larger and slower.
  - **Cache lines** (commonly **64 bytes**) are the unit of transfer — accessing one byte loads the whole line. **Spatial locality** (use the whole line) and **temporal locality** (reuse before eviction) are the levers.
  - **Hardware prefetchers** anticipate sequential access and hide latency — which is why unit-stride access patterns win.

- **SIMD / vector instructions** (data parallelism within a core):
  - Vector registers (128/256/512-bit: SSE/AVX/AVX-512) apply one instruction across multiple data elements. A 512-bit register holds 8 doubles → up to 8× throughput.
  - **Downside**: like pipelining, branches/divergence and non-contiguous access defeat vectorization. Compilers auto-vectorize unit-stride, dependence-free loops; `-march=native` enables the widest registers.

- **Accelerators & node architecture**:
  - **GPUs** connect via **PCIe** (or faster NVLink) — high-throughput, latency-hidden-by-occupancy devices with their own memory. Host↔device transfer is the bottleneck.
  - **NUMA** (non-uniform memory access): on multi-socket nodes, memory local to a socket is faster than remote — thread/data placement matters.
  - **Latency**: the time to move data between components; positioning data close to where it's used (locality) is the central optimization.

- **Clusters** (scale beyond one node): many nodes joined by a high-speed **interconnect** (InfiniBand, etc.); distributed memory programmed with MPI. The TOP500 tracks the largest (note exotic architectures like vector-CPU systems exist alongside GPU-accelerated ones).

## Key Concepts
- **Roofline model**: attainable performance = min(peak compute, arithmetic-intensity × memory bandwidth). Low **arithmetic intensity** (FLOPs/byte) ⇒ memory-bound (optimize data movement); high ⇒ compute-bound (optimize arithmetic).
- **Latency vs throughput hardware**: CPUs minimize latency (deep caches, out-of-order, branch prediction); GPUs maximize throughput (many threads hide latency). Algorithms must match.
- **Structure-of-Arrays (SoA)** vs Array-of-Structures: SoA keeps each field contiguous → enables SIMD and coalesced access; AoS often defeats them.
- **First-touch + affinity**: on NUMA, memory is allocated near the thread that first writes it — pin threads (`OMP_PROC_BIND`) and initialize data in parallel to keep it local.

## Mental Models
- **The fastest memory level you can keep data in sets your ceiling** — most optimization is locality engineering: tile, block, and reuse to stay in cache.
- **Lay data out SoA and access unit-stride** — this is what enables auto-vectorization (CPU) and coalescing (GPU); AoS and strided access leave throughput on the table.
- **Locate your kernel on the roofline before optimizing** — memory-bound code doesn't benefit from faster math, and vice versa. The single best triage for "why is this slow?"
- **NUMA and false sharing are invisible until they aren't** — they appear as mysterious scaling cliffs; fix with affinity, first-touch, and cache-line padding.

## Reference Tables

| Level | Speed | Unit | Lever |
|---|---|---|---|
| register | ~1 cyc | scalar/vector | keep hot data here |
| L1/L2/L3 | ~few–40 cyc | 64-byte line | spatial + temporal locality |
| DRAM | ~hundreds cyc | line/page | bandwidth, prefetch |
| device (PCIe) | µs transfer | bulk | minimize host↔device |
| network | µs–ms | message | minimize comms |

| Parallelism scale | Mechanism |
|---|---|
| within core | SIMD / vector registers |
| within socket | multicore threads |
| across sockets | NUMA-aware threads |
| within node | + GPU accelerators |
| across nodes | MPI over interconnect |

## Key Takeaways
1. The memory hierarchy dominates performance — each level is ~10× slower; cache lines (64 B) transfer in bulk, so locality (spatial + temporal) is the main lever.
2. SIMD/vector registers give per-core data parallelism, but only for unit-stride, dependence-free loops; lay data out SoA.
3. GPUs are throughput devices behind PCIe — host↔device transfer is the bottleneck; CPUs are latency devices with deep caches.
4. Use the roofline model and arithmetic intensity to classify a kernel as memory- or compute-bound before optimizing.
5. NUMA (affinity + first-touch) and false sharing (cache-line padding) are silent scaling killers on multi-socket nodes.

## Connects To
- **Ch 04 (Parallel patterns)**: SIMD (`par_unseq`), false sharing, data races.
- **Ch 06 (MPI)**: the cluster/interconnect distributed-memory model.
- **Ch 09 (CUDA)**: the GPU throughput model and host↔device transfer.
- **Ch 12 (Profiling)**: roofline and cache analysis tools.
