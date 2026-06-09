# Chapter 20: Compute Capabilities & Technical Specs

## Core Idea
Every CUDA device has a **compute capability** `X.Y` (major.minor) that fixes both the *feature set* it supports and the *hardware limits* (threads/block, registers/SM, shared memory, warp size). The major number names the architecture family; the minor refines it. You query it at build time (to choose `sm_XY` targets) and at runtime (to gate feature use). Since CC 9.0, not all features are forward-portable: **architecture-specific** (`a` suffix) and **family-specific** (`f` suffix) targets carve out specialized hardware (Tensor Cores, TMA) that does not propagate to all later architectures.

## Frameworks Introduced

- **Three feature-set compiler targets** — the central CC 9.0+ concept:
  - **Baseline** (`compute_XY`, e.g. `compute_100`): the portable set; available on this CC *and all later ones*. Summarized in Table 29.
  - **Family-specific** (`compute_XYf`, e.g. `compute_100f`): a superset of baseline; the subset of architecture features *shared across a GPU family*. Runs only on family members. Introduced with CC 10.0.
  - **Architecture-specific** (`compute_XYa`, e.g. `compute_100a`): the *complete* specialized set for one exact CC. Runs only on that exact CC. Superset of the family set. Introduced with CC 9.0.
  - Subset chain: `baseline ⊂ family ⊂ architecture-specific`.

## Key Concepts
- **Querying CC**: page lookup (NVIDIA GPU Compute Capability table), `nvidia-smi --query-gpu=name,compute_cap`, or programmatically via `cudaDeviceGetAttribute()`, `cuDeviceGetAttribute()`, or `nvmlDeviceGetCudaComputeCapability()`.
- **Runtime attributes**: `cudaDevAttrComputeCapabilityMajor` / `...Minor` (Runtime API); `CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR` / `...MINOR` (Driver API).
- **Feature availability default**: most features introduced with an architecture *are* available on all later ones (the "yes" propagation in Table 29) — this is the baseline contract.
- **Architecture-specific features** (CC ≥ 9.0): may *not* survive to later CCs; target accelerators like Tensor Core ops that change generation-to-generation. Built with the `a` suffix; runnable only on the exact CC compiled for.
- **Family-specific features** (CC ≥ 10.0): architecture features common to *more than one* CC. Guaranteed across the family; built with the `f` suffix.
- **Endianness**: all NVIDIA GPU architectures are little-endian.
- **Unit convention**: in these tables `KB` = 1024 bytes (KiB) and `K` = 1024.

## Mental Models
- Think of the three targets as **concentric portability rings**: `compute_100` is the widest net (any 10.x+ device), `compute_100f` narrows to one family, `compute_100a` pins to one exact chip. You pay portability to unlock specialized silicon.
- Think of the **major number as the warranty boundary**: with few exceptions, later devices sharing a major CC are in the same family (Table 28). Cross-major = different family = no `f` portability.
- Think of **runtime CC query as a feature gate**, not just a printout: branch on it to call `atomicAdd(float4*)` only where CC ≥ 9.0 etc.

## Anti-patterns
- **Compiling with `a` suffix and expecting forward compatibility**: `compute_100a` runs *only* on CC 10.0 — not 10.3, not 11.0. It is the least portable choice.
- **Assuming every new feature is forever**: pre-9.0 yes; from 9.0 onward, architecture-specific features can vanish on the next generation.
- **Hardcoding limits** (e.g. "2048 threads/SM"): these vary by CC (1024 on 7.5, 1536 on 8.6/12.x). Query, don't assume.
- **Shared-memory allocation > 48 KB/block without opt-in**: requires dynamic shared memory plus an explicit opt-in (Configuring L1/Shared Memory Balance), or the launch fails.

## Reference Tables

**Family-specific compatibility (Table 28)**

| Compilation target | Compatible with CC |
|---|---|
| `compute_100f` | 10.0, 10.3 |
| `compute_103f` | 10.3 |
| `compute_110f` | 11.0 |
| `compute_120f` | 12.0, 12.1 |
| `compute_121f` | 12.1 |

**Device / SM info per CC (Table 30, key rows)**

| Spec | 7.5 | 8.0 | 8.6 | 8.9 | 9.0 | 10.x | 11.0 | 12.x |
|---|---|---|---|---|---|---|---|---|
| FP32:FP64 throughput ratio | 32:1 | 2:1 | 64:1 | 64:1 | 2:1 | 64:1 | 64:1 | 64:1 |
| Max resident grids/device | 128 | 128 | 128 | 128 | 128 | 128 | 128 | 128 |
| Max grid dimensionality | 3 | | | | | | | |
| Max grid x-dim | 2³¹−1 | | | | | | | |
| Max grid y/z-dim | 65535 | | | | | | | |
| Max block dimensionality | 3 | | | | | | | |
| Max block x/y-dim | 1024 | | | | | | | |
| Max block z-dim | 64 | | | | | | | |
| Max threads/block | 1024 | | | | | | | |
| Warp size | 32 | | | | | | | |
| Max resident blocks/SM | 16 | 32 | 16 | 24 | 32 | 32 | 32 | 24 |
| Max resident warps/SM | 32 | 64 | 48 | 48 | 64 | 64 | 64 | 48 |
| Max resident threads/SM | 1024 | 2048 | 1536 | 1536 | 2048 | 2048 | 2048 | 1536 |

