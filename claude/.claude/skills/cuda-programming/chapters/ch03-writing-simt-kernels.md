# Chapter 3: Writing SIMT Kernels

## Core Idea
A SIMT kernel is ordinary per-thread code, but performance is won or lost on **how threads in a warp touch memory**. Two levers dominate: **coalesced global access** (consecutive threads → consecutive addresses, maximizing bytes-used / bytes-transferred) and **conflict-free shared memory** (consecutive threads → distinct banks). Shared memory is the user-managed scratchpad that lets you re-stage data so *both* the global read and the global write are coalesced — the matrix-transpose lesson. Coordination uses `__syncthreads()` within a block, atomics across the grid, and cooperative groups beyond a block.

## Frameworks Introduced

- **Thread hierarchy intrinsics**: `gridDim`, `blockDim`, `blockIdx`, `threadIdx` (`.x/.y/.z`). Multi-dim is convenience only — no performance effect. Linearization: `x` fastest, then `y` (stride `blockDim.x`), then `z` (stride `blockDim.x*blockDim.y`). This linearization is exactly what assigns threads to warps.
- **`__syncthreads()` / `cuda.syncthreads()`**: block-level barrier. All threads must arrive before any proceeds; orders all prior shared/global writes. Synchronizes *within one block only*.
- **Memory spaces**: global, constant, shared, local, registers (see table). Plus texture/surface (legacy for non-graphics) and distributed shared memory (clusters).
- **Shared memory allocation**: static (`__shared__ float a[1024]` / `cuda.shared.array(shape=1024, dtype=...)`) sized at compile time; dynamic (`extern __shared__ float a[]` + 3rd chevron arg `<<<grid, block, bytes>>>` / `LaunchConfig.shmem_size`). Only **one** dynamic array — partition it manually for multiple buffers.
- **Constant memory**: `__constant__` (file scope) + `cudaMemcpyToSymbol`/`cudaGetSymbolAddress` in C++; `cuda.const.array_like(ary)` in Python. ~64 KB/device, read-only, broadcast-friendly.
- **Atomics**: prefer `cuda::atomic_ref<T, cuda::thread_scope_device>` (and `cuda::atomic`, `cuda::std::atomic`) in C++; `cuda.atomic.add/sub/max/min/compare_and_swap` in Python. Read-modify-write under an implicit lock.
- **Distributed shared memory** (CC ≥ 9.0, clusters, C++ only via `cooperative_groups`): a block reads/writes/atomics another block's shared memory via `cluster.map_shared_rank(smem, rank)`, gated by `cluster.sync()`.
- **Cooperative Groups**: software-defined thread groups (sub-block, cross-block, cross-grid, multi-GPU) with their own sync.
- **Occupancy tooling**: `cudaGetDeviceProperties`, `nvcc --resource-usage`, `nvcc --maxrregcount`.

