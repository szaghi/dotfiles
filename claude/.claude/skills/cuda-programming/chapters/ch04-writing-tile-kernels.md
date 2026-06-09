# Chapter 4: Writing Tile Kernels (cuTile)

## Core Idea
CUDA Tile flips the programming altitude: instead of writing per-thread code and computing a global thread index, you write **per-block** code that operates on whole **tiles** (fixed-size, power-of-two, compile-time-shaped multidimensional arrays). The compiler owns thread-level mapping, including lowering to **tensor cores** (matmul) and the **Tensor Memory Accelerator (TMA)** (structured loads). Each tile block runs as a single logical thread → one control-flow path per block, so warp divergence and bank-conflict tuning simply don't exist at this level. The surrounding host code (alloc, copy, launch) is identical to SIMT. Available as `cuda.tile` (Python, aliased `ct`) and `cuda::tiles` (C++ ≥ Toolkit 13.3, `cuda_tile.h`, aliased `ct`); both share the CUDA Tile IR backend and identical semantics.

## Frameworks Introduced

- **Kernel/function declarations**: C++ `__tile_global__` (entry, = `__global__`) and `__tile__` (device-callable, = `__device__`); Python `@ct.kernel` and `@ct.function` (the latter optional — any function called from tile code is auto-compiled). Tile and SIMT code coexist in one `.cu`/program, but tile and `__device__`/`__global__` functions **cannot call each other** (current limitation).
- **Launch**: C++ reuses triple-chevron `kernel<<<grid, 1>>>(...)` — **second arg must be 1** (compiler picks thread count); also works via `cudaLaunchKernel`/`cudaLaunchKernelEx` with `grid, 1`. Python: `ct.launch(stream, grid_tuple, kernel, args_tuple)`.
- **Block-position queries**: C++ `ct::bid()` → `uint3`, `ct::num_blocks()` → `dim3` (`.x/.y/.z`); Python `ct.bid(axis)`, `ct.num_blocks(axis)`. No thread index needed.
- **Tiles**: C++ `ct::tile<T, ct::shape<dims...>>`; Python factories return tiles exposing `.shape/.dtype/.ndim`. Value semantics, cheap copies, no manual alloc/free. Factories: `ct::zeros/ones/full/iota<Tile>()` (C++); `ct.zeros/ones/full/arange(shape, dtype)` (Python).
- **Compile-time constants**: Python `ct.Constant[int]` kernel-param annotation embeds the literal value (drives shapes/loop bounds). C++ `ct::integral_constant<N>` + `_ic` literals from `ct::literals` (`8_ic`). `ct::extents`/`ct::shape` brace form mixes `_ic` (compile-time) and plain variables (runtime).
- **Tile-space loads/stores**: structured, TMA-eligible. C++ `ct::tensor_span{ptr, extents}` → `ct::partition_view{span, shape}` → `.load(idx)/.store(tile, idx)`; masked variants `.load_masked/.store_masked`. Python `Array.tiled_view(shape).load/store`, or one-call `ct.load/ct.store(array, index, shape)`.
- **Gather/scatter**: irregular access. Python `ct.gather(arr, indices)/ct.scatter(arr, indices, vals)` (bounds-checked by default). C++ builds a **tile of pointers** (`scalar_ptr + int_tile`) passed to `ct::load/ct::store`, with `ct::load_masked/store_masked` + boolean mask tile.
- **Tile primitives**: matmul `a @ b` / mma `ct::mma(a, b, acc)`; reductions `ct::sum`/scans; `ct::transpose`/`ct::permute`; selection `ct::select`/`ct.where`; element-wise math (`exp`, `sqrt`, `rsqrt`, `tanh`, ...).
- **Atomics**: per-element atomic update (whole call not atomic, order unspecified). C++ `ct::atomic_add(ptr_or_tile, val, memory_order_..._t{}, thread_scope_..._t{})`; Python `ct.gather/scatter`-style indices or `TiledView.atomic_add(index, update)`.
- **Optimization hints** (semantics-neutral, ignorable): C++ `[[ cutile::hint(arch, kind=value) ]]`; Python `@ct.kernel(...)` kwargs + per-call kwargs + `ByTarget(...)` + `.replace_hints()`.
- **C++ perf idioms**: `__restrict__`, `ct::assume_aligned(ptr, 16_ic)`, prefer `partition_view`, `ct::irange`.

