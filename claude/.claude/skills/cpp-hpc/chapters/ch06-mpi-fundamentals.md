# Chapter 6: MPI Fundamentals — Point-to-Point & Collective Communication

## Core Idea
Distributed-memory HPC uses **MPI**: the SPMD model where many processes, each with private memory and a **rank** in a **communicator**, coordinate by **passing messages**. Computation scales across cluster nodes, but communication — not compute — is the bottleneck to minimize and overlap.

## Frameworks Introduced

- **The SPMD + communicator model**: every process runs the same program, identified by `rank` within a communicator (`MPI_COMM_WORLD` = all processes); `size` is the count. Branch on rank.

```cpp
MPI_Init(&argc, &argv);
int rank, size;
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);
// ... work, branching on rank ...
MPI_Finalize();
```
All work must lie between `MPI_Init` and `MPI_Finalize`.

- **Point-to-point communication**:
  - **Blocking**: `MPI_Send(buf, count, type, dest, tag, comm)` / `MPI_Recv(buf, count, type, src, tag, comm, &status)` — return when the buffer is safe to reuse / the message has arrived. A message matches on **(communicator, source, tag)**; use `MPI_ANY_SOURCE`/`MPI_ANY_TAG` and read actual values from `MPI_Status`.
  - **Deadlock hazard**: two ranks both issuing a blocking `Send` to each other before receiving can deadlock. Fix with `MPI_Sendrecv` or nonblocking calls.
  - **Nonblocking**: `MPI_Isend`/`MPI_Irecv` return immediately (don't touch the buffer until `MPI_Wait`/`MPI_Test`) — the basis for overlapping communication with computation.

- **Collective communication** (all ranks participate, heavily optimized):
  - `MPI_Bcast` (root→all), `MPI_Scatter`/`MPI_Gather` (distribute/collect chunks), `MPI_Reduce`/`MPI_Allreduce` (combine with `MPI_SUM`/`MPI_MAX`/…), `MPI_Barrier` (synchronize). Always prefer collectives over hand-rolled point-to-point loops.

## Key Concepts
- **Blocking vs nonblocking completion**: blocking returns when safe; nonblocking returns immediately and you must complete it later — the mechanism for overlap.
- **Message matching**: (comm, source, tag) — wildcards on receive, details recovered from `MPI_Status` (`MPI_SOURCE`, `MPI_TAG`, `MPI_Get_count`).
- **Communication is the bottleneck**: minimize message count and volume, batch small messages, and overlap with computation.
- **C++ + MPI**: MPI is a C API; pass `&buf[0]`/`buf.data()` for `std::vector`, and `MPI_DOUBLE`/`MPI_INT` etc. for built-in types (custom types need derived datatypes, Ch 7).

## Mental Models
- **Branch on rank; coordinate by messages** — SPMD means one binary, many ranked instances over different data.
- **Every blocking exchange between two ranks risks deadlock** — use `MPI_Sendrecv` or nonblocking; never rely on the standard mode's optional buffering.
- **Prefer collectives over point-to-point loops** — a hand-written gather is slower and more bug-prone than `MPI_Gather`; reductions especially are tuned.
- **Overlap communication with computation** — post `Irecv`/`Isend`, do independent work, then `Wait` — hides network latency behind useful compute.

## Code Examples
```cpp
// Deadlock-safe pairwise exchange
MPI_Sendrecv(send_buf.data(), n, MPI_DOUBLE, neighbor, 0,
             recv_buf.data(), n, MPI_DOUBLE, neighbor, 0,
             MPI_COMM_WORLD, MPI_STATUS_IGNORE);

// Collective reduction instead of manual gather + sum
double local = local_sum(data);
double total;
MPI_Allreduce(&local, &total, 1, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);

// Overlap: nonblocking receive, compute, then wait
MPI_Request req;
MPI_Irecv(ghost.data(), n, MPI_DOUBLE, src, 0, MPI_COMM_WORLD, &req);
compute_interior();                         // overlap with the in-flight message
MPI_Wait(&req, MPI_STATUS_IGNORE);
compute_boundary(ghost);
```
- **What it demonstrates**: deadlock-safe exchange, a collective reduction, and communication/computation overlap.

## Reference Tables

| Operation | Blocking | Nonblocking |
|---|---|---|
| send | `MPI_Send` | `MPI_Isend` |
| recv | `MPI_Recv` | `MPI_Irecv` |
| exchange | `MPI_Sendrecv` | `Isend`+`Irecv`+`Wait` |

| Collective | Effect |
|---|---|
| `Bcast` | root → all |
| `Scatter`/`Gather` | distribute/collect chunks |
| `Reduce`/`Allreduce` | combine (sum/max/…) → root / all |
| `Barrier` | synchronize all ranks |

## Key Takeaways
1. MPI is SPMD: one program ranked over a communicator; messages match on (comm, source, tag).
2. Blocking calls return when safe; two ranks blocking-sending to each other deadlock — use `MPI_Sendrecv` or nonblocking.
3. Prefer optimized collectives (`Bcast`/`Allreduce`/`Scatter`/`Gather`) over hand-rolled point-to-point loops.
4. Overlap communication with computation via `Isend`/`Irecv` + `Wait` to hide network latency.
5. From C++, pass `vector::data()` buffers and built-in `MPI_*` datatypes; all MPI work lives between `MPI_Init`/`MPI_Finalize`.

## Connects To
- **Ch 05 (Hardware)**: the cluster/interconnect model.
- **Ch 07 (Advanced MPI)**: derived datatypes, communicators, RMA, scaling.
- **Ch 14 (Actor model)**: an alternative message-passing concurrency model.
