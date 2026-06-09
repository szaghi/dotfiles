# Chapter 11: Process Initialization, Creation, and Management

## Core Idea
How MPI starts up and how processes come into existence: the classic **World Model** (`MPI_Init` → `MPI_COMM_WORLD`), the modern **Sessions Model** (MPI 4.0+, refined 5.0 — decoupled, library-friendly init), and **dynamic process management** (`MPI_Comm_spawn`).

## Frameworks Introduced
- **World Model** (§11.2): `MPI_Init`/`MPI_Init_thread` (exactly once) → `MPI_COMM_WORLD`, `MPI_COMM_SELF` → `MPI_Finalize`. `MPI_Initialized`/`MPI_Finalized` to query state. The traditional single-world startup.
- **Sessions Model** (§11.3): `MPI_Session_init(info, errhandler, &session)` → query a **process set** by name (`MPI_Session_get_pset_info`, `mpi://WORLD`, `mpi://SELF`) → `MPI_Group_from_session_pset` → `MPI_Comm_create_from_group` → communicator. Multiple independent sessions; **no global `MPI_COMM_WORLD` required**. `MPI_Session_finalize`.
- **Thread support at init**: `MPI_Init_thread(&argc, &argv, required, &provided)` — request a thread level (ch2), check `provided ≥ required`. Sessions request thread support via info.
- **Dynamic processes** (§11.x): `MPI_Comm_spawn`/`MPI_Comm_spawn_multiple` launch new processes, connected via an **intercommunicator**. `MPI_Comm_connect`/`MPI_Comm_accept` + `MPI_Open_port` for client/server; `MPI_Comm_join` from a socket.

## Key Concepts
- **World vs Sessions — why Sessions exist**: the World Model couples all of MPI to one `MPI_Init` in `main`, and one global communicator. Sessions let **independent components/libraries** each initialize MPI, request their own thread level and resources, and derive communicators from named **process sets** — without fighting over who calls `MPI_Init`. Both models can coexist in one program.
- **process set**: a named set of processes (e.g. `mpi://WORLD`) the runtime exposes; the Sessions entry point to building groups/communicators.
- **`MPI_Finalize` is collective** over connected processes; all MPI calls must complete first.
- **Dynamic spawn is niche in HPC**: most jobs are fixed-size SPMD; spawn matters for master/worker, coupled multi-physics, or malleable jobs.

## Code Examples
```c
// World Model with thread support (typical MPI+OpenMP)
int provided;
MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
if (provided < MPI_THREAD_FUNNELED) { /* abort: insufficient threading */ }
int rank, size;
MPI_Comm_rank(MPI_COMM_WORLD, &rank);
MPI_Comm_size(MPI_COMM_WORLD, &size);
/* ... */
MPI_Finalize();
```
```c
// Sessions Model: a library initializes MPI independently of main()
MPI_Session sh;
MPI_Session_init(MPI_INFO_NULL, MPI_ERRORS_RETURN, &sh);
MPI_Group wgroup;
MPI_Group_from_session_pset(sh, "mpi://WORLD", &wgroup);
MPI_Comm comm;
MPI_Comm_create_from_group(wgroup, "lib.tag", MPI_INFO_NULL,
                           MPI_ERRORS_RETURN, &comm);
/* ... library uses comm ... */
MPI_Comm_free(&comm); MPI_Group_free(&wgroup); MPI_Session_finalize(&sh);
```
- **Demonstrates**: World-Model `MPI_Init_thread` for hybrid MPI+OpenMP, and the Sessions-Model chain (`Session_init` → process set → group → communicator) for library-friendly init.

## Anti-patterns
- **Multiple `MPI_Init` calls / using MPI before init or after finalize**: erroneous; exactly one init in the World Model.
- **Requesting `MPI_THREAD_MULTIPLE` then not checking `provided`**: the implementation may give less — always verify.
- **A library forcing `MPI_Init` in user code**: use Sessions so the library initializes independently.
- **Assuming `MPI_COMM_WORLD` exists under Sessions-only init**: it may not — derive communicators from process sets.
- **Designing around dynamic spawn for a fixed-size job**: unnecessary complexity; use static SPMD.

## Key Takeaways
1. **World Model**: one `MPI_Init`/`MPI_Init_thread` → `MPI_COMM_WORLD` → `MPI_Finalize` (the classic path).
2. **Sessions Model** (MPI 5.0): independent `MPI_Session`s derive communicators from named **process sets** — no global world; ideal for libraries/composition.
3. Always `MPI_Init_thread` with the minimum required level and **check `provided`**.
4. Dynamic process management (`MPI_Comm_spawn`, connect/accept) exists but is niche for fixed-size HPC SPMD.
5. Both models can coexist; pass communicators rather than assuming `MPI_COMM_WORLD`.

## Connects To
- **Ch 2**: thread levels requested at init.
- **Ch 7**: communicators/groups derived from sessions/process sets.
- **Ch 9**: error handlers attached at session/world init.
- **openmp-6.0**: hybrid MPI+OpenMP needs the right thread level (`FUNNELED`/`MULTIPLE`).
