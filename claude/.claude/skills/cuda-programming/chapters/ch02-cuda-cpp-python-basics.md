# Chapter 2: CUDA C++ & Python Basics

## Core Idea
A CUDA program is host code that allocates GPU-accessible memory, launches a `__global__` kernel as a grid of thread blocks, and synchronizes to retrieve results. The same SIMT model appears in C++ (compiled by `nvcc`, launched with `<<<grid, block>>>`) and in Python (`@cuda.jit` via Numba, launched with `[grid, block]`). The two recurring traps for beginners: **kernel launches are asynchronous** (you must synchronize before trusting results), and **errors are sticky and often asynchronous** (a `cudaSuccess` right after launch proves almost nothing).

## Frameworks Introduced

- **nvcc compilation**: the NVIDIA CUDA Compiler driver. Compile a `.cu` file with `nvcc file.cu -o exe`. It orchestrates the host (C++) and device (PTX→cubin) compilation stages behind a familiar CLI. Targets Linux, Windows cmd/PowerShell, and WSL.
- **Kernels (`__global__`)**: a `void`-returning function compiled for the GPU and invocable from the host via a launch. `__global__ void vecAdd(float* A, float* B, float* C, int n)`.
- **Triple-chevron launch (`<<<grid, block>>>`)**: the C++ language-extension launch syntax. First arg = grid dims (blocks), second = block dims (threads). Use `int` for 1-D, `dim3` for 2-/3-D. The other launch path is `cudaLaunchKernelEx` (covered later).
- **Index intrinsics**: `threadIdx`, `blockDim`, `blockIdx`, `gridDim` — each a 3-component vector (`.x/.y/.z`). Unspecified dims default to 1. The canonical global index is `threadIdx.x + blockDim.x*blockIdx.x`.
- **Unified Memory**: `cudaMallocManaged(&p, bytes)` (or the `__managed__` specifier) — one pointer the driver migrates between host and device on demand. Freed with `cudaFree`.
- **Explicit memory management**: `cudaMalloc` device buffers + `cudaMemcpy(dst, src, bytes, kind)` to move data; pair with page-locked host buffers via `cudaMallocHost`/`cudaFreeHost`. More verbose, more control, more overlap opportunity.
- **Error checking**: `cudaError_t` return codes, `cudaGetLastError`/`cudaPeekAtLastError`, `cudaGetErrorString`, and the `CUDA_LOG_FILE` env var.
- **CUDA Python**: Numba (`@cuda.jit`) for SIMT kernels; **CuPy** for GPU `ndarray`s and host↔device copies; the broader `cuda.core`/`cuda.compute`/`cuda.tile`/`cuda.bindings` ecosystem.

## Key Concepts
- **Asynchronous launch**: the host thread proceeds immediately after `<<< >>>` — possibly before the kernel even starts. `cudaDeviceSynchronize()` blocks the host until *all* prior GPU work finishes.
- **Block size limit**: up to 1024 threads/block on current GPUs (one block lives on one SM). 256 is a good default starting block size.
- **Bounds guard**: launch `ceil(N/block)` blocks and guard with `if (workIndex < N)`. Extra *threads* are cheap; launching whole blocks that do no work is wasteful.
- **`cudaMallocHost` (pinned/page-locked) memory**: faster copies, required for async transfers — but page-lock only the buffers you actually transfer (over-pinning degrades the system).
- **`cudaMemcpyDefault`**: lets the runtime infer direction from the pointers, instead of spelling out `HostToDevice`/`DeviceToHost`/`DeviceToDevice`. `cudaMemcpy` is synchronous.
- **Sticky error state**: the runtime keeps a per-host-thread `cudaError_t`. An async error (e.g. an invalid memory access inside a kernel) is reported by the *next* API call and is returned by *every* subsequent call until `cudaGetLastError` clears it.
- **Runtime initialization**: the primary context is created lazily (or by `cudaSetDevice`/`cudaInitDevice` as of CUDA 12.0). Always check `cudaSetDevice`'s return — it now triggers init and can surface init errors.
- **Variable specifiers**: `__device__` → global memory, `__constant__` → constant memory, `__managed__` → unified memory, `__shared__` → shared memory. No specifier inside device code → registers (spilling to local memory).
- **Function specifiers**: `__global__` (kernel entry), `__device__` (callable from device), `__host__` (CPU); `__host__ __device__` compiles both — use `#ifdef __CUDA_ARCH__` to branch device-only code.
- **Thread block clusters** (CC ≥ 9.0): a co-scheduled group of blocks on one GPC. Portable max = 8 blocks (query `cudaOccupancyMaxPotentialClusterSize`). Enables `cluster.sync()` and **distributed shared memory**. Declare via `__cluster_dims__(X,Y,Z)` (compile-time) or `cudaLaunchKernelEx` (runtime). `gridDim` still counts blocks, and grid dims must be a multiple of the cluster size.

