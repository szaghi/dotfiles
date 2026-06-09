# Chapter 13: Cooperative Groups

## Core Idea
Cooperative Groups (CG) is a programming-model extension that lets you name and operate on **groups of collaborating threads** at any granularity — a warp tile, a block, a cluster, the whole grid — instead of relying on the single coarse `__syncthreads()` primitive. A group is represented by a **handle** that knows each thread's rank, the size, and the dimensions; from that handle you get safe, future-proof synchronization (`sync`, barriers) and tuned collective primitives (`reduce`, scans, `invoke_one`, `memcpy_async`). It replaces the brittle hand-written warp/grid-sync hacks performance programmers used to write.

## Frameworks Introduced

- **Group handle + member functions**: every group exposes `thread_rank()`, `num_threads()`, `thread_index()` (3-D), `dim_threads()`. The handle is how participating threads learn their position and size.
  - When to use: anytime you need finer-than-block or coarser-than-block collaboration.
- **Implicit (groupless) groups**: created automatically from the launch config — `this_thread_block()`, `this_grid()`, `coalesced_threads()` (active threads in a warp), `this_cluster()` (CC ≥ 9.0).
  - How: grab them as early as possible, before any branching; pass handles by reference.
- **Partitioning** (creating explicit subgroups): `tiled_partition<N>` (fixed-size 1-D tiles), `labeled_partition` (subgroups by integral label), `binary_partition` (label 0/1).
  - Why: decompose a parent group into the exact warp-tile or predicate-group your algorithm needs.
- **Collectives**: `reduce`, `inclusive_scan`/`exclusive_scan`, `invoke_one`/`invoke_one_broadcast`, `memcpy_async`/`wait`. All require *all* threads in the named group to participate.
- **Large-scale groups**: grid-spanning groups; grid sync requires the `cudaLaunchCooperativeKernel` launch API. (Multi-device CG removed as of CUDA 13.)

## Key Concepts
- **Group creation is collective**: partitioning requires *all* threads of the parent to call it. Doing so in a branch not all threads reach → deadlock or corruption.
- **Handles have no default constructor**: initialize at declaration, pass by reference, avoid copy-construction.
- **`sync()` semantics** match `__syncthreads()`: all pre-sync memory ops are visible post-sync, and no thread proceeds until all arrive.
- **CG barriers vs `cuda::barrier`**: CG barriers are auto-initialized; every thread must `barrier_arrive` then `barrier_wait` once per phase; `barrier_arrive` returns a single-use `arrival_token`.
- **Collective contract**: all threads must pass the *same* argument values per collective call unless the API explicitly allows otherwise — else UB.
- **`reduce` hardware acceleration**: CC ≥ 8.0, 4-byte types only; software fallback otherwise.

## Mental Models
- Think of a group handle as **"the `this` pointer of a thread collective"** — it carries identity (rank), size, and shape, and every collective method dispatches through it.
- Think of partitioning as **structured-programming for parallelism**: instead of computing warp masks by hand, you carve the parent group into named children whose membership the compiler/runtime tracks.
- Think of `barrier_arrive`/`barrier_wait` as a **split fence**: arrive signals "I'm done producing," wait blocks on "everyone arrived" — the gap between them is free latency-hiding compute.

## Anti-patterns
- **Partitioning (or creating a group) inside a divergent branch**: collective op without full participation → deadlock/corruption.
- **Using a collective op between `barrier_arrive` and `barrier_wait`**: forbidden.
- **Assuming `barrier_wait` means everyone called `barrier_wait`**: it only guarantees everyone called `barrier_arrive`.
- **Using grid sync without `cudaLaunchCooperativeKernel`**: grid-spanning sync is unavailable on a normal launch.
- **Reusing a stale `arrival_token`**: it's consumed by `barrier_wait` and invalid afterward.
- **Reaching for CG when you mean a full block/warp**: prefer `__syncthreads()`/`__syncwarp()` for whole-block/warp sync — better performance.

## Reference Tables

**Implicit groups**

| Accessor | Scope | Notes |
|---|---|---|
| `this_thread_block()` | all threads in current block | |
| `this_grid()` | all threads in grid | grid sync needs cooperative launch |
| `coalesced_threads()` | currently active warp threads | membership not guaranteed/stable |
| `this_cluster()` | threads in current cluster | CC ≥ 9.0; 1×1×1 if non-cluster grid |

**Partitioning ops**

| Op | Result |
|---|---|
| `tiled_partition<N>(parent)` | fixed-size N 1-D row-major tiles (`thread_block_tile<N>`) |
| `labeled_partition(parent, label)` | 1-D subgroups grouped by integral label |
| `binary_partition(parent, pred)` | specialized labeled partition, label 0 or 1 |

**Reduction operators** (`cg::reduce`): `plus`, `less` (min), `greater` (max), `bit_and`, `bit_or`, `bit_xor`.

**Cooperative launch query**: `cudaDeviceGetAttribute(&v, cudaDevAttrCooperativeLaunch, dev)` — CC ≥ 6.0; Linux w/o MPS, Linux+MPS on CC ≥ 7.0, or latest Windows.

## Worked Example
A block-wide sum reduction — the canonical CG collective, showing handle acquisition, the collective call, and rank-0 writing the result:

```cpp
namespace cg = cooperative_groups;

cg::thread_block my_group = cg::this_thread_block();

int val = data[threadIdx.x];

int sum = cg::reduce(my_group, val, cg::plus<int>());

// Store the result from the reduction
if (my_group.thread_rank() == 0) {
   result[blockIdx.x] = sum;
}
```
- **What it demonstrates**: grab the implicit block handle, every thread feeds one value into the collective `reduce`, and `thread_rank()` selects the single writer. On CC ≥ 8.0 the 4-byte `int` reduction is hardware-accelerated.

## Key Takeaways
1. A group handle (rank/size/shape) is the unit of all CG operations — create it early, pass by reference, never copy-construct.
2. Implicit groups (`this_thread_block`, `this_grid`, `coalesced_threads`, `this_cluster`) come free from the launch; explicit groups come from `tiled_/labeled_/binary_partition`.
3. Every collective (sync, barrier, reduce, scan, memcpy_async) needs *full* participation with matching arguments — partition/call outside divergent branches only.
4. CG barriers are split (`barrier_arrive` → token → `barrier_wait`); the wait guarantees all *arrived*, not all *waited*.
5. `reduce`/scans are HW-accelerated for 4-byte types on CC ≥ 8.0.
6. Grid-wide sync requires `cudaLaunchCooperativeKernel`; multi-device CG is gone as of CUDA 13.
7. For whole-block/warp sync, plain `__syncthreads()`/`__syncwarp()` is faster than CG.

## Connects To
- **Ch 1 (SIMT, warps, clusters)**: CG names the warp/block/cluster/grid hierarchy the SIMT model already defines.
- **Ch 15 (Async barriers & pipelines)**: CG barriers parallel `cuda::barrier`; `cg::memcpy_async` is one of the LDGSTS-driving APIs.
- **CUDA Graphs / streams**: cooperative kernels launched via `cudaLaunchCooperativeKernel` integrate with stream ordering.
- **`mbarrier` / `cuda::ptx`**: CG barrier API is a higher-level face on the same shared-memory barrier hardware (Ch 15).
