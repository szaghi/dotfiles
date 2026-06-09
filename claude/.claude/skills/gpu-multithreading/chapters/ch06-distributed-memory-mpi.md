# Chapter 6: Distributed-Memory Programming with Message Passing (MPI)

## Core Idea
When memory is *not* shared, processes coordinate by **explicitly passing messages**. The SPMD model — one program, **ranked** instances over a **communicator** — plus point-to-point and collective operations is how computation scales beyond a single node. Communication, not computation, is the scaling bottleneck, so the craft is minimizing, overlapping, and structuring it.

## Frameworks Introduced

### The SPMD + communicator model
Every process runs the same program, identified by a **rank** in a **communicator** (`MPI_COMM_WORLD` is all processes); `size` is the count. Control flow branches on rank.

```c
MPI_Init(&argc, &argv);
int rank, size;
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);
/* ... work, branching on rank ... */
MPI_Finalize();
```

### Point-to-point: the call and the status
```c
int MPI_Send(const void* buf, int count, MPI_Datatype dt, int dest, int tag, MPI_Comm comm);
int MPI_Recv(void* buf, int count, MPI_Datatype dt, int src, int tag, MPI_Comm comm, MPI_Status* st);
```
- A message is matched by **(communicator, source, tag)**. Use `MPI_ANY_SOURCE` / `MPI_ANY_TAG` wildcards on receive; then read the actual sender/tag/length from `MPI_Status` (`st.MPI_SOURCE`, `st.MPI_TAG`, and `MPI_Get_count(&st, dt, &n)`).
- `tag` is a non-negative label (≤ `MPI_TAG_UB`) letting you distinguish message classes between the same pair.

### Send modes (completion semantics — the deadlock surface)
| Mode | Call | Returns when | Use |
|---|---|---|---|
| Standard | `MPI_Send` | impl choice (may buffer or block) | default |
| Synchronous | `MPI_Ssend` | matching recv has *started* | provably no buffering, debug deadlocks |
| Buffered | `MPI_Bsend` | data copied to user buffer (`MPI_Buffer_attach`) | decouple sender |
| Ready | `MPI_Rsend` | assumes recv already posted | micro-opt, fragile |

`MPI_Recv` always blocks until the message is fully received. **Two ranks both issuing a blocking `Send` to each other before receiving can deadlock** (standard mode may or may not, depending on buffering — never rely on it). Fixes: `MPI_Sendrecv` (atomic exchange), nonblocking, or strict ordering.

```c
/* deadlock-safe pairwise exchange */
MPI_Sendrecv(send_buf, n, MPI_DOUBLE, neighbor, 0,
             recv_buf, n, MPI_DOUBLE, neighbor, 0, comm, MPI_STATUS_IGNORE);
```

### Nonblocking communication (overlap)
```c
int MPI_Isend(const void* buf, int count, MPI_Datatype dt, int dest, int tag, MPI_Comm comm, MPI_Request* req);
int MPI_Irecv(void* buf, int count, MPI_Datatype dt, int src,  int tag, MPI_Comm comm, MPI_Request* req);
int MPI_Wait(MPI_Request* req, MPI_Status* st);   /* or MPI_Waitall / MPI_Test */
```
- Return immediately; the buffer **must not be touched** until `MPI_Wait`/`MPI_Test` reports completion. This is what enables communication/computation overlap.

### Collective communication
All ranks in the communicator must call the same collective. They are **optimized** (tree/ring/recursive-doubling) — always prefer them to hand-rolled point-to-point loops.

| Collective | Effect |
|---|---|
| `MPI_Bcast(buf,n,dt,root,comm)` | root → all |
| `MPI_Scatter` / `MPI_Scatterv` | root distributes chunks (v = variable counts) |
| `MPI_Gather` / `MPI_Gatherv` | collect chunks to root |
| `MPI_Allgather` | gather + share to all |
| `MPI_Alltoall` | full transpose (each→each) |
| `MPI_Reduce(sbuf,rbuf,n,dt,op,root,comm)` | combine with `op` → root |
| `MPI_Allreduce` | reduce + result to all |
| `MPI_Scan` / `MPI_Exscan` | (inclusive/exclusive) prefix reduction |
| `MPI_Barrier` | synchronize all ranks |

`op` ∈ `MPI_SUM`, `MPI_MAX`, `MPI_MIN`, `MPI_PROD`, `MPI_LAND/LOR/BAND/BOR`, `MPI_MAXLOC/MINLOC`, or a user op via `MPI_Op_create`. **Nonblocking collectives** (`MPI_Ibcast`, `MPI_Iallreduce`, …) allow overlap.

### Domain decomposition + halo exchange (the workhorse pattern)
Partition the global grid across ranks; each owns a subdomain plus a **ghost/halo** layer holding neighbors' boundary cells, exchanged every step. Communication scales with subdomain **surface area**, compute with **volume** — so larger subdomains per rank improve the surface-to-volume (comms-to-compute) ratio.

```c
/* overlap halo exchange with interior compute */
MPI_Irecv(ghost_lo, n, MPI_DOUBLE, lo, 0, comm, &req[0]);
MPI_Irecv(ghost_hi, n, MPI_DOUBLE, hi, 1, comm, &req[1]);
MPI_Isend(edge_lo,  n, MPI_DOUBLE, lo, 1, comm, &req[2]);
MPI_Isend(edge_hi,  n, MPI_DOUBLE, hi, 0, comm, &req[3]);
compute_interior(field);                 /* overlap: work while messages fly */
MPI_Waitall(4, req, MPI_STATUSES_IGNORE);
compute_boundary(field, ghost_lo, ghost_hi);
```

