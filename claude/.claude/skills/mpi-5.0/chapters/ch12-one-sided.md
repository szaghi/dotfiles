# Chapter 12: One-Sided Communications (RMA)

## Core Idea
**Remote Memory Access** — one process reads/writes another's memory **without the target actively participating** in each transfer. Decouples data movement from synchronization; maps to RDMA hardware. Built on **windows** (exposed memory) + explicit **synchronization epochs**.

## Frameworks Introduced
- **Window creation** (expose memory for RMA):
  - **`MPI_Win_create(base, size, disp_unit, info, comm, &win)`**: expose existing memory.
  - **`MPI_Win_allocate(...)`**: allocate + expose (often RDMA-registered — preferred).
  - **`MPI_Win_allocate_shared(...)`**: allocate a window in **shared memory** (within a node-local communicator from `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)`) — direct load/store access via `MPI_Win_shared_query`. The MPI route to intra-node shared memory.
  - **`MPI_Win_create_dynamic`** + `MPI_Win_attach`: attach memory regions dynamically.
- **Communication calls** (within an epoch): **`MPI_Put`** (write remote), **`MPI_Get`** (read remote), **`MPI_Accumulate`** (atomic-combine remote with an op), **`MPI_Get_accumulate`**, **`MPI_Fetch_and_op`**, **`MPI_Compare_and_swap`** (atomics).
- **Synchronization — two paradigms**:
  - **Active target** (target participates in sync): **`MPI_Win_fence`** (collective, BSP-style — simplest) or **PSCW** (`MPI_Win_post`/`_start`/`_complete`/`_wait` — scalable, exposure/access groups).
  - **Passive target** (target uninvolved): **`MPI_Win_lock`/`_unlock`** (or `_lock_all`/`_unlock_all`) bracketing accesses; **`MPI_Win_flush`**/`_flush_all`/`_flush_local` to force completion without ending the epoch.

## Key Concepts
- **RMA != immediate**: `MPI_Put`/`MPI_Get` only guaranteed complete at the **end of the epoch** (`fence`/`unlock`/`flush`) — not when the call returns. Reading the buffer early sees stale/partial data.
- **fence is the easy mode** (collective, bulk-synchronous): `fence … puts/gets … fence`. PSCW and passive-target lock are for finer-grained/scalable patterns.
- **Shared-memory windows** (`MPI_Win_allocate_shared`) give true load/store access among node-local ranks — the standard, portable alternative to raw shared memory for MPI+MPI hybrid (MPI everywhere, shared memory within a node).
- **Accumulate is atomic** for predefined ops — the safe way to do concurrent remote updates (vs racy Put).
- **memory models**: RMA has a *unified* (cache-coherent) vs *separate* memory model; `MPI_Win_get_attr(MPI_WIN_MODEL)` tells which — affects whether local load/store and RMA see each other without sync.

## Code Examples
```c
// active-target (fence) one-sided accumulate
MPI_Win win;
MPI_Win_allocate(n*sizeof(double), sizeof(double), MPI_INFO_NULL,
                 comm, &base, &win);
MPI_Win_fence(0, win);                      // open epoch
MPI_Accumulate(local, n, MPI_DOUBLE, target_rank, 0, n, MPI_DOUBLE,
               MPI_SUM, win);               // atomic remote += local
MPI_Win_fence(0, win);                      // close epoch -> now complete
MPI_Win_free(&win);

// node-local shared memory window
MPI_Comm node; MPI_Comm_split_type(comm, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &node);
MPI_Win shwin; double *shptr;
MPI_Win_allocate_shared(bytes, sizeof(double), MPI_INFO_NULL, node, &shptr, &shwin);
// shptr is directly load/store-accessible across the node's ranks (with sync)
```
- **Demonstrates**: fence-synchronized atomic `MPI_Accumulate`, and a shared-memory window for direct intra-node access.

## Anti-patterns
- **Reading an RMA buffer before the epoch closes**: `Put`/`Get` aren't done until `fence`/`unlock`/`flush` — stale/partial data.
- **Concurrent `MPI_Put` to the same location**: racy — use `MPI_Accumulate` (atomic) for concurrent updates.
- **Forgetting the closing `fence`/`unlock`**: the transfer may never complete.
- **Passive-target without `MPI_Win_flush` before using results**: completion isn't guaranteed mid-epoch.
- **Assuming local stores are visible to RMA without sync in the separate memory model**: check `MPI_WIN_MODEL`.
- **`MPI_Win_create` over `malloc` memory on RDMA nets**: prefer `MPI_Win_allocate` (registered).

## Key Takeaways
1. RMA = one-sided `Put`/`Get`/`Accumulate` on **windows**; the target doesn't participate per transfer (maps to RDMA).
2. Completion is at **epoch end** (`fence`/`unlock`/`flush`), not call return — never read early.
3. **`MPI_Win_fence`** is the simple bulk-synchronous mode; PSCW and passive-target lock/flush are the scalable/fine-grained modes.
4. `MPI_Accumulate`/atomics for concurrent remote updates (Put is racy).
5. **`MPI_Win_allocate_shared`** + node-local communicator = portable intra-node shared memory (MPI+MPI hybrid).

## Connects To
- **Ch 7**: `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` for shared-memory windows.
- **Ch 9**: `MPI_Alloc_mem` and window memory.
- **Ch 10**: window info hints/assertions (`no_locks`, `accumulate_ordering`).
- **Ch 6**: RMA vs collective trade-offs for reductions/exchanges.
