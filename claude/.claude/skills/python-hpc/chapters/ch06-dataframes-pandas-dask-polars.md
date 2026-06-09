# Chapter 6: Fast DataFrames — Pandas, Dask & Polars

## Core Idea
DataFrame performance comes from staying in **vectorized columnar operations** and out of per-row Python. Pandas is the baseline; **Polars** rebuilds the model around a lazy, query-optimized, multi-threaded engine; **Dask** scales the Pandas API across cores and machines for larger-than-memory data.

## Frameworks Introduced

- **Pandas, used fast**:
  - **Avoid `.apply()` and `.iterrows()` for numeric work** — they run a Python callable per row; use vectorized column expressions (`df["a"] * df["b"]`), built-in aggregations, and `groupby` which run in C.
  - **`dtype` discipline**: downcast (`int64`→`int32`, `float64`→`float32`) and use **`category`** dtype for low-cardinality strings — large memory and speed wins.
  - Vectorized string ops (`df["s"].str.*`) and `merge`/`join` beat manual loops.

- **Polars** (the modern fast DataFrame):
  - Rust-backed, **multi-threaded** by default, columnar (Arrow) memory.
  - **Lazy API** (`pl.scan_*` → build a query → `.collect()`): a **query optimizer** reorders/prunes/pushes down filters and projections before executing — so it reads/computes only what's needed. The expression API (`pl.col("a") * pl.col("b")`) is vectorized and parallel.
  - Typically faster than Pandas on medium-to-large data with less memory.

- **Dask** (scale the familiar API):
  - **`dask.dataframe`** mirrors the Pandas API but partitions the frame into many Pandas chunks processed in parallel, lazily, across cores or a **cluster** — enabling **larger-than-memory** computation.
  - Builds a task graph executed on `.compute()`; the dashboard shows the graph and progress. Same idea for `dask.array` (chunked NumPy).

## Key Concepts
- **Vectorized vs row-wise**: column operations and `groupby` run in compiled code; `.apply(axis=1)` / `.iterrows()` drop to Python per row — orders of magnitude slower.
- **Lazy + query optimization** (Polars/Dask): defer execution, then optimize the whole plan (predicate/projection pushdown, common-subexpression elimination) so less data is touched.
- **Columnar/Arrow memory**: storing each column contiguously enables SIMD, cache efficiency, and zero-copy interchange between Arrow-based tools.
- **Partitioning** (Dask): the frame is many smaller Pandas frames; choose partition size to balance parallelism against per-task overhead.

## Mental Models
- **If you wrote `.apply()` over rows, you probably lost the vectorization** — reach for column expressions, `groupby`, or vectorized string methods first.
- **Reach for Polars' lazy API on medium/large data** — `scan` + build + `collect` lets the optimizer prune work before it runs; it's commonly several times faster than Pandas with less RAM.
- **Use Dask when data exceeds memory or you need a cluster** — it keeps the Pandas API while partitioning and parallelizing; tune partition size.
- **Fix dtypes early** — `category` for repeated strings and downcast numerics cut memory and speed up every subsequent operation.

## Code Examples
```python
# Pandas: vectorize, don't .apply per row; use category dtype
df["c"] = df["a"] * df["b"]                       # C-speed, not per-row Python
df["label"] = df["label"].astype("category")      # big memory win for low-cardinality

# Polars lazy: optimizer pushes filter/projection down before executing
import polars as pl
result = (
    pl.scan_parquet("big.parquet")                # lazy scan
      .filter(pl.col("value") > 0)
      .group_by("key").agg(pl.col("value").sum())
      .collect()                                   # optimized plan runs here
)

# Dask: larger-than-memory, parallel, Pandas-like
import dask.dataframe as dd
ddf = dd.read_parquet("huge/*.parquet")
out = ddf.groupby("key").value.mean().compute()    # parallel task graph
```
- **What it demonstrates**: vectorized Pandas + category dtype, a Polars lazy optimized query, and Dask's larger-than-memory parallel groupby.

## Reference Tables

| Need | Tool | Why |
|---|---|---|
| in-memory, familiar | Pandas (vectorized) | baseline, huge ecosystem |
| fast medium/large | Polars (lazy) | multi-threaded + query optimizer |
| larger-than-memory / cluster | Dask | partitioned Pandas API |

| Pandas anti-pattern | Fix |
|---|---|
| `.apply(axis=1)` / `.iterrows()` | vectorized column ops / `groupby` |
| `object` strings | `category` dtype |
| `float64`/`int64` everywhere | downcast to 32-bit |

## Key Takeaways
1. Stay vectorized and columnar — avoid `.apply(axis=1)`/`.iterrows()`; use column expressions, `groupby`, and vectorized string ops.
2. Fix dtypes early: `category` for low-cardinality strings, downcast numerics — memory and speed wins.
3. Polars' lazy API + query optimizer (predicate/projection pushdown) is commonly several times faster than Pandas with less RAM.
4. Dask scales the Pandas/NumPy API to larger-than-memory data and clusters via lazy, partitioned task graphs.
5. Columnar/Arrow memory underpins all three's speed and enables zero-copy interchange.

## Connects To
- **Ch 03 (Vectorization)**: the same loop-in-C principle applied to columns.
- **Ch 05 (Clusters)**: Dask's distributed execution model.
- **Ch 10 (RAPIDS/cuDF)**: the GPU DataFrame — same API, on the device.
