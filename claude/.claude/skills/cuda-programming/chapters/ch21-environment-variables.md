# Chapter 21: CUDA Environment Variables

## Core Idea
CUDA exposes a set of **process-level environment variables** that tune device visibility, JIT-compilation caching, launch/execution behavior, module loading, and error logging — *without recompiling*. They are the operator's knobs: pin GPUs (`CUDA_VISIBLE_DEVICES`), make launches synchronous for debugging (`CUDA_LAUNCH_BLOCKING`), trade startup time for footprint (`CUDA_MODULE_LOADING`), and surface descriptive driver errors (`CUDA_LOG_FILE`). MPS-related variables live in the GPU Deployment and Management Guide, not here.

## Frameworks Introduced

- **Device enumeration control**: `CUDA_VISIBLE_DEVICES` + `CUDA_DEVICE_ORDER` together decide *which* GPUs the app sees and *in what ordinal order*. This is the primary multi-GPU isolation and binding mechanism.
  - When to use: pin a process to specific GPUs (job schedulers, per-rank MPI binding, reproducibility).
- **JIT cache controls** (`CUDA_CACHE_*`, `CUDA_FORCE_*`, `CUDA_DISABLE_*`): govern the on-disk PTX→cubin cache and whether the driver uses embedded cubin or JITs the PTX. Used to validate forward compatibility and diagnose driver/build differences.
- **Lazy vs eager module loading** (`CUDA_MODULE_LOADING`, `CUDA_MODULE_DATA_LOADING`): trade program startup time and GPU memory footprint against predictable launch overhead. Default is LAZY.

## Key Concepts
- **Ordinal remapping**: with `CUDA_VISIBLE_DEVICES=2,1`, `cudaGetDeviceCount()` returns 2; `cudaSetDevice(0)` selects physical device 2 (first enumerated). Invalid index truncates the list — `0,2,-1,1` makes only 0 and 2 visible.
- **GPU identifiers**: integer indices (per `nvidia-smi`), full or abbreviated UUID strings (`GPU-8932f937...`), or MIG strings (`MIG-<UUID>/<gi>/<ci>`, single instance only).
- **Override precedence**: `CUDA_FORCE_PTX_JIT` overrides `CUDA_FORCE_JIT`; `CUDA_DISABLE_PTX_JIT` overrides `CUDA_DISABLE_JIT`; `CUDA_DEVICE_MAX_COPY_CONNECTIONS` overrides the copy count set by `CUDA_DEVICE_MAX_CONNECTIONS`.
- **Synchronous debugging**: `CUDA_LAUNCH_BLOCKING=1` makes every launch synchronous so API errors surface *at the offending call*, not later.
- **Work-queue false dependencies**: set `CUDA_DEVICE_MAX_CONNECTIONS` ≥ number of active streams/context to avoid serializing independent streams onto a shared queue.

## Mental Models
- Think of `CUDA_VISIBLE_DEVICES` as a **renaming filter applied before the app starts**: physical IDs disappear, only the filtered/reordered ordinals exist inside the process.
- Think of the JIT cache vars as the **PTX forward-compat test harness**: `CUDA_FORCE_PTX_JIT=1` proves your PTX still compiles on new silicon; `CUDA_DISABLE_PTX_JIT=1` proves your cubins cover every kernel.
- Think of LAZY vs EAGER as **startup-latency vs steady-state-predictability**: LAZY pays per-first-call and shrinks footprint; EAGER front-loads everything for deterministic launch cost.

## Anti-patterns
- **Relying on physical device indices after setting `CUDA_VISIBLE_DEVICES`**: APIs only accept ordinals `[0, visible_count-1]`; the physical numbers are gone.
- **Setting `CUDA_DEVICE_ORDER` and assuming index 0 is the same GPU as before**: default `FASTEST_FIRST` reorders by heuristic; use `PCI_BUS_ID` for stable binding.
- **Leaving `CUDA_LAUNCH_BLOCKING=1` in production**: it serializes host↔device and tanks throughput; it is a debug-only knob.
- **Under-provisioning work queues**: fewer connections than active streams creates false dependencies and silently serializes concurrent kernels/copies.

## Reference Tables

**Device enumeration & properties**

| Variable | Meaning | Values / default |
|---|---|---|
| `CUDA_VISIBLE_DEVICES` | which GPUs visible + enumeration order | comma list of indices / UUIDs / MIG strings; unset = all, empty = none |
| `CUDA_DEVICE_ORDER` | enumeration ordering | `FASTEST_FIRST` (default), `PCI_BUS_ID` |
| `CUDA_MANAGED_FORCE_DEVICE_ALLOC` | force device memory for Unified Memory storage | 0 (default) / non-zero (requires P2P-compatible devices, else `cudaErrorInvalidDevice`) |

**JIT compilation**

