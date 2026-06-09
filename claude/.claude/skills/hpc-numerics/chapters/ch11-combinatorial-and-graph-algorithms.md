# Chapter 11: Combinatorial Algorithms — Sorting & Graphs

## Core Idea
Not all HPC is numerical. **Sorting** and **graph algorithms** are combinatorial problems where the parallel algorithm is often *fundamentally different* from the sequential one, and where the key insight is that graph problems can be recast as **sparse linear algebra** on the adjacency matrix — unifying them with the numerical toolkit.

## Frameworks Introduced

- **Parallel sorting** (the sequential algorithm doesn't parallelize directly):
  - **Sorting networks** (oblivious algorithms): a fixed sequence of compare-exchange operations independent of the data — **bitonic sort** (O(n log²n) comparisons but highly parallel) and **odd-even transposition sort** (neighbor compare-exchanges, natural for distributed/SIMD).
  - These trade a worse operation count for a *parallel structure* the optimal sequential quicksort lacks — a recurring theme: the best parallel algorithm is often not the parallelization of the best sequential one.

- **Graph algorithms, two views**:
  - **Traditional**: BFS/DFS traversal, shortest paths (Dijkstra, Floyd-Warshall), connected components, spanning trees — irregular, pointer-chasing, hard to parallelize and cache-hostile.
  - **Linear-algebra view**: a graph is its **adjacency matrix** (sparse); many graph operations become sparse matrix operations. **BFS = repeated sparse matrix-vector products** (multiply the adjacency matrix by the frontier vector to get the next frontier); all-pairs shortest path relates to matrix powers in the (min, +) semiring. This recasts irregular graph work as the well-understood sparse matvec (Ch 8, 10).

- **Graph coloring** (for parallelism): color the graph so adjacent nodes differ — independent (same-color) nodes can be processed in parallel. Used to parallelize sparse-matrix operations (e.g. Gauss-Seidel/ILU) where data dependencies follow the matrix graph.

## Key Concepts
- **The parallel algorithm differs from the sequential**: optimal sequential sorting (quicksort, O(n log n)) doesn't map to parallel hardware; sorting networks accept more operations for a fixed parallel structure. Recognizing this is the core combinatorial-HPC insight.
- **Graph = sparse matrix**: the adjacency-matrix view unifies graph algorithms with numerical linear algebra — BFS as sparse matvec, reachability as matrix powers — so the sparse-LA performance analysis (memory-bound, irregular access) applies.
- **Irregularity is the enemy**: graph algorithms have data-dependent, scattered memory access (pointer chasing) → cache-hostile and load-imbalanced; "real world" graphs (power-law degree distributions) make this worse.
- **Coloring exposes parallelism**: independent sets (same color) have no dependencies and run concurrently — the bridge from a dependency graph to a parallel schedule.

## Mental Models
- **The best parallel algorithm is often not the best sequential one parallelized** — for sorting especially, accept a worse operation count (bitonic/odd-even) to gain a regular parallel structure.
- **Recast graph problems as sparse linear algebra** — BFS becomes repeated sparse matvec on the adjacency matrix; this gives you the numerical toolkit (and its memory-bound performance model) for irregular graph work.
- **Expect graph algorithms to be memory-bound and irregular** — scattered access defeats caches and prefetchers; optimize data layout and partitioning, not arithmetic.
- **Color the graph to find independent work** — when a computation's dependencies follow a graph (sparse-matrix iterations), coloring partitions it into parallel-safe sets.

## Reference Tables

| Sort | Parallelism | Comparisons | Use |
|---|---|---|---|
| quicksort | poor (sequential-optimal) | O(n log n) | serial |
| bitonic sort | high (oblivious network) | O(n log²n) | parallel/SIMD |
| odd-even transposition | high (neighbor exchanges) | O(n²) | distributed/SIMD |

| Graph operation | Linear-algebra form |
|---|---|
| BFS frontier expansion | sparse matrix × vector |
| reachability / paths | matrix powers (semiring) |
| parallel scheduling | graph coloring |

## Key Takeaways
1. Combinatorial HPC (sorting, graphs) often requires a fundamentally different parallel algorithm than the optimal sequential one — sorting networks (bitonic, odd-even) trade operation count for parallel structure.
2. Graph algorithms have two views: traditional traversal (irregular, cache-hostile) and the linear-algebra view (adjacency matrix → sparse operations).
3. BFS is repeated sparse matrix-vector products on the adjacency matrix — recasting graph work as the numerical sparse-LA toolkit.
4. Graph algorithms are memory-bound and irregular (pointer chasing, power-law graphs) — optimize layout/partitioning, not arithmetic.
5. Graph coloring exposes independent (same-color) work for parallel scheduling, e.g. parallelizing sparse-matrix iterations.

## Connects To
- **Ch 07–08 (Numerical LA)**: the sparse matvec and matrix-graph view shared with fill-in/iterative solvers.
- **Ch 02 (Architecture)**: why irregular graph access is cache-hostile.
- **Ch 12 (N-body)**: another irregular, spatially-structured problem.
