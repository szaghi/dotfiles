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

### MPL — the modern C++ MPI binding
The C MPI API works from C++ but is verbose and type-unsafe (`void*` buffers, manual `MPI_Datatype`, explicit counts). **MPL** (Message Passing Layer) is a **header-only C++ library** wrapping MPI in idiomatic, type-safe, RAII C++ — the modern way to write MPI in C++.

- **No init/finalize calls**: `mpl::environment` initializes on first use and finalizes automatically (RAII) — no `MPI_Init`/`MPI_Finalize`.
- **Communicators are RAII objects** with the **copy operator deleted** (copying would duplicate a communicator — usually a bug). Get the world communicator as a `const&` and **pass communicators by reference**:
  ```cpp
  const mpl::communicator &comm = mpl::environment::comm_world();
  int rank = comm.rank(), nprocs = comm.size();   // methods, not free functions
  ```
- **Type-safe buffers via polymorphism (templating + ADL)** — no explicit datatype or count for the common cases:
  - **Scalar**: `comm.bcast(0, x);` (root first; `x` is a plain `T`, no `&`/count).
  - **`std::vector`**: pass `.data()` + an `mpl::contiguous_layout<T>(n)` derived type.
  - **Iterator ranges**: `comm.send(v.begin(), v.end(), dest);` / `comm.recv(v.begin(), v.end(), src);` — the most idiomatic form.
- **Point-to-point**: `comm.send(scalar, dest)` / `comm.recv(scalar, src)`; nonblocking calls return an **`mpl::irequest`** whose `.wait()` is a method (vs C's `MPI_Wait(&req)`).
- **Collectives** are communicator methods with functor reduction operators: `comm.allreduce(mpl::plus<float>(), sendbuf, recvbuf)` (or in-place with one buffer). `mpl::plus`/`mpl::max`/… replace `MPI_SUM`/`MPI_MAX`.
- **Derived datatypes** are **layout objects** (`mpl::contiguous_layout`, `mpl::vector_layout`, `mpl::indexed_layout`) — typed, RAII, no `MPI_Type_commit`/`MPI_Type_free`.

```cpp
#include <mpl/mpl.hpp>
int main() {                                       // no MPI_Init/Finalize
    const mpl::communicator &comm = mpl::environment::comm_world();
    int rank = comm.rank();
    std::vector<double> x(n);
    if (rank == 0) { /* fill x */ }
    comm.bcast(0, x.data(), mpl::contiguous_layout<double>(n));   // type-safe broadcast
    double local = work(x), total;
    comm.allreduce(mpl::plus<double>(), local, total);            // functor reduction
}                                                  // RAII finalize on scope exit
```

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

| Concept | C API | MPL (C++) |
|---|---|---|
| init/finalize | `MPI_Init`/`MPI_Finalize` | none (RAII `environment`) |
| communicator | `MPI_Comm` handle | `mpl::communicator` (RAII, copy-deleted) |
| rank/size | `MPI_Comm_rank/size` | `comm.rank()`/`comm.size()` methods |
| send buffer | `void*`+count+`MPI_Datatype` | typed scalar / `vector` / iterator range |
| reduction op | `MPI_SUM`/`MPI_MAX` | `mpl::plus<T>`/`mpl::max<T>` functors |
| derived type | `MPI_Type_*`+commit/free | `mpl::contiguous_layout<T>` (RAII) |
| nonblocking | `MPI_Request`+`MPI_Wait(&r)` | `mpl::irequest`+`r.wait()` |

## Key Takeaways
1. MPI is SPMD: one program ranked over a communicator; messages match on (comm, source, tag).
2. Blocking calls return when safe; two ranks blocking-sending to each other deadlock — use `MPI_Sendrecv` or nonblocking.
3. Prefer optimized collectives (`Bcast`/`Allreduce`/`Scatter`/`Gather`) over hand-rolled point-to-point loops.
4. Overlap communication with computation via `Isend`/`Irecv` + `Wait` to hide network latency.
5. From C++, pass `vector::data()` buffers and built-in `MPI_*` datatypes; all MPI work lives between `MPI_Init`/`MPI_Finalize`.
6. For modern C++, **MPL** is the idiomatic binding: header-only, RAII communicators (copy-deleted, pass by reference), type-safe buffers (scalar/vector/iterator, no explicit datatype/count), functor reductions (`mpl::plus`), layout-object derived types, and no init/finalize — far safer than the raw C API from C++.

## Connects To
- **Ch 05 (Hardware)**: the cluster/interconnect model.
- **Ch 07 (Advanced MPI)**: derived datatypes, communicators, RMA, scaling.
- **Ch 14 (Actor model)**: an alternative message-passing concurrency model.
- **mpi-5.0 skill**: the authoritative MPI standard semantics (C/Fortran bindings) that MPL wraps.
