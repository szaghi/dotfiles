# Cheatsheet — OpenACC 3.4

## New in 3.4 (vs 3.3)
| Change | Where |
|---|---|
| `collapse(force:n)` — collapse **non-tightly**-nested loops | Ch5 (§2.9.1) |
| Implicit `routine` generalized to **all procedures** (not just C++ lambdas) | Ch7 (§2.15.1) |
| Fortran interfaces added for `acc_malloc`/`acc_free`/`acc_map_data`/`acc_memcpy_*`/`acc_attach`/`acc_detach` etc. | Ch8 |
| `acc_map_data` error when `bytes == 0` | Ch8 |
| `_OPENACC` = **202506** | Ch2 |

## Decision rules

### Which compute construct?
- Know the loop nest is parallel, want control → **`parallel loop`**.
- Unsure / let compiler analyze dependencies → **`kernels`**.
- Sequential work on already-resident data → **`serial`** (avoids host round-trip).

### Which data clause?
| Need | Clause |
|---|---|
| read-only input | `copyin` |
| write-only output | `copyout` |
| in and out | `copy` |
| device scratch only | `create` |
| already staged elsewhere | `present` |
| reuse if present, else local | `no_create` |
| raw device pointer (interop) | `deviceptr` |
| pointer member of struct/DT | `attach` |

### Structured vs unstructured data
- Lifetime = lexical block → **`data`** construct.
- Lifetime spans functions / whole solver run → **`enter data` / `exit data`** (or `declare`).

### Loop mapping (must nest outer→inner)
`gang` ⊃ `worker` ⊃ `vector` ⊃ `seq`. At most one `gang` per loop. Never nest equal/higher level inside.

### Sync / overlap
- Block host on device work → `wait` (or `wait(q)`).
- Overlap independent work → distinct `async(q)` values (same value = serialized in one queue).
- Build device-side dependency without blocking host → `wait(q1) async(q2)`.

## Thresholds & defaults
- Offload pays off only at **high compute intensity** (flops ÷ bytes-moved) — low intensity → transfer-bound, keep on host.
- Default async queue when `async` has no arg → `acc-default-async-var` (`ACC_DEVICE_*`/`acc_set_default_async`).
- Adopt `default(none)` on compute constructs like `implicit none`.
- Prefer combined `parallel loop` over bare `parallel`.

## Tells & smells (GPU correctness/perf)
- **`>100×` "speedup"** → almost always a missing `wait`/`!$acc wait` before the timer; async kernels return immediately. Time with `system_clock`, never `cpu_time`. (feedback_gpu_benchmark_timing)
- **Bare `parallel` (no inner `loop`)** → body runs **redundantly per gang** (GR mode), not parallelized.
- **`copy` inside a hot loop** → re-transfers every iteration; hoist to `enter data` + `present`.
- **Kernel reads garbage / crashes** → host pointer dereferenced on device, or data not `present`/`attach`ed.
- **Wrong results, run-to-run varying** → race on weak memory model, or `independent` asserted on a dependent loop, or cross-gang sync attempt.
- **Trying to barrier/lock across gangs/workers** → deadlock; restructure, don't synchronize.
- **Device library call gets host address** → wrap in `host_data use_device(...)`.
- **`update` "does nothing"** → it doesn't allocate; data was never staged. Use `enter data`/`copyin` first or `if_present`.
- **Consumer NVIDIA GPU, FP64 code slow** → 1:64 FP64:FP32 ratio (vs 1:2 datacenter); FP32-store/FP64-compute is a *trap*, strictly slower than full FP64. (reference_consumer_gpu_fp64_trap)

## MPI + OpenACC
- Map ranks → GPUs via `ACC_DEVICE_NUM` (node-local rank) or `acc_set_device_num`.
- Halo exchange: `update self(halo)` → MPI → `update device(halo)`; or device-aware MPI via `host_data use_device(halo)` (no host bounce).
- `async` data transfers are **not inherited** by nested constructs — synchronize halos deliberately.
