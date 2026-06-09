# Chapter 18: CUDA Dynamic Parallelism

## Core Idea
**CUDA Dynamic Parallelism (CDP)** lets device code launch new kernels — GPU work spawning GPU work — so launch decisions become data-dependent and runtime-driven, without round-tripping to the host. A launching thread belongs to the **parent grid**; the kernel it launches is a **child grid**. Parent/child nesting is strict (parent isn't complete until all children finish, via *implicit* synchronization), but the modern **CDP2** model (default since CUDA 12.0, the *only* model on CC ≥ 9.0) removes `cudaDeviceSynchronize` from device code — you observe child results through the **tail-launch stream**, not by blocking.

## Frameworks Introduced

- **CUDA Device Runtime**: a device-callable subset of the runtime API (`<<< >>>` launches, streams, events) usable from inside kernels. Per-thread code — each thread decides independently what to launch; no inter-thread sync required, so it's deadlock-safe in divergent code.
  - When to use: recursion, irregular/data-dependent parallelism that doesn't fit flat single-level grids.
- **`cudaStreamTailLaunch`**: a special stream; a kernel launched into it runs *after* the current grid and all its children complete. The only way to observe child modifications before the parent exits.
- **`cudaStreamFireAndForget`**: launch that runs without ordering against same-stream launches (concurrency, no in-order guarantee).
- **PTX device-launch primitives**: `cudaLaunchDevice()` + `cudaGetParameterBuffer()` — the low-level mechanism `<<< >>>` lowers to, for language/compiler implementers targeting PTX.

## Key Concepts
- **Implicit synchronization only**: CDP2 has no `cudaDeviceSynchronize` on device — parent/child sync happens implicitly when the parent grid exits. To read child output, launch into `cudaStreamTailLaunch`.
- **Grid-scoped objects**: streams/events created on the device are visible to all threads in the *creating grid* but invalid outside it. Host streams/events are undefined inside kernels; parent streams undefined in children.
- **NULL stream is per-block, named streams are per-grid**: implicit-stream launches from one block are in-order; from different blocks may run concurrently. Use explicit named streams for intra-block concurrency.
- **No concurrency guarantees**: between thread blocks, or between parent and child. A child *may* start once dependencies/resources allow but isn't guaranteed to run until the parent hits an implicit sync point. Never depend on concurrency.
- **Build requirements**: `nvcc -rdc=true ... -lcudadevrt` (relocatable device code + device runtime library).
- **Events**: only inter-stream sync (`cudaStreamWaitEvent`) is supported; create with `cudaEventCreateWithFlags(..., cudaEventDisableTiming)`. No `cudaEventSynchronize`/`ElapsedTime`/`Query`.
- **Device management**: no `cudaSetDevice`; no catch-all `cudaGetDeviceProperties` (query attributes individually via `cudaDeviceGetAttribute`).

## Mental Models
- CDP = **a manager (parent) who can hire subcontractors (children) on the fly** but can't watch them work. The manager's project isn't "done" until all subcontractors finish, but to *read their deliverables* you schedule a follow-up meeting (tail launch).
- Memory consistency = **a single snapshot handed to the child at launch**: the child sees all parent writes prior to its launch (use `__syncthreads()` to make all block writes visible first); the parent gets *nothing back* except through a tail-launch kernel.
- "Pass only global storage to children" = **only hand a subcontractor an address in the shared warehouse (global heap)**, never a sticky-note on your own desk (local/shared memory) that vanishes when you leave.

## Anti-patterns
- **Passing local- or shared-memory pointers as launch arguments** → undefined behavior. Use `__isGlobal()` to check; allocate child-visible storage from the global heap (`cudaMalloc`, `new`, `__device__` global-scope).
- **Passing shared/local pointers to `cudaMemcpy*Async`/`cudaMemset*Async`** in device code → error (these may spawn child kernels).
- **Expecting parent to see child writes without a tail launch** → never guaranteed; modifications are invisible to the parent grid.
- **Using `cudaDeviceSynchronize` in device code under CDP2** → compile error (CC < 9.0) or `cudaErrorSymbolNotFound` at load (CC ≥ 9.0).
- **Depending on concurrency between blocks or parent/child** → unsupported, undefined.
- **Mixing CDP1 and CDP2 in one call graph** → `cudaErrorCdpVersionMismatch` at load; a CDP1 function cannot launch a CDP2 function or vice versa.

## Reference Tables

**Parent/child memory accessibility (same pointers?)**

| Memory space | Same pointers? |
|---|---|
| Global memory | Yes (coherent at child launch; weak between) |
| Mapped memory | Yes |
| Local memory | No |
| Shared memory | No |
| Texture memory | Yes (read-only; coherent at child launch/completion) |

**CDP2 vs CDP1**

| | CDP2 (default, CUDA 12.0+) | CDP1 (legacy, opt-in) |
|---|---|---|
| Opt-in flag | (default) | `-DCUDA_FORCE_CDP1_IF_SUPPORTED` |
| Devices | only model on CC ≥ 9.0 | CC < 9.0 only |
| Device sync | none — use tail launch | `cudaDeviceSynchronize` |
| Special streams | tail-launch, fire-and-forget | — |

**PTX launch primitives**

| API | Role |
|---|---|
| `cudaLaunchDevice(func, paramBuf, gridDim, blockDim, sharedMemSize, stream)` | launch the kernel |
| `cudaGetParameterBuffer(alignment, size)` | obtain param buffer (always 64-byte aligned; max 4KB, no reordering) |

## Worked Example
The canonical CDP2 "Hello World" — parent launches a child, then a tail-launch kernel that runs only after the child completes:

```cpp
#include <stdio.h>

__global__ void childKernel() { printf("Hello "); }
__global__ void tailKernel()  { printf("World!\n"); }

__global__ void parentKernel()
{
    childKernel<<<1,1>>>();                              // launch child (async)
    if (cudaSuccess != cudaGetLastError()) return;

    // tail launch: implicitly waits for child to complete before running
    tailKernel<<<1,1,0,cudaStreamTailLaunch>>>();
}

int main()
{
    parentKernel<<<1,1>>>();
    if (cudaSuccess != cudaGetLastError())   return 1;
    if (cudaSuccess != cudaDeviceSynchronize()) return 2;  // host-side sync is fine
    return 0;
}
// Build:  $ nvcc -arch=sm_75 -rdc=true hello_world.cu -o hello -lcudadevrt
```
- **What it demonstrates**: device-side `<<< >>>` launch, `cudaGetLastError()` after each launch, ordering "Hello" before "World!" via `cudaStreamTailLaunch` (not via a device-side sync), and the `-rdc=true -lcudadevrt` build requirements. Host-side `cudaDeviceSynchronize` remains valid.

## Key Takeaways
1. CDP launches GPU work from GPU code; parent/child nesting is strict with *implicit* synchronization at parent exit.
2. CDP2 (default, CUDA 12.0+; mandatory on CC ≥ 9.0) drops device-side `cudaDeviceSynchronize` — observe child results only via `cudaStreamTailLaunch`.
3. Pass only global-heap storage to children; local/shared pointers are illegal (`__isGlobal()` guards).
4. Device streams/events are grid-scoped; events support only `cudaStreamWaitEvent`, must use `cudaEventDisableTiming`.
5. No concurrency guarantees anywhere — never depend on parent/child or inter-block concurrency.
6. Build with `nvcc -rdc=true -lcudadevrt`; never mix CDP1/CDP2 in one call graph.

## Connects To
- **Ch 1**: grids, blocks, threads — CDP makes "a thread launches a grid" first-class.
- **Streams & events chapters**: tail-launch / fire-and-forget extend stream-ordering semantics into device code.
- **Ch 3 / memory consistency**: the weak parent↔child global-memory consistency is the device model applied across launch boundaries.
- **PTX / inline-assembly chapters**: `cudaLaunchDevice`/`cudaGetParameterBuffer` are the lowering target for compiler implementers.
