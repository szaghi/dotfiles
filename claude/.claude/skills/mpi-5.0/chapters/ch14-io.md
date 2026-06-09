# Chapter 14: I/O (MPI-IO)

## Core Idea
Parallel I/O: many processes read/write **one shared file** efficiently via **file views** (each process sees only its portion) and **collective operations** (the implementation aggregates/optimizes accesses). The standard way to do scalable checkpoint/restart and distributed-array I/O.

## Frameworks Introduced
- **File view** = `(displacement, etype, filetype, datarep)` set by **`MPI_File_set_view`**:
  - **etype**: the elementary datatype (unit of access/offset).
  - **filetype**: a derived datatype (often `MPI_Type_create_subarray`) defining *which* parts of the file this process sees — non-overlapping views tile the file across processes.
  - **datarep**: `"native"` (raw, fast, non-portable), `"internal"` (impl-portable), `"external32"` (fully portable across platforms).
- **Access dimensions** (combine freely):
  - **positioning**: explicit offset (`MPI_File_read_at`), individual file pointer (`MPI_File_read`), shared file pointer (`MPI_File_read_shared`).
  - **coordination**: **independent** (per-process) vs **collective** (`_all` suffix — all processes in the file's group participate; enables collective buffering).
  - **synchronism**: blocking, nonblocking (`MPI_File_iread`), or **split-collective** (`_begin`/`_end`).
- **`MPI_File_open(comm, name, amode, info, &fh)`**: collective; `amode` = `MPI_MODE_RDONLY|WRONLY|RDWR|CREATE|...`. `MPI_File_set_size`/`MPI_File_preallocate`/`MPI_File_close` (collective).

## Key Concepts
- **Collective + view = scalability**: `MPI_File_set_view` (each rank's subarray) + `MPI_File_write_all` (collective) lets the implementation aggregate small scattered writes into large contiguous file-system I/O (collective buffering, two-phase I/O). This is *the* reason to use MPI-IO over per-rank POSIX files.
- **Info hints dominate performance** (ch10): `collective_buffering`, `cb_nodes`, `striping_factor`/`striping_unit` (Lustre) — defaults are often far from optimal.
- **etype/filetype mirror derived datatypes** (ch5): a 3D distributed array uses `MPI_Type_create_subarray` as the filetype so each rank writes its block to the right file region.
- **`external32`** for cross-platform-portable files; **`native`** for speed within one platform.
- Avoid the "one file per rank" anti-pattern at scale — it overwhelms the metadata server and complicates restart.

## Code Examples
```c
// each rank writes its block of a distributed 2D array into one shared file
int gsizes[2]={NX,NY}, lsizes[2]={nx,ny}, starts[2]={x0,y0};
MPI_Datatype filetype;
MPI_Type_create_subarray(2, gsizes, lsizes, starts, MPI_ORDER_C, MPI_DOUBLE, &filetype);
MPI_Type_commit(&filetype);

MPI_File fh;
MPI_File_open(comm, "field.dat", MPI_MODE_CREATE|MPI_MODE_WRONLY, info, &fh);
MPI_File_set_view(fh, 0, MPI_DOUBLE, filetype, "native", info);
MPI_File_write_all(fh, local, nx*ny, MPI_DOUBLE, MPI_STATUS_IGNORE);  // collective
MPI_File_close(&fh);
MPI_Type_free(&filetype);
```
- **Demonstrates**: the canonical distributed-array write — a `subarray` filetype gives each rank its file region, and **`MPI_File_write_all`** (collective) lets the implementation aggregate for throughput.

## Anti-patterns
- **One file per rank at scale**: metadata-server meltdown + painful restart with different process counts — use one shared file + views.
- **Independent (non-`_all`) writes for a structured collective pattern**: forgoes collective buffering — use the `_all` variants.
- **Ignoring I/O hints**: default striping/buffering on Lustre/GPFS often cripples bandwidth — set them via `MPI_Info` (ch10).
- **`native` datarep for portable archives**: not portable across endian/size — use `external32` if the file must move between platforms.
- **Forgetting MPI-IO calls are collective** (`open`/`set_view`/`set_size`/`_all`): all ranks in the group must call.

## Key Takeaways
1. **File view** (`MPI_File_set_view` with a `subarray` filetype) gives each rank its slice of one shared file.
2. **Collective** (`_all`) operations enable aggregation/collective-buffering — the scalability win over per-rank POSIX files.
3. I/O **info hints** (collective buffering, striping) are the dominant performance lever on parallel file systems.
4. `datarep`: `native` (fast/non-portable) vs `external32` (portable archives).
5. Positioning (explicit-offset / individual / shared pointer) × coordination (independent / collective) × sync (blocking / nonblocking / split-collective) compose freely.

## Connects To
- **Ch 5**: derived types (`subarray`) as etype/filetype.
- **Ch 10**: `MPI_Info` I/O hints — the performance lever.
- **Ch 7**: the communicator defining the file's process group.
- **Ch 2**: collective semantics — all ranks must call the collective I/O ops.
