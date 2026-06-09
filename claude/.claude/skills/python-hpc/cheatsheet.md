# Python HPC Cheatsheet — Decision Rules & Tells

## The optimization order (always)
1. **Profile** — `%timeit` → `cProfile` → `line_profiler` → Scalene. Never optimize unmeasured.
2. **Vectorize** — replace numeric Python loops with NumPy array ops.
3. **Compile** — Numba `@njit` / Cython for loops you can't vectorize.
4. **Parallelize** — `multiprocessing` (CPU) / `asyncio` (I/O); scale with Dask.
5. **Offload to GPU** — CuPy/cuDF drop-in, then Numba-CUDA kernels.
6. **Always re-profile** and keep a baseline + test.

## Profiler picker
| Question | Tool |
|---|---|
| quick A/B | `%timeit` |
| which function | `cProfile` + SnakeViz |
| which line | `line_profiler` |
| memory | `memory_profiler` / Scalene |
| CPU+mem, py vs native | Scalene |
| running/production | py-spy |
| GPU timeline | Nsight Systems (`nsys`) |
| why kernel slow | Nsight Compute (`ncu`) |

## Concurrency picker (the GIL question)
| Workload | Use |
|---|---|
| CPU-bound | `multiprocessing` / Joblib / Numba `parallel` |
| I/O-bound, high concurrency | `asyncio` |
| I/O-bound, simple | threads |
| larger-than-memory / cluster | Dask |
→ Threads do NOT speed up CPU-bound pure Python (GIL).

## Speedup picker
| Have | Reach for |
|---|---|
| numeric loop | vectorize (NumPy) |
| loop you can't vectorize | Numba `@njit` |
| need C lib / module control | Cython |
| pure-Python loops | PyPy |
| existing C library | `cffi`/`ctypes` |

## GPU library picker
| CPU code | GPU drop-in |
|---|---|
| NumPy/SciPy | CuPy |
| Pandas | cuDF |
| scikit-learn | cuML |
| Dask DF | Dask-cuDF |
| custom kernel | Numba-CUDA |
| autodiff / ML / JIT | JAX |

## NumPy / DataFrame anti-patterns
| Smell | Fix |
|---|---|
| `for` over array elements | vectorize |
| `a*b + c*d` on big arrays | `NumExpr` / `out=` |
| `x in long_list` | `x in set` |
| `.apply(axis=1)` / `.iterrows()` | column ops / `groupby` |
| `object` string column | `category` dtype |
| many small objects | `__slots__` / arrays |

## Numba-CUDA kernel checklist
- Index: `i = cuda.grid(1)`; **guard `if i < n`** (grid is rounded up).
- Transfer once: `cuda.to_device` / `.copy_to_host()` — not per launch.
- `threadsperblock` multiple of 32 (128–256); `bpg = ceil(n/tpb)`.
- Concurrent accumulation → `cuda.atomic.add`; block cooperation → `cuda.syncthreads()`.
- Kernels return nothing — write into output arrays.

## GPU optimization order
1. **Coalesce** global access (unit stride per warp, SoA).
2. **Shared-memory tile** reuse-heavy kernels; pad `[T][T+1]`.
3. **Occupancy** — tune block size vs register/shared limits.
4. Avoid **warp divergence** (warp-uniform branches).
5. **Overlap** transfer + compute via streams + pinned memory.

## GPU timing (non-negotiable)
- **Warm up** (first call includes JIT), then `cuda.synchronize()` / events before stopping the clock.
- A ">100× speedup" usually means a missing synchronization.
- Prefer **float32** (consumer GPUs run float64 at a small fraction of float32).
- Keep data on the GPU; transfer only at pipeline boundaries.

## JAX rules
- Pure functions, immutable arrays (`x.at[i].set(v)`).
- Compose: `jit(grad(vmap(f)))`. `jit` = biggest win (fusion).
- Value-dependent control flow → `lax.cond`/`scan`, not Python `if`/`for`.
- Explicit PRNG keys (`split` per use).

## Memory-bound vs compute-bound
- Memory-bound → coalesce, shared-memory reuse, fewer bytes.
- Compute-bound → occupancy, ILP/unroll, intrinsics, tensor cores.
- Profile to classify (Nsight Compute / roofline) — don't guess.
