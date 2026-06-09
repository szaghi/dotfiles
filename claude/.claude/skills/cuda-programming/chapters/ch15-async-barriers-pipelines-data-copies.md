# Chapter 15: Async Barriers, Pipelines & Async Data Copies (TMA)

## Core Idea
This is the machinery for **overlapping computation with data movement** inside a kernel. Three layers stack: (1) `cuda::barrier` — a *split* arrive/wait barrier (with optional transaction counting) that lets threads signal "done" and keep computing before everyone synchronizes; (2) `cuda::pipeline` — a multi-stage producer/consumer abstraction for double/N-buffering; (3) the async-copy hardware — **LDGSTS** (CC 8.0+) for small element-wise global→shared copies and the **Tensor Memory Accelerator (TMA)** (CC 9.0+) for bulk 1-D and multi-dimensional tile transfers, both signalling completion through barriers or async-groups. **STAS** copies registers to distributed shared memory.

## Frameworks Introduced

- **`cuda::barrier<Scope>`**: initialized once with an expected arrival count; threads call `arrive()` (returns a phase-bound `arrival_token`) then `wait(std::move(token))`. Countdown auto-resets to the next phase when it hits zero.
  - When to use: fine-grained, non-blocking, split synchronization; tracking async copies.
- **Async transaction barriers** (CC 9.0+, shared mem, block/cluster scope): add a *transaction count* (typically bytes) so the barrier blocks until all bytes of async copies have landed. Set via `barrier_arrive_tx` / `barrier_expect_tx`.
- **`cuda::pipeline<Scope>`**: stages work via `producer_acquire` → submit `memcpy_async` → `producer_commit`; consume via `consumer_wait` → `consumer_release`. Unified (all threads both roles) or partitioned (fixed producer/consumer roles).
- **LDGSTS async copy**: `cuda::memcpy_async`, `cooperative_groups::memcpy_async`, `__pipeline_memcpy_async` — global→shared, 4/8/16 bytes.
- **TMA (bulk / bulk-tensor copies)**: `cuda::ptx::cp_async_bulk` (1-D), `cuda::ptx::cp_async_bulk_tensor` (multi-D, needs a tensor map from `cuTensorMapEncodeTiled`); `cuda::device::memcpy_async_tx`.

## Key Concepts
- **Barrier phase rules**: `arrive()` must occur in the current phase; `wait()` in the same or next phase; a phase advances exactly when the countdown hits zero, and the token must be of the current or immediately-preceding phase (else UB).
- **Explicit phase tracking**: `mbarrier_try_wait_parity(bar, parity)` waits on a 0/1 parity bit instead of a token — lets *one* thread arrive and set the transaction count while others just wait on the flip. More efficient; shared-mem block/cluster barriers only.
- **Warp entanglement (barriers)**: a converged warp updates the barrier *once*; a fully diverged warp applies *32* updates. Re-converge with `__syncwarp` before arrive-on operations.
- **Warp entanglement (pipelines)**: commit coalesces across converged threads; divergence spreads submissions across stages and makes `consumer_wait` over-wait. Re-converge before commit.
- **`arrive_and_drop()`**: a thread leaving early must drop out (arrives for the current phase, then decrements the expected count for future phases).
- **Completion function**: `cuda::barrier<Scope, CompletionFn>` runs `CompletionFn` once per phase after the last arrive and before any unblock, with full memory visibility both ways.
- **LDGSTS modes**: 4/8 bytes → L1 ACCESS (cached in L1); 16 bytes → L1 BYPASS (no L1 pollution). 128-byte alignment is best.
- **Per-thread completion**: by default each thread waits only for *its own* LDGSTS copies — a `__syncthreads()` is needed if prefetched data is shared.
- **TMA needs a tensor map** for multi-D: built on host via `cuTensorMapEncodeTiled`, passed as `const __grid_constant__ CUtensorMap`. Fastest-moving dimension first; strides multiple of 16 bytes.
- **Proxy fence**: shared-memory writes (generic proxy) must be ordered before a subsequent TMA read (async proxy) with `fence_proxy_async`, then `__syncthreads()`.
- **Single-thread TMA election**: initiate TMA from *one* thread; use `elect_sync` / the `is_elected()` helper (or `invoke_one`) so the compiler doesn't insert a peeling loop → warp serialization.

