# Chapter 4: Partitioned Point-to-Point Communication

## Core Idea
A single message split into **partitions** that the sender fills and marks ready **independently** — designed for multithreaded/GPU senders where different threads produce different parts of one buffer, and for finer-grained communication/computation overlap. Introduced in MPI 4.0, refined in 5.0.

## Frameworks Introduced
- **Persistent partitioned init** (local): `MPI_Psend_init(buf, partitions, count, datatype, dest, tag, comm, info, &request)` and `MPI_Precv_init(...)`. Send-side and receive-side partition counts **may differ**. Setup happens once, before transfers.
- **`MPI_Pready(partition, request)`**: notify MPI that a specific send partition's data is ready — the transfer of that partition may begin. `MPI_Pready_range`/`MPI_Pready_list` for batches.
- **`MPI_Parrived(request, partition, &flag)`**: test whether a specific receive partition has arrived — consume partitions as they land.
- **Start/complete**: `MPI_Start`/`MPI_Startall` to activate the persistent request each iteration; `MPI_Wait`/`MPI_Test` to complete.

## Key Concepts
- **Thread/partition mapping**: each thread (or GPU stream) produces one or more partitions and calls `MPI_Pready` when done — no need to synchronize all producers before any data moves.
- **Persistent by design**: the init cost is paid once; the buffer/partition layout is reused across many `MPI_Start` cycles (ideal for iterative solvers' halo exchange).
- **Decoupled granularity**: send-side and receive-side partition counts differ, so the producer's natural decomposition (e.g. per-thread) need not match the consumer's.
- **Early data movement**: an implementation may start moving partition *k* as soon as `MPI_Pready(k)` is called, overlapping with the production of partition *k+1*.

## Code Examples
```c
MPI_Request req;
MPI_Psend_init(buf, nparts, count_per_part, MPI_DOUBLE, dest, tag,
               comm, MPI_INFO_NULL, &req);
for (int iter = 0; iter < nsteps; ++iter) {
  MPI_Start(&req);
  #pragma omp parallel for                 // each thread fills + marks its partition
  for (int p = 0; p < nparts; ++p) {
    fill_partition(buf, p);
    MPI_Pready(p, req);                     // partition p can start moving now
  }
  MPI_Wait(&req, MPI_STATUS_IGNORE);
}
MPI_Request_free(&req);
```
- **Demonstrates**: persistent partitioned send where OpenMP threads independently produce and `MPI_Pready` their partitions — overlapping production with transfer (the MPI+OpenMP hybrid sweet spot).

## Anti-patterns
- **Calling `MPI_Pready` before the partition data is actually written**: the implementation may transfer stale data.
- **Re-init each iteration**: defeats the persistent design — init once, `MPI_Start` per iteration.
- **Assuming send/recv partition counts must match**: they need not — that's the point.
- **Using partitioned comm where plain nonblocking suffices**: added complexity only pays off with multiple independent producers (threads/streams).

## Key Takeaways
1. Partitioned comm splits one persistent message into independently-readied **partitions** — for multithreaded/GPU senders.
2. `MPI_Psend_init`/`MPI_Precv_init` (once) → `MPI_Start` (per iteration) → `MPI_Pready(p)` per partition → `MPI_Wait`.
3. Send- and receive-side partition counts may differ; `MPI_Parrived` lets the receiver consume partitions as they land.
4. The win is overlapping per-thread data production with transfer — pairs with `MPI_THREAD_MULTIPLE` / OpenMP.
5. Persistent by design: amortize setup across many iterations (iterative solvers).

## Connects To
- **Ch 3**: the point-to-point semantics it refines.
- **Ch 2**: persistent operations and thread levels (`MPI_THREAD_MULTIPLE`).
- **openmp-6.0 / openacc-3.4**: per-thread/per-stream production feeding partitions (hybrid MPI+X).
