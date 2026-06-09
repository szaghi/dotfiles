# Chapter 7: Profiling & Benchmarking

## Core Idea
You cannot optimize what you haven't measured. **Profiling** reveals where a program spends its time (which functions, which lines); **benchmarking** measures performance reproducibly. The HPC toolchain spans `gprof` (function profiling), **PAPI** (portable hardware counters), and **TAU** (parallel profiling and tracing across ranks).

## Frameworks Introduced

- **Timing & benchmarking discipline**: processor-specific timers exist but aren't portable; measure wall time with a monotonic clock, **warm up** before timing, **repeat** and report variation. On parallel programs, be careful what you measure — a collective's cost depends on all ranks, so time the right scope.

- **Profiling tools** (where the time goes):
  - **`gprof`** — function-level profiler; requires **recompiling with `-pg`** (instrumentation), then run, then `gprof` reads `gmon.out`. Shows a flat profile (time per function) and a call graph.
  - **Sampling profilers** (`perf`) — low overhead, no recompile; sample the program counter to find hot functions and hardware events.

- **PAPI** (portable hardware counters): a uniform interface to CPU **hardware performance counters** (cache misses, branch mispredictions, FLOP counts, cycles) across processors. Lets you measure *why* code is slow at the hardware level — e.g. a high cache-miss rate confirms a memory-bound kernel. Supports **derived metrics** (e.g. computed FLOP/s, cache-miss ratios).

- **TAU** (Tuning and Analysis Utilities — parallel profiling & tracing):
  - Instruments parallel (MPI/OpenMP) programs to **profile** (time/counts per function per rank) and **trace** (a timeline of events across all ranks). Visualized with **ParaProf** (profiles) and **Jumpshot** (traces).
  - Reveals parallel pathologies: load imbalance (one rank slower), communication overhead, serialization, and which phase dominates — things a serial profiler can't see.

## Key Concepts
- **Profile before optimizing**: the bottleneck is rarely where intuition says; `gprof`/`perf` find the hot functions, and **Amdahl** says optimizing anything but the dominant cost caps your gain at that fraction.
- **Hardware counters explain *why***: a flat profile says *where* time goes; PAPI counters (cache misses, mispredicts) say *why* — distinguishing memory-bound from compute-bound from branch-bound.
- **Parallel profiling needs per-rank/per-thread view**: aggregate timing hides load imbalance and communication cost; TAU's per-rank profiles and timeline traces expose them.
- **Reproducible benchmarking**: warm up (avoid cold-cache/first-call effects), pin to specific nodes for stable timings, repeat, and report variation — a single number is not a measurement.

## Mental Models
- **Measure first, optimize the dominant cost only** — profile to find where time actually goes; Amdahl caps the payoff of optimizing a small fraction. Never guess the bottleneck.
- **Flat profile for *where*, hardware counters for *why*** — `gprof`/`perf` locate the hot function; PAPI counters tell you if it's cache-bound, branch-bound, or compute-bound, pointing at the fix.
- **Profile parallel programs per-rank, not in aggregate** — use TAU to find the load imbalance, communication overhead, or serialization that aggregate wall time hides.
- **Benchmark reproducibly** — warm up, pin nodes, repeat, report spread; an unwarmed single-shot timing is noise.

## Code Examples
```bash
# gprof: instrument, run, analyze
g++ -pg -O2 solver.cpp -o solver
./solver                       # produces gmon.out
gprof ./solver gmon.out | head -40   # flat profile + call graph

# perf: low-overhead sampling, no recompile
perf record -g ./solver
perf report                    # hot functions + hardware events

# PAPI: hardware counters (sketch — link -lpapi)
#   PAPI_start_counters({PAPI_L2_TCM, PAPI_FP_OPS}, 2);
#   ... region ...
#   PAPI_stop_counters(values, 2);   // cache misses, FLOPs

# TAU: parallel profile + trace, then visualize
tau_exec mpirun -np 16 ./solver
paraprof    # per-rank profiles (find load imbalance)
```
- **What it demonstrates**: gprof instrumentation, perf sampling, PAPI hardware counters, and TAU parallel profiling.

## Reference Tables

| Tool | Measures | Recompile? |
|---|---|---|
| `gprof` | function time + call graph | yes (`-pg`) |
| `perf` | hot functions + HW events | no (sampling) |
| PAPI | hardware counters (cache/FLOP/branch) | link `-lpapi` |
| TAU + ParaProf/Jumpshot | parallel profile + trace per rank | instrument |

| Question | Tool |
|---|---|
| where does time go? | gprof / perf |
| why is it slow (cache/branch)? | PAPI |
| which rank/phase dominates? | TAU |

## Key Takeaways
1. Profile before optimizing — the bottleneck is rarely where you guess, and Amdahl caps the gain of optimizing anything but the dominant cost.
2. `gprof` (instrumented) and `perf` (sampling) show *where* time goes; PAPI hardware counters show *why* (cache misses, branch mispredicts, FLOPs).
3. Parallel programs need per-rank/per-thread profiling — TAU (with ParaProf/Jumpshot) exposes load imbalance, communication cost, and serialization that aggregate timing hides.
4. Benchmark reproducibly: warm up, pin nodes, repeat, report variation — a single number isn't a measurement.
5. Distinguish memory-bound from compute-bound from branch-bound via counters to pick the right optimization.

## Connects To
- **Ch 06 (Debugging)**: the correctness counterpart to performance measurement.
- **Ch 08 (SLURM)**: profiling runs are submitted as batch jobs; pin nodes for stable timing.
- **Ch 01 (Unix)**: profilers are command-line tools emitting text to analyze.
