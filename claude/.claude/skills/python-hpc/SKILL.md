---
name: python-hpc
description: "Practitioner knowledge base for performance engineering in Python across CPU and GPU. Use when profiling or optimizing Python performance: finding bottlenecks (cProfile, line_profiler, memory_profiler, Scalene, py-spy); choosing data structures and cutting RAM (list/dict/set complexity, __slots__, Bloom/trie); vectorizing with NumPy/NumExpr and lazy generators; compiling hot loops (Numba @njit, Cython, PyPy, the GIL, nogil/prange); concurrency (asyncio for I/O, multiprocessing/Joblib for CPU, Dask clusters, mpi4py for distributed-memory MPI); fast DataFrames (Pandas vectorization, Polars lazy/query-optimizer, Dask); writing CUDA kernels in Python (Numba-CUDA: cuda.grid, atomics, syncthreads, device functions); GPU kernel optimization (occupancy, coalescing, shared-memory tiling, bank conflicts, warp divergence); CUDA streams and multi-GPU (Dask-CUDA, JAX pmap); GPU array/DataFrame libraries (CuPy, RAPIDS cuDF/cuML); JAX (jit/grad/vmap/pmap, XLA, autodiff); GPU profiling/debugging (Nsight Systems/Compute, nvtx, CUDA simulator); or applied GPU patterns (stencils/PDEs, N-body, image processing, deep learning). Covers CPU-side performance and GPU acceleration end to end with concrete APIs and code."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, tool (numba/cupy/jax/dask), or chapter (e.g. ch08)]
---

# Python HPC — CPU & GPU Performance
**Scope**: profiling · vectorization · compiling · concurrency · DataFrames · GPU kernels · GPU libraries · JAX · applied patterns | **Chapters**: 13 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core decision rules below.
- **With a topic** — ask about `profiling`, `vectorization`, `Numba`, `coalescing`, `CuPy`, `JAX`, `streams`; I find and read the relevant chapter.
- **With a tool** — ask about `cupy`, `dask`, `numba-cuda`; I load that chapter.
- **With a chapter** — ask for `ch08`; I load that file.

When you ask about something not in the Core section, I read the relevant chapter (and `cheatsheet.md` / `patterns.md` / `glossary.md`). Every chapter carries concrete APIs and code for hands-on work.

## Core Optimization Framework

### The order of operations (CPU)
**Profile → vectorize → compile → parallelize → re-profile.** (Ch 1, 3, 4, 5)
1. **Profile first** — never optimize unmeasured; the bottleneck is rarely where you guess. `%timeit`→`cProfile`→`line_profiler`→Scalene.
2. **Vectorize** numeric loops into NumPy array ops (10–100×); avoid temporaries (`out=`/`NumExpr`).
3. **Compile** what won't vectorize — Numba `@njit` (one decorator) or Cython (types, `nogil`+`prange`).
4. **Parallelize** by what blocks you: `multiprocessing`/Joblib (CPU-bound, own GIL per process) vs `asyncio` (I/O-bound); scale with Dask.
5. **Re-profile** and keep a baseline + test.

### Data & memory (Ch 2, 6)
Pick containers by operation: `set` membership O(1) beats `list` O(n); `dict` for key→value; `__slots__`/packed arrays cut object overhead. DataFrames: stay vectorized and columnar (not `.apply(axis=1)`), use `category` dtype, Polars lazy + query optimizer, Dask for larger-than-memory.

### The GIL (Ch 4, 5)
One thread runs Python bytecode at a time — threads don't speed up CPU-bound pure Python. Release it (`nogil`/Numba `parallel`) or use processes; threads/async are fine for I/O.

### GPU acceleration ladder (Ch 7–13)
1. **Drop-in libraries first** — CuPy (NumPy), cuDF (Pandas), cuML (sklearn): most speedup, least effort. Keep data resident; transfer only at boundaries.
2. **Custom kernels** with Numba-CUDA — `@cuda.jit`, index `cuda.grid(1)`, **guard `if i < n`**, transfer once, atomics for accumulation.
3. **Optimize**: coalesce global access (unit stride per warp) → shared-memory tiling (pad to avoid bank conflicts) → occupancy → avoid warp divergence → overlap with streams + pinned memory.
4. **JAX** for autodiff/ML/JIT — pure functions, compose `jit`/`grad`/`vmap`/`pmap`.
5. **Always synchronize before timing** (warm up + `cuda.synchronize()`/events) — a ">100× speedup" is usually a missing sync. Prefer float32 on consumer GPUs.

