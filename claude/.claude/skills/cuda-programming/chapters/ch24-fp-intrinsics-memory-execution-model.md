# Chapter 24: Floating-Point, Intrinsics, Memory & Execution Models

## Core Idea
This chapter binds four reference topics into one practitioner contract. **Floating-point**: CUDA implements IEEE-754, and the order of operations, FMA contraction, and denormal handling change results in ways that are *correct yet not bit-identical* across host/device. **Intrinsics**: `__`-prefixed device-only functions trade accuracy for speed (`__fdividef`, `__sinf`); `--use_fast_math` swaps them in wholesale. **Memory model**: CUDA extends C++ atomics with **thread scopes** (`thread`/`block`/`device`/`system`) because synchronization cost is *non-uniform* — cheap within a block, expensive across GPUs. **Execution model**: device threads provide only **parallel forward progress** (a thread is guaranteed to progress only *after* it has executed at least one step), which is weaker than the host's concurrent forward progress and forbids spin-wait idioms that work on a CPU.

## Frameworks Introduced

- **IEEE-754 + FMA**: single rounding step `rn(x*y+z)` beats separate multiply-add; enabled via `-fmad=true` / `--use_fast_math`, `fma()`/`fmaf()`, or `__fma[f]_[rn,rz,ru,rz]` intrinsics. FMA defends against subtractive-cancellation precision loss by keeping a double-width product.
- **Intrinsic math functions** (`__sinf`, `__expf`, `__fdividef`, …): device-only, fewer native instructions, documented ULP error; `--use_fast_math` auto-translates a fixed list (Table 60) *and* affects `-ftz`, `-prec-div`, `-prec-sqrt`.
- **Thread scopes** (`cuda::thread_scope_{system,device,block,thread}`): the scope parameter on `cuda::atomic`/`cuda::atomic_ref`/`cuda::barrier` declaring *which threads* the operation is atomic and ordered with respect to. `std::`/`cuda::std::` types behave as the `system`-scoped `cuda::` types.
- **Forward-progress model** ([intro.progress] modifications): device threads guarantee progress only after their first step; once one thread in a cooperative grid / cluster / block progresses, the rest of that group eventually do too — but *other clusters need not*.

## Key Concepts
- **Associativity is lost**: `(A+B)+C != A+(B+C)` in finite precision; this is not a GPU bug. CPU↔GPU differences usually stem from associativity + FMA contraction + library rounding, not error.
- **Denormals (subnormals)**: required by IEEE-754 but costly; `-ftz=true` (flush-to-zero, included in `--use_fast_math`) drops them for speed. `__tanhf` notably does *not* flush even under `-ftz`.
- **Rounding modes** (`rn` nearest-ties-even default, `rz` toward zero, `ru` toward +∞, `rd` toward −∞): selectable per-op via intrinsic suffix.
- **Non-FMA intrinsics**: `__fadd_rn`/`__fmul_rn` etc. map to ops the compiler *never* fuses into FFMA/DFMA — use them to force separate rounding; `*`/`+` operators *are* fused.
- **Atomicity at system scope is conditional**: it depends on device attributes — `pageableMemoryAccess`, `concurrentManagedAccess`, `hostNativeAtomicSupported`, `cudaDevP2PAttrNativeAtomicSupported`. GPU-only access to GPU memory is the easy case.
- **Data race redefinition**: a race occurs if two conflicting concurrent actions, *at least one not atomic at a scope that includes the other thread*, lack a happens-before — UB. The scope must *include* the other thread, or the "atomic" op doesn't synchronize.
- **Device forward-progress restrictions**: a device thread may NOT rely on `std::this_thread::yield`, volatile/atomic ops on *automatic-storage* objects, or a trivial infinite loop to guarantee progress — these spin idioms that terminate on a CPU may hang on the GPU.

## Mental Models
- Think of **thread scope as a synchronization radius**: `block` is cheap and local, `system` is expensive and global. Pick the *smallest* scope that includes every thread that must see the operation — and never smaller (the message-passing race below).
- Think of **`--use_fast_math` as a blunt instrument**: it changes accuracy *and* special-case handling (denormals, division ULP) for the whole TU. The robust move is to hand-pick intrinsics where the speed pays and the accuracy loss is acceptable.
- Think of **device forward progress as "the GPU will run your thread only once it's been scheduled, and only your block/cluster/grid-mates are guaranteed to join it"** — cross-cluster spin-waits can deadlock because the other cluster may never be scheduled.
- Think of **FMA as free precision on subtractive cancellation**: the double-width intermediate product preserves bits that a separate multiply-then-add would have already rounded away.

## Anti-patterns
- **Block-scope store read by a thread in another block**: `cuda::atomic_ref<int, thread_scope_block>` stored in block 0 and loaded in block 1 is a *data race / UB* — the store's scope doesn't include the loading thread. Use `thread_scope_device`.
- **CPU-style spin-wait on the GPU**: `while(True);` on a volatile automatic, or `cuda::atomic<bool, thread_scope_thread>` automatic-storage flag, may *never* make progress (allowed outcomes Execution.Model.Device.2/3).
- **Cross-cluster producer/consumer without cooperative launch**: a consumer block busy-waiting on a producer block in another cluster can hang — only same-cluster (or cooperative-grid) progress is guaranteed.
- **Treating CPU≠GPU bit differences as a correctness bug**: associativity, FMA, and non-IEEE library functions legitimately diverge.
- **Global `--use_fast_math` in a numerics-sensitive kernel**: silently degrades division to 2 ULP and flushes denormals — verify against an optimizations-off (`-G`) build.
- **Forcing FMA off by accident**: writing `__fmul_rn` then `__fadd_rn` blocks fusion; if you *want* FMA, use `*`/`+` or `fma()`.

