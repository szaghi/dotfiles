---
name: gpu-multithreading
description: "Practitioner knowledge base for parallel, multithreaded, and GPU programming — the design methodology, performance laws, and cross-technology optimization playbook. Use when designing or optimizing parallel software: choosing a parallel decomposition (PCAM, geometric/pipeline/master-worker patterns); reasoning about speedup and scalability (Amdahl, Gustafson, roofline, arithmetic intensity); writing shared-memory code (C++ threads, mutexes, atomics, memory_order, condition variables, lock-free/CAS, false sharing, deadlock); distributed-memory message passing (MPI, domain decomposition, halo exchange, collectives); GPU programming (CUDA/OpenCL thread hierarchy, warps, coalescing, shared-memory tiling, occupancy, host-device transfer); directive-based parallelism (OpenMP fork-join, data-sharing clauses, reductions, target offload); high-level GPU template libraries (Thrust transform/reduce/scan/sort); load balancing (static/DLT, dynamic/work-stealing/master-worker); or diagnosing parallel performance and correctness pitfalls (data races, uncoalesced access, benchmark-timing errors, floating-point non-reproducibility). Self-contained: the CUDA, MPI, OpenMP, and OpenCL chapters carry concrete APIs, host-program skeletons, code, and parameter tables — usable for hands-on coding, not just design."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, technology (cuda/mpi/openmp), pattern, or chapter (e.g. ch03)]
---

# GPU & Multithreaded Parallel Programming
**Scope**: design methodology · performance laws · shared/distributed/GPU programming models · optimization | **Chapters**: 12 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core decision rules below.
- **With a topic** — ask about `decomposition`, `Amdahl`, `coalescing`, `false sharing`, `load balancing`, `memory_order`; I find and read the relevant chapter.
- **With a technology** — ask about `CUDA`, `MPI`, `OpenMP`; I load that chapter.
- **With a chapter** — ask for `ch03`; I load that file.

When you ask about something not in the Core section, I read the relevant chapter (and `cheatsheet.md` / `patterns.md` / `glossary.md`). The CUDA, MPI, OpenMP, and OpenCL chapters are self-contained — they carry concrete APIs, host-program skeletons, code, and parameter tables for hands-on coding.

---

## Core Decision Framework

### Pick the programming model from the memory model (Ch 1)
Shared address space, one node → **threads / OpenMP**. Separate address spaces, many nodes → **MPI**. Massive data-parallel arithmetic → **GPU** (CUDA / OpenCL / Thrust). Real HPC node → **hybrid** (MPI + OpenMP/GPU). CPUs hide latency with caches; GPUs hide it with occupancy — algorithms must match.

### Design with PCAM + a decomposition pattern (Ch 2)
**Partition → Communicate → Agglomerate → Map.** The task dependency graph is the central artifact. Pattern by work shape: embarrassingly parallel (independent), divide-and-conquer (recursive), **geometric/domain + halo** (grids/stencils — the HPC workhorse), pipeline (streaming; slowest stage sets rate), master–worker (irregular). Maximize surface-to-volume in geometric decomposition.

### Know the ceilings (Ch 3)
**Amdahl** (strong scaling): `S ≤ 1/((1−α)+α/N)`, capped at `1/(1−α)` — attack the serial fraction first. **Gustafson** (weak scaling): `S = (1−α)+αN`, ~linear as problems grow. **Roofline**: arithmetic intensity (FLOPs/byte) locates a kernel as memory-bound (reuse/tile) or compute-bound (vectorize/FMA).

### Shared-memory correctness (Ch 4–5)
Shared mutable state → mutex or atomic (read-only/thread-local need neither); data race = UB. Always RAII locks (`scoped_lock` for multiple, or global order → no deadlock). `cv.wait` with a predicate. Default atomics `seq_cst`; weaken to acquire/release only with a happens-before proof. Watch false sharing. Start with coarse locking; earn lock-free (CAS loops, ABA-aware) with profiler evidence.

### GPU performance order (Ch 7–8, 10)
1) **Coalesce** global access (SoA, contiguous per warp) — #1 lever. 2) **Tile** through shared memory (raise arithmetic intensity). 3) **Occupancy** to hide latency. 4) Minimize **warp divergence**. 5) Minimize + **overlap host↔device copies**. CUDA↔OpenCL maps thread/block/grid ↔ work-item/work-group/NDRange. Prefer high-level primitives (`transform`/`reduce`/`scan`/`sort`) over hand kernels.

### Distributed memory (Ch 6)
SPMD over a communicator; **communication is the bottleneck** — minimize, batch, overlap (`Irecv`/`Isend` + interior compute). Prefer collectives over point-to-point loops; `Sendrecv`/nonblocking to avoid deadlock. Domain decomposition + halo exchange is the dominant pattern.