| Variable | Meaning | Values / default |
|---|---|---|
| `CUDA_CACHE_DISABLE` | disable on-disk JIT cache | 1 = disable / 0 = enable (default) |
| `CUDA_CACHE_PATH` | JIT cache directory | path; default `~/.nv/ComputeCache` (Linux), `%APPDATA%\NVIDIA\ComputeCache` (Win) |
| `CUDA_CACHE_MAXSIZE` | JIT cache size, bytes | default 1 GiB desktop / 256 MiB embedded; max 4 GiB |
| `CUDA_FORCE_PTX_JIT` / `CUDA_FORCE_JIT` | ignore embedded cubin, JIT the PTX | 1 / 0; PTX form overrides JIT form |
| `CUDA_DISABLE_PTX_JIT` / `CUDA_DISABLE_JIT` | disable PTX JIT, require compatible cubin | 1 / 0; PTX form overrides JIT form |
| `CUDA_FORCE_PRELOAD_LIBRARIES` | preload NVVM/JIT libs at init (avoids multi-thread deadlocks) | 1 / 0 (default) |

**Execution**

| Variable | Meaning | Values / default |
|---|---|---|
| `CUDA_LAUNCH_BLOCKING` | synchronous launches for debugging | 1 = sync / 0 = async (default) |
| `CUDA_DEVICE_MAX_CONNECTIONS` | compute + copy work queues | 1–32, default 8 |
| `CUDA_DEVICE_MAX_COPY_CONNECTIONS` | copy work queues (CC ≥ 8.0) | 1–32, default 8; overrides copy count from above |
| `CUDA_SCALE_LAUNCH_QUEUES` | command-buffer scaling factor | 0.25x, 0.5x, 2x, 4x (other = 1x) |
| `CUDA_GRAPHS_USE_NODE_PRIORITY` | honor per-node graph priorities | 0 = inherit stream (default) / 1 = node priorities |
| `CUDA_DEVICE_WAITS_ON_EXCEPTION` | halt on device exception for debugger attach | 0 (default) / 1 |
| `CUDA_DEVICE_DEFAULT_PERSISTING_L2_CACHE_PERCENTAGE_LIMIT` | L2 set-aside % for persisting accesses (CC ≥ 8.0, MPS) | 0–100, default 0; set before MPS daemon |
| `CUDA_DISABLE_PERF_BOOST` | disable perf-state boost (Linux) | 1 / 0 (default) |
| `CUDA_AUTO_BOOST` *(deprecated)* | clock auto-boost; use `nvidia-smi --applications-clocks` instead | — |

**Module loading & error log**

| Variable | Meaning | Values / default |
|---|---|---|
| `CUDA_MODULE_LOADING` | kernel load timing | `DEFAULT`(=LAZY), `LAZY`, `EAGER` |
| `CUDA_MODULE_DATA_LOADING` | module-data load timing | `DEFAULT`(=LAZY), `LAZY`, `EAGER`; inherits from `CUDA_MODULE_LOADING` if unset |
| `CUDA_BINARY_LOADER_THREAD_COUNT` | CPU threads for binary loading | integer, default 0 (= 1 thread) |
| `CUDA_LOG_FILE` | descriptive error-log destination | `stdout`, `stderr`, or file path |

## Worked Example
Pin an MPI rank to one GPU with stable ordering and synchronous error reporting during bring-up:

```bash
# Stable PCI ordering so ordinal 0 is always the same physical card
export CUDA_DEVICE_ORDER=PCI_BUS_ID
# Expose exactly one GPU to this process (rank-local binding)
export CUDA_VISIBLE_DEVICES=$LOCAL_RANK
# Make launches synchronous so a bad config aborts at the launch line
export CUDA_LAUNCH_BLOCKING=1
# Route descriptive driver errors somewhere greppable
export CUDA_LOG_FILE=/tmp/cuda_${LOCAL_RANK}.log
./my_cuda_app
```
- **What it demonstrates**: the common multi-GPU binding idiom (order + visibility), plus the two debug knobs. Inside the app, `cudaSetDevice(0)` now refers to the single visible card, and an invalid block dim like `dim3(1,1,128)` produces a descriptive message in the log rather than a bare "invalid configuration argument".

## Key Takeaways
1. `CUDA_VISIBLE_DEVICES` + `CUDA_DEVICE_ORDER` are the multi-GPU binding/isolation primitives; after filtering, only remapped ordinals exist.
2. `FASTEST_FIRST` is the default order and is *not stable* — use `PCI_BUS_ID` when you need reproducible device identity.
3. JIT cache + force/disable vars are your forward-compatibility test harness: force PTX JIT to validate new silicon, disable PTX JIT to validate cubin coverage.
4. `CUDA_LAUNCH_BLOCKING=1` and `CUDA_DEVICE_WAITS_ON_EXCEPTION=1` are debug-only; leaving them on kills concurrency.
5. Set `CUDA_DEVICE_MAX_CONNECTIONS` ≥ active streams to avoid false-dependency serialization.
6. LAZY (default) loading minimizes startup/footprint; EAGER gives predictable launch latency.

## Connects To
- **Ch 1**: PTX/cubin/fatbin compatibility — the JIT cache and force/disable vars operate directly on that pipeline.
- **Ch 20**: compute capability — `CUDA_DEVICE_MAX_COPY_CONNECTIONS` and the L2-persisting var are CC ≥ 8.0 gated.
- **Ch 2**: streams, launches, error checking — `CUDA_LAUNCH_BLOCKING` and the connection knobs shape stream concurrency.
