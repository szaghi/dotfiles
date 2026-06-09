# Chapter 7: The GPU Model & Writing CUDA Kernels in Python (Numba-CUDA)

## Core Idea
A GPU is a throughput machine: thousands of threads, organized as a **grid of blocks of threads**, run the same **kernel** in lockstep **warps** of 32 over high-bandwidth device memory. Numba-CUDA lets you write these kernels in pure Python with a decorator — no C, no separate compiler — while keeping the real CUDA execution model.

## Frameworks Introduced

- **The CUDA execution hierarchy** (same as native CUDA):
  - **Thread → block → grid.** Threads in a block share fast on-chip memory and can synchronize; blocks are independent. Hardware runs threads in **warps of 32** (SIMT).
  - Launch config: `kernel[blockspergrid, threadsperblock](args)`. Choose `threadsperblock` as a multiple of 32 (start 128–256); `blockspergrid = ceil(n / threadsperblock)`.

- **Writing a kernel with `@cuda.jit`**:
  - Decorate a Python function; index with `cuda.grid(1)` (the flattened global thread index) or manually `cuda.blockIdx.x * cuda.blockDim.x + cuda.threadIdx.x`.
  - **Always guard** `if i < n:` — the grid is rounded up, so excess threads must not write out of bounds (mismatched grid vs problem size).
  - **Device functions**: `@cuda.jit(device=True)` makes a helper callable *from* kernels (returns a value, no launch config) — the way to make kernels modular.

- **Memory management & data movement**:
  - `d = cuda.to_device(host_array)` uploads; `d.copy_to_host()` downloads; `cuda.device_array(shape, dtype)` allocates on device. Numba also auto-transfers NumPy args, but explicit transfer avoids redundant copies across launches.
  - Host↔device transfer over PCIe is the slow path — move data once, run many kernels, copy back once.

- **Correctness: race conditions & synchronization**:
  - Multiple threads writing the same location race → wrong results. Fix with **`cuda.syncthreads()`** (a block-wide barrier; never call it inside divergent control flow) or **atomics** (`cuda.atomic.add(arr, idx, val)`) for safe concurrent updates (e.g. histograms, reductions).

- **Higher-level kernel definitions**:
  - **`@vectorize([sig], target="cuda")`** builds a GPU ufunc from a scalar function — elementwise ops with no explicit indexing.
  - **`@reduce`** turns a binary function into a GPU reduction.

## Key Concepts
- **SPMD**: every thread runs the same code over its own index — you write the body for one element and launch n of them.
- **Grid-stride loop**: for problems larger than the grid, loop `for i in range(start, n, stride)` with `stride = cuda.gridDim.x * cuda.blockDim.x` so a fixed grid covers any n.
- **Kernels return nothing**: they write into output arrays passed in; there is no return value from a `@cuda.jit` kernel.
- **Supported subset**: kernels run a typed subset of Python (numeric types, arrays, math intrinsics) — no arbitrary Python objects, no exceptions, no list/dict.
- **JIT inspection**: Numba compiles on first call; you can inspect generated PTX and check register/shared-memory usage to understand resource limits.

## Mental Models
- **Write the body for one element, launch n threads** — the index (`cuda.grid(1)`) is your loop variable; the hardware runs the "loop" in parallel.
- **Always guard the index and move data once** — the two most common Numba-CUDA bugs are out-of-bounds writes from an over-rounded grid and redundant host↔device copies per launch.
- **Use atomics for concurrent accumulation, `syncthreads` for block cooperation** — a plain `+=` to a shared location from many threads is a race.
- **Make kernels modular with `device=True` helpers** — same decomposition discipline as ordinary code, compiled inline.

## Code Examples
```python
from numba import cuda
import numpy as np

@cuda.jit(device=True)
def scale(v, a):                          # device function: callable from kernels
    return a * v

@cuda.jit
def saxpy(a, x, y):                        # kernel: writes into y, returns nothing
    i = cuda.grid(1)                       # flattened global thread index
    if i < x.size:                         # GUARD: grid is rounded up
        y[i] = scale(x[i], a) + y[i]

n = 1_000_000
d_x = cuda.to_device(np.arange(n, dtype=np.float32))   # upload once
d_y = cuda.to_device(np.zeros(n, dtype=np.float32))
tpb = 256
bpg = (n + tpb - 1) // tpb                 # ceil division
saxpy[bpg, tpb](2.0, d_x, d_y)             # launch n threads
result = d_y.copy_to_host()                # download once

# Safe concurrent accumulation: atomics (e.g. histogram)
@cuda.jit
def histogram(data, hist):
    i = cuda.grid(1)
    if i < data.size:
        cuda.atomic.add(hist, data[i], 1)  # race-free increment
```
- **What it demonstrates**: a guarded kernel with a device-function helper, explicit one-time transfer, and atomic accumulation.

## Reference Tables

| Numba-CUDA construct | Role |
|---|---|
| `@cuda.jit` | kernel (launched, returns void) |
| `@cuda.jit(device=True)` | device helper (callable from kernels) |
| `cuda.grid(1)` | flattened global thread index |
| `cuda.to_device` / `.copy_to_host()` | upload / download |
| `cuda.syncthreads()` | block barrier |
| `cuda.atomic.add` | race-free update |
| `@vectorize(target="cuda")` | GPU ufunc from a scalar fn |

| Launch param | Rule of thumb |
|---|---|
| `threadsperblock` | multiple of 32, start 128–256 |
| `blockspergrid` | `ceil(n / threadsperblock)` |

## Key Takeaways
1. The GPU runs a grid of blocks of threads in 32-wide warps; write the kernel body for one element and launch n threads.
2. Index with `cuda.grid(1)` and **always guard** `if i < n` — the grid is rounded up.
3. Move data once (`to_device`/`copy_to_host`), run many kernels, copy back once — PCIe transfer is the slow path.
4. Use `cuda.atomic.*` for concurrent accumulation and `cuda.syncthreads()` for block cooperation; a shared `+=` from many threads races.
5. `@cuda.jit(device=True)` helpers make kernels modular; `@vectorize(target="cuda")` builds GPU ufuncs with no explicit indexing.

## Connects To
- **Ch 04 (Numba)**: the same JIT engine, now targeting the GPU.
- **Ch 08 (CUDA optimization)**: occupancy, coalescing, shared memory, warp behavior.
- **Ch 10 (CuPy)**: array-level GPU computing when you don't need a custom kernel.
- **Ch 12 (GPU profiling)**: measuring and debugging these kernels.
