# Chapter 4: Compiling Python to Native Code — Cython, Numba, PyPy

## Core Idea
When a hot loop can't be vectorized away, **compile it**. Cython, Numba, and PyPy each turn dynamic Python into native machine code, removing interpreter overhead and (with type information) boxing — often 10–100× on numeric inner loops. The lever is giving the compiler enough type knowledge to generate tight C.

## Frameworks Introduced

- **Cython** (Python → C, with optional static types):
  - Annotate hot variables/functions with C types (`cdef int i`, `cdef double[:] arr` memoryviews) so the loop compiles to C with no Python object overhead.
  - `cpdef` exposes a function to both C and Python; **`cython -a`** ("annotate") generates an HTML report coloring lines by how much Python interaction remains — drive optimization by whitening the hot lines.
  - Disable safety checks on proven-correct loops: `@cython.boundscheck(False)`, `@cython.wraparound(False)`.
  - **Release the GIL** (`with nogil:`) and parallelize with **`prange`** (OpenMP) for true multicore in compiled sections.

- **Numba** (JIT-compile Python functions):
  - `@njit` (= `@jit(nopython=True)`) compiles a function to native code on first call using type inference — **no rewrite**, just a decorator. **`nopython` mode** is the fast path (fails loudly if it can't avoid the Python object layer, which is what you want).
  - `@njit(parallel=True)` + `prange` for multicore; `@vectorize`/`@guvectorize` to build fast ufuncs. Caches compiled code with `cache=True`.
  - Same engine drives **Numba-CUDA** for GPU kernels (later chapters).

- **PyPy** (tracing-JIT alternative interpreter):
  - A drop-in interpreter that JIT-compiles hot loops automatically — speeds up *pure-Python* code with no annotations, but has weaker C-extension compatibility (NumPy works but isn't its strength).

- **Foreign function interfaces**: **`ctypes`** / **`cffi`** call existing C/C++ libraries directly from Python — the fastest path when the fast code already exists in a native library.

## Key Concepts
- **The GIL** (Global Interpreter Lock): one thread executes Python bytecode at a time, so threads don't speed up CPU-bound pure-Python code. Cython `nogil` blocks and Numba's `parallel=True` *release* it for true parallelism; multiprocessing sidesteps it (Ch 5).
- **Type information is the speedup** — both Cython and Numba get their gains from knowing concrete types so they can drop boxing and generate native arithmetic; untyped Cython is barely faster than Python.
- **Numba vs Cython tradeoff**: Numba = zero rewrite, JIT, great for array/numeric functions; Cython = more control, ahead-of-time compiled, integrates C libraries, better for whole modules and non-numeric code.
- **Memoryviews** (`double[:, ::1]`) give Cython typed, bounds-checkable, contiguous access to NumPy buffers without Python indexing overhead.

## Mental Models
- **Reach for Numba first for a numeric hot function** — `@njit` is one line and often matches Cython; escalate to Cython when you need C-library integration, fine control, or `nogil` parallelism in a larger module.
- **Use `cython -a` and whiten the hot lines** — yellow = Python interaction = slow; the goal is white (pure C) in the inner loop.
- **The GIL is why threads don't speed up CPU-bound Python** — release it (`nogil`/Numba `parallel`) or use processes; for I/O-bound work, threads/async are fine (Ch 5).
- **If the fast code already exists in C, just call it** (`cffi`/`ctypes`) rather than reimplementing.

## Code Examples
```python
# Numba: one decorator, native speed, multicore
from numba import njit, prange
@njit(parallel=True, cache=True)
def pairwise_sum(a):
    total = 0.0
    for i in prange(a.shape[0]):          # parallel loop, GIL released
        total += a[i] * a[i]
    return total
```
```cython
# Cython: typed memoryview, no bounds checks, nogil parallel
import cython
from cython.parallel import prange
@cython.boundscheck(False)
@cython.wraparound(False)
def saxpy(double[::1] x, double[::1] y, double a):
    cdef Py_ssize_t i
    with nogil:
        for i in prange(x.shape[0]):       # OpenMP, true multicore
            y[i] = a * x[i] + y[i]
```
- **What it demonstrates**: Numba's zero-rewrite JIT and Cython's typed, GIL-free parallel loop.

## Reference Tables

| Tool | Effort | Best for | Parallelism |
|---|---|---|---|
| Numba `@njit` | one decorator | numeric functions / arrays | `parallel=True`+`prange` |
| Cython | annotate + build | modules, C integration | `nogil`+`prange` |
| PyPy | swap interpreter | pure-Python loops | per-process |
| `cffi`/`ctypes` | bind | calling existing C libs | native |

## Key Takeaways
1. When vectorization isn't enough, compile the hot loop — Numba (`@njit`) for zero-rewrite numeric speedups, Cython for control and C integration.
2. The speedup comes from type information that lets the compiler drop boxing and emit native arithmetic.
3. `cython -a` shows residual Python interaction line-by-line; whiten the inner loop.
4. The GIL blocks thread-based CPU parallelism — release it with `nogil`/Numba `parallel`, or use processes.
5. PyPy accelerates pure Python with no annotations; `cffi`/`ctypes` call existing native libraries directly.

## Connects To
- **Ch 01 (Profiling)**: compile the function profiling identified as hot.
- **Ch 03 (NumPy)**: compile only what vectorization can't express.
- **Ch 05 (Concurrency)**: the GIL and the process-vs-thread decision.
- **Ch 07 (Numba-CUDA)**: the same Numba JIT targeting the GPU.
