# Chapter 10: The Info Object

## Core Idea
`MPI_Info` is an opaque **(key, value) string dictionary** for passing implementation-specific hints and assertions to MPI routines — file access patterns, RMA optimizations, communicator placement, spawn arguments. The portable channel for non-portable tuning.

## Frameworks Introduced
- **Info API**: `MPI_Info_create(&info)`, `MPI_Info_set(info, key, value)`, `MPI_Info_get_string`/`MPI_Info_get` (retrieve), `MPI_Info_delete`, `MPI_Info_dup`, `MPI_Info_free`. Keys and values are strings (max lengths `MPI_MAX_INFO_KEY`/`MPI_MAX_INFO_VAL`).
- **Where info is consumed**: `MPI_File_open` (I/O hints), `MPI_Win_allocate`/`MPI_Win_create` (RMA hints), `MPI_Comm_dup_with_info`/`MPI_Comm_split_type` (communicator hints), `MPI_Comm_spawn` (launch args), Sessions init.
- **Standard-reserved keys** (advisory; implementation honors what it can): I/O — `access_style`, `collective_buffering`, `cb_nodes`, `striping_factor`, `striping_unit`, `romio_*`; RMA — `no_locks`, `accumulate_ordering`, `same_size`, `same_disp_unit`; communicator — `mpi_assert_no_any_tag`, `mpi_assert_exact_length`, etc.
- **Info-as-assertion**: some keys are *assertions* (you promise a property, MPI optimizes assuming it) vs *hints* (advisory). Violating an assertion is erroneous.

## Key Concepts
- **Hints are advisory, assertions are contracts**: a hint MPI may ignore; an assertion (e.g. `no_locks=true` on a window) MPI may exploit and you must honor.
- **The portable escape hatch for tuning**: rather than implementation-specific APIs, you pass `MPI_Info` and the implementation extracts what it understands — code stays portable, tuning is per-deployment.
- **I/O hints are the biggest practical lever** (ch14): collective buffering and striping hints can change MPI-IO throughput by large factors on parallel file systems (Lustre/GPFS).
- `MPI_INFO_NULL` when you have no hints.

## Code Examples
```c
// tune MPI-IO for a large collective write on Lustre
MPI_Info info;
MPI_Info_create(&info);
MPI_Info_set(info, "collective_buffering", "true");
MPI_Info_set(info, "cb_nodes", "16");
MPI_Info_set(info, "striping_factor", "16");
MPI_File fh;
MPI_File_open(comm, "out.dat", MPI_MODE_CREATE|MPI_MODE_WRONLY, info, &fh);
MPI_Info_free(&info);

// assert a window has no passive-target locks -> implementation may optimize
MPI_Info wininfo; MPI_Info_create(&wininfo);
MPI_Info_set(wininfo, "no_locks", "true");
MPI_Win_allocate(bytes, disp, wininfo, comm, &base, &win);
```
- **Demonstrates**: I/O hints steering collective buffering/striping, and an RMA `no_locks` assertion enabling window optimization.

## Anti-patterns
- **Treating assertions as hints**: asserting `no_locks=true` then using locks is erroneous — honor what you assert.
- **Hardcoding implementation-specific tuning in API calls**: route it through `MPI_Info` so the code stays portable.
- **Ignoring I/O hints on parallel file systems**: default striping/buffering is often far from optimal for large collective I/O.
- **Leaking info objects**: `MPI_Info_free` what you create.

## Key Takeaways
1. `MPI_Info` = portable (key,value) string hints/assertions consumed by file/window/comm/spawn routines.
2. Hints are advisory; **assertions are contracts** you must honor (e.g. `no_locks`).
3. The portable way to pass non-portable tuning — biggest practical impact on MPI-IO (collective buffering, striping).
4. `MPI_INFO_NULL` for none; free what you create.

## Connects To
- **Ch 14**: MPI-IO hints (the highest-impact use).
- **Ch 12**: RMA window hints/assertions.
- **Ch 7/11**: communicator and Sessions info.
