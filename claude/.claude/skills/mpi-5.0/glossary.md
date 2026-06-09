# Glossary — MPI 5.0

Key terms + API vocabulary. Format: **Term** — definition (Ch).

**ABI (standard)** — MPI 5.0 binary interface so one executable runs against any conforming impl (Ch17).
**Accumulate** — atomic remote combine (`MPI_Accumulate`) in RMA (Ch12).
**active target** — RMA sync where the target participates (`MPI_Win_fence`, PSCW) (Ch12).
**blocking** — operation whose single call combines all four stages; completes before return (Ch2).
**collective** — operation all processes in a group call; mismatch deadlocks (Ch2, 6).
**communicator** — group + context; the scope of communication (`MPI_Comm`) (Ch7).
**context** — message-isolation tag distinguishing communicators (Ch7).
**datarep** — file data representation: native / internal / external32 (Ch14).
**deprecated** — legal but discouraged; the removal queue (Ch16).
**derived datatype** — describes non-contiguous memory (vector/indexed/struct/subarray) (Ch5).
**epoch** — RMA synchronization interval; transfers complete at epoch end (Ch12).
**etype / filetype** — elementary type / file-view layout type in MPI-IO (Ch14).
**extent vs size** — span (incl. gaps) vs actual data bytes of a datatype (Ch5).
**file view** — (disp, etype, filetype, datarep) giving a process its slice of a file (Ch14).
**generalized request** — MPI request backed by user-defined async work (Ch13).
**group** — ordered set of processes → ranks (`MPI_Group`); local ops (Ch7).
**handle** — reference to an opaque MPI object (Ch2).
**info object** — (key,value) string hints/assertions (`MPI_Info`) (Ch10).
**intercommunicator** — communicator spanning two groups (Ch7).
**local / nonlocal** — completes without / may require another process (Ch2).
**MPI process** — execution unit with private address space (Ch1).
**MPI_IN_PLACE** — avoid a separate send buffer in collectives (Ch6).
**MPI_PROC_NULL** — null peer; send/recv is a completing no-op (Ch3).
**MPI_T** — tool information interface: cvars/pvars/events (Ch15).
**MPI_Wtime** — portable wall-clock timer (Ch9).
**neighborhood collective** — communicate with topology neighbors only (Ch6, 8).
**nonblocking** — init+start now (returns request), complete later via Wait/Test (Ch2, 3).
**one-sided / RMA** — remote memory access without target participation (Ch12).
**partition** — independently-readied piece of a partitioned message (Ch4).
**passive target** — RMA sync where target is uninvolved (`MPI_Win_lock`/`flush`) (Ch12).
**persistent** — init separated from repeated start (amortize setup) (Ch2).
**PMPI** — profiling interface; `PMPI_X` twin of each `MPI_X` (Ch15).
**process set** — named set of processes in the Sessions model (Ch11).
**rank** — process ID within a communicator's group (0-based) (Ch1).
**ready send** — `MPI_Rsend`; only valid if receive already posted (Ch3).
**reduction op** — `MPI_SUM`/`MAX`/`MINLOC`/… or user `MPI_Op_create` (Ch6).
**request** — handle for a pending nonblocking/persistent operation (Ch2, 3).
**Sessions Model** — MPI 5.0 init via independent sessions/process sets, no global world (Ch11).
**SPMD** — single program, many processes branching on rank (Ch1).
**standard send** — `MPI_Send`; impl chooses buffering (Ch3).
**status** — receive result: source, tag, error, count (`MPI_Status`) (Ch3).
**subarray type** — `MPI_Type_create_subarray`; halo/distributed-array descriptor (Ch5, 14).
**synchronous send** — `MPI_Ssend`; completes when receiver starts (rendezvous) (Ch3).
**thread level** — SINGLE/FUNNELED/SERIALIZED/MULTIPLE (`MPI_Init_thread`) (Ch2, 11).
**topology (virtual)** — Cartesian/graph communication structure on a communicator (Ch8).
**window** — memory region exposed for RMA (`MPI_Win`) (Ch12).
**World Model** — classic `MPI_Init` → `MPI_COMM_WORLD` init (Ch11).
**`use mpi_f08`** — modern type-safe Fortran binding (typed handles, INTENT) (Ch16, 17).
