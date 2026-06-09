# Chapter 22: C++ Language Support & Restrictions

## Core Idea
`nvcc` compiles device code as **standard C++** — selectable from C++03 through C++23 via `--std=c++NN` — and supports *all* language features of the chosen standard *subject to documented restrictions*. The host and device share the same dialect. Where the standard library is concerned, CUDA ships **libcu++** (`cuda::std::*`), a host-and-device STL implementation. A small set of C standard library functions (`printf`, `malloc`/`free`, `memcpy`, `clock`, `alloca`) are callable from device code with CUDA-specific semantics. The sharpest practitioner concern is **lambdas**: which execution space a lambda gets, and the long list of restrictions on *extended* (`__device__`/`__host__ __device__`) lambdas used as `__global__` template arguments.

## Frameworks Introduced

- **Per-standard feature tables (Tables 34–38)**: `nvcc` device-code support for C++11/14/17/20/23. Most features are supported (✓); concurrency-library features (C++11 `<atomic>`, memory model, TLS) are ✗ in the *language* tables — provided instead through libcu++ and CUDA primitives. Notable ✗ in device code: **Modules** (C++20), **Coroutines** (C++20).
- **libcu++ (`cuda::std::`)**: host+device STL; C++17 backports of newer-standard features (C++20/23/26); extended types `__int128`, `__half`, `__nv_bfloat16`, `__float128`; ships with the toolkit and in the open-source CCCL repo.
- **Extended lambdas** (`--extended-lambda`, macro `__CUDACC_EXTENDED_LAMBDA__`): lambdas annotated with `__device__` or `__host__ __device__` *inside a host or host-device function*, usable as `__global__` template type arguments. This is the bridge for passing closures into kernels.

## Key Concepts
- **Lambda execution space inference**: a lambda inherits the execution space of its *innermost enclosing function scope*; no enclosing function ⇒ `__host__`. So a lambda in a `__device__` function is `__device__`, in a `__global__` function is `__device__`, in `__host__ __device__` is `__host__ __device__`.
- **`__global__` argument rule**: a lambda may be a `__global__` argument *only if* its space is `__device__` or `__host__ __device__`. Global/namespace-scope lambdas and host-only closures are rejected.
- **Extended-lambda enclosing-function requirement**: nvcc replaces the lambda with a placeholder whose template argument takes the *address of the enclosing function* — so that function must be **named, address-accessible, non-private/protected, not local to a function, not have deduced return type, and (MSVC) have external linkage**.
- **Capture restrictions (extended lambdas)**: **by-value only** (no `&` capture); array dims ≤ 7; no variadic-pack element; no function-local types; **init-capture** allowed for device-only lambdas (not host-device, and not `initializer_list`/array initializers); the closure is **not** a literal type — `constexpr`/`consteval` forbidden.
- **C-library device functions**: `clock()`/`clock64()` (per-SM cycle counter, *time-sliced* so over-counts), `printf()` (per-thread, returns *args parsed* not chars, 32-arg cap, host-side circular buffer), `malloc`/`free`/`__nv_aligned_device_malloc` (device heap, 16-byte aligned, set size via `cudaDeviceSetLimit(cudaLimitMallocHeapSize,...)` before launch), `alloca()` (stack-frame, auto-freed on return).

## Mental Models
- Think of the **execution-space of a lambda as "wherever its enclosing function runs"** — you annotate `__device__` only to *override* that for the `__global__`-argument case.
- Think of **extended-lambda restrictions as the cost of the address-of-enclosing-function trick**: every rule (named function, accessible, not local, non-deduced return) exists because nvcc must form a valid pointer-to-function template argument behind your back.
- Think of the **device heap as a separate universe from `cudaMalloc`**: device-`malloc` memory cannot be touched by `cudaMemcpy`/`cudaFree`, and vice versa. They never mix.
- Think of `cuda::std::` as **"the STL that compiles for the GPU"** — prefer it over raw C functions (`cuda::std::memcpy`, `cuda::std::clock`, `<cuda/std/chrono>`).

## Anti-patterns
- **Capturing by reference in a `__device__` lambda**: `[&a] __device__ {...}` is an error — extended lambdas capture by value only (the host stack reference is meaningless on device).
- **Defining an extended lambda inside another extended lambda, a generic (`auto`-param) lambda, a function-local class, or a function with deduced return type**: all rejected by the enclosing-function machinery.
- **Making a host-device extended lambda generic** (`[] __host__ __device__ (auto i){...}`): forbidden; only device-only extended lambdas may be generic-ish, and even those have caveats.
- **Freeing device-`malloc` memory with `cudaFree`** (or vice versa): undefined; the two allocators are disjoint.
- **Assuming `printf` returns the character count**: CUDA's returns the *number of arguments parsed*; format-spec/arg mismatch is a warning in SIMT (an error in tile code).
- **Allocating on the device heap without sizing it first**: default is 8 MB and *cannot* be resized after a module loads — call `cudaDeviceSetLimit(cudaLimitMallocHeapSize, ...)` before any launch.

## Reference Tables

**Standard selection**