## Mental Models
- **Launch is a "fire-and-forget post"**: you've handed work to the GPU; nothing is true until you synchronize.
- **`cudaSuccess` after a launch = "the paperwork was accepted"**, not "the kernel ran." It only confirms the launch config was valid and no *prior* error is pending.
- **Unified vs explicit = automatic transmission vs manual**: managed memory is convenient and portable; explicit `cudaMalloc`/`cudaMemcpy` is verbose but lets you overlap copies with compute and place data deliberately.
- **CuPy/Numba arrays live on exactly one side**: a host `ndarray` passed to a kernel, or a device array passed to a plain Python function, is an error — copies are explicit by design.

## Anti-patterns
- **Reading results before synchronizing**: the kernel may not have run. Always `cudaDeviceSynchronize()` (or stream-sync) before trusting output.
- **Trusting a post-launch `cudaSuccess` as "kernel succeeded"**: it can't — kernel runtime errors are asynchronous.
- **Forgetting `cudaGetLastError` after a triple-chevron launch**: the launch returns no `cudaError_t`, so config errors silently set the state.
- **Not clearing a sticky error**: every later API keeps returning the stale async error until `cudaGetLastError` resets it.
- **Over-pinning host memory** with `cudaMallocHost`: too much page-locked memory degrades whole-system performance.
- **Launching empty blocks** (all threads fail the bounds guard): size the grid with `ceil(N/block)`, not a fixed oversized grid.
- **Calling CUDA APIs after `main` returns / during static teardown**: global runtime state is destroyed at program exit → undefined behavior.

## Reference Tables

**`cudaMemcpy` kinds**

| Kind | Direction |
|---|---|
| `cudaMemcpyHostToDevice` | CPU → GPU |
| `cudaMemcpyDeviceToHost` | GPU → CPU |
| `cudaMemcpyDeviceToDevice` | within/between GPUs |
| `cudaMemcpyDefault` | inferred from pointer values |

**Specifiers**

| Specifier | Placement / role |
|---|---|
| `__global__` | kernel entry point (host-launchable) |
| `__device__` | function/var on GPU; device-callable / global memory |
| `__host__` | CPU function (combinable with `__device__`) |
| `__constant__` | variable in constant memory |
| `__managed__` | variable in unified memory |
| `__shared__` | variable in shared memory |

**Error API**

| Call | Effect |
|---|---|
| `cudaGetLastError()` | return error state, **reset** to `cudaSuccess` |
| `cudaPeekAtLastError()` | return error state, **don't** reset |
| `cudaGetErrorString(e)` | human-readable string for a code |
| `CUDA_LOG_FILE=path` | driver writes error detail to file (`stdout`/`stderr` also valid); r570+ |

**Python ↔ C++ mapping**

