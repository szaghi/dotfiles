# Chapter 12: Debugging & Profiling HPC Applications

## Core Idea
Correctness comes before speed, and speed comes from measurement, not intuition. The HPC toolchain provides **GDB** for interactive debugging, **Valgrind/sanitizers** for memory and race errors, **perf/gprof/Cachegrind** for CPU profiling, and **Nsight** for GPU kernels. The discipline: reproduce, instrument, locate the dominant cost, fix, re-measure.

## Frameworks Introduced

- **GDB** (interactive debugging):
  - `break file:line` / `break func` (breakpoints), `run`, `step`/`next`/`continue`, `backtrace` (the call stack at a crash), `print`/`watch` (inspect/watch variables), `frame`. Load a **core dump** (`gdb prog core`) to debug a segfault post-mortem.
  - Compile with `-g` (debug symbols) and ideally `-O0` so line numbers and variables map cleanly.

- **Memory & thread error detection**:
  - **Valgrind/Memcheck** — detects leaks, use-after-free, uninitialized reads, out-of-bounds (slow but thorough, no recompile).
  - **Sanitizers** (compile with `-fsanitize=`): **AddressSanitizer** (out-of-bounds, use-after-free — fast), **ThreadSanitizer** (data races), **UBSan** (undefined behavior). Faster than Valgrind; the first thing to run on a crash or a parallel bug.

- **CPU profiling**:
  - **`perf`** — low-overhead sampling profiler (`perf record`/`perf report`); shows hot functions and hardware counters (cache misses, branch mispredicts). The production workhorse.
  - **`gprof`** — instrumented call-graph profiler (needs `-pg`).
  - **Cachegrind** (Valgrind) — simulates the cache hierarchy to find cache-miss hotspots and analyze locality.

- **GPU / compute-kernel profiling**:
  - **Nsight Systems** — the timeline (kernels, transfers, streams; reveals serialization and missed overlap); **Nsight Compute** — per-kernel deep metrics (occupancy, memory throughput, coalescing, stall reasons). (`nvprof` is the legacy tool.)

## Key Concepts
- **Reproduce first**: a bug you can't reproduce deterministically can't be fixed reliably — minimize the input, fix the random seed, reduce thread/rank count.
- **Sanitizers before Valgrind**: ASan/TSan are fast enough to run routinely; Valgrind is the thorough fallback.
- **Sampling vs instrumenting**: `perf` samples (low overhead, production-safe); `gprof`/Valgrind instrument (accurate, high overhead).
- **GPU async timing**: kernel launches are asynchronous — synchronize before timing; Nsight Systems shows whether overlap actually happens.
- **Parallel debugging**: data races are timing-dependent — ThreadSanitizer finds them deterministically; MPI bugs (deadlocks) need run-with-fewer-ranks and message tracing.

## Mental Models
- **Reproduce → instrument → locate → fix → re-measure** — the diagnosis loop; never optimize or "fix" without a reproduction and a measurement.
- **Run sanitizers on every crash and every parallel bug** — ASan for memory, TSan for races; they turn heisenbugs into deterministic reports.
- **Profile to find the dominant cost, then optimize only that** — Amdahl: speeding up 5% of runtime caps the gain at 5%. `perf` first, then drill in.
- **For GPUs, timeline (Nsight Systems) before metrics (Nsight Compute)** — find the slow kernel or missed overlap first, then the per-kernel lever.

## Code Examples
```bash
# Debug a segfault post-mortem
g++ -g -O0 app.cpp -o app
gdb ./app core          # then: backtrace, frame N, print var

# Sanitizers: fast memory + race detection
g++ -g -fsanitize=address app.cpp -o app && ./app       # out-of-bounds, leaks
g++ -g -fsanitize=thread  app.cpp -o app && ./app       # data races

# CPU profiling (sampling, low overhead)
perf record -g ./app && perf report

# Cache analysis
valgrind --tool=cachegrind ./app

# GPU profiling
nsys profile ./app          # timeline
ncu --set full ./app        # per-kernel metrics
```
- **What it demonstrates**: post-mortem GDB, the two key sanitizers, `perf` sampling, Cachegrind, and the Nsight pair.

## Reference Tables

| Tool | Finds | Overhead |
|---|---|---|
| GDB | crashes, logic (interactive) | — |
| AddressSanitizer | OOB, use-after-free, leaks | low |
| ThreadSanitizer | data races | medium |
| Valgrind/Memcheck | memory errors (thorough) | high |
| `perf` | hot functions, HW counters | low (sampling) |
| Cachegrind | cache misses, locality | high |
| Nsight Systems/Compute | GPU timeline / kernel metrics | medium |

## Key Takeaways
1. Reproduce before fixing; minimize the input and reduce thread/rank count to make bugs deterministic.
2. Run sanitizers routinely — ASan for memory errors, TSan for data races, UBSan for undefined behavior; Valgrind is the thorough fallback.
3. Compile with `-g` (and `-O0` for clean debugging); use GDB + core dumps for post-mortem crash analysis.
4. Profile with `perf` (low-overhead sampling) to find the dominant cost; Cachegrind for cache/locality analysis.
5. For GPUs, synchronize before timing; use Nsight Systems for the timeline, Nsight Compute for per-kernel metrics.

## Connects To
- **Ch 01 (Toolchain)**: `-g`/optimization flags these tools rely on.
- **Ch 04 (Parallel patterns)**: ThreadSanitizer catches the data races there.
- **Ch 09 (CUDA)**: Nsight + the synchronized GPU-timing discipline.
- **Ch 05 (Hardware)**: Cachegrind/perf connect to the memory-hierarchy model.
