# Glossary — Python HPC (CPU & GPU)

**amortized cost** — average cost per operation over a sequence; list append is amortized O(1) (Ch 2).
**arithmetic intensity** — FLOPs per byte of memory traffic; locates a kernel on the roofline (Ch 8).
**asyncio** — cooperative single-thread concurrency for I/O-bound work via an event loop (Ch 5).
**atomics** — race-free concurrent updates (`cuda.atomic.add`) for histograms/reductions (Ch 7).
**autodiff** — automatic differentiation; `jax.grad` gives exact gradients (Ch 11).
**bank conflict** — threads in a warp hitting different addresses in one shared-memory bank, serialized (Ch 8).
**BLAS** — optimized linear-algebra library backing `@`/`np.dot` (Ch 3).
**Bloom filter** — probabilistic set membership in tiny space, no false negatives (Ch 2).
**broadcasting** — applying an op across compatible shapes without copying (Ch 3).
**coalescing** — consecutive threads accessing consecutive global addresses → one transaction (Ch 8).
**cProfile** — built-in function-level deterministic CPU profiler (Ch 1).
**cuDF** — RAPIDS Pandas-on-GPU DataFrame (Ch 10).
**cuML** — RAPIDS scikit-learn-on-GPU (Ch 10).
**CuPy** — near drop-in NumPy/SciPy for the GPU (Ch 10).
**`@cuda.jit`** — Numba decorator compiling a Python function to a CUDA kernel (Ch 7).
**`cuda.grid(1)`** — flattened global thread index in a kernel (Ch 7).
**Cython** — Python→C compiler with optional static types and `nogil` parallelism (Ch 4).
**Dask** — partitioned, lazy, parallel Pandas/NumPy API for larger-than-memory/cluster (Ch 5, 6).
**Dask-CUDA** — Dask cluster of GPU workers (Ch 9).
**device function** — `@cuda.jit(device=True)` helper callable from kernels (Ch 7).
**event** — `cuda.event` for accurate async-safe GPU timing and cross-stream sync (Ch 9, 12).
**event loop** — the asyncio scheduler interleaving coroutines (Ch 5).
**GIL** — Global Interpreter Lock; one thread runs Python bytecode at a time (Ch 4, 5).
**grid-stride loop** — fixed grid covering any n via a strided loop (Ch 7).
**JAX** — NumPy + composable `jit`/`grad`/`vmap`/`pmap` transformations (Ch 11).
**`jit` (JAX)** — compile a pure function to a fused XLA kernel (Ch 11).
**Joblib** — simple embarrassingly-parallel CPU loops with memmap handling (Ch 5).
**line_profiler** — line-by-line CPU profiler (`@profile` + kernprof) (Ch 1).
**memory pool (CuPy)** — reuses device allocations to avoid repeated cudaMalloc (Ch 10).
**memory-bound** — limited by data movement; fix with reuse/coalescing (Ch 8, 12).
**memoryview (Cython)** — typed, contiguous view of a NumPy buffer (Ch 4).
**multiprocessing** — separate processes (own GIL each) for CPU-bound parallelism (Ch 5).
**Nsight Compute (`ncu`)** — per-kernel deep GPU metrics (Ch 12).
**Nsight Systems (`nsys`)** — GPU timeline profiler (Ch 12).
**Numba** — JIT compiler for Python functions (`@njit`), CPU and CUDA (Ch 4, 7).
**NumExpr** — chunked, fused, threaded evaluation of array expressions (Ch 3).
**occupancy** — resident warps ÷ SM maximum; hides GPU memory latency (Ch 8).
**pinned memory** — page-locked host memory enabling async DMA / overlap (Ch 9).
**Polars** — Rust-backed multi-threaded lazy DataFrame with a query optimizer (Ch 6).
**`pmap`** — JAX parallelization across devices (Ch 9, 11).
**`prange`** — parallel loop in Numba/Cython (releases GIL) (Ch 4).
**pure function** — no side effects/mutation; required by JAX transformations (Ch 11).
**py-spy** — sampling profiler attaching to a running process (Ch 1).
**PyPy** — tracing-JIT alternative Python interpreter (Ch 4).
**query optimizer** — reorders/prunes a lazy DataFrame plan before execution (Ch 6).
**race condition** — wrong result from unsynchronized concurrent access (Ch 5, 7).
**RAPIDS** — GPU data-science suite (cuDF, cuML, …) (Ch 10).
**roofline** — model classifying a kernel memory- vs compute-bound (Ch 8, 12).
**Scalene** — combined CPU+memory profiler separating Python vs native (Ch 1).
**shared memory** — fast on-chip per-block GPU scratchpad; basis of tiling (Ch 8).
**`__slots__`** — drops per-instance `__dict__` to cut object memory (Ch 2).
**SPMD** — single program, many data-indexed instances (GPU kernels) (Ch 7).
**stream** — ordered GPU command queue; different streams overlap (Ch 9).
**`cuda.syncthreads()`** — block-wide barrier (Ch 7, 8).
**tiling** — staging a data tile into shared memory for reuse (Ch 8, 13).
**ufunc** — vectorized elementwise function (NumPy/CuPy) (Ch 3, 10).
**vectorization** — replacing Python loops with compiled array operations (Ch 3).
**`vmap`** — JAX automatic vectorization over a batch axis (Ch 11).
**warp** — group of 32 GPU threads executing in lockstep (SIMT) (Ch 7, 8).
**warp divergence** — threads in a warp taking different branches → serialized (Ch 8).
**XLA** — the compiler JAX `jit` targets; fuses operations (Ch 11).
**`yield`** — makes a generator for lazy, O(1)-memory iteration (Ch 3).