| Concept | C++ | Python (Numba/CuPy) |
|---|---|---|
| kernel decl | `__global__ void f(...)` | `@cuda.jit def f(...)` |
| launch | `f<<<g, b>>>(args)` | `f[g, b](args)` |
| global index | `threadIdx.x + blockDim.x*blockIdx.x` | `cuda.grid(1)` |
| device sync | `cudaDeviceSynchronize()` | `cuda.synchronize()` / `cp.synchronize()` |
| device alloc | `cudaMalloc` | `cp.zeros(...)`, `cp.array(host)` |
| copy to host | `cudaMemcpy(..., DeviceToHost)` | `cp.asnumpy(dev)` |
| error handling | return codes / `CUDA_CHECK` | Python exceptions (`try/except`) |

## Worked Example
Vector addition with a bounds guard, ceil-div grid sizing, unified memory, and synchronization — the complete C++ pattern:

```cpp
#include <cuda_runtime_api.h>
#include <cuda/cmath>   // cuda::ceil_div

__global__ void vecAdd(float* A, float* B, float* C, int vectorLength)
{
    int workIndex = threadIdx.x + blockIdx.x*blockDim.x;
    if(workIndex < vectorLength)
    {
        C[workIndex] = A[workIndex] + B[workIndex];
    }
}

void unifiedMemExample(int vectorLength)
{
    float* A = nullptr; float* B = nullptr; float* C = nullptr;
    cudaMallocManaged(&A, vectorLength*sizeof(float));
    cudaMallocManaged(&B, vectorLength*sizeof(float));
    cudaMallocManaged(&C, vectorLength*sizeof(float));
    initArray(A, vectorLength);
    initArray(B, vectorLength);

    int threads = 256;
    int blocks  = cuda::ceil_div(vectorLength, threads);
    vecAdd<<<blocks, threads>>>(A, B, C, vectorLength);
    cudaDeviceSynchronize();      // host must wait before reading C
    // ... compare against serial CPU result ...
    cudaFree(A); cudaFree(B); cudaFree(C);
}
```
- **Demonstrates**: managed allocation (single pointer, no explicit copy), `cuda::ceil_div` grid sizing, the `if(workIndex < vectorLength)` tail guard, and the mandatory `cudaDeviceSynchronize()` before results are valid. The error-checked variant wraps launches with `CUDA_CHECK(cudaGetLastError())` then `CUDA_CHECK(cudaDeviceSynchronize())`.

## Key Takeaways
1. `nvcc file.cu -o exe` builds it; `<<<grid, block>>>` (C++) or `[grid, block]` (Python) launches it.
2. Launches are asynchronous — synchronize (`cudaDeviceSynchronize`) before trusting any result.
3. Compute the global index `threadIdx.x + blockDim.x*blockIdx.x` (or `cuda.grid(1)`), size the grid with `ceil(N/block)`, and guard the tail with `if (i < N)`.
4. Unified memory (`cudaMallocManaged`) trades control for convenience; explicit `cudaMalloc`/`cudaMemcpy` (+ pinned `cudaMallocHost`) unlocks overlap and placement control.
5. Errors are sticky and asynchronous: check `cudaGetLastError()` after launches, clear the state, and never read a post-launch `cudaSuccess` as proof the kernel ran.
6. Specifiers place code and data: `__global__`/`__device__`/`__host__` for functions; `__device__`/`__constant__`/`__managed__`/`__shared__` for variables.
7. Thread block clusters (CC ≥ 9.0) co-schedule blocks on a GPC for `cluster.sync()` and distributed shared memory.

## Connects To
- **Ch 1**: the host/device, grid/block/thread, SIMT, and cluster concepts these APIs make concrete.
- **Ch 3**: SIMT kernels in depth — `__syncthreads`, memory spaces, coalescing, atomics, cooperative groups.
- **Ch 4**: the tile model (cuTile / `cuda.tile`) as the alternative to per-thread SIMT.
- **Async Execution chapter**: streams, events, async copies — finer-grained synchronization than `cudaDeviceSynchronize`.
- **OpenACC/OpenMP-offload**: directive-based alternatives to hand-written kernels on the same hardware (`openacc-3.4`, `openmp-6.0`).