| Flag | Standard |
|---|---|
| `--std=c++03` | C++03 (14882:2003) |
| `--std=c++11` | C++11 |
| `--std=c++14` | C++14 |
| `--std=c++17` | C++17 |
| `--std=c++20` | C++20 (needs GCC≥10, Clang≥10, MSVC 2022, nvc++≥20.7) |
| `--std=c++23` | C++23 (needs GCC≥14, Clang≥18, MSVC *not supported*, nvc++≥24.3) |

**Notable device-code support gaps**

| Feature | Standard | Device support |
|---|---|---|
| `<atomic>`, memory model, TLS, sequence points | C++11 concurrency | ✗ (use libcu++ / CUDA primitives) |
| Sized deallocation, clarifying memory allocation | C++14 | ✗ |
| Modules | C++20 | ✗ |
| Coroutines | C++20 | ✗ |
| `consteval`, `constinit`, `<=>`, Concepts, `using enum` | C++20 | ✓ |
| `if consteval`, deducing `this`, `[[assume]]`, multidim `[]` | C++23 | ✓ |

**Device-callable C-library functions**

| Function | Signature (abridged) | Key semantics |
|---|---|---|
| `clock()` / `clock64()` | `__host__ __device__ clock_t clock(); __device__ long long clock64();` | per-SM cycle counter; over-counts (time-slicing); prefer `cuda::std::clock` |
| `printf()` | `__host__ __device__ __tile__ int printf(fmt, ...)` | per-thread; returns args parsed (0 if none, −1 NULL fmt, −2 error); ≤32 args; host circular buffer (default 1 MB) |
| `memcpy`/`memset` | `__host__ __device__ __tile__ void* ...` | prefer `cuda::std::memcpy`/`memset` (`<cuda/std/cstring>`) |
| `malloc`/`free` | `__host__ __device__ void* malloc(size_t); ... void free(void*)` | device heap, 16-byte aligned, NULL on OOM; double-free UB |
| `__nv_aligned_device_malloc` | `__device__ void* (size_t, size_t align)` | `align` = power of two |
| `alloca()` | `__host__ __device__ void* alloca(size_t)` | stack-frame, 16-byte aligned, auto-freed on return; can overflow stack |

**Extended-lambda type traits**

| Trait | Returns true when |
|---|---|
| `__nv_is_extended_device_lambda_closure_type(T)` | T is an extended `__device__` lambda closure |
| `__nv_is_extended_device_lambda_with_preserved_return_type(T)` | ...and it has a trailing return type not referencing its params |
| `__nv_is_extended_host_device_lambda_closure_type(T)` | T is an extended `__host__ __device__` lambda closure |

## Worked Example
Per-thread device-heap allocation — sizing the heap before launch, then allocating inside the kernel:

```cpp
#include <stdlib.h>
#include <stdio.h>

__global__ void single_thread_allocation_kernel() {
    size_t size = 123;
    char* ptr = (char*) malloc(size);   // device heap, 16-byte aligned
    memset(ptr, 0, size);
    printf("Thread %d got pointer: %p\n", threadIdx.x, ptr);
    free(ptr);                          // each thread frees its own
}

int main() {
    // MUST set heap size before any kernel launch; default is 8 MB and
    // cannot be resized after a module loads.
    cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024);
    single_thread_allocation_kernel<<<1, 5>>>();
    cudaDeviceSynchronize();
    return 0;
}
```
- **What it demonstrates**: each thread independently hits `malloc`/`free` (5 distinct pointers); the device heap is sized via `cudaDeviceSetLimit` *before* launch; this memory is disjoint from `cudaMalloc` allocations.

## Key Takeaways
1. `nvcc` supports full C++03–C++23 in device code via `--std=c++NN`, minus documented gaps (Modules, Coroutines, C++11 concurrency library).
2. A lambda's execution space = its enclosing function's; annotate `__device__`/`__host__ __device__` (extended lambdas, `--extended-lambda`) to pass closures into `__global__` templates.
3. Extended-lambda restrictions all stem from the address-of-enclosing-function transform: named, accessible, non-local function; by-value capture only; not generic for host-device; not `constexpr`.
4. libcu++ (`cuda::std::`) is the host+device STL; prefer it over raw C functions and for extended types (`__half`, `__nv_bfloat16`, `__int128`).
5. Device `malloc`/`free` use a separate 8 MB-default heap sized via `cudaLimitMallocHeapSize` *before* launch; never mix with `cudaMalloc`/`cudaFree`.
6. `printf` is per-thread, returns args parsed (not chars), caps at 32 args, and flushes its host circular buffer only on sync/launch/copy — never at program exit automatically.

## Connects To
- **Ch 23**: the `__device__`/`__host__`/`__global__`/`__tile__` execution-space specifiers that govern lambda spaces.
- **Ch 24**: atomics, fences, and the memory model that fill the C++11-concurrency gap left ✗ in the language tables.
- **Ch 2**: kernel launch (`<<<>>>`) and `cudaDeviceSynchronize` that flush `printf` and bound device-heap lifetime.
- **Ch 20**: extended types (`__int128`, bfloat16) gated by compute capability.
