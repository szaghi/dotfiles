---
name: mpi-5.0
description: "Authoritative knowledge base from the MPI: A Message-Passing Interface Standard, Version 5.0. CONSULT THIS BEFORE ANSWERING — do not answer MPI questions from memory; send-mode/completion semantics, collective and RMA synchronization rules, datatype matching, thread levels, and routine signatures are subtle, deadlock-prone, and version-sensitive. TRIGGER whenever a question concerns: writing/reading/debugging MPI code (any MPI_* / mpi_f08 routine); message passing, distributed-memory parallelism, or multi-node HPC communication; point-to-point (send/recv modes, nonblocking, partitioned); collectives (bcast/reduce/allreduce/alltoall/scan, nonblocking, neighborhood); derived datatypes; communicators/groups/topologies/Sessions; one-sided RMA (windows/put/get/accumulate, fence/lock); MPI-IO (file views, collective I/O); process init (MPI_Init/Init_thread/Sessions/spawn); thread support levels; the standard ABI; error handling; the omp+MPI or GPU+MPI hybrid model; or diagnosing deadlocks, buffer-reuse bugs, or MPI performance. SKIP only when the user explicitly wants a specific MPI implementation's internals (Open MPI/MPICH/Cray) rather than the MPI standard, or a non-MPI parallel model (OpenMP→openmp-6.0, OpenACC→openacc-3.4)."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, MPI_ routine, or chapter (e.g. ch12)]
---

# MPI: A Message-Passing Interface Standard — Version 5.0
**Source**: MPI Forum, MPI 5.0 | **Pages**: ~1189 | **Chapters**: 18 (grouped from 20 spec chapters + Annex A) | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the semantic model + point-to-point/collective core below.
- **With a topic** — ask about `nonblocking`, `collectives`, `RMA`, `datatypes`, `MPI-IO`, `Sessions`, `topologies`; I read the relevant chapter.
- **With an `MPI_` routine** — name it (`MPI_Allreduce`, `MPI_Win_fence`, `MPI_File_set_view`); I find the chapter.
- **With a chapter** — `ch03` (point-to-point), `ch06` (collectives), `ch12` (RMA), `ch14` (I/O).

This is the *standard*, not a tutorial or an implementation manual — answers cite chapters. For exact signatures see ch18 (Annex A). Pairs with `openmp-6.0`, `openacc-3.4`, `fortran-2023-standard`, `CLAUDE-gpu.md`.

---

## Core Frameworks & Mental Models

### What MPI is (Ch 1)
- A **specification** (not an implementation) for **cooperative message passing** in distributed memory: data moves between process address spaces via matched operations. Beyond send/recv: **collectives**, **one-sided RMA**, **parallel I/O**, **dynamic processes**. The unit is an **MPI process** with a **rank** in a **communicator**; SPMD is the norm.

### Operation taxonomy (Ch 2) — classify every call
- **timing**: blocking / nonblocking (returns a **request**, complete with `MPI_Wait`/`MPI_Test`) / persistent (init once, start many).
- **participation**: collective (all processes in the group call it — mismatch deadlocks) / noncollective.
- **locality**: local (no peer needed) / nonlocal (may need a matching call).
- **Completion = buffer reusable (send) / data arrived (recv)** — *not* that the peer finished (except `MPI_Ssend`).