## Reference Tables

**Rounding-mode suffixes**

| Suffix | Mode |
|---|---|
| `_rn` | round to nearest, ties to even (default) |
| `_rz` | round toward zero |
| `_ru` | round toward +∞ |
| `_rd` | round toward −∞ |

**IEEE-compliant (0-ULP) intrinsics (Table 58)** — never fused into FMA (except the fma ones):

| Op | float | double |
|---|---|---|
| x+y | `__fadd_[rn,rz,ru,rd]` | `__dadd_[...]` |
| x−y | `__fsub_[...]` | `__dsub_[...]` |
| x·y | `__fmul_[...]` | `__dmul_[...]` |
| x·y+z | `__fmaf_[...]` | `__fma_[...]` |
| x/y | `__fdiv_[...]` | `__ddiv_[...]` |
| 1/x | `__frcp_[...]` | `__drcp_[...]` |
| √x | `__fsqrt_[...]` | `__dsqrt_[...]` |

**Fast single-precision intrinsics (Table 59, ULP)**

| Function | Max ULP / error |
|---|---|
| `__fdividef(x,y)` | 2 for \|y\| ∈ [2⁻¹²⁶, 2¹²⁶] |
| `__frsqrt_rn(x)` | 0 |
| `__expf(x)` | 2 + ⌊\|1.173·x\|⌋ |
| `__logf(x)` | 3 ULP (2⁻²¹·⁴¹ abs in [0.5,2]) |
| `__sinf/__cosf(x)` | 2⁻²¹·⁴¹ abs in [−π,π], larger else |
| `__tanhf(x)` | rel 2⁻¹¹; not flushed under -ftz |

**`--use_fast_math` translations (Table 60)**: `x/y`,`fdividef`→`__fdividef`; `sinf/cosf/tanf/sincosf`→`__*`; `logf/log2f/log10f`→`__*`; `expf/exp10f`→`__*`; `powf`→`__powf`; `tanhf`→`__tanhf`.

**Thread scopes (memory model)**

| Scope | Synchronizes |
|---|---|
| `cuda::thread_scope_system` | all threads in the system (GPUs + CPUs) |
| `cuda::thread_scope_device` | all GPU threads on the same device + sync domain |
| `cuda::thread_scope_block` | all threads in the same thread block |
| `cuda::thread_scope_thread` | the thread itself |

**FP types (Table 44/45)**: `__nv_bfloat16` (`<cuda_bf16.h>`, CC≥8.0, non-IEEE), `__half` (`<cuda_fp16.h>`, IEEE), `float`/`double` (built-in, IEEE), `__float128`/`_Float128` (CC≥10.0 + host support). Epsilon: half 2⁻¹⁰, bf16 2⁻⁷, single 2⁻²³, double 2⁻⁵², quad 2⁻¹¹².

## Worked Example
Cross-block message passing — the canonical scope-correctness case:

```cpp
// Initially: int x = 0, f = 0;

// Thread 0, Block 0  (producer)
x = 42;
cuda::atomic_ref<int, cuda::thread_scope_device> flag(f);   // DEVICE scope
flag.store(1, cuda::memory_order_release);

// Thread 0, Block 1  (consumer)
cuda::atomic_ref<int, cuda::thread_scope_device> flag(f);   // DEVICE scope
while (flag.load(cuda::memory_order_acquire) != 1);
assert(x == 42);                                            // OK
```
- **What it demonstrates**: release/acquire ordering carries the non-atomic `x = 42` across blocks *only because both atomics use `thread_scope_device`*, which includes both threads. Downgrading the store to `thread_scope_block` makes it a data race (UB): the store's scope excludes the block-1 loader, so the store and load are no longer mutually atomic and `x`'s write is not guaranteed visible.

## Key Takeaways
1. CUDA is IEEE-754, but associativity loss + FMA contraction + non-IEEE library functions make CPU↔GPU results differ legitimately — interpret diffs, don't assume bugs.
2. FMA (`rn(x*y+z)`, single rounding) is both faster and more accurate, especially against subtractive cancellation; `*`/`+` fuse, `__f*_rn` intrinsics do not.
3. Intrinsics (`__`-prefixed) and `--use_fast_math` buy speed for documented ULP loss and denormal flushing (`-ftz`); apply surgically and validate.
4. Choose the *smallest thread scope that includes every participating thread*; a too-narrow scope (block store, device load across blocks) is a data race and UB.
5. System-scope atomicity is conditional on device attributes (`hostNativeAtomicSupported`, P2P native atomics, managed/pageable access).
6. Device threads provide only *parallel* forward progress; CPU spin-wait idioms (yield loops, volatile/atomic on automatic storage, trivial infinite loops) may never progress on the GPU. Only block/cluster/cooperative-grid mates are guaranteed to join a progressing thread.

## Connects To
- **Ch 1**: warp/SIMT and the GPU throughput model that motivates non-uniform synchronization cost.
- **Ch 23**: `__syncthreads()` (block barrier + fence) is the block-scope counterpart to these device-scope atomics.
- **Ch 20**: bfloat16/`__float128` and FP32:FP64 throughput ratios gated by compute capability (the consumer-GPU FP64 trap lives here).
- **Ch 21**: `CUDA_LAUNCH_BLOCKING=1`, `CUDA_DEVICE_MAX_CONNECTIONS=1` as the (insufficient but useful) forward-progress test harness.
- **Ch 3**: atomics and coalescing deep dive — the SIMT-level mechanics under these memory-model guarantees.