### Load balancing (Ch 11) & pitfalls (Ch 12)
Static (proportional/DLT) for predictable work; dynamic (master–worker, **work stealing**) for irregular. Balance heterogeneous hardware by measured throughput. **Always synchronize before timing** async GPU/MPI work — a missing sync produces the classic impossible ">100× speedup." Parallel floating-point reductions reorder additions → not bitwise reproducible.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-hardware-and-parallelism-taxonomy.md) | Hardware & Parallelism Taxonomy | Flynn, SIMD/MIMD/SPMD, shared/distributed, NUMA, GPU hierarchy |
| [ch02](chapters/ch02-decomposition-patterns-and-pcam.md) | Decomposition & PCAM | PCAM, dependency graph, geometric/pipeline/master-worker patterns |
| [ch03](chapters/ch03-performance-laws-and-scalability.md) | Performance Laws & Scalability | Amdahl, Gustafson, roofline, arithmetic intensity |
| [ch04](chapters/ch04-cpp-threads-and-concurrency.md) | C++ Threads & Concurrency | thread/jthread, mutex, CV, atomics, memory_order, deadlock |
| [ch05](chapters/ch05-parallel-data-structures.md) | Parallel Data Structures | locking spectrum, lock-free/CAS, ABA, scan, reduction |
| [ch06](chapters/ch06-distributed-memory-mpi.md) | Distributed Memory (MPI) | SPMD, point-to-point, collectives, halo exchange, overlap |
| [ch07](chapters/ch07-gpu-programming-cuda.md) | GPU Programming (CUDA) | grid/block/thread, warps, coalescing, shared-memory tiling, occupancy |
| [ch08](chapters/ch08-portable-accelerators-opencl.md) | Portable Accelerators (OpenCL) | NDRange, work-items, CUDA↔OpenCL map, runtime compile, SYCL |
| [ch09](chapters/ch09-shared-memory-openmp.md) | Shared Memory (OpenMP) | fork-join, data-sharing clauses, reduction, schedule, target offload |
| [ch10](chapters/ch10-high-level-gpu-thrust.md) | High-Level GPU (Thrust) | device_vector, transform/reduce/scan/sort, fancy iterators, fusion |
| [ch11](chapters/ch11-load-balancing.md) | Load Balancing | static/DLT, dynamic, master-worker, work stealing, tuple space |
| [ch12](chapters/ch12-optimization-and-pitfalls.md) | Optimization & Pitfalls | triage order, data races, false sharing, timing discipline, FP reproducibility |

## Topic Index

- **Amdahl / Gustafson / scalability** → ch03
- **arithmetic intensity / roofline** → ch03, ch12
- **atomics / memory_order / CAS** → ch04, ch05
- **coalescing / SoA layout** → ch07, ch12
- **collectives (Bcast/Allreduce)** → ch06
- **condition variables** → ch04
- **CUDA (grid/block/warp/SM)** → ch07
- **data race / false sharing / deadlock** → ch04, ch12
- **decomposition patterns** → ch02
- **domain decomposition / halo exchange** → ch02, ch06
- **Flynn taxonomy / SIMD / MIMD / SPMD** → ch01
- **load balancing (static/dynamic/DLT/work-stealing)** → ch11
- **lock-free / wait-free** → ch05
- **master–worker / task farm** → ch02, ch11
- **MPI / message passing** → ch06
- **mutex / RAII locking** → ch04
- **OpenCL / NDRange / work-items** → ch08
- **OpenMP / fork-join / clauses** → ch09
- **occupancy / warp divergence** → ch07
- **PCAM methodology** → ch02
- **pipeline pattern** → ch02
- **reduction / scan (prefix sum)** → ch05, ch09
- **roofline / memory-vs-compute bound** → ch03, ch12
- **shared-memory tiling** → ch07
- **Thrust / high-level GPU primitives** → ch10
- **benchmark timing / synchronization** → ch12
- **floating-point reproducibility** → ch05, ch12

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete techniques (PCAM, halo exchange, tiling, CAS loop, overlap, synchronized benchmarking)
- [cheatsheet.md](cheatsheet.md) — decision rules: model picker, decomposition picker, GPU optimization order, CUDA↔OpenCL map, pitfall→fix

---

## Scope & Limits

This skill covers parallel-programming end to end: the *design methodology and performance laws*, the *cross-technology optimization playbook*, and *self-contained, hands-on chapters* for C++ threads, MPI, CUDA, OpenCL, OpenMP, and Thrust — each with concrete APIs, host-program skeletons, code, and parameter tables. It targets the durable model and the practical coding patterns rather than exhaustively enumerating every API entry point or the newest spec revision's micro-features; for the latest version-specific spec minutiae the upstream specifications remain the final word. For language-standard concurrency/memory-model questions, see **iso-cpp-2023** (C++) or **iso-c-9899-2024** (C).
