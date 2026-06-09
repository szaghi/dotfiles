# Chapter 23: C/C++ Language Extensions

## Core Idea
CUDA extends C/C++ with a small vocabulary of **annotations** that answer two questions: *where does this run* (execution-space specifiers) and *where does this live* (memory-space specifiers), plus per-kernel **configuration** attributes (`__launch_bounds__`, `__maxnreg__`, `__cluster_dims__`) and **synchronization intrinsics** (`__syncthreads*`). Built-in variables (`threadIdx`, `blockIdx`, `blockDim`, `gridDim`, `warpSize`) give each thread its coordinates, and vector types (`float4`, `int4`, …) provide aligned aggregate loads. These extensions are the actual surface you write CUDA C++ against.

## Frameworks Introduced

- **Execution-space specifiers** (`__host__`, `__device__`, `__global__`, `__tile__`, `__tile_global__`): tag where a function executes and from where it is callable. `__global__` = a kernel: returns void, not a class member, no recursion, asynchronous launch, needs `<<<...>>>` config. `__host__ __device__` compiles for both — branch with `__CUDA_ARCH__`.
- **Memory-space specifiers** (`__device__`, `__constant__`, `__shared__`, `__managed__`, `__tile__`): fix a variable's storage location, scope, and lifetime. Host reaches device/constant/tile symbols via `cudaMemcpyToSymbol`/`FromSymbol`, `cudaGetSymbolAddress/Size`.
- **Kernel configuration attributes**: `__launch_bounds__(maxThreadsPerBlock[, minBlocksPerMultiprocessor[, maxBlocksPerCluster]])`, `__maxnreg__(N)`, `__cluster_dims__(x,y,z)` — compiler hints that map to PTX directives and shape occupancy.

## Key Concepts
- **`__CUDA_ARCH__`**: defined only in device compilation passes; use it to fork host/device code in `__host__ __device__` functions and to vary launch bounds per architecture. **Undefined in host code** — never branch host launch configs on it.
- **`__shared__` sizing**: static (compile-time, cannot be initialized at declaration) or dynamic (`extern __shared__ T arr[]`, size given as 3rd `<<<>>>` argument).
- **`__managed__` restrictions**: address is not a constant expression; no reference type; cannot be used during static init/destruction or when the runtime may be uninitialized; not a bare `decltype` argument (parenthesize: `decltype((var))` is OK).
- **`__restrict__`**: programmer's promise of no aliasing — unlocks CSE and reordering. *All* pointer args must be restricted to help the optimizer. On `__global__` const-restricted pointers, loads become read-only cache loads (`ld.global.nc`, like `__ldg()`). Trade-off: higher register pressure can cut occupancy.
- **`__grid_constant__`**: a `const`-qualified non-reference `__global__` parameter accessed through one shared address (no per-thread copy); read-only, kernel-lifetime, modifying is UB.
- **Inlining**: `__noinline__`, `__forceinline__`, `__inline_hint__` (LTO cross-TU) — mutually exclusive; ignored on `__tile__`.
- **Built-in variables**: `dim3 gridDim`/`blockDim`, `uint3 blockIdx`/`threadIdx`, runtime `int warpSize` (commonly 32). Not available in tile code — use `cuda::tiles::bid()` / `num_blocks()`.
- **Thread-block clusters** (CC ≥ 9.0): compile-time `__cluster_dims__(2,1,1)` or runtime via `cudaLaunchKernelEx` + `cudaLaunchAttributeClusterDimension`; grid dim must be a multiple of cluster size.
- **`__syncthreads*`**: block-wide barrier + memory ordering (the call *strongly happens-before* any thread is unblocked). Variants return aggregates over a predicate.

## Mental Models
- Think of **execution + memory specifiers as a 2-axis grid**: one axis = *who runs the code*, the other = *where the data sits*. Mismatches (a `__device__` variable named directly in `__tile_global__` code) are errors; passing *pointers* across the axis is fine because the memory is shared global DRAM.
- Think of **`__launch_bounds__(maxThreadsPerBlock)` as forward-compatibility insurance**: it caps registers so at least one block always fits an SM, avoiding "too many resources requested for launch" on future hardware. The optional `minBlocksPerMultiprocessor` is a tuning lever for occupancy vs instruction count.
- Think of **`__restrict__` as trading registers for fewer memory ops**: great when you're memory-bound and have register headroom; harmful when register pressure already caps occupancy.
- Think of **`__grid_constant__` as "one read-only copy for the whole grid"** — avoids the per-thread parameter spill for large struct kernel arguments.

## Anti-patterns
- **Using `MY_KERNEL_MAX_THREADS` (which depends on `__CUDA_ARCH__`) as the host launch block size**: `__CUDA_ARCH__` is undefined on the host, so you silently get the wrong (fallback) value. Choose block size from a CC-independent constant or at runtime via `cudaGetDeviceProperties().major`.
- **Initializing a static `__shared__` variable at its declaration**: not allowed.
- **Restrict-qualifying only some pointers**: the optimizer needs *all* aliasing pointers marked, or it must assume aliasing anyway.
- **Combining `__launch_bounds__` and `__maxnreg__` on one kernel**: forbidden.
- **Modifying a `__grid_constant__` object (even a `mutable` member)**: compile error or UB.
- **Recursion in a `__global__` function, or making it a class member, or non-`void` return**: all illegal.
- **Taking `&managed_var` in static initialization**: the address is not a constant expression.