### Point-to-point (Ch 3) — and deadlock
- Match on **(communicator, source, tag)**; data is `(buf, count, datatype)`, count in *elements*.
- Send modes: **standard `MPI_Send`** (impl-chosen buffering — **don't rely on it**), buffered, **synchronous `MPI_Ssend`** (rendezvous), ready.
- **Mutual send-before-recv in standard mode can deadlock** → use **`MPI_Sendrecv`** or **nonblocking + `MPI_Waitall`** (which also overlaps comm/compute). Never touch an `MPI_Isend` buffer before completion.

### Collectives (Ch 6)
- Same call by **all** group members. `MPI_Bcast`/`Gather`/`Scatter`/`Alltoall`/`Reduce`/**`Allreduce`** (the global-reduction workhorse — norms/convergence, but a sync point). Nonblocking (`MPI_Iallreduce`) for overlap; **neighborhood** collectives (+ topology) for scalable halo exchange. `MPI_IN_PLACE` drops a buffer. FP reductions are not bit-reproducible across layouts.

### Datatypes (Ch 5)
- **Derived types** (`MPI_Type_vector`/`create_subarray`/`create_struct`) send non-contiguous memory in one call — no manual packing. `subarray` is the halo/distributed-array descriptor. `commit` before, `free` after; mind **extent vs size** (`MPI_Type_create_resized`).

### Communicators & topologies (Ch 7, 8)
- Communicator = group (ranks) + context (message isolation). **Libraries must `MPI_Comm_dup`**. `MPI_Comm_split` partitions; `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` → node-local. `MPI_Cart_create`+`MPI_Cart_shift`+`MPI_Sendrecv` = canonical halo exchange.

### One-sided RMA (Ch 12)
- `Put`/`Get`/`Accumulate` on **windows**, target doesn't participate (maps to RDMA). Completion at **epoch end** (`fence`/`unlock`/`flush`), never early. `MPI_Accumulate` (atomic) for concurrent updates. `MPI_Win_allocate_shared` = portable node-local shared memory.

### Parallel I/O (Ch 14)
- One shared file + **file view** (`subarray` filetype per rank) + **collective `_all`** ops → the implementation aggregates for throughput. Never one-file-per-rank at scale. `MPI_Info` hints (collective buffering, striping) dominate performance.

### Init & threads (Ch 11, 2)
- **World Model** (`MPI_Init`→`MPI_COMM_WORLD`) vs **Sessions Model** (5.0 — independent init, no global world; library-friendly). `MPI_Init_thread` with the minimum level (`FUNNELED` typical hybrid; `MULTIPLE` only for concurrent MPI from threads) — **check `provided`**.

### MPI 5.0 highlights
**Standard ABI** (one binary runs against any conforming MPI — `MPI_Abi_get_version`) · Sessions refinements · **partitioned** point-to-point (multithreaded/GPU senders) · large-count `_c` routines · `use mpi_f08` standard Fortran binding · C++ bindings removed.

### Hybrid (cross-referenced)
One rank per NUMA domain; threads/GPU within (`MPI_THREAD_FUNNELED`/`MULTIPLE`); device-aware MPI passes device pointers; pin ranks+threads. Timing: **`MPI_Wtime`** (wall-clock), not `cpu_time`; reduce local intervals (clocks not cross-rank synced).

---

## Chapter Index

| # | Covers | Key topics |
|---|--------|------------|
| [ch01](chapters/ch01-introduction.md) | Ch 1 | message-passing model, spec vs impl, rank/communicator |
| [ch02](chapters/ch02-terms-conventions.md) | Ch 2 | operation taxonomy, opaque handles, errors, thread levels |
| [ch03](chapters/ch03-point-to-point.md) | Ch 3 | send modes, nonblocking, Sendrecv, deadlock |
| [ch04](chapters/ch04-partitioned.md) | Ch 4 | partitioned point-to-point (multithreaded senders) |
| [ch05](chapters/ch05-datatypes.md) | Ch 5 | derived datatypes, subarray, pack/unpack |
| [ch06](chapters/ch06-collective.md) | Ch 6 | bcast/reduce/allreduce/alltoall/scan, nonblocking, neighborhood |
| [ch07](chapters/ch07-communicators.md) | Ch 7 | groups, contexts, comm split, caching, Sessions intro |
| [ch08](chapters/ch08-topologies.md) | Ch 8 | Cartesian/graph topologies, Cart_shift, neighborhood |
| [ch09](chapters/ch09-environment.md) | Ch 9 | error handlers, MPI_Wtime, MPI_Alloc_mem |
| [ch10](chapters/ch10-info-object.md) | Ch 10 | MPI_Info hints/assertions |
| [ch11](chapters/ch11-process-management.md) | Ch 11 | World vs Sessions model, Init_thread, spawn |
| [ch12](chapters/ch12-one-sided.md) | Ch 12 | RMA windows, put/get/accumulate, fence/lock, shared mem |
| [ch13](chapters/ch13-external-interfaces.md) | Ch 13 | generalized requests, datatype decoding, progress |
| [ch14](chapters/ch14-io.md) | Ch 14 | MPI-IO file views, collective I/O, datarep |
| [ch15](chapters/ch15-tool-support.md) | Ch 15 | PMPI profiling, MPI_T cvars/pvars |
| [ch16](chapters/ch16-deprecated-removed.md) | Ch 16-18 | deprecated/removed, mpi_f08, semantic changes |
| [ch17](chapters/ch17-language-bindings.md) | Ch 19-20 | C/Fortran bindings, large-count `_c`, standard ABI |
| [ch18](chapters/ch18-bindings-summary.md) | Annex A | signature + constant reference |

## Topic Index

- **ABI / binary portability** → ch17
- **allreduce / reduction** → ch06
- **alltoall / transpose** → ch06
- **collectives** → ch06
- **communicators / groups / split** → ch07
- **datatypes (derived/subarray/struct)** → ch05
- **deadlock avoidance** → ch03, ch06, cheatsheet
- **deprecated / removed / mpi_f08** → ch16, ch17
- **dynamic processes / spawn** → ch11
- **error handling** → ch09, ch02
- **halo / ghost-cell exchange** → ch03, ch05, ch08, patterns
- **hybrid MPI + OpenMP/GPU** → ch02, ch11, cheatsheet
- **info hints** → ch10, ch14
- **MPI-IO / parallel I/O / file views** → ch14
- **nonblocking / Isend / Waitall** → ch03, ch06
- **one-sided / RMA / windows** → ch12
- **partitioned communication** → ch04
- **persistent communication** → ch02, patterns
- **point-to-point / send modes** → ch03
- **process init (World/Sessions)** → ch11
- **profiling (PMPI/MPI_T)** → ch15
- **send modes (standard/sync/buffered/ready)** → ch03
- **Sendrecv** → ch03
- **Sessions model** → ch11, ch07
- **shared memory (node-local)** → ch12, ch07
- **signatures / constants reference** → ch18
- **thread levels** → ch02, ch11
- **timing (MPI_Wtime)** → ch09
- **topologies (Cartesian/graph)** → ch08
- **windows / Win_fence / lock** → ch12

## Supporting Files

- [glossary.md](glossary.md) — terms + API vocabulary
- [patterns.md](patterns.md) — MPI idioms (halo exchange, overlap, RMA, hybrid, I/O)
- [cheatsheet.md](cheatsheet.md) — send/collective/RMA decision rules + deadlock tells & smells

---

## Scope & Limits

Covers MPI Standard v5.0. Extracted with pdftotext (docling garbles this spec class — see the fortran-2023-standard note). This is the *standard* — implementation behavior (transport, progress engine, default eager limits, launch via `mpirun`/`srun`) belongs to Open MPI / MPICH / Cray MPICH / Intel MPI docs. Exact routine signatures live in ch18 (Annex A); consult it rather than recalling argument order. For shared-memory threading use `openmp-6.0`; for GPU offload `openacc-3.4`; for the Fortran `mpi_f08` base language `fortran-2023-standard`; for HPC practice `CLAUDE-gpu.md`.
