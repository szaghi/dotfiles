# Chapter 10: GPU Arrays & DataFrames — CuPy and RAPIDS (cuDF / cuML)

## Core Idea
You usually don't need to write kernels. **CuPy** is a near drop-in NumPy/SciPy for the GPU; **RAPIDS cuDF** is Pandas on the GPU and **cuML** is scikit-learn on the GPU. They give array- and DataFrame-level acceleration with the APIs you already know — the fastest path to GPU speedups for existing code.

## Frameworks Introduced

- **CuPy** (NumPy/SciPy on the GPU):
  - `import cupy as cp`; `cp.ndarray` mirrors `np.ndarray`. Move data with `cp.asarray(np_arr)` (host→device) and `cp.asnumpy(cu_arr)` / `.get()` (device→host).
  - Vectorized **ufuncs**, **reductions**, **scans**, broadcasting, indexing, FFT, linear algebra — all run on the GPU with NumPy syntax. A **memory pool** reuses device allocations to avoid repeated `cudaMalloc`.
  - Custom kernels when needed: `cp.ElementwiseKernel`, `cp.ReductionKernel`, `cp.RawKernel` (raw CUDA C). Interoperates with Numba (`__cuda_array_interface__`) and SciPy (`cupyx.scipy`).

- **RAPIDS cuDF** (Pandas on the GPU):
  - `import cudf`; `cudf.DataFrame` mirrors the Pandas API — `read_csv`/`read_parquet`, `groupby`, `merge`, vectorized column ops, string methods — executed on the GPU over columnar (Arrow) memory.
  - Move between host and device with `cudf.from_pandas(df)` / `gdf.to_pandas()`. Exchanges zero-copy with CuPy and other Arrow tools.

- **RAPIDS cuML** (scikit-learn on the GPU):
  - `import cuml`; estimators mirror the sklearn API (`fit`/`predict`/`transform`) — regression, clustering, dimensionality reduction, tree models — accelerated on the GPU. Drop-in for many sklearn workflows.

- **GPU-agnostic code**: write functions against the array/DataFrame *protocol* (using `cp.get_array_module(x)` or duck typing) so the same code runs on CPU (NumPy/Pandas) or GPU (CuPy/cuDF) depending on the input — one codebase, both backends.

## Key Concepts
- **When CuPy wins**: large arrays with enough arithmetic to amortize the host↔device transfer; tiny arrays lose to transfer overhead. Keep data resident on the GPU across many operations.
- **CuPy vs Numba-CUDA**: CuPy for array-level operations expressible as NumPy (no kernel needed); Numba-CUDA when you need a custom kernel CuPy can't express.
- **dtype discipline**: GPUs strongly prefer **float32** (consumer GPUs run float64 at a small fraction of float32 throughput); mismatched dtypes force conversions. Be deliberate about precision.
- **Don't ping-pong**: every `asnumpy`/`to_pandas` is a PCIe round-trip; keep the whole pipeline on the GPU and transfer only at the boundaries.

## Mental Models
- **Reach for CuPy/cuDF before writing a kernel** — if your computation is expressible in NumPy/Pandas, the GPU drop-in gives most of the speedup for almost none of the effort.
- **Keep data on the GPU end-to-end** — the transfer is the cost; move once at the start, compute many operations, move back once at the end.
- **Prefer float32 and preallocate** — match the GPU's strength and let the memory pool reuse buffers instead of reallocating per op.
- **Write GPU-agnostic functions** with `get_array_module` so the same code serves CPU and GPU callers.

## Code Examples
```python
import cupy as cp
x = cp.asarray(host_array)              # host → device, once
y = cp.exp(-x**2).sum(axis=1)          # NumPy syntax, runs on GPU
result = cp.asnumpy(y)                  # device → host, once at the end

# GPU-agnostic: same function for NumPy or CuPy input
def normalize(a):
    xp = cp.get_array_module(a)        # np for host array, cp for device array
    return (a - a.mean()) / xp.std(a)

import cudf
gdf = cudf.read_parquet("big.parquet")  # Pandas API, on the GPU
out = gdf.groupby("key").value.mean()   # columnar, GPU-accelerated

from cuml.linear_model import LinearRegression
model = LinearRegression().fit(X_gpu, y_gpu)   # sklearn API, on the GPU
```
- **What it demonstrates**: CuPy with one-time transfer, a GPU-agnostic function, cuDF groupby, and a cuML estimator.

## Reference Tables

| CPU library | GPU drop-in | Module |
|---|---|---|
| NumPy / SciPy | CuPy | `cupy`, `cupyx.scipy` |
| Pandas | cuDF | `cudf` |
| scikit-learn | cuML | `cuml` |
| Dask DataFrame | Dask-cuDF | `dask_cudf` |

| When to use | Choice |
|---|---|
| NumPy-expressible array math | CuPy |
| custom kernel needed | Numba-CUDA |
| DataFrame pipeline | cuDF |
| classical ML | cuML |

## Key Takeaways
1. CuPy is a near drop-in NumPy/SciPy for the GPU; cuDF is Pandas-on-GPU and cuML is sklearn-on-GPU — most GPU speedups need no custom kernel.
2. Keep data resident on the GPU end-to-end; transfer (`asarray`/`asnumpy`, `from_pandas`/`to_pandas`) only at the boundaries — it's the dominant cost.
3. CuPy wins on large, arithmetic-heavy arrays; tiny arrays lose to transfer overhead.
4. Prefer float32, preallocate, and let CuPy's memory pool reuse buffers.
5. Write GPU-agnostic code with `get_array_module` so one function serves CPU and GPU backends.

## Connects To
- **Ch 03 (NumPy)**: the CPU API CuPy mirrors.
- **Ch 06 (Pandas/Dask)**: the CPU DataFrame APIs cuDF and Dask-cuDF mirror.
- **Ch 07 (Numba-CUDA)**: drop to a custom kernel when CuPy can't express it.
- **Ch 11 (JAX)**: another array model with autodiff and JIT.
