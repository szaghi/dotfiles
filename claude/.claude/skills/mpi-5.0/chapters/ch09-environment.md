# Chapter 9: MPI Environmental Management

## Core Idea
The runtime-environment services: **error handling** (handlers, classes, strings), **timers** (`MPI_Wtime`), process/version inquiry, and MPI-managed memory allocation. The "everything around the communication" chapter.

## Frameworks Introduced
- **Error handling**: an **error handler** is attached to a communicator/window/file. Predefined: `MPI_ERRORS_ARE_FATAL` (default — abort), `MPI_ERRORS_RETURN` (return a code), `MPI_ERRORS_ABORT` (abort the associated group). Set with `MPI_Comm_set_errhandler`; create custom with `MPI_Comm_create_errhandler`.
  - **Error classes** (`MPI_ERR_*`: `MPI_ERR_BUFFER`, `MPI_ERR_COUNT`, `MPI_ERR_RANK`, `MPI_ERR_TRUNCATE`, `MPI_ERR_INTERN`, …) vs implementation-specific **error codes**; `MPI_Error_class` maps code→class, `MPI_Error_string` gives text.
- **Timers**: **`MPI_Wtime()`** returns wall-clock seconds (double); `MPI_Wtick()` the resolution. Per-process, not synchronized across ranks unless `MPI_WTIME_IS_GLOBAL`.
- **Inquiry**: `MPI_Get_processor_name`, `MPI_Get_version`/`MPI_Get_library_version`, `MPI_Get_count` (received elements).
- **MPI memory**: `MPI_Alloc_mem`/`MPI_Free_mem` — allocate memory MPI can use efficiently (RDMA-registered, required for some RMA windows).
- **`MPI_Abort(comm, errorcode)`**: forcibly terminate.

## Key Concepts
- **`MPI_Wtime` is the portable MPI timer** — wall-clock, like `omp_get_wtime`. Bracket a region; for collective timing, `MPI_Barrier` before the start `MPI_Wtime` to align ranks (one of the few legit barrier uses).
- **Default fatal handler**: set `MPI_ERRORS_RETURN` early if you want to inspect/recover from errors rather than abort. Fault-tolerant codes need this.
- **Timing across ranks**: `MPI_Wtime` clocks are not guaranteed synchronized — measure local intervals and reduce (e.g. `MPI_Reduce` the max).
- **`MPI_Alloc_mem`** for RMA/RDMA: some networks require registered memory; allocate windows' memory this way.

## Code Examples
```c
// switch off fatal aborts so we can handle errors
MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN);
int err = MPI_Send(buf, n, MPI_DOUBLE, dest, tag, comm);
if (err != MPI_SUCCESS) {
  char msg[MPI_MAX_ERROR_STRING]; int len;
  MPI_Error_string(err, msg, &len);
  fprintf(stderr, "MPI error: %s\n", msg);
}

// aligned cross-rank timing
MPI_Barrier(comm);                 // align ranks before timing a collective phase
double t0 = MPI_Wtime();
phase();
double dt = MPI_Wtime() - t0, dt_max;
MPI_Reduce(&dt, &dt_max, 1, MPI_DOUBLE, MPI_MAX, 0, comm);   // slowest rank
```
- **Demonstrates**: `MPI_ERRORS_RETURN` + `MPI_Error_string` for recoverable error handling, and barrier-aligned `MPI_Wtime` + max-reduce for honest cross-rank timing.

## Anti-patterns
- **`cpu_time`/`clock()` for MPI timing**: use `MPI_Wtime` (wall-clock); `clock()` measures CPU, misleading under communication waits.
- **Assuming `MPI_Wtime` is synchronized across ranks**: it usually isn't — time local intervals and reduce.
- **Leaving the default fatal handler in a fault-tolerant or long-running code**: set `MPI_ERRORS_RETURN` and check codes.
- **Comparing error codes to literals**: map to classes via `MPI_Error_class`; codes are implementation-specific.
- **Plain `malloc` for RMA window memory on RDMA networks**: use `MPI_Alloc_mem`.

## Key Takeaways
1. `MPI_Wtime` is the portable wall-clock timer; clocks aren't cross-rank synchronized — reduce local intervals.
2. Default error handler aborts; set `MPI_ERRORS_RETURN` to handle codes, map via `MPI_Error_class`/`MPI_Error_string`.
3. `MPI_Alloc_mem`/`MPI_Free_mem` for efficient/registered memory (RMA/RDMA).
4. Barrier-before-`MPI_Wtime` is a legitimate use for aligning collective-phase timing.
5. `MPI_Get_library_version`/`MPI_Get_version` to branch on implementation/standard level.

## Connects To
- **Ch 2**: error-handling model and completion semantics.
- **Ch 12**: `MPI_Alloc_mem` for RMA windows.
- **Ch 6**: reduce local timings for honest cross-rank measurement.
- **feedback_gpu_benchmark_timing**: wall-clock timing discipline (MPI analog of `omp_get_wtime`).
