# Chapter 8: Virtual Topologies for MPI Processes

## Core Idea
Attach a **communication structure** (Cartesian grid or arbitrary graph) to a communicator so MPI can (a) provide convenient neighbor queries and (b) **remap ranks to physical topology** for locality. The natural fit for stencil/grid codes and the enabler of neighborhood collectives.

## Frameworks Introduced
- **Cartesian topology** (`MPI_Cart_create(comm, ndims, dims[], periods[], reorder, &cart)`): an n-D grid with optional periodic (wrap-around) dimensions. `reorder=true` lets MPI renumber ranks for physical locality.
  - **`MPI_Cart_shift(cart, dim, disp, &src, &dest)`**: get the neighbor ranks along a dimension (returns `MPI_PROC_NULL` at non-periodic boundaries) — feeds `MPI_Sendrecv` for halo exchange.
  - **`MPI_Cart_coords`/`MPI_Cart_rank`**: convert between rank and grid coordinates. **`MPI_Dims_create`**: suggest a balanced `dims[]` factorization.
- **Graph topology**: `MPI_Graph_create` (legacy,全-replicated) and **`MPI_Dist_graph_create`/`MPI_Dist_graph_create_adjacent`** (scalable, distributed adjacency) for irregular communication patterns.
- **Neighborhood collectives** (ch6): `MPI_Neighbor_allgather`, `MPI_Neighbor_alltoall(v/w)` (+ `I`/persistent) communicate exactly with the topology neighbors — one call replaces a hand-coded loop of sends/recvs.

## Key Concepts
- **`reorder=true` for locality**: tells MPI it may renumber ranks so grid-neighbors are physically close (same node/switch) — can materially improve halo-exchange bandwidth. Re-query your rank after creation.
- **`MPI_Cart_shift` + `MPI_Sendrecv`** is the textbook deadlock-free halo exchange; `MPI_PROC_NULL` boundaries make edge handling branch-free.
- **Neighborhood collectives scale better** than explicit per-neighbor send/recv loops and let the implementation optimize the whole exchange.
- The topology is **cached on the communicator** — it's communicator metadata, queryable later.

## Code Examples
```c
// 2D periodic Cartesian grid + halo exchange via Cart_shift
int dims[2] = {0,0}, periods[2] = {1,1};
MPI_Dims_create(nprocs, 2, dims);            // balanced factorization
MPI_Comm cart;
MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, /*reorder=*/1, &cart);

int up, down, left, right;
MPI_Cart_shift(cart, 0, 1, &up, &down);      // neighbors along dim 0
MPI_Cart_shift(cart, 1, 1, &left, &right);   // neighbors along dim 1

MPI_Sendrecv(top_row,    n, MPI_DOUBLE, up,   0,
             bot_halo,   n, MPI_DOUBLE, down, 0, cart, MPI_STATUS_IGNORE);
```
- **Demonstrates**: `MPI_Dims_create` + `MPI_Cart_create(reorder)` for a locality-aware grid, then `MPI_Cart_shift` feeding `MPI_Sendrecv` halo exchange (boundaries auto-handled via `MPI_PROC_NULL`).

## Anti-patterns
- **Computing neighbor ranks by hand** (`rank±1`, `rank±ncols`): error-prone at boundaries; use `MPI_Cart_shift` (gives `MPI_PROC_NULL` automatically).
- **`reorder=false` then complaining about poor locality**: allow reordering so MPI can map grid-neighbors physically close.
- **Forgetting ranks may change after `reorder=true`**: re-query `MPI_Comm_rank` on the new communicator.
- **`MPI_Graph_create` (non-distributed) at scale**: it replicates the full graph on every process — use `MPI_Dist_graph_create_adjacent`.
- **Hand-rolled neighbor send/recv loops**: prefer neighborhood collectives for scalability.

## Key Takeaways
1. `MPI_Cart_create` (+ `MPI_Dims_create`) builds an n-D grid; `reorder=true` enables locality-aware rank remapping.
2. **`MPI_Cart_shift` + `MPI_Sendrecv`** is the canonical deadlock-free, boundary-safe halo exchange.
3. Use **distributed graph** (`MPI_Dist_graph_create_adjacent`) for irregular patterns, not the legacy replicated `MPI_Graph_create`.
4. **Neighborhood collectives** turn the whole halo exchange into one optimizable call.
5. The topology is cached on the communicator; ranks may change with `reorder` — re-query.

## Connects To
- **Ch 6**: neighborhood collectives use the topology.
- **Ch 7**: a topology produces a new communicator with cached structure.
- **Ch 3**: `MPI_Sendrecv` + `MPI_PROC_NULL` for the actual halo transfer.
- **shore / Xall**: Cartesian/block decomposition maps onto Chimera/structured-grid domain partitioning.
