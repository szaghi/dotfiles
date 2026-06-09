# Chapter 3: NumPy, Vectorization & Lazy Iteration

## Core Idea
Numeric Python is fast only when the inner loop runs in **compiled, vectorized** code over **contiguous memory**, not in the Python interpreter. NumPy provides packed arrays + vectorized ufuncs that hand the loop to BLAS/SIMD; generators provide the complementary lever — process data lazily so it never has to be materialized at all.

## Frameworks Introduced

- **Vectorization** (replace Python loops with array ops):
  - A Python `for` loop over a million elements pays interpreter overhead per element; the NumPy equivalent (`a + b`, `np.sin(a)`, `a @ b`) runs one compiled loop over contiguous memory, often SIMD-vectorized and BLAS-backed.
  - **Broadcasting** applies an operation across mismatched-but-compatible shapes without copying — `a[:, None] * b[None, :]` forms an outer product with no explicit loop.

- **Memory-aware array work** (the hidden cost is allocation and cache):
  - **In-place operations** (`a += b`, `np.add(a, b, out=a)`) avoid allocating a new array each step — large temporaries cause **memory allocation** churn and **cache misses**.
  - **Contiguity & strides**: row-major (C-order) vs column-major (F-order) determines cache behavior; iterate along the contiguous axis. A non-contiguous view forces gather/copy.
  - **`NumExpr`** — evaluates array expressions in chunks that fit cache, fusing operations and using threads, avoiding the big intermediate temporaries a naive `a*b + c*d` allocates.

- **Lazy iteration with generators** (avoid materialization):
  - **`yield`** turns a function into a generator producing items one at a time — O(1) memory instead of building a full list. **`itertools`** composes lazy pipelines (`islice`, `chain`, `groupby`, `count`).
  - Single-pass streaming: transform → filter → reduce without ever holding the whole sequence.

## Key Concepts
- **ufunc**: a NumPy universal function (`np.add`, `np.exp`) that loops in C with optional `out=` and broadcasting — the unit of vectorized work.
- **Temporary arrays**: `d = a*b + c*d` allocates intermediates for `a*b` and `c*d`; `NumExpr`/in-place ops or fusing avoid them.
- **BLAS**: `@` / `np.dot` dispatch to an optimized BLAS (OpenBLAS/MKL) — multi-threaded, blocked, SIMD; never hand-roll matrix multiply.
- **Strides & views**: slicing returns a view (no copy) with adjusted strides; `np.ascontiguousarray` forces a contiguous copy when needed.
- **Generator vs list**: a generator has O(1) memory footprint and is single-pass; a list is O(n) memory and re-iterable.

## Mental Models
- **If you're writing a Python `for` loop over numbers, you're probably leaving 10–100× on the table** — express it as array operations so the loop runs in C.
- **Watch the temporaries** — chained array expressions allocate intermediate arrays; use `out=`, in-place ops, or `NumExpr` for large arrays to stay in cache and cut allocation.
- **Iterate along the contiguous axis** — row-major arrays should be looped/reduced along the last axis to hit cache lines in order.
- **Use generators to bound memory** — when you only need one pass, `yield` and `itertools` keep memory flat regardless of input size.

## Code Examples
```python
import numpy as np
# Vectorized + broadcast: outer product, no Python loop
result = a[:, None] * b[None, :]            # one compiled loop, no explicit iteration

# Avoid temporaries: in-place and out=
np.multiply(a, b, out=tmp)                  # no new allocation
tmp += c                                    # in-place

# NumExpr fuses and chunks to cache, multi-threaded
import numexpr as ne
d = ne.evaluate("a*b + c*d")                # no big intermediates

# Lazy pipeline: O(1) memory, single pass
def process(lines):
    for line in lines:                      # generator: never materializes
        if valid(line):
            yield transform(line)
total = sum(x.value for x in process(stream))
```
- **What it demonstrates**: vectorization + broadcasting, temporary-free array math, and a lazy generator pipeline.

## Reference Tables

| Pattern | Slow | Fast |
|---|---|---|
| element math | Python `for` loop | `a + b`, ufuncs |
| outer/combine | nested loops | broadcasting |
| chained expr (large) | `a*b + c*d` (temporaries) | `NumExpr` / `out=` |
| matrix multiply | hand loop | `@` / BLAS |
| big sequence, one pass | build a list | generator / `itertools` |

## Key Takeaways
1. Vectorize numeric loops into NumPy array ops so the inner loop runs compiled over contiguous memory.
2. Broadcasting expresses cross-shape operations without explicit loops or copies.
3. Eliminate temporary arrays with in-place ops, `out=`, or `NumExpr` to stay in cache and cut allocation.
4. Dispatch matrix work to BLAS (`@`/`np.dot`); iterate along the contiguous axis for cache locality.
5. Use generators + `itertools` for single-pass, O(1)-memory streaming over large data.

## Connects To
- **Ch 02 (Memory)**: packed arrays vs list-of-objects overhead.
- **Ch 04 (Compiling)**: when vectorization isn't enough, Cython/Numba compile the loop.
- **Ch 10 (CuPy)**: the GPU drop-in for NumPy — same vectorized model on the device.
