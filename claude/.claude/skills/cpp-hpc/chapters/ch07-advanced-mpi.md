# Chapter 7: Advanced MPI — Datatypes, Communicators, RMA & Scaling

## Core Idea
Beyond basic send/recv, MPI scales real applications with **derived datatypes** (send non-contiguous data in one call), **communicators & topologies** (structure ranks to match the problem), **one-sided RMA** (decouple data movement from synchronization), and a discipline of **scaling analysis** to know whether to add more ranks.

## Frameworks Introduced

- **Derived datatypes** (send structured/non-contiguous data without manual packing):
  - `MPI_Type_contiguous`, `MPI_Type_vector` (strided blocks — e.g. a matrix column or a halo face), `MPI_Type_indexed`, `MPI_Type_create_struct` (heterogeneous C++ structs). `MPI_Type_commit` before use, `MPI_Type_free` after.
  - The alternative — `MPI_Pack`/`MPI_Unpack` into a byte buffer — is more manual; derived types let MPI move the data directly.

- **Communicators, groups & topologies** (structure ranks to the problem):
  - **`MPI_Comm_split`** (by color/key) creates sub-communicators for sub-team collectives; build from groups via `MPI_Group_incl` + `MPI_Comm_create`.
  - **Cartesian topology** `MPI_Cart_create` + `MPI_Cart_shift` maps ranks onto a logical grid and computes neighbor ranks automatically — the natural fit for domain-decomposed stencils.

- **One-sided / RMA communication** (decouple movement from synchronization):
  - A process exposes a memory **window** (`MPI_Win_create`); others `MPI_Put`/`MPI_Get`/`MPI_Accumulate` into it without the target issuing a matching call.
  - Synchronized by epochs: active-target (`MPI_Win_fence`) or passive-target (`MPI_Win_lock`/`unlock`).

- **Scaling analysis & modern features**:
  - **Strong scaling** (fixed problem, more ranks → Amdahl-bounded) vs **weak scaling** (problem grows with ranks → Gustafson, ~linear). Measure both to answer "faster?" vs "bigger?".
  - **Nonblocking collectives** (`MPI_Iallreduce`, …) overlap collective communication with compute; **neighborhood collectives** optimize halo patterns; **thread support** via `MPI_Init_thread` (check the provided level) for hybrid MPI+OpenMP/threads.

## Key Concepts
- **Domain decomposition + halo exchange**: partition the global grid across ranks; each owns a subdomain + ghost cells exchanged each step. Communication scales with subdomain **surface area**, compute with **volume** — larger subdomains per rank improve the surface-to-volume ratio.
- **Hybrid MPI+X**: MPI across nodes, OpenMP/threads/GPU within a node — the standard HPC structure. `MPI_THREAD_MULTIPLE` allows any thread to call MPI concurrently.
- **Surface-to-volume**: the ratio that makes coarser decompositions communication-efficient.
- **Communicator hygiene**: use sub-communicators to scope collectives to the ranks that need them, avoiding global synchronization.

## Mental Models
- **Use derived datatypes and Cartesian topologies for halo exchange** — they eliminate manual packing and neighbor-index arithmetic, the two classic stencil bugs.
- **A good decomposition is the biggest determinant of MPI scaling** — balance load and maximize subdomain surface-to-volume before micro-optimizing calls.
- **Report strong and weak scaling separately** — they answer different questions ("run faster" vs "run bigger"); conflating them misleads.
- **Overlap collectives too** — nonblocking collectives (`Iallreduce`) hide global communication behind local compute, the next lever after point-to-point overlap.

## Code Examples
```cpp
// Derived datatype: a strided column (halo face) sent in one call
MPI_Datatype col;
MPI_Type_vector(/*count*/ nrows, /*blocklen*/ 1, /*stride*/ ncols, MPI_DOUBLE, &col);
MPI_Type_commit(&col);
MPI_Sendrecv(&grid[0][last_col], 1, col, right, 0,
             &grid[0][0],        1, col, left,  0, comm, MPI_STATUS_IGNORE);
MPI_Type_free(&col);

// Cartesian topology computes neighbor ranks for a 2D decomposition
int dims[2] = {0,0}, periods[2] = {1,1}, coords[2];
MPI_Dims_create(size, 2, dims);
MPI_Comm cart;
MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, 1, &cart);
int up, down;
MPI_Cart_shift(cart, 0, 1, &up, &down);     // neighbor ranks, no manual arithmetic

// One-sided RMA
MPI_Win win;
MPI_Win_create(base, bytes, sizeof(double), MPI_INFO_NULL, comm, &win);
MPI_Win_fence(0, win);
MPI_Put(local, n, MPI_DOUBLE, target, 0, n, MPI_DOUBLE, win);
MPI_Win_fence(0, win);
MPI_Win_free(&win);
```
- **What it demonstrates**: a strided derived datatype for halos, Cartesian neighbor computation, and an RMA epoch.

## Reference Tables

| Feature | Use |
|---|---|
| `MPI_Type_vector` | strided data (columns, halo faces) |
| `MPI_Type_create_struct` | heterogeneous C++ structs |
| `MPI_Comm_split` | sub-team collectives |
| `MPI_Cart_create`/`Cart_shift` | grid topology + neighbors |
| `MPI_Win`/`Put`/`Get` | one-sided RMA |
| `MPI_Iallreduce` | overlapped collective |

| Scaling | Regime |
|---|---|
| strong | fixed size, more ranks (Amdahl) |
| weak | size grows with ranks (Gustafson) |

## Key Takeaways
1. Derived datatypes send non-contiguous data (columns, halo faces, structs) in one call — no manual packing.
2. `MPI_Comm_split` and Cartesian topologies structure ranks to the problem and compute neighbors automatically.
3. One-sided RMA (windows + `Put`/`Get`) decouples data movement from synchronization.
4. Domain decomposition + halo exchange is the dominant pattern; maximize subdomain surface-to-volume.
5. Measure strong and weak scaling separately; use nonblocking collectives and `MPI_Init_thread` for overlap and hybrid MPI+threads.

## Connects To
- **Ch 06 (MPI fundamentals)**: the point-to-point and collective basics this extends.
- **Ch 08 (OpenMP)**: the within-node layer of hybrid MPI+OpenMP.
- **Ch 11 (Parallel I/O)**: MPI-IO and parallel filesystems for distributed output.