### Memory- vs compute-bound (Ch 8, 12)
Profile to classify. Memory-bound → coalesce, shared-memory reuse, fewer bytes. Compute-bound → occupancy, ILP/unroll, intrinsics, tensor cores. Don't guess — Nsight/roofline decides.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-profiling-and-finding-bottlenecks.md) | Profiling & Bottlenecks | cProfile, line_profiler, Scalene, py-spy, the loop |
| [ch02](chapters/ch02-data-structures-and-memory.md) | Data Structures & RAM | list/dict/set complexity, `__slots__`, Bloom/trie |
| [ch03](chapters/ch03-numpy-vectorization-and-generators.md) | NumPy, Vectorization & Generators | ufuncs, broadcasting, NumExpr, in-place, `yield` |
| [ch04](chapters/ch04-compiling-cython-numba-pypy.md) | Compiling to Native | Numba `@njit`, Cython, PyPy, GIL, `nogil`/`prange` |
| [ch05](chapters/ch05-concurrency-multiprocessing-clusters.md) | Concurrency | asyncio, multiprocessing, shared memory, Joblib, clusters |
| [ch06](chapters/ch06-dataframes-pandas-dask-polars.md) | Fast DataFrames | Pandas vectorization, Polars lazy, Dask |
| [ch07](chapters/ch07-gpu-model-and-numba-cuda-kernels.md) | GPU Model & Numba-CUDA Kernels | grid/block/warp, `cuda.grid`, atomics, syncthreads |
| [ch08](chapters/ch08-cuda-optimization-in-python.md) | CUDA Optimization | occupancy, coalescing, shared-memory tiling, divergence |
| [ch09](chapters/ch09-streams-and-multi-gpu.md) | Streams & Multi-GPU | streams, events, pinned memory, Dask-CUDA, pmap |
| [ch10](chapters/ch10-gpu-arrays-and-dataframes-cupy-rapids.md) | GPU Arrays & DataFrames | CuPy, cuDF, cuML, GPU-agnostic code |
| [ch11](chapters/ch11-jax-jit-autodiff-vmap.md) | JAX | jit, grad, vmap, pmap, XLA, pure functions |
| [ch12](chapters/ch12-gpu-profiling-and-debugging.md) | GPU Profiling & Debugging | Nsight Systems/Compute, nvtx, CUDA simulator |
| [ch13](chapters/ch13-applied-gpu-patterns.md) | Applied GPU Patterns | stencils/PDEs, N-body, imaging, deep learning |

## Topic Index

- **asyncio / event loop** → ch05
- **atomics / syncthreads (GPU)** → ch07
- **bank conflicts** → ch08
- **broadcasting** → ch03
- **coalescing** → ch08
- **cProfile / line_profiler / Scalene** → ch01
- **cuDF / cuML / RAPIDS** → ch10
- **CuPy** → ch10
- **Cython** → ch04
- **Dask** → ch05, ch06
- **DataFrames (Pandas/Polars)** → ch06
- **generators / yield / itertools** → ch03
- **GIL** → ch04, ch05
- **GPU agnostic code** → ch10
- **JAX (jit/grad/vmap)** → ch11
- **memory-bound vs compute-bound** → ch08, ch12
- **multiprocessing / Joblib** → ch05
- **mpi4py / distributed MPI (uppercase vs lowercase)** → ch05
- **Nsight profiling** → ch12
- **Numba `@njit`** → ch04
- **Numba-CUDA kernels** → ch07
- **NumPy / vectorization / NumExpr** → ch03
- **occupancy** → ch08
- **`__slots__` / RAM reduction** → ch02
- **streams / events / pinned memory** → ch09
- **shared-memory tiling** → ch08, ch13
- **multi-GPU / pmap / Dask-CUDA** → ch09
- **warp / warp divergence** → ch07, ch08

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete techniques (profile loop, vectorize, compile, GPU drop-in, kernel checklist, tiling, JAX transforms)
- [cheatsheet.md](cheatsheet.md) — decision rules: optimization order, profiler/concurrency/GPU-library pickers, anti-patterns, kernel checklist, timing discipline

---

## Scope & Limits

Covers Python performance engineering end to end — CPU-side performance engineering (profiling, data structures, NumPy/vectorization, compiling, concurrency, DataFrames) and GPU acceleration (Numba-CUDA kernels, kernel optimization, streams/multi-GPU, CuPy/RAPIDS, JAX, profiling, applied patterns) — with concrete APIs and runnable code. It targets the durable techniques and decision rules; specific library APIs evolve, so verify exact signatures against current package docs. For language-level memory-model/standards questions see **iso-cpp-2023** / **iso-c-9899-2024**; for the cross-language parallel/GPU design methodology see **gpu-multithreading**.