## Key Concepts
- **Compile-time everything-structural**: tile shape and dtype must be known at compile time (the compiler specializes machine code per shape/type combo). Pass them as literals or `Constant`/`_ic`.
- **Tiles vs arrays**: an **array** is global-memory, visible to all blocks; a **tile** is block-local, usually a sub-region of an array. Loads move array→tile, stores move tile→array.
- **Boundary handling diverges by language**: Python `ct.load` takes `padding_mode` (`PaddingMode.ZERO` or default `UNDETERMINED`); `ct.store`/scatter silently discard OOB. C++ unmasked `.load/.store` assume in-bounds (partial OOB = UB); `.load_masked` zero-pads (or NaN, etc.), `.store_masked` discards OOB. Gather: Python auto-bounds-checks (`check_bounds=False` to disable); C++ needs an explicit boolean `mask`.
- **Single control-flow path per block**: scalar conditions/loop bounds drive control flow; tile ops in the body are distributed by the compiler. No warp divergence to reason about. (Returning from inside a loop is *not* allowed.)
- **Broadcasting = NumPy semantics**: scalars duplicate; singleton (length-1) dims stretch; lower-rank operands align to trailing dims (missing leading dims treated as singleton). Two non-singleton unequal dims → ill-formed.
- **Type promotion on mixed arithmetic**: tile+tile → higher precision/range (`int+float`→`float`). Scalar+tile: if exactly representable, use tile type; if narrowing needed (`int_tile + 2.5`), **Python promotes**, **C++ rejects as ill-formed**.
- **FP32-accumulate GEMM pattern**: accumulate in FP32 regardless of input precision, cast on store; K-loop runs `ceil(K/tk)` times, partial K-tiles zero-padded, partial M/N edges store-discarded.
- **Reduction result-shape diverges**: Python **drops** the reduced axis by default (`keepdims=True` to keep); C++ **always keeps** it (preserves rank).
- **`__restrict__` is load-bearing for perf**: if the compiler can't prove input/output arrays don't overlap, it must complete all tile reads before any writes (no read/write interleave). Mislabeling overlapping memory `__restrict__` = UB.
- **16-byte alignment enables TMA**: `ct::assume_aligned(ptr, 16_ic)` is required for `partition_view` to lower to TMA. `cudaMalloc` pointers are ≥16-byte aligned; providing unaligned pointers anyway is UB.

## Mental Models
- **Tile programming as "NumPy on a block"**: you write array-level ops (`a + b`, `a @ b`, `ct.sum`, `ct.where`) and the compiler vectorizes them onto threads and tensor cores — the SIMT thread-index bookkeeping vanishes.
- **`partition_view` as a tiling stencil**: lay a fixed grid of non-overlapping tiles over an array; address one tile by its tile-space index (`bid`). Reuse the view when partitioning is reused; use the one-call `ct.load`/`ct.store` for one-offs.
- **Hints as tuning knobs, not contracts**: add/remove/`replace_hints` freely — correctness never changes, only codegen. `ByTarget`/per-arch values let one kernel tune per SM.
- **`__restrict__` as a promise that unlocks overlap of reads and writes**: the single biggest C++ tile perf lever after alignment.

## Anti-patterns
- **Launching C++ tile kernels with a thread count ≠ 1**: the second chevron arg must be `1`.
- **Mixing tile and `__device__`/`__global__` calls**: currently unsupported across the boundary.
- **Passing runtime-varying tile shapes**: shape/dtype must be compile-time (`Constant`/`_ic`/literals) or the kernel won't compile.
- **Unmasked C++ load/store on partial edge tiles**: undefined behavior. Use `.load_masked/.store_masked` (or correct `padding_mode` in Python) when the array isn't tile-divisible.
- **Loading a tile fully outside the array**: always undefined — masking only saves *partially* OOB tiles.
- **Narrowing scalar literals in C++ tile arithmetic** (`int_tile + 2.5`): ill-formed; write literals in the tile's element type.
- **Omitting `__restrict__` / `ct::assume_aligned(..., 16_ic)`**: forces conservative codegen and blocks TMA — measurable slowdown.
- **Gather/scatter for structured access**: prefer `partition_view`/`tiled_view` (TMA-eligible) over per-element gather.
- **Plain `for` over opaque bounds in C++**: use `ct::irange` so the compiler can pipeline/vectorize.
- **Hand-rolling a tile→scalar sum via intra-block atomics**: use `ct::sum`/reduction instead (the atomic form is illustrative only).
- **Relying on per-element atomic ordering**: order within a tile atomic call is unspecified — only use it where the op is commutative/associative.

## Reference Tables

**SIMT ↔ Tile mapping**

| Concept | SIMT | Tile (C++) | Tile (Python) |
|---|---|---|---|
| Entry point | `__global__` | `__tile_global__` | `@ct.kernel` |
| Device fn | `__device__` | `__tile__` | `@ct.function` |
| Launch | `f<<<g, b>>>` | `f<<<g, 1>>>` | `ct.launch(stream, g, f, args)` |
| Block index | `blockIdx` | `ct::bid()` | `ct.bid(axis)` |
| Unit of work | thread + manual index | whole tile | whole tile |

**Boundary handling**

| Op | C++ | Python |
|---|---|---|
| Structured load OOB | `.load_masked` (zero/NaN pad) | `padding_mode=PaddingMode.ZERO` |
| Structured store OOB | `.store_masked` (discard) | `ct.store` always discards |
| Gather OOB | explicit boolean `mask` + `load_masked` | bounds-checked by default (`check_bounds=False` to disable) |

**Key primitives**