## Mental Models
- Think of a `cuda::barrier` as a **fence you can split in half**: `arrive()` = "I'm done with my half," `wait()` = "block till everyone's done." The gap between is free overlap.
- Think of **transaction counting** as the barrier counting *bytes in flight*, not just *threads arrived* — the phase flips only when both reach their targets.
- Think of a `cuda::pipeline` as a **conveyor of N buffers**: producers fill the head, consumers drain the tail, and `producer_acquire` blocks only when all N stages are occupied.
- Think of **TMA as a DMA engine for tiles**: you hand it a tensor map (the array's shape/stride) and tile coordinates, and it does all the address arithmetic, out-of-bounds zero-fill, and a single bulk transfer.
- Think of **LDGSTS vs TMA** as *element-wise prefetch* vs *bulk tile move*: LDGSTS for small/irregular, TMA for large multi-dimensional sub-tiles.

## Anti-patterns
- **Calling `arrive()`/`wait()` from a diverged warp without `__syncwarp`**: 32× redundant barrier updates / over-waiting.
- **Exiting a barrier/pipeline sequence without `arrive_and_drop()` / `pipeline::quit()`**: remaining threads deadlock waiting on the departed one.
- **Using a stale token / wrong-phase token**: UB; only current or immediately-preceding phase is valid.
- **Initiating TMA from `if (threadIdx.x == 0)`**: compiler can't prove single-thread → peeling loop → warp serialization. Use `elect_sync`/`invoke_one`.
- **Skipping `fence_proxy_async` before a shared→global TMA write**: shared-memory writes may not be visible to the async proxy.
- **Misaligned TMA**: bulk ops require 16-byte global/shared alignment (128-byte shared for tensor copies) and transfer size multiple of 16; `cp_async_bulk`/`memcpy_async_tx` give UB if violated (plain `cuda::memcpy_async` silently falls back to sync copies).
- **Forgetting `__syncthreads()` after waiting on shared LDGSTS prefetch**: each thread only waited for its own copies.
- **Preferring `cuda::pipeline` (partitioned) when a thread-local/unified pattern suffices**: extra shared-memory barriers per stage are pure overhead.

## Reference Tables

**Barrier API (cuda::barrier)**

| Operation | Meaning |
|---|---|
| `init(&bar, count[, completion_fn])` | one thread sets expected arrival count |
| `token = bar.arrive()` | arrive (non-blocking), get phase token |
| `bar.wait(std::move(token))` | block while token's phase is current |
| `bar.arrive_and_wait()` | = `bar.wait(bar.arrive())` |
| `bar.arrive_and_drop()` | arrive + stop participating in future phases |
| `barrier_arrive_tx(bar, arr, tx)` / `barrier_expect_tx` | set transaction (byte) count |
| `mbarrier_try_wait_parity(&bar, parity)` | explicit-phase wait (0/1) |

**Async-copy mechanisms**

| Mechanism | Scope | Direction | Completion | API |
|---|---|---|---|---|
| LDGSTS (CC 8.0+) | element-wise 4/8/16 B | global→shared | shared-mem barrier / pipeline | `cuda::memcpy_async`, `cg::memcpy_async`, `__pipeline_memcpy_async` |
| TMA bulk (CC 9.0+) | 1-D contiguous | global↔shared, shared→dsmem | shared-mem barrier (read) / bulk async-group (write) | `cuda::ptx::cp_async_bulk`, `cuda::device::memcpy_async_tx` |
| TMA bulk-tensor (CC 9.0+) | multi-D (≤ 5-D) tile, needs tensor map | global↔shared, shared→cluster | shared-mem barrier / bulk async-group | `cuda::ptx::cp_async_bulk_tensor` |

**TMA 1-D alignment**: global/shared address 16-byte aligned; barrier 8-byte; transfer size multiple of 16. **Tensor copy**: shared address 128-byte aligned; global strides multiple of 16 bytes.

**Tensor map**: host `cuTensorMapEncodeTiled` → pass as `const __grid_constant__ CUtensorMap` (preferred), or `__constant__` + `cudaMemcpyToSymbol`, or global mem (needs fence). On-device modify: `cuda::ptx::tensormap_replace_*` + `tensormap_cp_fenceproxy` (sm_90a only).

## Worked Example
A 1-D TMA read-modify-write — barrier as completion mechanism, single-thread election, transaction (byte) counting, proxy fence before the write-back:

```cpp
__global__ void add_one_kernel(int* data, size_t offset)
{
  __shared__ alignas(16) int smem_data[buf_len];   // bulk dest must be 16B aligned

  __shared__ barrier bar;
  if (threadIdx.x == 0) { init(&bar, blockDim.x); }
  __syncthreads();

  if (is_elected()) {                              // one thread initiates TMA
    cuda::memcpy_async(                            // counts tx (bytes) automatically
        smem_data, data + offset,
        cuda::aligned_size_t<16>(sizeof(smem_data)), bar);
  }
  barrier::arrival_token token = bar.arrive();     // all threads arrive
  bar.wait(std::move(token));                       // wait for data to land

  for (int i = threadIdx.x; i < buf_len; i += blockDim.x) smem_data[i] += 1;

  ptx::fence_proxy_async(ptx::space_shared);        // make smem writes visible to TMA
  __syncthreads();

  if (is_elected()) {                               // write back via bulk copy
    ptx::cp_async_bulk(ptx::space_global, ptx::space_shared,
                       data + offset, smem_data, sizeof(smem_data));
    ptx::cp_async_bulk_commit_group();
    ptx::cp_async_bulk_wait_group_read(ptx::n32_t<0>());  // wait read-of-smem done
  }
}
```
- **What it demonstrates**: the read uses a *shared-memory barrier* completion (transaction count auto-set by `cuda::memcpy_async`); the write uses a *bulk async-group* completion; `fence_proxy_async` orders generic-proxy shared writes before the async-proxy read; `is_elected()` keeps TMA single-threaded to avoid a peeling loop.

## Key Takeaways
1. `cuda::barrier` is a split arrive/wait fence — the gap between `arrive()` and `wait()` is free compute/communication overlap.
2. Transaction (byte) counting makes a barrier wait for *async copies to land*, not just for threads to arrive (CC 9.0+, shared mem, block/cluster scope).
3. Explicit phase tracking (`try_wait_parity`) lets one thread set the tx count while others wait on a parity flip — cheaper than all-threads-with-tokens.
4. Warp entanglement: diverged warps cause 32× barrier updates / pipeline over-wait — re-converge with `__syncwarp` before arrive/commit.
5. Threads leaving early must `arrive_and_drop()` / `pipeline::quit()` or the rest deadlock.
6. LDGSTS = small element-wise global→shared (4/8/16 B; 16 B bypasses L1); each thread waits only for its own copies (add `__syncthreads()` if shared).
7. TMA = bulk tile DMA; multi-D needs a host-built `cuTensorMap` passed as `__grid_constant__`; initiate from a single elected thread and fence the proxy before write-back.

## Connects To
- **Ch 13 (Cooperative Groups)**: CG barriers and `cg::memcpy_async` are the higher-level face of the same `mbarrier`/LDGSTS hardware; `invoke_one` is an alternative to `is_elected()`.
- **Ch 1 (Shared memory, clusters, distributed shared memory)**: transaction barriers, cluster-scope copies, and STAS target the cluster/dsmem hierarchy.
- **§3.2.5 (Asynchronous data copies)**: this chapter is the applied deep-dive on that model.
- **PTX ISA (`cp.async.bulk`, `mbarrier`, `tensormap.replace`)**: `cuda::ptx::*` wrappers expose these instructions; many are sm_90a-specific.
- **Tensor-core GEMM / library kernels**: TMA tile loading is the standard front-end for matrix-multiply pipelines.