## Key Concepts
- **Coalescing rule**: global memory moves in **32-byte transactions**. A warp's 32 requests are coalesced into the minimum transactions needed. Perfectly coalesced 4-byte access = 128 bytes in four 32-byte transactions (100% utilization). Worst case (≥32-byte stride per thread) = 32 transactions, 1024 bytes moved for 128 bytes used → 12.5% utilization.
- **Coalescing is about segments, not strict adjacency**: any linear or permuted access within the same 32-byte segments coalesces. Goal: minimize transactions per load = maximize bytes-used / bytes-transferred.
- **Shared memory banks**: 32 banks, successive 32-bit words → successive banks, 32 bits/bank/cycle. A **bank conflict** = multiple threads in a warp hit *different* words in the *same* bank → serialized. Exceptions: same-word reads **broadcast**; same-address writes pick one (undefined) winner — neither conflicts.
- **The transpose pattern**: a naive transpose has coalesced read but strided (uncoalesced) write. Stage the 32×32 tile through shared memory so both global accesses are coalesced; swap `threadIdx.x/.y` on the shared read to transpose.
- **The padding trick**: a `[32][32]` shared array gives a 32-way bank conflict on column access; declare `[32][32+1]` (or `(32, 33)`) so column and row access are both conflict-free.
- **Local memory ≠ local**: it lives in *device/global* memory (same latency/bandwidth as global). Compiler spills here: non-constant-indexed arrays, oversized structs, register spills. It *is* coalesced when all warp lanes hit the same relative address.
- **Registers**: per-thread, on-SM, compiler-managed. `--maxrregcount` caps them — fewer registers can raise occupancy but may cause spilling to local memory.
- **Occupancy**: active warps / max active warps per SM. Bounded by `maxThreadsPerMultiProcessor`, `maxBlocksPerMultiProcessor`, `sharedMemPerMultiprocessor`, `regsPerMultiprocessor`. Higher occupancy generally hides latency.
- **No grid-wide barrier**: blocks are scheduled in unknown order with no co-residency guarantee. Cross-block coordination needs atomics, clusters, or cooperative groups.

## Mental Models
- **Warp as a "memory-fetch crew"**: it issues one transaction and everyone shares the haul. Scatter the crew across 32-byte segments and it makes 32 trips for one segment's worth of data.
- **Shared memory as a transpose buffer**: you can't make both a strided read and a strided write coalesced in DRAM — so route through on-chip shared memory and pay the cost once, in the fast space.
- **Banks as 32 checkout lanes**: if every lane (thread) goes to a different lane (bank), all 32 check out in parallel; if they queue at one lane, it serializes. Padding shifts the queue apart.
- **Atomics as a global mutex**: correct but serializing — use them sparingly and prefer one atomic per block (reduce locally first), not one per thread.

## Anti-patterns
- **Uncoalesced global access** (e.g. column-major writes with stride = leading dim > 32): the single biggest kernel-performance mistake. Re-stage through shared memory.
- **Square `[32][32]` shared tiles**: silent 32-way bank conflict on column access. Pad to `[32][33]`.
- **Missing `__syncthreads()` between a shared-memory write and a dependent read**: the read may race ahead of other warps' writes → wrong results. Required whenever a thread uses data it didn't load.
- **Atomic-per-thread on a global accumulator**: massive serialization. Reduce in shared memory, then one atomic per block.
- **Non-atomic global accumulation** (`s[0] = s[0] + x` across threads): lost updates; result varies run-to-run and across GPUs.
- **Assuming block scheduling order or co-residency**: undefined; breaks on different SM counts.
- **Reimplementing reductions/scans by hand for production**: prefer CCCL (`cuda.coop` in Python) tuned primitives.
- **Using texture/surface memory for non-graphics loads on current GPUs**: no benefit anymore; use plain load/store.

## Reference Tables

**Memory types**

| Type | Scope | Lifetime | Location |
|---|---|---|---|
| Global | Grid | Application | Device DRAM |
| Constant | Grid | Application | Device (cached, read-only) |
| Shared | Block | Kernel | SM (shares L1 space) |
| Local | Thread | Kernel | Device DRAM |
| Register | Thread | Kernel | SM |

**Coalescing utilization (4-byte words/thread, 32-thread warp)**

| Access pattern | Transactions | Bytes moved | Utilization |
|---|---|---|---|
| Consecutive (coalesced) | 4 × 32B | 128 | 100% |
| ≥32-byte stride (worst) | 32 × 32B | 1024 | 12.5% |

**Shared memory declaration**

| Mode | C++ | Python |
|---|---|---|
| Static | `__shared__ float a[1024];` | `cuda.shared.array(shape=1024, dtype=np.float32)` |
| Dynamic | `extern __shared__ float a[];` + `<<<g,b,bytes>>>` | `cuda.shared.array(shape=0, ...)` + `LaunchConfig.shmem_size` |
| Pad to avoid conflict | `__shared__ float a[32][33];` | `cuda.shared.array(shape=(32,33), ...)` |

