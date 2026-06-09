# Chapter 11: Load Balancing

## Core Idea
Parallel performance is bounded by the *slowest* worker — an imbalanced workload wastes the rest. Load balancing distributes work so all resources finish together, via **static** schemes (decide up front, low overhead) or **dynamic** schemes (adapt at runtime, absorb irregularity at coordination cost).

## Frameworks Introduced

- **Static load balancing** (assign before execution):
  - Partition work proportionally to resource capability, known up front. Zero runtime coordination overhead, but cannot adapt to unpredictable task durations or heterogeneous/contended resources.
  - **Divisible Load Theory (DLT)** — a systematic model for *arbitrarily divisible* workloads (data that can be split in any ratio): it solves for the optimal fraction to send each node given its compute speed and the link bandwidth, accounting for communication startup and transfer time. Yields closed-form optimal partitions for tree/bus/linear network topologies.
  - When to use: regular workloads on known (possibly heterogeneous) hardware — GPU+CPU splits, multi-node data distribution.

- **Dynamic load balancing** (adapt during execution):
  - **Master–worker / task farm** — a coordinator hands work units to idle workers; naturally balances irregular work; the coordinator can become a bottleneck at scale.
  - **Work stealing** — idle workers steal tasks from busy workers' queues (decentralized, scales better than a central master); the model behind most task runtimes (TBB, OpenMP tasks, Cilk).
  - **Tuple-space / Linda model** — workers coordinate through a shared associative "tuple space" (`out`/`in`/`rd`); decouples producers from consumers and gives implicit, anonymous load balancing.
  - When to use: irregular, data-dependent, or unpredictable task durations; heterogeneous or contended resources.

## Key Concepts
- **Load imbalance cost**: total time = max over workers of their assigned work; the gap between max and mean is wasted capacity.
- **Granularity vs overhead**: finer work units balance better but cost more scheduling; coarser units are cheaper but risk imbalance — the same granularity tradeoff as decomposition.
- **Heterogeneous balancing**: with a fast GPU + slower CPU (or mixed nodes), proportional-to-throughput static splits, or dynamic schemes that let faster resources pull more, are essential.
- **Communication-aware balancing**: DLT explicitly trades compute distribution against transfer cost — sending more work to a node only helps if the link can feed it.

## Mental Models
- **Static when the workload is predictable, dynamic when it isn't.** Static wins on overhead; dynamic wins on adaptability. Many systems combine them (static initial split + dynamic correction).
- **Work stealing scales better than a central master** — a single coordinator serializes dispatch; decentralized stealing has no global bottleneck.
- **Balance proportionally to throughput on heterogeneous hardware** — splitting a GPU+CPU job 50/50 starves the GPU; split by measured throughput, or let a dynamic scheme self-tune.
- **Right-size work units** — too fine drowns in scheduling overhead, too coarse leaves stragglers; tune to the coordination cost.

## Reference Tables

| Approach | Overhead | Adapts? | Use |
|---|---|---|---|
| static (proportional) | none | no | predictable, known hardware |
| static (DLT) | none | no | divisible loads, comms-aware |
| master–worker | medium | yes | irregular work, modest scale |
| work stealing | low (decentralized) | yes | irregular, large scale |
| tuple space (Linda) | medium | yes | decoupled producer/consumer |

## Key Takeaways
1. Parallel time is set by the slowest worker — minimize the gap between max and mean load.
2. Static balancing (incl. DLT for divisible, communication-aware loads) has zero runtime overhead but can't adapt.
3. Dynamic balancing — master–worker, work stealing, tuple space — absorbs irregularity at coordination cost.
4. Work stealing scales better than a central master by removing the dispatch bottleneck.
5. On heterogeneous hardware (GPU+CPU, mixed nodes), balance proportionally to measured throughput or use a self-tuning dynamic scheme.

## Connects To
- **Ch 02 (Master–worker pattern)**: the dynamic-balancing decomposition.
- **Ch 06 (MPI)**: domain decomposition and master–worker at cluster scale.
- **Ch 03 (Performance laws)**: imbalance is one of the overheads that keeps you below the speedup ceiling.
- **Ch 09 (OpenMP)**: `schedule(dynamic/guided)` and `task` are built-in dynamic balancing.
