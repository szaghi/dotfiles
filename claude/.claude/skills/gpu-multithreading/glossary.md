# Glossary — GPU & Multithreaded Parallel Programming

**agglomeration** — PCAM phase grouping fine tasks to cut communication/overhead (Ch 2).
**Amdahl's law** — strong-scaling speedup bound 1/((1−α)+α/N); serial fraction is the wall (Ch 3).
**arithmetic intensity** — FLOPs per byte moved; locates a kernel on the roofline (Ch 3).
**ABA problem** — a value changes A→B→A, fooling a CAS into wrongly succeeding (Ch 5).
**atomic** — indivisible memory operation; basis of lock-free code and counters (Ch 4, 5).
**barrier** — synchronization point all participants must reach (Ch 4, 6, 9).
**block (CUDA)** — group of threads cooperating via shared memory + `__syncthreads` (Ch 7).
**CAS (compare-and-swap)** — atomic primitive behind lock-free structures (Ch 5).
**coalescing** — consecutive threads accessing consecutive addresses; essential GPU optimization (Ch 7).
**collective** — MPI operation all ranks participate in (Bcast/Reduce/Alltoall) (Ch 6).
**condition variable** — wait/notify primitive; always used with a predicate (Ch 4).
**critical path** — longest dependency chain in the task graph; bounds parallel time (Ch 2).
**data race** — unsynchronized conflicting access (≥1 write) ⇒ undefined behavior (Ch 4).
**deadlock** — circular resource wait (locks) or mismatched blocking send/recv (MPI) (Ch 4, 6).
**device_vector** — GPU-resident container in a high-level template library (Ch 10).
**divisible load theory (DLT)** — static, communication-aware optimal load distribution (Ch 11).
**domain decomposition** — partition data/grid across workers; the geometric pattern (Ch 2, 6).
**efficiency** — speedup / N; falls fast under Amdahl, flat under good weak scaling (Ch 3).
**embarrassingly parallel** — independent tasks, no communication (Ch 2).
**false sharing** — distinct variables on one cache line silently serializing (Ch 4, 12).
**Flynn's taxonomy** — SISD/SIMD/MISD/MIMD execution-model classification (Ch 1).
**fork–join** — OpenMP model: fork a thread team, join at region end (Ch 9).
**ghost/halo cells** — replicated boundary data exchanged between subdomains (Ch 2, 6).
**granularity** — task size; fine = more parallelism + overhead, coarse = less of both (Ch 2, 11).
**Gustafson's law** — weak-scaling speedup (1−α)+αN; ~linear as problems grow (Ch 3).
**happens-before** — sequenced-before + synchronizes-with ordering relation (Ch 4).
**lock-free** — progress guaranteed without locks, via atomic CAS (Ch 5).
**load imbalance** — gap between max and mean worker load; wasted capacity (Ch 11).
**master–worker** — coordinator dispatches work to workers; dynamic balancing (Ch 2, 11).
**memory_order** — relaxed/acquire/release/acq_rel/seq_cst atomic ordering (Ch 4).
**MIMD** — independent instruction+data streams per PE; multicore/clusters (Ch 1).
**mutex** — mutual-exclusion lock; use via RAII (Ch 4).
**NDRange** — OpenCL index space (≈ CUDA grid) (Ch 8).
**NUMA** — non-uniform memory access; local memory faster on multi-socket nodes (Ch 1).
**occupancy** — active warps / SM maximum; hides GPU memory latency (Ch 7).
**PCAM** — partition/communicate/agglomerate/map design methodology (Ch 2).
**pipeline** — staged assembly-line pattern; throughput set by slowest stage (Ch 2).
**prefix sum (scan)** — O(log N) running-aggregate primitive (Ch 5).
**reduction** — associative combine of N values; O(log N); FP-order-sensitive (Ch 5, 9).
**roofline** — model plotting attainable FLOP/s vs arithmetic intensity (Ch 3).
**SIMD/SIMT** — single instruction, multiple data/threads (vector units, warps) (Ch 1, 7).
**shared memory (CUDA)** — fast per-block on-chip scratchpad; basis of tiling (Ch 7).
**SPMD** — single program, multiple data; the MPI/GPU-kernel model (Ch 1, 6).
**strong scaling** — fixed problem, more processors (Amdahl regime) (Ch 3).
**streaming multiprocessor (SM)** — GPU core cluster running warps (Ch 1, 7).
**task farm** — see master–worker (Ch 2, 11).
**tiling** — staging a data tile into fast memory for reuse (GPU agglomeration) (Ch 7).
**tuple space (Linda)** — associative shared space for decoupled coordination (Ch 11).
**warp / wavefront** — group of (typ. 32) GPU threads executing in lockstep (Ch 1, 7).
**warp divergence** — threads in a warp taking different branches → serialized paths (Ch 7).
**weak scaling** — problem grows with processors (Gustafson regime) (Ch 3).
**work stealing** — idle workers steal tasks from busy queues; decentralized balancing (Ch 11).
**work-item/work-group (OpenCL)** — ≈ CUDA thread/block (Ch 8).
