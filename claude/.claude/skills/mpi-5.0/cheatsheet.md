# Cheatsheet — MPI 5.0

## New / notable in MPI 5.0 (vs 4.x/3.x)
Standard **ABI** (`MPI_Abi_get_version`/`_get_info` — one binary, any conforming impl) · **Sessions Model** refinements (init without `MPI_COMM_WORLD`) · **Partitioned** point-to-point (`MPI_Psend_init`/`Pready`) · large-count **`_c`** routines (`MPI_Count`) · `use mpi_f08` the standard Fortran binding · C++ bindings removed.

## Decision rules

### Which send?
| Situation | Send |
|---|---|
| default, portable | `MPI_Send` (standard) |
| must return immediately, you own buffer | `MPI_Bsend` (buffered) |
| deterministic / debugging deadlock | `MPI_Ssend` (synchronous) |
| receive guaranteed pre-posted (micro-opt) | `MPI_Rsend` (ready) |
| mutual exchange | **`MPI_Sendrecv`** (deadlock-free) |
| overlap comm/compute | `MPI_Isend`/`MPI_Irecv` + `MPI_Waitall` |

### Avoid deadlock
- Mutual send-before-recv in standard mode **can deadlock** (buffering not guaranteed) → `MPI_Sendrecv` or nonblocking.
- Never reuse an `MPI_Isend` buffer before `MPI_Wait`.
- All ranks must call every collective (no rank-conditional skips).

### Which collective?
one→all `Bcast` · gather→root `Gather(v)` · gather→all `Allgather` · scatter `Scatter(v)` · transpose `Alltoall(v/w)` · reduce→root `Reduce` · reduce→all **`Allreduce`** · prefix `Scan`/`Exscan` · neighbors `Neighbor_*`. Use `MPI_IN_PLACE` to drop a buffer.

### Communicator scope
- Library? `MPI_Comm_dup` (isolate messages) — never use `MPI_COMM_WORLD` directly.
- Partition? `MPI_Comm_split(color,key)` (row/col grids).
- Node-local shared mem? `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)`.
- Pass communicators as params; don't hardcode the world.

### Thread level (MPI+OpenMP/GPU)
| Threads call MPI | Level |
|---|---|
| never (one thread) | `MPI_THREAD_SINGLE` |
| only master thread | `MPI_THREAD_FUNNELED` (common hybrid default) |
| one at a time | `MPI_THREAD_SERIALIZED` |
| concurrently | `MPI_THREAD_MULTIPLE` (partitioned comm; has cost) |
Always check `provided ≥ required`.

### RMA synchronization
- Bulk/simple → `MPI_Win_fence … Put/Get/Accumulate … fence`.
- Scalable active → PSCW (`post/start/complete/wait`).
- Passive → `MPI_Win_lock`/`unlock` (+ `MPI_Win_flush` to complete mid-epoch).
- Concurrent remote update → `MPI_Accumulate` (atomic), never bare `Put`.
- Data complete only at **epoch end** — never read early.

### Datatype
- Strided/structured → `MPI_Type_vector`/`create_subarray`/`create_struct`; `commit` before, `free` after.
- Halo face → `MPI_Type_create_subarray`.
- Array of a derived type packs wrong → `MPI_Type_create_resized` (fix extent).
- Displacements → `MPI_Get_address`, never hand-computed.

### Parallel I/O
- One shared file + `subarray` filetype + `MPI_File_set_view` + collective `_all` ops — never one-file-per-rank at scale.
- Tune via `MPI_Info`: `collective_buffering`, `cb_nodes`, `striping_factor`/`unit`.
- `datarep`: `native` (fast) vs `external32` (portable archives).

## Tells & smells
- **Code "works" small, hangs at scale** → relied on standard-mode buffering; use `Sendrecv`/nonblocking.
- **Data corruption after `Isend`** → buffer reused before `MPI_Wait` (Fortran: missing `ASYNCHRONOUS`).
- **Deadlock on a collective** → a rank skipped it (conditional branch) or mismatched order.
- **`MPI_Barrier` sprinkled "for safety"** → almost always removable overhead.
- **Allreduce in a tight loop** → global sync each iteration; batch or `Iallreduce`-overlap.
- **One file per rank** → metadata-server meltdown; restart breaks on different P. Use shared file + views.
- **`cpu_time` for timing** → use `MPI_Wtime`; clocks aren't cross-rank synced (reduce local intervals).
- **Binary won't run against another MPI** → pre-ABI behavior; check `MPI_Abi_get_version` (5.0 ABI fixes this).
- **`mpif.h` argument bug at runtime** → use `use mpi_f08` (typed handles catch it at compile time).
- **FP reduction not reproducible** → reassociation varies with rank count/order; expected.

## Hybrid placement (MPI + OpenMP/GPU)
- One rank per NUMA domain/socket; `OMP_NUM_THREADS` = cores/rank; bind (`OMP_PROC_BIND=close`, `OMP_PLACES=cores`).
- GPU per rank via local rank: `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` → node-local rank → `acc_set_device_num`/`omp` device.
- Device-aware MPI: pass device pointers directly (CUDA-aware) — `MPI_Send(device_ptr,...)`; check implementation support.
