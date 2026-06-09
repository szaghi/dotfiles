# Chapter 3: Performance Laws & Scalability — Amdahl, Gustafson, Roofline

## Core Idea
Parallel speedup has hard mathematical ceilings set by the **serial fraction** (Amdahl) and the **problem-scaling regime** (Gustafson). The **roofline model** then tells you whether your kernel is compute-bound or memory-bound. Measure against these before celebrating any speedup.

## Frameworks Introduced

- **Amdahl's law** (fixed problem size — *strong scaling*):
  - With parallelizable fraction α and N processors: **speedup ≤ 1 / ((1−α) + α/N)**.
  - As N → ∞: **speedup → 1 / (1−α)**. The serial fraction (1−α) is a hard wall.
  - Brutal consequence: α = 0.9 caps speedup below 10 no matter how many processors; α = 0.95 still caps below 20.
  - When to use: predicting the benefit of parallelizing a *fixed* workload; deciding whether the serial part is worth attacking first.

- **Gustafson–Barsis' law** (scaled problem size — *weak scaling*):
  - If the problem grows with the machine (serial part stays constant, parallel part scales): **scaled speedup = N − (1−α)(N − 1)** = (1−α) + αN.
  - The rebuttal to Amdahl's pessimism: in practice we solve *bigger* problems on bigger machines, so speedup grows ~linearly with N.
  - When to use: HPC where larger machines run larger simulations (the normal case).

- **The roofline model** (the compute-vs-memory ceiling):
  - Plot attainable GFLOP/s vs **arithmetic intensity** (FLOPs per byte of memory traffic).
  - Two roofs: a slanted **memory-bandwidth** roof (low intensity) and a flat **peak-compute** roof (high intensity); the ridge point is where they meet.
  - A kernel below the memory roof is **memory-bound** (optimize data movement/reuse); above the ridge it's **compute-bound** (optimize instruction throughput).

## Key Concepts
- **Strong scaling**: fixed problem, more processors → governed by Amdahl; efficiency drops as N grows.
- **Weak scaling**: problem grows with processors → governed by Gustafson; efficiency can stay near-constant.
- **Parallel efficiency** = speedup / N. Falls off fast under Amdahl (the serial part dominates), stays flat under good weak scaling.
- **Arithmetic intensity** = FLOPs / bytes moved; raising it (via tiling, fusion, reuse) is how memory-bound kernels move up the roofline.
- **Overhead** (communication, synchronization, load imbalance) is the gap between the law's prediction and reality — the laws are *upper bounds*.

## Mental Models
- **Attack the serial fraction first** — Amdahl says a 1% serial part caps you at 100×; profiling to shrink (1−α) often beats adding processors.
- **Report weak scaling for "can we run bigger?" and strong scaling for "can we run faster?"** — they answer different questions; conflating them misleads.
- **Locate your kernel on the roofline before optimizing** — memory-bound kernels don't benefit from faster math, and vice versa. This is the single best triage for "why is my GPU/CPU kernel slow?"
- **A >N× speedup on N cores is a red flag** — usually a measurement error or a baseline that wasn't using caches/vectorization (cf. the GPU-benchmark-timing discipline: a missing synchronization makes the GPU look 100× faster than it is).

## Code Examples
```text
Amdahl (strong):    S(N) = 1 / ((1 - α) + α/N),     S(∞) = 1/(1-α)
Gustafson (weak):   S(N) = (1 - α) + α·N
Efficiency:         E(N) = S(N) / N
Arithmetic intensity: AI = FLOPs / bytes_moved
Roofline ceiling:   attainable = min(peak_FLOPs, AI × peak_bandwidth)
```
- **What it demonstrates**: the four numbers to compute before and after any parallelization.

## Reference Tables

| Law | Regime | Speedup | Verdict |
|---|---|---|---|
| Amdahl | strong (fixed size) | 1/((1−α)+α/N) | serial fraction = hard wall |
| Gustafson | weak (scaled size) | (1−α)+αN | ~linear if problem grows |

| Roofline position | Bound by | Optimize |
|---|---|---|
| left of ridge (low AI) | memory bandwidth | reuse, tiling, fewer bytes |
| right of ridge (high AI) | peak compute | ILP, vectorization, FMA |

## Key Takeaways
1. Amdahl caps strong-scaling speedup at 1/(1−α); the serial fraction is the wall — shrink it first.
2. Gustafson shows weak scaling can be ~linear because real problems grow with the machine.
3. Roofline triages a kernel as memory-bound or compute-bound via arithmetic intensity — optimize accordingly.
4. Parallel efficiency = speedup/N; distinguish strong- vs weak-scaling reports.
5. Super-linear or implausibly large speedups almost always mean a measurement error (e.g. missing GPU synchronization) or a non-representative baseline.

## Connects To
- **Ch 01 (Hardware)**: peak FLOPs and bandwidth come from the hardware.
- **Ch 02 (Decomposition)**: agglomeration and tiling raise arithmetic intensity.
- **Ch 12 (Optimization)**: profiling and benchmark-timing discipline.
- **Ch 07 (CUDA)**: occupancy and memory coalescing move kernels up the roofline.
