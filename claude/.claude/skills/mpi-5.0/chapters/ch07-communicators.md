# Chapter 7: Groups, Contexts, Communicators, and Caching

## Core Idea
**Communicators** define the safe scope of communication: a **group** (ordered set of processes → ranks) + a **context** (an isolation tag so messages from different libraries/phases can't collide). The machinery for partitioning processes, building libraries, and (MPI 5.0) the **Sessions** model.

## Frameworks Introduced
- **Group**: an ordered set of processes (`MPI_Group`). Operations: `MPI_Group_incl`/`MPI_Group_excl`, `MPI_Group_union`/`_intersection`/`_difference`, `MPI_Group_translate_ranks`, `MPI_Group_size`/`_rank`. Groups are *local* (no communication to manipulate).
- **Communicator** (`MPI_Comm`) = group + context. **Intra**communicator (one group; the usual case) vs **inter**communicator (two groups, for client/server or coupled-code communication).
- **Communicator creation**:
  - **`MPI_Comm_dup`**: copy (new context) — the *first thing a library should do* to isolate its messages.
  - **`MPI_Comm_split(comm, color, key, &new)`**: partition into sub-communicators by `color` (group) and `key` (rank order) — e.g. split a 2D grid into row/column communicators.
  - **`MPI_Comm_create`/`MPI_Comm_create_group`**: build from an explicit group.
- **Caching**: attach user attributes (and the topology) to a communicator via `MPI_Comm_create_keyval`/`MPI_Comm_set_attr` — library state that travels with the communicator.
- **Two initialization models** (ch11): the **World Model** (`MPI_Init` → `MPI_COMM_WORLD`) and the **Sessions Model** (MPI 4.0+, refined 5.0) — multiple independent `MPI_Session`s, each yielding communicators without a global `MPI_COMM_WORLD`.

## Key Concepts
- **Context = message isolation**: two communicators over the same processes don't cross-deliver messages — this is why libraries `MPI_Comm_dup` (so a library `MPI_Send` can't be received by user code).
- **`MPI_Comm_split` is the partitioning workhorse**: row/column decomposition, splitting by node (`MPI_COMM_TYPE_SHARED` via `MPI_Comm_split_type`) for hybrid MPI+OpenMP (one communicator per node).
- **`MPI_Comm_split_type(comm, MPI_COMM_TYPE_SHARED, ...)`**: get a communicator of processes sharing memory — the basis for shared-memory windows (ch12) and hybrid placement.
- **Sessions** decouple init from a single world: a library can initialize MPI independently of `main`, avoiding the "who calls MPI_Init" coupling.
- Free communicators/groups you create (`MPI_Comm_free`, `MPI_Group_free`).

## Code Examples
```c
// split MPI_COMM_WORLD into per-node communicators (hybrid MPI+OpenMP placement)
MPI_Comm node_comm;
MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0,
                    MPI_INFO_NULL, &node_comm);
int node_rank; MPI_Comm_rank(node_comm, &node_rank);   // 0 = node leader

// 2D grid: row and column sub-communicators
int row = world_rank / ncols, col = world_rank % ncols;
MPI_Comm row_comm, col_comm;
MPI_Comm_split(MPI_COMM_WORLD, row, col, &row_comm);   // group by row
MPI_Comm_split(MPI_COMM_WORLD, col, row, &col_comm);   // group by col
```
- **Demonstrates**: `MPI_Comm_split_type` for node-local communicators (hybrid placement) and `MPI_Comm_split` for row/column decomposition.

## Anti-patterns
- **A library communicating on `MPI_COMM_WORLD`**: user messages can collide with library messages — always `MPI_Comm_dup` a private communicator.
- **Hardcoding `MPI_COMM_WORLD` everywhere**: pass communicators as parameters; it makes code composable and Sessions-compatible.
- **Manipulating groups expecting communication**: group ops are local; only communicator *creation* is collective.
- **Leaking communicators in a loop**: `MPI_Comm_dup`/`split` in a hot loop without `MPI_Comm_free` exhausts contexts.

## Key Takeaways
1. Communicator = group (ranks) + context (message isolation); pass communicators, don't hardcode `MPI_COMM_WORLD`.
2. Libraries **must `MPI_Comm_dup`** to isolate their messages from user code.
3. `MPI_Comm_split` partitions (row/col grids); `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` gives node-local communicators for hybrid placement.
4. Group operations are local; communicator creation is collective.
5. **Sessions** (ch11) free MPI from a single `MPI_COMM_WORLD` — better for libraries and composition.

## Connects To
- **Ch 6**: collectives operate over a communicator's group.
- **Ch 8**: a topology is cached on a communicator (`MPI_Cart_create` returns a new comm).
- **Ch 11**: World vs Sessions initialization models.
- **Ch 12**: shared-memory windows use node-local communicators.
