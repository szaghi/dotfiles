# Chapter 15: Tool Support

## Core Idea
Two interfaces for tools: the **PMPI profiling interface** (every `MPI_X` has a `PMPI_X` twin a tool can intercept via weak symbols) and the **MPI_T tool information interface** (introspect/set control variables, read performance variables, trace events). The basis for profilers (Score-P, TAU, mpiP, Vampir) and tuning.

## Frameworks Introduced
- **PMPI profiling interface**: the standard guarantees each MPI routine is also callable as `PMPI_` (e.g. `PMPI_Send`). A profiling library defines `MPI_Send` (intercept → record → call `PMPI_Send`), linked via weak symbols (`#pragma weak MPI_Send = PMPI_Send`). Lets tools wrap MPI **without** the MPI source or recompiling the app.
- **MPI_T — control variables (cvar)**: `MPI_T_cvar_get_info`/`_handle_alloc`/`_read`/`_write` — read/tune implementation knobs (eager-limit, buffer sizes, protocol thresholds) at runtime.
- **MPI_T — performance variables (pvar)**: `MPI_T_pvar_*` — read counters/timers the implementation exposes (bytes sent, queue depths, unexpected-message counts) for performance analysis.
- **MPI_T — events** (MPI 4.0+): callback-based event tracing (`MPI_T_event_*`) for fine-grained tool instrumentation.
- **MPI_T session/category model**: variables are organized into categories; `MPI_T_init_thread` is independent of `MPI_Init` (tools can introspect before/without full MPI init).

## Key Concepts
- **PMPI is link-time, zero-source interception**: the reason every MPI profiler works portably — wrap, measure, delegate to `PMPI_`.
- **MPI_T cvars expose the tuning knobs** a vendor would otherwise hide — e.g. raise the eager/rendezvous threshold for a message-size sweet spot, all at runtime.
- **pvars are the introspection counterpart**: diagnose unexpected-message queue growth (a sign of receiver-too-slow / mismatched posting) or measure actual bytes moved.
- These are for **tool authors and performance engineers**; applications usually consume them through a profiler rather than calling MPI_T directly.

## Code Examples
```c
// PMPI wrapper: count and time every MPI_Send (a tool/profiling library)
static double send_time = 0; static long send_count = 0;
int MPI_Send(const void *buf, int n, MPI_Datatype t, int dest, int tag, MPI_Comm c) {
  double t0 = PMPI_Wtime();
  int rc = PMPI_Send(buf, n, t, dest, tag, c);   // delegate to the real impl
  send_time += PMPI_Wtime() - t0; send_count++;
  return rc;
}
```
- **Demonstrates**: the PMPI interception pattern — redefine `MPI_Send`, measure, then call `PMPI_Send`; linked transparently via weak symbols, no app recompile.

## Anti-patterns
- **Patching MPI source to add instrumentation**: unnecessary — use PMPI interception.
- **Hardcoding implementation tuning in source**: read/set it via MPI_T cvars at runtime instead.
- **Ignoring pvars when diagnosing scaling problems**: unexpected-message-queue and eager-buffer counters often reveal the real bottleneck.
- **Calling MPI_T from application logic for control flow**: it's a tools interface; keep it in tooling, not app correctness paths.

## Key Takeaways
1. **PMPI** gives every `MPI_X` a `PMPI_X` twin — the portable, zero-source, weak-symbol interception that all MPI profilers use.
2. **MPI_T cvars** expose runtime-tunable implementation knobs; **pvars** expose performance counters/timers; **events** give trace callbacks.
3. MPI_T is independent of `MPI_Init` (introspect early).
4. Use pvars (unexpected-queue depth, bytes moved) to diagnose scaling/communication bottlenecks.
5. These are tool-author/perf-engineer interfaces — most users meet them through Score-P/TAU/mpiP/Vampir.

## Connects To
- **Ch 13**: external interfaces — tool hooks foundation.
- **Ch 9**: `MPI_Wtime`/`PMPI_Wtime` for timing in wrappers.
- **openmp-6.0 ch18 / openacc-3.4 ch10**: the analogous OMPT/OpenACC tool interfaces (whole-stack profiling).