(Common values: registers/thread max = 255; registers/SM = 64K; registers/block max = 64K — see Table 31.)

**Memory info per CC (Table 31, key rows)**

| Spec | 7.5 | 8.0 | 8.6 | 9.0 | 10.x | 12.x |
|---|---|---|---|---|---|---|
| 32-bit registers/SM | 64 K | 64 K | 64 K | 64 K | 64 K | 64 K |
| Max 32-bit registers/block | 64 K | | | | | |
| Max 32-bit registers/thread | 255 | | | | | |
| Max shared mem/SM | 64 KB | 164 KB | 100 KB | 228 KB | 228 KB | 100 KB |
| Max shared mem/block | 64 KB | 163 KB | 99 KB | 227 KB | 227 KB | 99 KB |
| Shared memory banks | 32 | | | | | |
| Max local mem/thread | 512 KB | | | | | |
| Constant memory size | 64 KB | | | | | |

**Shared memory capacity (Table 32)**

| CC | Unified data cache (KB) | SMEM capacity options (KB) |
|---|---|---|
| 7.5 | 96 | 32, 64 |
| 8.0 / 8.7 | 192 | 0, 8, 16, 32, 64, 100, 132, 164 |
| 8.6 / 8.9 / 12.x | 128 | 0, 8, 16, 32, 64, 100 |
| 9.0 / 10.x / 11.0 | 256 | 0, 8, 16, 32, 64, 100, 132, 164, 196, 228 |

**Feature support highlights (Table 29)** — `Yes` from the listed CC onward (baseline):

| Feature | Introduced |
|---|---|
| 128-bit-integer atomics (shared/global) | 9.0 |
| `atomicAdd()` on `float2`/`float4` (global) | 9.0 |
| Warp reduce functions | 8.x |
| Bfloat16 ops | 8.x |
| Hardware `memcpy_async` (Pipelines) | 8.x |
| Hardware split arrive/wait barrier | 8.x |
| L2 cache residency management | 8.x |
| DPX instructions (native) | 9.0 (multi-instr emulation earlier) |
| Distributed shared memory | 9.0 |
| Thread block cluster | 9.0 |
| Tensor Memory Accelerator (TMA) | 9.0 |

## Worked Example
Runtime compute-capability query — the canonical gate before using a CC-specific feature:

```cpp
#include <cuda_runtime_api.h>

int major, minor;
cudaDeviceGetAttribute(&major, cudaDevAttrComputeCapabilityMajor, device_id);
cudaDeviceGetAttribute(&minor, cudaDevAttrComputeCapabilityMinor, device_id);

if (major >= 9) {
    // safe to use thread block clusters, 128-bit atomics, TMA path
} else {
    // fall back to the baseline kernel
}
```
- **What it demonstrates**: two-call major/minor query, and branching on `major`/`minor` as a feature gate rather than assuming a fixed target.

## Key Takeaways
1. Compute capability `X.Y` fixes both *features* and *hardware limits*; query it, never assume.
2. Three compiler targets form portability rings: `compute_XY` (baseline, forward-portable) ⊂ `compute_XYf` (family) ⊂ `compute_XYa` (one exact chip).
3. From CC 9.0, architecture-specific features (TMA, Tensor Core, clusters) may not survive to later generations — the old "every feature is forever" rule ended at 9.0.
4. Hardware limits drift across CC: max threads/SM is 1024 (7.5) → 2048 (8.0/9.0) → 1536 (8.6/12.x); shared mem/SM ranges 64 KB → 228 KB.
5. Shared memory > 48 KB/block needs dynamic allocation + explicit opt-in.
6. `nvidia-smi --query-gpu=name,compute_cap` at the shell; `cudaDeviceGetAttribute` in code.

## Connects To
- **Ch 1**: CC ↔ `sm_XY` ↔ PTX `compute_XY` compatibility model — this chapter is the §5.1 spec appendix it references.
- **Ch 23**: `__launch_bounds__`, max registers/thread — the limits here constrain those annotations.
- **Ch 24**: 128-bit/`float4` atomics and warp intrinsics gated by the feature table here.
- **Ch 21**: environment variables that select/order devices once you know their CC.
