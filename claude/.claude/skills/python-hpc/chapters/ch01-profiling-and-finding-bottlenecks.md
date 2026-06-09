# Chapter 1: Profiling — Finding Bottlenecks Before Optimizing

## Core Idea
**Never optimize without measuring.** Profiling tells you *where* time and memory actually go — which is almost never where intuition says. Always profile, change one thing, re-profile, and keep a representative baseline. Premature optimization wastes effort on code that isn't the bottleneck.

## Frameworks Introduced

- **The profiling toolkit, coarse → fine**:
  - **`time` / `timeit` / `%timeit`** — wall-clock timing of a whole operation; `%timeit` (IPython) auto-repeats and reports best-of-N. The first, cheapest measurement.
  - **`cProfile`** — function-level deterministic profiler (built-in): which *functions* dominate cumulative/total time. Visualize the call graph with **SnakeViz**.
  - **`line_profiler`** (`@profile` + `kernprof -l -v`) — *line-by-line* time within a chosen function. The workhorse for "which line is slow."
  - **`memory_profiler`** (`@profile`, line-by-line RAM) — *memory* growth per line; catches accidental copies and large allocations.
  - **`Scalene`** — combines CPU *and* memory profiling, separates Python vs native time, and flags lines worth moving to C/GPU. The modern all-in-one.
  - **`py-spy`** — sampling profiler that attaches to a *running* process without code changes; ideal for production.

- **The optimization loop**: (1) establish a representative baseline + regression test, (2) profile to find the dominant cost, (3) change one thing, (4) re-profile and compare, (5) keep it only if it measurably wins and tests still pass.

## Key Concepts
- **Deterministic vs sampling profilers**: `cProfile`/`line_profiler` instrument every call (accurate, higher overhead); `py-spy`/`Scalene` sample (low overhead, production-safe).
- **Cumulative vs total time** in `cProfile`: *total* (tottime) excludes sub-calls; *cumulative* (cumtime) includes them — read tottime to find the actual hot function, cumtime to find the expensive call tree.
- **Representative input**: profile with data of realistic size and distribution; a toy input hides the real bottleneck and can invert the ranking.
- **Wall-clock vs CPU time**: I/O-bound code shows low CPU but high wall time — different fix (concurrency) than CPU-bound code (vectorize/compile).

## Mental Models
- **Profile first, always** — "I think this loop is slow" is a hypothesis, not data. The bottleneck is routinely somewhere surprising.
- **Drill coarse-to-fine**: `%timeit` to spot a slow operation → `cProfile` to find the function → `line_profiler` to find the line → `memory_profiler`/Scalene if it's allocation-bound.
- **Optimize the dominant cost only** — Amdahl applies: speeding up a function that's 5% of runtime caps your gain at 5%.
- **Keep the baseline and a correctness test** — every optimization risks a behavior change; without a test you trade speed for silent bugs.

## Code Examples
```python
# Line-by-line timing: decorate, then run with kernprof
@profile                                  # line_profiler injects this name
def compute(data):
    total = 0
    for x in data:                        # kernprof -l -v script.py shows
        total += expensive(x)             #   time + %time per line
    return total

# Quick comparative timing in a notebook
%timeit -n 100 -r 5 vectorized(a, b)      # best of 5 runs of 100 loops

# Production sampling — no code changes
#   py-spy top --pid 12345
#   py-spy record -o profile.svg --pid 12345   (flame graph)
```
- **What it demonstrates**: line-level timing for development and zero-instrumentation sampling for production.

## Reference Tables

| Tool | Granularity | Measures | Overhead | Use when |
|---|---|---|---|---|
| `%timeit` | operation | wall time | low | quick A/B |
| `cProfile` + SnakeViz | function | CPU time | medium | find hot function |
| `line_profiler` | line | CPU time | high | find hot line |
| `memory_profiler` | line | RAM | high | find allocation |
| `Scalene` | line | CPU + RAM, py vs native | low | all-in-one triage |
| `py-spy` | sampled | CPU | very low | running/production process |

## Key Takeaways
1. Never optimize without profiling — the bottleneck is rarely where you guess.
2. Drill coarse-to-fine: `%timeit` → `cProfile` → `line_profiler` → memory profiler / Scalene.
3. Read `cProfile` tottime for the hot function, cumtime for the expensive call tree.
4. Profile with representative input and keep a baseline + correctness test through every change.
5. Use sampling profilers (`py-spy`, Scalene) for low-overhead and production profiling; distinguish CPU-bound (compile/vectorize) from I/O-bound (concurrency).

## Connects To
- **Ch 03 (NumPy)**: vectorization is the usual fix for a CPU-bound numeric hot loop.
- **Ch 04 (Compiling)**: Cython/Numba target the hot function profiling reveals.
- **Ch 12 (GPU profiling)**: Nsight/`nvtx` profiling for the GPU side, same discipline.