| Operation | C++ | Python |
|---|---|---|
| matmul / mma | `a @ b` / `ct::mma(a,b,acc)` | `a @ b` / `ct.mma(a,b,acc)` |
| reduction | `ct::sum(x, 1_ic)` (keeps axis) | `ct.sum(x, axis=1)` (drops; `keepdims=True`) |
| transpose / permute | `ct::transpose` / `ct::permute(x, dimension_map{...})` | `ct.transpose` / `ct.permute(x, axes)` |
| select | `ct::select(cond, a, b)` | `ct.where(cond, a, b)` |
| concat | `ct::cat<0>(l,r)` or `ct::cat(l,r,0_ic)` | — |

**Hint kinds** (shared semantics)

| Hint | C++ name | Python name | Values |
|---|---|---|---|
| CTAs per cluster | `num_cta_in_cga` | `num_ctas` | 1,2,4,8,16 (sm_80: 1 only) |
| Occupancy | `occupancy` | `occupancy` | [1,32] active CTAs/SM |
| Mem latency | `latency` | `latency` | [1,10] (10 = heavy → deeper prefetch) |
| Allow TMA | `allow_tma` | `allow_tma` | true/false (loads/stores only) |

## Worked Example
A tiled GEMM with FP32 accumulation and masked edge handling — the canonical tensor-core kernel, showing `partition_view`, the `ct::mma` K-loop, and `ct::irange`:

```cpp
__tile_global__ void gemm(const __half* __restrict__ A, const __half* __restrict__ B, float* __restrict__ C,
                          std::size_t M, std::size_t K, std::size_t N) {
    namespace ct = cuda::tiles;
    using namespace ct::literals;
    using f32_acc = ct::tile<float, ct::shape<32, 32>>;

    A = ct::assume_aligned(A, 16_ic);
    B = ct::assume_aligned(B, 16_ic);
    C = ct::assume_aligned(C, 16_ic);

    constexpr auto tm = 32_ic; constexpr auto tn = 32_ic; constexpr auto tk = 16_ic;

    auto aView = ct::partition_view{ct::tensor_span{A, ct::extents{M, K}}, ct::shape{tm, tk}};
    auto bView = ct::partition_view{ct::tensor_span{B, ct::extents{K, N}}, ct::shape{tk, tn}};
    auto cView = ct::partition_view{ct::tensor_span{C, ct::extents{M, N}}, ct::shape{tm, tn}};

    auto [bx, by, bz] = ct::bid();
    auto acc = ct::full<f32_acc>(0.0f);                  // FP32 accumulator

    std::size_t num_k = (K + tk - 1) / tk;
    for (auto k : ct::irange(std::size_t{0}, num_k)) {
        acc = ct::mma(aView.load_masked(bx, k),          // zero-pad partial K-tile
                      bView.load_masked(k, by),
                      acc);                              // acc += a @ b
    }
    cView.store_masked(acc, bx, by);                     // drop OOB edge lanes
}
```
- **Demonstrates**: `__restrict__` + `assume_aligned(...,16_ic)` (TMA + non-overlap), compile-time tile dims via `_ic`, the two-step `tensor_span`→`partition_view` construction, an FP32 accumulator carried across the `ct::irange` K-loop, masked loads to zero-pad partial K-tiles, and a masked store to discard partial M/N edges. The Python counterpart is `ct.mma(a, b, acc)` with `PaddingMode.ZERO` loads and `acc.astype(C.dtype)` on store.

## Key Takeaways
1. Write per-block, tile-level code; the compiler maps to threads, tensor cores, and TMA. No thread index, no warp divergence, no manual bank-conflict tuning.
2. Tile shape and dtype are compile-time (`Constant`/`_ic`/literals); tiles have value semantics and need no manual memory management.
3. Prefer structured `partition_view`/`tiled_view` loads (TMA-eligible) over gather/scatter; reserve gather/scatter for irregular, data-dependent access.
4. Handle non-divisible arrays with masked loads/stores (C++) or `padding_mode` (Python); fully-OOB tiles are always UB.
5. Tile arithmetic broadcasts NumPy-style; mixed types promote to higher precision; C++ rejects narrowing scalar literals where Python promotes.
6. Reductions: Python drops the reduced axis (`keepdims=True` to keep), C++ keeps it. GEMM: accumulate FP32, cast on store.
7. Atomics do one atomic per element with unspecified order — use only for commutative merges; prefer reductions for in-block sums.
8. Hints never change semantics (tune freely); `__restrict__` and 16-byte alignment are the load-bearing C++ perf annotations, and `ct::irange` unlocks loop pipelining.

## Connects To
- **Ch 1**: the tile programming model introduced as a per-block alternative to SIMT — made concrete here.
- **Ch 2**: identical host-side alloc/copy/launch and the `cudaLaunchKernelEx`/cluster machinery tile launches reuse.
- **Ch 3**: the SIMT concerns (coalescing, bank conflicts, divergence) that the tile compiler handles automatically — same hardware goals, higher abstraction.
- **Tensor cores / TMA hardware chapters**: what `ct::mma` and TMA-lowered `partition_view` loads target.
- **CCCL**: tuned primitives (`cuda.coop`) for cases beyond hand-written tile kernels.
