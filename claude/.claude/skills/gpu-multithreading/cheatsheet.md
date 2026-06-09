# GPU & Multithreading Cheatsheet — Decision Rules & Tells

## Pick the model (decision rule)
- Shared address space, one node → **threads / OpenMP**.
- Separate address spaces, many nodes → **MPI**.
- Massive data-parallel arithmetic → **GPU** (CUDA / OpenCL / Thrust).
- Real HPC node → **hybrid**: MPI across nodes + OpenMP/GPU within.

## Pick the decomposition pattern
| Work shape | Pattern |
|---|---|
| independent units | embarrassingly parallel |
| recursive split+combine | divide-and-conquer |
| grid / stencil | geometric (domain) + halo |
| streaming stages | pipeline (slowest stage = rate) |
| irregular/unpredictable | master–worker / work stealing |

## Performance ceilings
- Strong scaling (fixed size) → **Amdahl**: `S ≤ 1/((1−α)+α/N)`, cap `1/(1−α)`. **Attack the serial fraction first.**
- Weak scaling (grow with N) → **Gustafson**: `S = (1−α)+αN`, ~linear.
- Roofline: `AI = FLOPs/bytes`. Below ridge → memory-bound (reuse/tile); above → compute-bound (vectorize/FMA).

## Shared-memory correctness
- Shared mutable state → **mutex or atomic**. Read-only / thread-local → no lock.
- Always RAII locks (`lock_guard`/`scoped_lock`); multiple mutexes → `scoped_lock` or global order (deadlock).
- `cv.wait(lk, predicate)` — never bare wait (lost/spurious wakeup).
- `reduction` for accumulation — never `critical { s += x; }`.
- `default(none)` in OpenMP — forces explicit shared/private, catches races.

## memory_order picker
| situation | order |
|---|---|
| default / unsure | `seq_cst` |
| publish data | `release` (store) |
| read published | `acquire` (load) |
| CAS / fetch_add | `acq_rel` |
| counter/stat only | `relaxed` |

## GPU optimization order
1. **Coalesce** global access (SoA, contiguous per warp) — #1 lever.
2. **Tile** through shared memory (raise arithmetic intensity).
3. **Occupancy** — many warps to hide latency; fewer registers.
4. Minimize **warp divergence**.
5. Minimize + **overlap host↔device copies** (streams, async).

## CUDA ↔ OpenCL map
| CUDA | OpenCL |
|---|---|
| thread / block / grid | work-item / work-group / NDRange |
| shared memory | local memory |
| `__syncthreads()` | `barrier(...)` |
| stream | command queue / events |

## MPI tells
- Two ranks exchanging → `MPI_Sendrecv` or nonblocking (blocking both-send = deadlock).
- Prefer collectives (`Bcast`/`Allreduce`/`Alltoall`) over point-to-point loops.
- Overlap: `Irecv`/`Isend` halos → compute interior → `Waitall` → compute boundary.
- Maximize subdomain surface-to-volume (bigger tiles = less comms per compute).

## Load balancing
- Predictable + known hardware → **static** (proportional / DLT, comms-aware).
- Irregular → **dynamic**: master–worker (modest scale) or **work stealing** (large scale).
- Heterogeneous (GPU+CPU) → split by **measured throughput**, not 50/50.

## Pitfall → fix
| Symptom | Cause | Fix |
|---|---|---|
| ">100× speedup" | no sync before timing | device/event/`MPI_Wait` sync |
| scaling cliff at N | false sharing / NUMA | pad/align, pin thread+data |
| GPU slow, high occupancy | uncoalesced | SoA, contiguous per warp |
| inter-phase stalls | host↔device copy | minimize/overlap, unified mem |
| results vary run-to-run | FP reduction reorder | fixed order / Kahan |
| hang | deadlock | lock order / `Sendrecv` |

## Measurement discipline
- Warm up, **synchronize**, monotonic clock, repeat, report variance.
- Baseline = an *optimized* serial version (vectorized, cache-friendly), not a strawman.
- A >N× speedup on N cores → suspect a measurement bug, not a triumph.

## Floating-point reproducibility
- Parallel `reduce`/`scan` reorder additions → not bitwise reproducible across thread/process counts.
- Need reproducibility → fix reduction order or use Kahan/pairwise summation.
- Consumer GPUs: FP64 ≈ 1:32–1:64 of FP32; FP32-store/FP64-compute usually a net loss.