**Occupancy-relevant device properties** (`cudaGetDeviceProperties`)

| Per SM | Per block |
|---|---|
| `maxBlocksPerMultiProcessor` | `maxThreadsPerBlock` |
| `maxThreadsPerMultiProcessor` | `sharedMemPerBlock` |
| `sharedMemPerMultiprocessor` | `regsPerBlock` |
| `regsPerMultiprocessor` | — |

## Worked Example
Shared-memory matrix transpose — staging a 32×32 tile so both the global read *and* write are coalesced, with the `__syncthreads()` barrier between them:

```cpp
#define THREADS_PER_BLOCK_X 32
#define THREADS_PER_BLOCK_Y 32
/* column-major index: ld = number of rows */
#define INDX( row, col, ld ) ( ( (col) * (ld) ) + (row) )

__global__ void smem_transpose(int m, float *a, float *c )
{
    __shared__ float smemArray[THREADS_PER_BLOCK_X][THREADS_PER_BLOCK_Y];

    const int myRow = blockDim.x * blockIdx.x + threadIdx.x;
    const int myCol = blockDim.y * blockIdx.y + threadIdx.y;
    const int tileX = blockDim.x * blockIdx.x;
    const int tileY = blockDim.y * blockIdx.y;

    if( myRow < m && myCol < m ) {
        /* coalesced global read -> shared */
        smemArray[threadIdx.x][threadIdx.y] = a[INDX( tileX + threadIdx.x, tileY + threadIdx.y, m )];
    }
    __syncthreads();                       /* all writes to smem visible before reads */
    if( myRow < m && myCol < m ) {
        /* swap indices to transpose; coalesced shared -> global write */
        c[INDX( tileY + threadIdx.x, tileX + threadIdx.y, m )] = smemArray[threadIdx.y][threadIdx.x];
    }
    return;
}
```
- **Demonstrates**: `threadIdx.x` in the fast index of both global accesses (coalesced read and write), the transposing index-swap on `smemArray`, and the mandatory `__syncthreads()` between the shared write and read. The `[32][32]` declaration here carries a 32-way bank conflict on one access — fix by declaring `smemArray[32][33]`.

## Key Takeaways
1. Coalescing is the #1 lever: make consecutive threads touch the same 32-byte segments; minimize transactions per warp load.
2. Shared memory exists to re-stage data so otherwise-strided global accesses become coalesced (and to share within a block).
3. Shared memory has 32 banks; same-bank/different-word access serializes. Pad `[N][N]` → `[N][N+1]` to kill conflicts; same-word reads broadcast for free.
4. `__syncthreads()` is mandatory between a shared write and any dependent read — and only syncs within one block.
5. Local memory lives in DRAM; registers are on-SM and compiler-managed (`--maxrregcount` trades registers for occupancy, risking spills).
6. Atomics are a serializing global mutex — reduce locally, then one atomic per block; never hand-roll non-atomic accumulation. Prefer CCCL/`cuda.coop`.
7. There's no grid-wide barrier; cross-block coordination = atomics, clusters (distributed shared memory + `cluster.sync()`), or cooperative groups.
8. Occupancy = active/max warps; tune block size, shared memory, and registers against per-SM and per-block limits.

## Connects To
- **Ch 1**: SM, warp, and memory-hierarchy hardware these techniques exploit.
- **Ch 2**: kernel launch, specifiers, and the cluster intro this chapter deepens (distributed shared memory).
- **Ch 4**: the tile model — same hardware goals (coalescing, on-chip staging), but the compiler maps tile ops to threads, sidestepping manual bank-conflict tuning.
- **Atomic Functions / Cooperative Groups feature chapters**: full atomic and group APIs.
- **CCCL**: production reductions/scans (`cuda.coop` in Python) — don't hand-roll.
