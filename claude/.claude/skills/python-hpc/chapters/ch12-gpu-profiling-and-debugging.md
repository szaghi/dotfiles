# Chapter 12: GPU Profiling & Debugging

## Core Idea
GPU code is hard to profile and debug because execution is **asynchronous**, host and device code are separate, and CPU timers don't see device work. The discipline: **synchronize before timing**, classify the kernel as memory- or compute-bound with Nsight, and emulate on the CPU to debug logic before chasing performance.

## Frameworks Introduced

- **The GPU profiling challenges** (why CPU habits fail):
  - **Asynchronous execution**: kernel launches return immediately; a CPU timer around a launch measures the *launch*, not the kernel. **Always synchronize** (`cuda.synchronize()` or CUDA events) before stopping the clock.
  - **Host/device separation**: CPU profilers (`cProfile`, Scalene) see Python/host time; they don't see inside kernels — you need GPU-aware tools.

- **Identifying bottlenecks**:
  - **Memory-bound vs compute-bound**: the first classification. Memory-bound → fix data movement (coalescing, shared-memory reuse); compute-bound → fix occupancy/ILP/intrinsics.
  - **Coalesced vs non-coalesced access**: a top metric — strided/transposed global access wastes bandwidth.

- **The tool ladder**:
  - **`time`/`timeit`** (with synchronization) — coarse wall-clock of a kernel.
  - **`cProfile`/Scalene** — the host side (Python overhead, transfer calls).
  - **Nsight Systems (`nsys`)** — the **timeline**: visualizes kernels, copies, and streams across the GPU; reveals serialization, gaps, and missed overlap (e.g. transfers not hidden behind compute).
  - **Nsight Compute (`ncu`)** — per-kernel **deep metrics**: occupancy achieved, memory throughput, coalescing efficiency, warp-divergence, stall reasons, roofline. The tool that tells you *why* a kernel is slow and which lever to pull.
  - **`nvtx`** ranges annotate your timeline with named regions for readable Nsight traces.

- **Debugging Numba-CUDA**:
  - **`print` inside kernels** (device-side printf) for quick inspection.
  - **CPU emulation / simulator** (`NUMBA_ENABLE_CUDASIM=1`): run the kernel on the CPU in pure Python to debug *logic* with normal Python tools before worrying about device behavior.
  - **Inspect JIT output**: check generated **PTX** and **resource usage** (registers/shared memory per thread) — register pressure caps occupancy.

## Key Concepts
- **Synchronization is mandatory for timing** — the single most common GPU benchmarking error is measuring an async launch and reporting an impossible speedup.
- **Warm-up runs**: the first kernel call includes JIT compilation; time the steady state, not the cold first call.
- **Achieved vs theoretical occupancy**: Nsight Compute reports what you actually got; a gap points at register/shared-memory limits or block sizing.
- **Stall reasons**: `ncu` attributes stalls (memory dependency, execution dependency, etc.), pointing directly at the fix.

## Mental Models
- **Synchronize, warm up, then time** — the non-negotiable benchmark protocol on the GPU; an untuned timer lies by orders of magnitude.
- **Use Nsight Systems for "where is the time" and Nsight Compute for "why is this kernel slow"** — timeline first (find the bad kernel or missed overlap), then deep metrics (find the lever).
- **Debug logic on the CPU simulator first** — get correctness with `CUDASIM` and `print` before profiling performance; chasing speed on a wrong kernel is wasted effort.
- **Check register/shared usage when occupancy is low** — the PTX/resource report explains the occupancy ceiling.

## Code Examples
```python
from numba import cuda
import numpy as np

# Correct GPU timing: warm up + synchronize
kernel[bpg, tpb](d)                     # warm-up (triggers JIT)
cuda.synchronize()
start, end = cuda.event(), cuda.event()
start.record()
kernel[bpg, tpb](d)
end.record(); end.synchronize()         # MUST sync before reading
ms = start.elapsed_time(end)

# Annotate the timeline for Nsight
#   import nvtx
#   with nvtx.annotate("stage1", color="green"): kernel[bpg, tpb](d)
# Profile:  nsys profile python app.py        (timeline)
#           ncu  --set full python app.py     (per-kernel metrics)

# Debug logic on the CPU: NUMBA_ENABLE_CUDASIM=1 python app.py
@cuda.jit
def k(a):
    i = cuda.grid(1)
    if i < a.size:
        print(i, a[i])                  # device-side print for inspection
```
- **What it demonstrates**: warm-up + event timing with synchronization, NVTX annotation, CUDA-sim debugging, and device print.

## Reference Tables

| Tool | Answers | Level |
|---|---|---|
| `timeit` + sync | how long (coarse) | wall clock |
| cProfile / Scalene | host/Python overhead | CPU |
| Nsight Systems (`nsys`) | where (timeline, overlap) | system |
| Nsight Compute (`ncu`) | why a kernel is slow | per-kernel metrics |
| CUDASIM + `print` | is the logic correct | debug |

| Symptom | Likely cause | Fix |
|---|---|---|
| "impossible" speedup | no sync before timing | `synchronize`/events |
| low achieved occupancy | register/shared pressure | tune block size, fewer registers |
| low memory throughput | non-coalesced access | unit-stride layout |
| gaps in timeline | missed overlap | streams + pinned memory |

## Key Takeaways
1. GPU execution is async — synchronize (and warm up) before timing, or the numbers are meaningless.
2. Classify memory-bound vs compute-bound first; check coalescing and occupancy.
3. Nsight Systems shows the timeline (where time goes, missed overlap); Nsight Compute shows per-kernel metrics (why a kernel is slow).
4. Debug kernel *logic* on the CPU simulator (`NUMBA_ENABLE_CUDASIM`) with `print` before profiling performance.
5. Inspect generated PTX and register/shared-memory usage to understand occupancy ceilings.

## Connects To
- **Ch 08 (Optimization)**: the metrics here drive the coalescing/occupancy/shared-memory fixes.
- **Ch 09 (Streams)**: Nsight Systems reveals whether overlap is actually happening.
- **Ch 01 (CPU profiling)**: same measure-first discipline, GPU-aware tools.
