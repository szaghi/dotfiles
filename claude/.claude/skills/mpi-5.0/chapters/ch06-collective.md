# Chapter 6: Collective Communication

## Core Idea
Structured group communication: **all processes in a communicator** call the same operation, which moves/combines data across the group (broadcast, gather/scatter, all-to-all, reductions, barrier). Available in **blocking, nonblocking, persistent**, and **neighborhood** forms.

## Frameworks Introduced
- **Synchronization**: `MPI_Barrier` — all processes rendezvous (rarely needed for correctness; usually a smell).
- **Data movement**:
  - **`MPI_Bcast`**: root sends one buffer to all.
  - **`MPI_Gather`/`MPI_Gatherv`**: all send to root (v = variable counts/displacements). **`MPI_Allgather`**: result to everyone.
  - **`MPI_Scatter`/`MPI_Scatterv`**: root distributes chunks to all.
  - **`MPI_Alltoall`/`MPI_Alltoallv`/`MPI_Alltoallw`**: every process sends distinct data to every other (transpose; the most bandwidth-intensive).
- **Reductions**:
  - **`MPI_Reduce`** (result to root) / **`MPI_Allreduce`** (result to all) with an op.
  - **`MPI_Reduce_scatter`**, **`MPI_Scan`** (inclusive prefix), **`MPI_Exscan`** (exclusive prefix).
  - Predefined ops: `MPI_SUM`, `MPI_PROD`, `MPI_MAX`, `MPI_MIN`, `MPI_LAND/LOR/LXOR`, `MPI_BAND/BOR/BXOR`, `MPI_MAXLOC`/`MPI_MINLOC` (value+location). User ops via **`MPI_Op_create`**.
- **Nonblocking collectives** (`MPI_Ibcast`, `MPI_Iallreduce`, `MPI_Ialltoall`, …): initiate, overlap with computation, complete with `MPI_Wait`. Persistent forms (`MPI_Bcast_init`, …) amortize setup.
- **Neighborhood collectives** (`MPI_Neighbor_allgather`, `MPI_Neighbor_alltoall`): communicate only with topology neighbors (ch8) — the scalable halo-exchange primitive.

## Key Concepts
- **All processes must call** the collective (in the same order across the group) — a missing or mismatched call deadlocks.
- **`MPI_IN_PLACE`**: avoid a separate send buffer (e.g. `MPI_Allreduce(MPI_IN_PLACE, buf, ...)` reduces in the receive buffer).
- **`MPI_Allreduce` is the global-reduction workhorse** (norms, dot products, convergence checks) — but it's a synchronization point; minimize its frequency.
- **reduction determinism**: floating-point reductions may reassociate → results vary with process count/order. For bit-reproducibility you need a deterministic implementation or manual ordering (cf. precision-floor concerns).
- **`v`/`w` variants** handle uneven data distributions (counts/displacements/types per process).

## Reference Tables
### Collective selection
| Need | Operation |
|---|---|
| one→all same data | `MPI_Bcast` |
| all→one collect | `MPI_Gather(v)` |
| all→all collect | `MPI_Allgather(v)` |
| one→all distribute | `MPI_Scatter(v)` |
| all→all distinct (transpose) | `MPI_Alltoall(v/w)` |
| global reduction → root | `MPI_Reduce` |
| global reduction → all | `MPI_Allreduce` |
| prefix sum | `MPI_Scan` / `MPI_Exscan` |
| neighbors only | `MPI_Neighbor_*` |

## Code Examples
```c
// global convergence check (the Allreduce workhorse)
double local_resid = compute_residual();
double global_resid;
MPI_Allreduce(&local_resid, &global_resid, 1, MPI_DOUBLE, MPI_SUM, comm);

// overlap a global reduction with interior compute
MPI_Request req;
MPI_Iallreduce(&local, &global, 1, MPI_DOUBLE, MPI_SUM, comm, &req);
compute_interior();                       // useful work while the reduction runs
MPI_Wait(&req, MPI_STATUS_IGNORE);
```
- **Demonstrates**: `MPI_Allreduce` for a global residual, and `MPI_Iallreduce` overlapping the (latency-bound) reduction with interior computation.

## Anti-patterns
- **A process skipping a collective** (e.g. inside a rank-conditional branch): deadlocks the group — collectives are unconditional for all members.
- **`MPI_Barrier` for "safety"**: almost never needed for correctness; it's pure synchronization overhead — remove unless a tool/timing reason demands it.
- **Frequent `MPI_Allreduce` in a hot loop**: each is a global sync; batch reductions or overlap with `MPI_Iallreduce`.
- **Assuming reproducible FP reductions**: associativity varies with layout — don't depend on bit-identical sums across run configurations.
- **`MPI_Alltoall` at scale without thought**: O(P²) messages; the most expensive pattern — restructure if possible.

## Key Takeaways
1. Collectives = same call by **all** processes in the communicator; mismatch deadlocks.
2. `MPI_Allreduce` is the global-reduction workhorse (norms/convergence) — but a sync point; minimize and consider `MPI_Iallreduce` overlap.
3. `MPI_IN_PLACE` avoids redundant buffers; `v`/`w` variants handle uneven distributions.
4. **Neighborhood collectives** (with a topology, ch8) are the scalable halo-exchange primitive.
5. FP reductions are not bit-reproducible across layouts; `MPI_MAXLOC`/`MINLOC` carry value+rank.

## Connects To
- **Ch 7**: communicators define the collective's group.
- **Ch 8**: virtual topologies enable neighborhood collectives.
- **Ch 3**: collectives are layered on point-to-point semantics.
- **Ch 5**: derived types as collective send/recv types.
- **feedback_conservation_diagnostic / precision-floor**: global-sum accuracy across ranks.
