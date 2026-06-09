# Patterns & Techniques — Python HPC

## Profile-first optimization loop
**When to use**: any performance work.
**How**: baseline + test → profile (`%timeit`→`cProfile`→`line_profiler`→Scalene) → change one thing → re-profile → keep only measured wins.
**Trade-offs**: the bottleneck is rarely where you guess; this prevents wasted effort and silent regressions.

## Vectorize the hot loop
**When to use**: a Python `for` loop over numbers shows up in the profile.
**How**: express as NumPy array ops / ufuncs / broadcasting so the loop runs compiled over contiguous memory.
**Trade-offs**: 10–100× typical; watch temporary arrays (use `out=`/in-place/`NumExpr` for large data).

## Compile what you can't vectorize
**When to use**: a numeric hot loop that isn't a clean array op.
**How**: `@njit` (Numba) first — one decorator; escalate to Cython (typed memoryviews, `cython -a`, `nogil`+`prange`) for C integration/control.
**Trade-offs**: type info is the speedup; the GIL blocks thread parallelism unless released.

## Pick concurrency by what blocks you
**When to use**: parallelizing.
**How**: CPU-bound → `multiprocessing`/Joblib (own GIL per process); I/O-bound → `asyncio`/threads.
**Trade-offs**: wrong model = zero speedup (threads for CPU work hit the GIL). Chunk tasks; share big arrays via shared memory, never pickle them.

## Stay columnar and lazy for DataFrames
**When to use**: DataFrame pipelines.
**How**: vectorized column ops (not `.apply(axis=1)`); `category` dtype + downcast; Polars lazy `scan`→`collect` for the optimizer; Dask for larger-than-memory/cluster.
**Trade-offs**: row-wise `.apply` loses vectorization by orders of magnitude.

## GPU drop-in before custom kernel
**When to use**: GPU-accelerating existing NumPy/Pandas/sklearn code.
**How**: CuPy (NumPy), cuDF (Pandas), cuML (sklearn) — same API on the device; keep data resident, transfer only at boundaries.
**Trade-offs**: most speedup for least effort; tiny arrays lose to transfer overhead. Drop to Numba-CUDA only for custom math.

## Write a CUDA kernel in Python
**When to use**: custom per-element/stencil computation.
**How**: `@cuda.jit`; index with `cuda.grid(1)`; **guard `if i < n`**; `to_device`/`copy_to_host` once; atomics for concurrent accumulation; `device=True` helpers for modularity.
**Trade-offs**: the two classic bugs are unguarded out-of-bounds writes and per-launch redundant transfers.

## Shared-memory tiling
**When to use**: GPU kernels with data reuse (stencils, matmul, convolution).
**How**: load a tile into `cuda.shared.array`, `syncthreads()`, compute from shared memory; pad `[T][T+1]` to avoid bank conflicts; coalesce the global loads.
**Trade-offs**: highest-leverage GPU optimization for reuse-heavy kernels; no benefit for pure elementwise ops.

## Overlap transfer with compute
**When to use**: GPU pipelines moving data each step / batches of inputs.
**How**: chunk the data; use multiple streams + pinned memory to overlap H2D, kernel, D2H across chunks.
**Trade-offs**: hides PCIe behind work; needs pinned memory and independent chunks.

## JAX functional transformations
**When to use**: optimization, ML, autodiff, or batched math on GPU/TPU.
**How**: write pure functions on immutable arrays; compose `jit` (fuse/compile), `grad` (autodiff), `vmap` (batch), `pmap` (multi-device); explicit PRNG keys.
**Trade-offs**: purity required; value-dependent control flow needs `lax.cond`/`scan`.

## Synchronized GPU benchmarking
**When to use**: every GPU timing.
**How**: warm up (trigger JIT), `cuda.synchronize()` / events before stopping the clock, repeat, report variance.
**Trade-offs**: skipping sync reports impossible speedups — the #1 GPU benchmarking error.

## Reduce RAM
**When to use**: memory-bound or many-small-objects code.
**How**: `__slots__`, packed arrays, `category` dtype, generators for streaming; Bloom/trie for huge approximate sets.
**Trade-offs**: trades flexibility/exactness for large memory savings.
