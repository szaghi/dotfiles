# Chapter 3: Point-to-Point Communication

## Core Idea
The core cooperative primitive: one process sends a typed message, another receives it, matched by **(communicator, source/dest rank, tag)**. The chapter that governs `MPI_Send`/`MPI_Recv` and their nonblocking and moded variants — and where deadlock lives.

## Frameworks Introduced
- **Message envelope**: a message is matched by **communicator + source + tag** (receiver may use `MPI_ANY_SOURCE`/`MPI_ANY_TAG`). The data is `(buf, count, datatype)`.
- **Four send modes** (the sender's buffering/synchronization contract):
  - **Standard `MPI_Send`**: implementation chooses whether to buffer; completes when the buffer is reusable (may or may not wait for the receiver). The default.
  - **Buffered `MPI_Bsend`**: completes immediately by copying into a user-attached buffer (`MPI_Buffer_attach`); decouples sender from receiver but you manage buffer space.
  - **Synchronous `MPI_Ssend`**: completes only after the matching receive has *started* — a rendezvous; deterministic, no hidden buffering.
  - **Ready `MPI_Rsend`**: may only be posted when the receive is *already* posted (else erroneous); enables the fastest protocol but is fragile.
- **Nonblocking** (`MPI_Isend`/`MPI_Irecv` → `MPI_Wait`/`MPI_Test`/`MPI_Waitall`/`MPI_Testany`): initiate now, complete later — the mechanism for **overlapping communication with computation** and avoiding deadlock.
- **`MPI_Sendrecv`**: combined send+receive in one call — the deadlock-free way to do paired exchange (e.g. halo swap).
- **Probe** (`MPI_Probe`/`MPI_Iprobe`, `MPI_Mprobe`/`MPI_Mrecv`): inspect an incoming message (size/source/tag) before receiving; matched probe avoids races in multithreaded receives.

## Key Concepts
- **`MPI_Status`**: filled on receive — `MPI_SOURCE`, `MPI_TAG`, `MPI_ERROR`, and `MPI_Get_count` for the actual element count. Use `MPI_STATUS_IGNORE` when not needed.
- **`MPI_PROC_NULL`**: a "null" peer — send/recv to it is a no-op that completes immediately (simplifies boundary code in stencils).
- **deadlock**: two processes each `MPI_Send` to the other before receiving can deadlock if neither buffers — standard mode's buffering is **not guaranteed**. Safe patterns: `MPI_Sendrecv`, nonblocking, or ordered send/recv.
- **datatype matching**: sender and receiver type signatures must match (ch5); count is in *elements*, not bytes.

## Reference Tables
### Send mode selection
| Mode | Completes when | Use when |
|---|---|---|
| `MPI_Send` (standard) | buffer reusable (impl-defined buffering) | default; portable |
| `MPI_Bsend` (buffered) | copied to user buffer | must return immediately; you own buffer mgmt |
| `MPI_Ssend` (synchronous) | receiver has started | debugging deadlock; deterministic; no buffering |
| `MPI_Rsend` (ready) | receiver already posted | micro-opt with guaranteed pre-posted recv (fragile) |

## Code Examples
```c
// deadlock-prone (standard mode, both send first):
MPI_Send(sbuf, n, MPI_DOUBLE, peer, 0, comm);   // may block if no buffering
MPI_Recv(rbuf, n, MPI_DOUBLE, peer, 0, comm, MPI_STATUS_IGNORE);

// safe paired exchange:
MPI_Sendrecv(sbuf, n, MPI_DOUBLE, peer, 0,
             rbuf, n, MPI_DOUBLE, peer, 0, comm, MPI_STATUS_IGNORE);

// overlap comm + compute:
MPI_Request reqs[2];
MPI_Irecv(rbuf, n, MPI_DOUBLE, peer, 0, comm, &reqs[0]);
MPI_Isend(sbuf, n, MPI_DOUBLE, peer, 0, comm, &reqs[1]);
compute_interior();                              // work while messages fly
MPI_Waitall(2, reqs, MPI_STATUSES_IGNORE);
```
- **Demonstrates**: the standard-mode deadlock trap, the `MPI_Sendrecv` fix, and nonblocking overlap of communication with interior computation (the halo-exchange idiom).

## Anti-patterns
- **Send-then-recv in standard mode for a mutual exchange**: deadlocks when the implementation doesn't buffer — use `MPI_Sendrecv` or nonblocking.
- **Reusing an `MPI_Isend` buffer before `MPI_Wait`**: data race/corruption.
- **`MPI_Rsend` without a guaranteed pre-posted receive**: erroneous.
- **Relying on standard-mode buffering for correctness**: it's not guaranteed; a program that "works" may deadlock at larger message sizes.
- **`MPI_Recv` with a too-small buffer**: truncation error — size for the max, or `MPI_Probe` first.

## Key Takeaways
1. Messages match on **(comm, source, tag)**; data is `(buf, count, datatype)` with count in *elements*.
2. Four send modes: standard (default), buffered (you manage space), synchronous (rendezvous, deadlock-debugging), ready (fragile micro-opt).
3. **`MPI_Sendrecv`** or **nonblocking + `MPI_Waitall`** are the deadlock-free exchange patterns; nonblocking also overlaps comm/compute.
4. Don't touch an `MPI_Isend` buffer until completion; don't assume standard-mode buffering.
5. `MPI_PROC_NULL` no-ops boundary communication; `MPI_Status` carries source/tag/count.

## Connects To
- **Ch 4**: partitioned point-to-point (MPI 4.0+, finer-grained sends).
- **Ch 5**: datatypes — type matching and derived types for the message data.
- **Ch 6**: collectives — structured group communication built atop these semantics.
- **Ch 13**: nonblocking completion and generalized requests.
