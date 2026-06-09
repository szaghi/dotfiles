# Chapter 1: Parallel Hardware & the Taxonomy of Parallelism

## Core Idea
Every parallel-programming decision is downstream of the hardware's **execution model** (how instructions and data are issued) and its **memory model** (shared vs distributed). Flynn's taxonomy and the shared/distributed split are the map you place a problem onto before choosing a tool.

## Frameworks Introduced

- **Flynn's taxonomy** (the execution-model map):
  - **SISD** — one instruction stream, one data stream (a classic sequential core).
  - **SIMD** — one instruction applied to many data lanes simultaneously (vector units; a GPU streaming multiprocessor / AMD SIMD unit; CPU AVX/SVE).
  - **MISD** — rare; multiple instructions on one datum (fault-tolerant pipelines).
  - **MIMD** — independent instruction + data streams per processing element (multicore CPUs, clusters). The most general.
  - **SPMD** — a *programming* model (not Flynn): one program, many instances over different data — the model MPI and CUDA kernels actually use.
  - When to use: classify the target. GPUs are SIMD-within-an-SM, MIMD-across-SMs; clusters are MIMD/SPMD.

- **The memory-model split** (determines the dominant cost):
  - **Shared-memory MIMD** — all PEs see one address space; coordination is cheap (loads/stores) but contention, cache coherence, and **NUMA** (non-uniform memory access) dominate. Tools: threads, OpenMP, Thrust.
  - **Distributed-memory (shared-nothing) MIMD** — each node has private memory; coordination is explicit **message passing**. Tools: MPI. Scales to thousands of nodes but communication is the bottleneck.
  - **Hybrid** — the real world: MPI across nodes + threads/OpenMP/GPU within a node.

- **The GPU execution hierarchy** (the accelerator model):
  - Device → **streaming multiprocessors (SMs)** → warps/wavefronts (SIMD lanes, typically 32) → threads. Massive thread-level parallelism hides memory latency rather than caching it away. Detail in the CUDA/OpenCL chapters.

## Key Concepts
- **Latency vs throughput hardware**: CPUs minimize latency (deep caches, OOO, branch prediction); GPUs maximize throughput (thousands of threads, latency hidden by oversubscription).
- **Cache coherence**: hardware keeps shared-memory caches consistent — but coherence traffic (false sharing!) is a hidden cost.
- **NUMA**: on multi-socket nodes, memory local to a socket is faster; thread/data placement matters.
- **Memory hierarchy**: registers → L1/L2/L3 → DRAM → (PCIe/NVLink to device memory) → network. Each level is ~10× slower; the algorithm's job is to maximize locality at the fastest level it can.
- **Hardware threads (SMT/"hyperthreading")**: extra logical cores sharing one physical core's resources — help latency-bound code, not compute-bound.

## Mental Models
- **Pick the tool from the memory model, not habit**: shared address space → threads/OpenMP; separate address spaces → MPI; massive data-parallel arithmetic → GPU.
- **GPUs hide latency with occupancy, CPUs hide it with caches** — porting a cache-friendly CPU algorithm naively to a GPU often loses because the access pattern fights the throughput model.
- **The fastest memory level you can keep data in sets your ceiling** — most optimization is locality engineering.
- **NUMA and false sharing are invisible until they aren't** — they show up as mysterious scaling cliffs, not crashes.

## Reference Tables

| Class | Execution | Memory | Typical tool |
|---|---|---|---|
| Multicore CPU | MIMD | shared (NUMA) | threads, OpenMP |
| GPU | SIMD-in-SM / MIMD-across | device + shared | CUDA, OpenCL, Thrust |
| Cluster | MIMD / SPMD | distributed | MPI |
| Hybrid HPC node | all of the above | shared + distributed | MPI + OpenMP + GPU |

| Hardware | Optimizes for | Hides latency via |
|---|---|---|
| CPU | latency | caches, OOO, prefetch |
| GPU | throughput | massive thread oversubscription |

## Key Takeaways
1. Classify the target with Flynn (SIMD/MIMD) and the memory model (shared/distributed) before choosing a programming model.
2. SPMD is the practical model behind MPI and GPU kernels: one program, many data-indexed instances.
3. CPUs are latency machines (caches); GPUs are throughput machines (occupancy) — algorithms must match.
4. Locality at the fastest memory level sets the performance ceiling; most tuning is locality engineering.
5. NUMA, cache coherence, and false sharing are silent scaling killers in shared-memory code.

## Connects To
- **Ch 02 (Decomposition)**: PCAM maps a problem onto this hardware.
- **Ch 03 (Performance laws)**: Amdahl/Gustafson/roofline quantify the ceilings.
- **Ch 07/08 (CUDA/OpenCL)**: the GPU execution hierarchy in depth.
- **Ch 06 (MPI)**: the distributed-memory model.