## Key Concepts

### Derived datatypes (send non-contiguous data without packing)
Describe a column, strided slice, or struct so MPI sends it in one call:
- `MPI_Type_contiguous`, `MPI_Type_vector` (strided blocks — e.g. a matrix column), `MPI_Type_indexed`, `MPI_Type_create_struct` (heterogeneous), then `MPI_Type_commit` before use and `MPI_Type_free` after. Alternative: `MPI_Pack`/`MPI_Unpack` into a byte buffer.

### Communicators, groups, topologies
- Subdivide ranks with `MPI_Comm_split` (by color/key) for sub-team collectives; build from groups via `MPI_Group_incl` + `MPI_Comm_create`.
- **Cartesian topology** `MPI_Cart_create` + `MPI_Cart_shift` maps ranks onto a logical grid and computes neighbor ranks for halo exchange automatically.

### One-sided / RMA communication
A process exposes a memory **window**; others `Put`/`Get`/`Accumulate` into it without the target issuing a matching call — decouples data movement from synchronization.
```c
MPI_Win_create(base, size, disp_unit, MPI_INFO_NULL, comm, &win);  /* collective */
MPI_Win_fence(0, win);                 /* open an access epoch (active target) */
MPI_Put(origin, n, dt, target_rank, target_disp, n, dt, win);
MPI_Get(origin, n, dt, target_rank, target_disp, n, dt, win);
MPI_Win_fence(0, win);                 /* close epoch — completes the RMA */
MPI_Win_free(&win);
```
Synchronization is **active-target** (`MPI_Win_fence`, or PSCW post/start/complete/wait) or **passive-target** (`MPI_Win_lock`/`unlock`).

### Persistent & modern communications
- **Persistent** (`MPI_Send_init`/`Recv_init` → `MPI_Start`/`Startall`): amortize setup for a message pattern repeated every iteration (e.g. fixed halo exchange).
- **Partitioned** (MPI 4.0, `MPI_Psend_init`/`Pready`): let multiple threads contribute partitions of one message — built for hybrid MPI+threads.
- **Big-count** (MPI 4.0, `MPI_Send_c` with `MPI_Count`): counts beyond `INT_MAX`.

### Hybrid MPI + X and thread safety
MPI across nodes, OpenMP/threads/GPU within a node is the standard HPC structure. Initialize with `MPI_Init_thread(&argc,&argv,required,&provided)` and check `provided`: `MPI_THREAD_SINGLE` < `FUNNELED` (only main thread calls MPI) < `SERIALIZED` (one at a time) < `MULTIPLE` (any thread, concurrently).

## Mental Models
- **Communication is the bottleneck — minimize, batch, and overlap it.** Maximize subdomain surface-to-volume, coalesce many small messages into few large ones, and overlap with `Isend`/`Irecv` + interior compute.
- **Every blocking `Send` between two ranks is a potential deadlock** — use `MPI_Sendrecv` or nonblocking; debug suspected buffering-dependent code by swapping `MPI_Send`→`MPI_Ssend` (if it now deadlocks, you were relying on buffering).
- **Prefer collectives over point-to-point loops** — a hand-written gather is slower and more bug-prone than `MPI_Gather`; reductions especially are heavily tuned.
- **Use derived datatypes and Cartesian topologies for halos** — they remove manual packing and neighbor-index arithmetic, the two classic stencil bugs.
- **A good decomposition is the single biggest determinant of MPI scaling** — balance load and minimize surface before micro-optimizing calls.

## Reference Tables

| Need | Blocking | Nonblocking | Persistent |
|---|---|---|---|
| send | `MPI_Send` | `MPI_Isend` | `MPI_Send_init`+`Start` |
| recv | `MPI_Recv` | `MPI_Irecv` | `MPI_Recv_init`+`Start` |
| exchange | `MPI_Sendrecv` | 4× I-calls + `Waitall` | init pair + `Startall` |

| Thread level | Meaning |
|---|---|
| `MPI_THREAD_SINGLE` | one thread total |
| `MPI_THREAD_FUNNELED` | only main thread calls MPI |
| `MPI_THREAD_SERIALIZED` | one thread at a time |
| `MPI_THREAD_MULTIPLE` | any thread, concurrent |

## Key Takeaways
1. MPI is SPMD: one program ranked over a communicator; messages match on (comm, source, tag), with details read from `MPI_Status`.
2. Send modes differ by completion semantics; blocking exchanges deadlock easily — use `MPI_Sendrecv` or nonblocking, and `MPI_Ssend` to expose buffering assumptions.
3. Communication is the scaling wall — maximize subdomain surface-to-volume, batch messages, and overlap with nonblocking calls + interior compute.
4. Prefer optimized collectives (`Bcast`/`Allreduce`/`Alltoall`); use derived datatypes and Cartesian topologies for halo exchange.
5. RMA windows, persistent, partitioned (MPI 4.0), and big-count round out the model; for hybrid MPI+threads init with `MPI_Init_thread` and check the provided thread level.

## Connects To
- **Ch 02 (Decomposition)**: domain decomposition + halo is the geometric pattern at cluster scale.
- **Ch 01 (Distributed memory)**: the hardware model MPI targets.
- **Ch 09 (OpenMP)**: the within-node layer of hybrid MPI+OpenMP.
- **Ch 11 (Load balancing)**: master–worker over MPI for irregular work.