## Reference Tables

**Execution space specifier (Table 39)**

| Specifier | Executed in | Callable from |
|---|---|---|
| `__host__` (or none) | Host | Host |
| `__device__` | SIMT | SIMT |
| `__global__` | SIMT | Host + SIMT |
| `__tile__` | Tile | Tile |
| `__tile_global__` | Tile | Host |
| `__host__ __device__` | Host + SIMT (+Tile w/ `__tile__`) | all |

**Memory space specifier (Table 40)**

| Specifier | Location | Accessible by | Lifetime | Unique instance |
|---|---|---|---|---|
| `__device__` | device global memory | grid threads / Runtime API | program/context | per device |
| `__tile__` | device global memory | tile blocks / Runtime API | program/context | per device |
| `__constant__` | device constant memory (read-only in device) | grid threads / Runtime API | program/context | per device |
| `__managed__` | host + device (automatic) | host/device threads | program | per program |
| `__shared__` | SM on-chip | block threads | block | per block |
| (none) | registers | single thread | thread | per thread |

**Annotation summary (Table 41)**

| Annotation | `__host__`/`__device__`/`__host__ __device__` | `__global__` |
|---|---|---|
| `__noinline__`, `__forceinline__`, `__inline_hint__` | Function | × |
| `__restrict__` | Pointer parameter | Pointer parameter |
| `__grid_constant__` | × | Parameter |
| `__launch_bounds__` | × | Function |
| `__maxnreg__` | × | Function |
| `__cluster_dims__` | × | Function |

**Vector types (Table 42, abridged)** — `make_<type>()` factory; fields `.x .y .z .w`.

| Fundamental | X1 / X2 / X3 / X4 |
|---|---|
| int | `int1`/`int2`/`int3`/`int4` (sizes 4/8/12/16, align 4/8/4/16) |
| float | `float1`..`float4` (4/8/12/16, align 4/8/4/16) |
| double | `double1`..`double4_16a`/`double4_32a` (`double4` deprecated in CUDA 13) |

(Also deprecated CUDA 13: `long4`, `ulong4`, `longlong4`, `ulonglong4` — use the `_16a`/`_32a` alignment-explicit variants.)

**Synchronization intrinsics**

| Intrinsic | Returns | Meaning |
|---|---|---|
| `void __syncthreads()` | — | barrier + memory order over the block |
| `int __syncthreads_count(p)` | count | number of threads with `p != 0` |
| `int __syncthreads_and(p)` | bool | non-zero iff `p != 0` for all |
| `int __syncthreads_or(p)` | bool | non-zero iff `p != 0` for any |

## Worked Example
`__syncthreads()` ordering a shared-memory write before a block-local reduction:

```cpp
// assuming blockDim.x is 128
__global__ void example_syncthreads(int* input_data, int* output_data) {
    __shared__ int shared_data[128];                       // static shared, no init
    shared_data[threadIdx.x] =
        input_data[blockDim.x * blockIdx.x + threadIdx.x]; // each thread writes its slot

    // Barrier: all writes to shared_data strongly-happen-before any thread
    // is unblocked, so thread 0 can safely read every slot below.
    __syncthreads();

    if (threadIdx.x == 0) {
        int sum = 0;
        for (int i = 0; i < blockDim.x; ++i) sum += shared_data[i];
        output_data[blockIdx.x] = sum;
    }
}
```
- **What it demonstrates**: static `__shared__` (no in-declaration init), the index idiom from Ch 1, and `__syncthreads()` as both a barrier *and* a memory fence — without it, thread 0's reads of other lanes' writes would race.

## Key Takeaways
1. Two annotation axes: execution-space (where it runs) and memory-space (where data lives); cross only via pointers, never by directly naming a variable from the wrong space.
2. `__global__` kernels: `void` return, no class membership, no recursion, async launch, mandatory `<<<grid, block, smem, stream>>>`.
3. `__CUDA_ARCH__` is device-only; using it to pick host-side launch dims silently misconfigures the launch.
4. Always add `__launch_bounds__(maxThreadsPerBlock)` for forward compatibility; the optional second arg tunes occupancy.
5. `__restrict__` (all pointers) buys CSE/reorder and read-only-cache loads at the cost of register pressure; `__grid_constant__` gives one shared read-only copy of a large kernel parameter.
6. `__syncthreads()` is a block barrier *and* memory fence; its `_count`/`_and`/`_or` variants reduce a predicate across the block.

## Connects To
- **Ch 1**: grid/block/thread hierarchy and SIMT — these built-in variables and specifiers make it concrete.
- **Ch 20**: compute-capability limits (max threads/block, registers/thread) that bound `__launch_bounds__`/`__maxnreg__`; clusters require CC ≥ 9.0.
- **Ch 22**: lambda execution spaces derive from these `__host__`/`__device__` specifiers.
- **Ch 24**: warp-level sync (`__syncwarp`), atomics, and the memory model that `__syncthreads`'s happens-before relation plugs into.
