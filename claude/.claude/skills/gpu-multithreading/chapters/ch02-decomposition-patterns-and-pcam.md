# Chapter 2: Parallel Decomposition — PCAM & the Pattern Catalogue

## Core Idea
Designing a parallel program is a *decomposition* problem: split work into tasks, identify their communication, group to cut overhead, and map to hardware. The **PCAM methodology** is the disciplined process; the **decomposition patterns** are the reusable shapes the solution takes.

## Frameworks Introduced

- **PCAM methodology** — the four-phase design process:
  1. **Partitioning** — split the computation into the finest reasonable tasks, by *functional decomposition* (split the operations) or *domain/data decomposition* (split the data). Aim for many more tasks than processors.
  2. **Communication** — determine what data must move between tasks; the partition + communication forms the **task dependency graph** (nodes = tasks, edges = communication volume).
  3. **Agglomeration** — group tasks to reduce communication and overhead (make a task's data local), trading parallelism for locality. Communication can also be cut by *duplicating* computation.
  4. **Mapping** — assign task groups to processing elements to balance load and minimize communication.
  - When to use: every from-scratch parallel design; it forces you to see the dependency graph before writing code.

- **The decomposition pattern catalogue** (the shapes a solution takes):
  - **Embarrassingly parallel** — independent tasks, no communication (Monte Carlo, pixel-wise image ops). Trivially scalable; the ideal.
  - **Divide-and-conquer / recursive** — split, solve sub-problems in parallel, combine (parallel sort, FFT, tree/graph algorithms over recursive data).
  - **Geometric / data (domain) decomposition** — partition a grid/array into tiles; each task owns a tile and exchanges *halo/ghost* boundaries with neighbors (stencils, PDE solvers, image convolution).
  - **Pipeline** — stages arranged like an assembly line; each item flows stage-to-stage; throughput is set by the **slowest stage**, latency by the time to fill all stages (signal processing, graphics pipelines, shell pipes).
  - **Event-based / coordination (master–worker, task farm)** — a coordinator hands work units to workers dynamically; naturally load-balances irregular work.

## Key Concepts
- **Task dependency graph**: nodes = tasks, edges = communication; the critical path through it bounds the achievable parallel time.
- **Granularity**: fine-grained = more parallelism but more overhead; coarse-grained = less overhead but risk of load imbalance. Agglomeration tunes it.
- **Halo / ghost cells**: replicated boundary data in geometric decomposition; the exchange volume scales with surface area, the compute with volume — favoring larger tiles (surface-to-volume ratio).
- **Pipeline metrics**: rate = 1 / (slowest stage time); latency = sum of all stage times until full; speedup approaches the number of stages only for balanced stages and many items.

## Mental Models
- **Decompose data when the data is large and regular; decompose function when the operations are distinct.** Most HPC is domain decomposition.
- **Maximize the surface-to-volume ratio in geometric decomposition** — bigger tiles mean proportionally less halo exchange. This is the same principle behind MPI domain decomposition and GPU tiling.
- **A pipeline is only as fast as its slowest stage** — balance stages or replicate the bottleneck stage.
- **Master–worker for irregular/unpredictable work; static geometric for regular work** — dynamic dispatch costs coordination but absorbs imbalance.

## Reference Tables

| Pattern | Communication | Best for |
|---|---|---|
| Embarrassingly parallel | none | independent work (Monte Carlo) |
| Divide-and-conquer | combine step | sort, FFT, recursive data |
| Geometric/domain | halo exchange | stencils, PDEs, grids |
| Pipeline | stage-to-stage | streaming, signal/graphics |
| Master–worker | dispatch/collect | irregular, dynamic load |

| PCAM phase | Goal | Output |
|---|---|---|
| Partition | maximize concurrency | fine tasks |
| Communicate | identify data movement | dependency graph |
| Agglomerate | cut overhead, raise locality | task groups |
| Map | balance + minimize comms | PE assignment |

## Key Takeaways
1. Apply PCAM in order: partition → communicate → agglomerate → map; the task dependency graph is the central artifact.
2. Choose a decomposition pattern that matches the data/operation structure — geometric for grids, pipeline for streams, master–worker for irregular work.
3. In geometric decomposition, larger tiles improve the surface-to-volume (compute-to-communication) ratio.
4. A pipeline's throughput is bounded by its slowest stage; balance or replicate it.
5. Granularity is a tunable: agglomerate to trade excess parallelism for locality and lower overhead.

## Connects To
- **Ch 03 (Performance laws)**: the dependency graph's critical path bounds speedup.
- **Ch 06 (MPI)**: domain decomposition + halo exchange is the MPI workhorse.
- **Ch 07 (CUDA)**: tiling is geometric decomposition onto shared memory.
- **Ch 11 (Load balancing)**: master–worker and mapping strategies.
