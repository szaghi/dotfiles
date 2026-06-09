# CUDA Decision Cheatsheet

## Block / grid sizing
- **Always** make block size a **multiple of 32** (warp size). Tail warps waste lanes otherwise.
- Default block: **128–256** threads. Tune by occupancy, not guesswork — use the occupancy calculator / `cudaOccupancyMaxPotentialBlockSize`.
- `grid = (n + block - 1) / block`; then guard `if (i < n)`. Or use a **grid-stride loop** and size grid to the device.

## Which memory?
| Need | Use |
|---|---|
| Per-thread scratch | registers (automatic); watch spills → local memory |
| Block-shared reuse / staging | `__shared__` (mind 32 banks; pad `[N+1]`) |
| Read-only broadcast to all threads | `__constant__` / `__ldg` |
| Large persistent data | global memory; coalesce accesses |
| Simplest host+device sharing | `cudaMallocManaged` + prefetch/advise |
| Async DMA overlap | pinned host (`cudaMallocHost`) + streams |
| Hot global region | persistent L2 set-aside |

## Coalescing tell
- If a warp's lanes touch addresses `base + i` → coalesced (good). Strided/AoS → uncoalesced (≤12.5% bus). **Smell**: `data[threadIdx.x * STRIDE]` with STRIDE>1, or accessing `struct.field` across a struct array.

## Sync primitive selection
| Scope | Primitive |
|---|---|
| Threads in a block | `__syncthreads()` |
| Lanes in a warp | `__syncwarp(mask)` |
| Block/tile/grid/cluster group | Cooperative Groups `group.sync()` |
| Stream completion (host) | `cudaStreamSynchronize` / event |
| Whole device (host) | `cudaDeviceSynchronize` (avoid in hot loops) |
| Async copy completion | `cuda::barrier` (transaction count) / `cuda::pipeline` |

## Atomic scope rule
- Sharing **within a block** → `thread_scope_block`.
- Across blocks, **one GPU** → `thread_scope_device`.
- Across **GPUs or with host** → `thread_scope_system`.
- Wrong-narrow scope = stale reads (silent). Wrong-wide = slower. Match to actual sharing.

## Streams & concurrency
- Operations in **one stream** run in order; **different** streams may overlap.
- The **default stream** synchronizes with others unless you compile `--default-stream per-thread` (or use `CUDA_API_PER_THREAD_DEFAULT_STREAM`).
- Overlap copy+compute needs **pinned** memory + `cudaMemcpyAsync` on non-default streams.

## Launch / overhead reduction (decision tree)
- Same op sequence relaunched many times? → **CUDA Graph** (capture once, launch N).
- Need a kernel to start after another partially finishes? → **Programmatic Dependent Launch**.
- Many small allocs/frees in a pipeline? → **`cudaMallocAsync`** + pool.
- Lots of unused kernels at startup? → **Lazy Loading** (`CUDA_MODULE_LOADING=LAZY`).
- Concurrent low-latency workloads sharing a GPU? → **Green Contexts** (SM partition).

## Compatibility quick rules
- cubin `sm_XY`: runs on same **major**, minor ≥ X.Y. Never across major versions.
- PTX `compute_XY`: JIT-runs on any CC ≥ X.Y (**ship PTX for forward compat**).
- Build: `-arch=sm_90` (one target) or `-gencode` per target; `-arch=native` for the build machine, `all`/`all-major` for broad coverage.

## Precision / fast-math
- **FMA** (`a*b+c`, single rounding) is default and IEEE-compliant — *more* accurate than separate mul+add.
- `--use_fast_math` swaps in low-ULP intrinsics (`__fdividef`, `__sinf`…) and flushes denormals. **Tell**: results drift in the last few digits → fast-math or intrinsic functions are in play.
- Consumer GPUs: FP64 is ~1/64 of FP32 throughput (vs 1/2 on datacenter). Don't assume FP64 is "free." (See `reference_consumer_gpu_fp64_trap`.)

## Benchmark timing (don't get fooled)
- Time GPU work with **CUDA events** + `cudaEventSynchronize`, never host wall-clock around an async launch.
- A ">100× speedup" almost always = a missing sync. (See `feedback_gpu_benchmark_timing`.)

## Error checking
- Kernels are async → `kernel<<<>>>()` returns before running. Check `cudaGetLastError()` (launch) **and** a later sync's return (execution). Errors are *sticky*.

## Common smells
- No `if (i < n)` guard with a rounded-up grid → OOB.
- `__syncthreads()` inside divergent `if` → deadlock/UB.
- Block size not ×32 → wasted lanes.
- AoS layout in a hot kernel → uncoalesced.
- Timing async work without sync → fantasy speedups.
- Device-side `cudaDeviceSynchronize()` in CDP2 → removed; restructure with tail launch.
