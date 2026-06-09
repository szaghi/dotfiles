# Patterns — MPI 5.0 idioms

Concrete techniques. Format: **When / How / Trade-offs.**

## Halo / ghost-cell exchange (the stencil workhorse)
**When**: structured-grid solver exchanging boundary layers with neighbors.
**How**: `MPI_Cart_create(reorder=true)` → `MPI_Cart_shift` for neighbor ranks → `MPI_Sendrecv` (or nonblocking) per direction; `MPI_Type_create_subarray` for non-contiguous faces; `MPI_PROC_NULL` auto-handles boundaries. (Ch3, 5, 8)
**Trade-offs**: `Sendrecv` is deadlock-free and simple; nonblocking allows compute/comm overlap.

## Nonblocking overlap of communication and computation
**When**: latency hiding in iterative solvers.
**How**: `MPI_Irecv`+`MPI_Isend` (or `MPI_Iallreduce`) → compute interior → `MPI_Waitall` → compute boundary. (Ch3, 6)
**Trade-offs**: hides latency if interior work ≥ comm time; needs care not to touch buffers before Wait.

## Global reduction for convergence/norms
**When**: residual/dot-product/convergence check across all ranks.
**How**: `MPI_Allreduce(MPI_IN_PLACE, &val, 1, MPI_DOUBLE, MPI_SUM, comm)`. (Ch6)
**Trade-offs**: global sync point — minimize frequency; overlap with `MPI_Iallreduce`; FP not bit-reproducible across layouts.

## Domain decomposition via Cartesian topology
**When**: mapping a grid onto ranks.
**How**: `MPI_Dims_create` for balanced factorization → `MPI_Cart_create` → `MPI_Cart_coords` for local origin. (Ch8)
**Trade-offs**: `reorder=true` improves locality; re-query rank after.

## Derived datatype instead of manual packing
**When**: sending strided/structured data (matrix column, struct array, array slice).
**How**: `MPI_Type_vector`/`create_subarray`/`create_struct` → `MPI_Type_commit` → send count=1 of the type → `MPI_Type_free`. (Ch5)
**Trade-offs**: lets MPI/hardware do strided access; mind extent (`MPI_Type_create_resized`) for arrays of the type.

## Collective distributed-array I/O (one shared file)
**When**: checkpoint/restart or field output of a decomposed array.
**How**: `subarray` filetype → `MPI_File_set_view` → `MPI_File_write_all` (collective); tune with `MPI_Info` (collective_buffering, striping). (Ch10, 14)
**Trade-offs**: scales far better than one-file-per-rank; hints dominate throughput; restart is decomposition-independent.

## One-sided accumulate for irregular updates
**When**: scatter/accumulate into remote memory without the target polling.
**How**: `MPI_Win_allocate` → `MPI_Win_fence` → `MPI_Accumulate(..., MPI_SUM, win)` → `MPI_Win_fence`. (Ch12)
**Trade-offs**: `Accumulate` is atomic (safe concurrent updates); completion only at epoch end.

## Node-local shared memory (MPI+MPI hybrid)
**When**: ranks on the same node should share memory directly (avoid intra-node copies).
**How**: `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` → `MPI_Win_allocate_shared` → `MPI_Win_shared_query` for load/store pointers. (Ch7, 12)
**Trade-offs**: portable alternative to OpenMP for intra-node sharing; still needs synchronization.

## Hybrid MPI + OpenMP/GPU
**When**: one rank per socket/NUMA, threads/GPU within.
**How**: `MPI_Init_thread(MPI_THREAD_FUNNELED|MULTIPLE)` (check `provided`); MPI on master thread (FUNNELED) or any thread (MULTIPLE); pin ranks to NUMA, threads to cores. (Ch2, 11)
**Trade-offs**: FUNNELED is cheaper/safer; MULTIPLE only if threads call MPI concurrently (e.g. partitioned comm).

## Partitioned send from multiple producers
**When**: threads/GPU streams each produce part of one message.
**How**: `MPI_Psend_init` once → per iter `MPI_Start` → each producer `MPI_Pready(p)` → `MPI_Wait`. (Ch4)
**Trade-offs**: overlaps per-partition production with transfer; needs `MPI_THREAD_MULTIPLE`.

## Persistent communication for repeated patterns
**When**: same send/recv every iteration of a time loop.
**How**: `MPI_Send_init`/`MPI_Recv_init` once → `MPI_Startall` + `MPI_Waitall` per iteration → `MPI_Request_free`. (Ch2)
**Trade-offs**: amortizes setup; fixed buffers/peers.

## Library communicator isolation
**When**: writing an MPI library callable from MPI apps.
**How**: `MPI_Comm_dup` (or Sessions `MPI_Comm_create_from_group`) at init; never communicate on `MPI_COMM_WORLD`. (Ch7, 11)
**Trade-offs**: prevents message collisions; Sessions avoids the `MPI_Init`-ownership problem.
