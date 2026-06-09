# Chapter 2: Single-Processor Architecture & the Memory Hierarchy

## Core Idea
The **von Neumann architecture** (instructions and data flowing through one processor over one memory bus) is throttled by the **memory wall**: memory delivers data far slower than the processor consumes it. Every performance technique — caches, pipelining, prefetching — exists to hide this gap, and exploiting them requires writing code with **locality**.

## Frameworks Introduced

- **The von Neumann model & its bottleneck**:
  - Processors operate by **control flow**: instructions execute in sequence over data fetched from memory. The fatal flaw is the **memory wall** (von Neumann bottleneck) — a single memory load has a latency of *hundreds* of cycles, while the CPU could issue many operations in that time.
  - The entire memory hierarchy exists to alleviate this.

- **The memory hierarchy** (each level faster but smaller):
  - **Registers** → **L1/L2/L3 cache** → **main memory (DRAM)**. The faster a level, the smaller and more expensive it is. Recently/nearby-used data is kept in faster levels so the processor rarely waits the full DRAM latency.
  - **Cache lines** are the transfer unit — a load fetches a whole line, so accessing one element makes its neighbors cheap. **Cache associativity** governs where lines can sit (and causes conflict misses).
  - **TLB** (translation lookaside buffer) caches virtual→physical page translations; TLB misses are a hidden cost of scattered access.

- **Latency-hiding mechanisms** (instruction-level parallelism):
  - **Pipelining**: instructions overlap in stages; longer pipelines need more independent instructions to stay full (the **n½** concept — the vector length at which you reach half peak).
  - **Superscalar / out-of-order**: analyze dependencies and execute independent instructions in parallel / reordered.
  - **Prefetching**: speculatively load data before it's needed — which is why *sequential, predictable* access wins.
  - **Branch prediction & speculative execution**: guess the branch to keep the pipeline full; a **misprediction** flushes it (a stall).

## Key Concepts
- **Latency vs bandwidth**: latency is the wait for the *first* datum (hundreds of cycles); bandwidth is the sustained rate after. Many small scattered accesses pay latency repeatedly; large contiguous accesses amortize it into bandwidth.
- **Spatial locality**: use all of a cache line (consecutive elements) — favors unit-stride access and Structure-of-Arrays layout.
- **Temporal locality**: reuse data while it's still in cache — favors blocking/tiling so a loaded block is fully exploited before eviction.
- **Peak vs achieved performance**: the gap between a processor's theoretical FLOP/s and what code achieves is almost always the memory wall — the algorithm can't feed the ALUs fast enough.
- **n½**: a deeper pipeline (or wider vector unit) raises the amount of independent work needed to reach near-peak — short loops never amortize the startup.

## Mental Models
- **The memory wall, not the ALU, is your limit** — most scientific code is *memory-bound*; the processor sits idle waiting for data. Optimization is mostly about feeding it.
- **Engineer locality, both kinds** — spatial (use the whole cache line: unit stride, SoA) and temporal (reuse before eviction: block/tile). This is the lever behind nearly every fast kernel.
- **Predictable access lets the hardware help you** — prefetchers and pipelines reward sequential, branch-light code; scattered access and unpredictable branches defeat them.
- **Reuse data; don't re-fetch it** — the difference between a BLAS-1 (memory-bound) and BLAS-3 (compute-bound) kernel is how many operations each loaded byte serves (Ch 10).

## Reference Tables

| Level | Relative speed | Size | Lever |
|---|---|---|---|
| register | fastest | tiny | keep hot scalars/vectors here |
| L1/L2/L3 cache | fast → moderate | KB → MB | spatial + temporal locality |
| DRAM | slow (100s of cycles latency) | GB | bandwidth, prefetch, amortize |

| Mechanism | Helps | Defeated by |
|---|---|---|
| caches | reuse + neighbors | scattered/large working set |
| pipelining | throughput | dependencies, short loops |
| prefetching | latency hiding | irregular access |
| branch prediction | pipeline fullness | unpredictable branches |

## Key Takeaways
1. The von Neumann memory wall — memory far slower than the processor — is the dominant performance limit; the memory hierarchy exists to hide it.
2. Cache lines transfer in bulk; exploit spatial locality (unit stride, SoA) and temporal locality (blocking/tiling).
3. Pipelining/superscalar/prefetching give instruction-level parallelism but reward predictable, sequential, branch-light code (n½: deep pipelines need long independent work).
4. Latency (the first-access wait) vs bandwidth (sustained rate) — amortize latency with large contiguous accesses.
5. The gap between peak and achieved FLOP/s is almost always the memory wall, not the ALU — most scientific code is memory-bound.

## Connects To
- **Ch 09 (Performance programming)**: cache-aware/cache-oblivious algorithms and the roofline model that quantify this.
- **Ch 10 (HP linear algebra)**: BLAS levels and blocking exploit locality.
- **Ch 01 (Foundations)**: the "computing" branch — efficient implementation on real hardware.
