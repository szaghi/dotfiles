# Chapter 10 (Ch 5): Profiling and Error Callback Interface

## Core Idea
A tools interface: the OpenACC runtime fires **callbacks** at well-defined **events** (device init, data alloc, kernel launch, wait, …) and on **runtime errors**. Tools (profilers) and applications register callbacks to observe execution or to handle errors gracefully (release resources, clean shutdown).

## Frameworks Introduced
- **Events** (§5.1): named points the runtime calls back at — categorized:
  - Runtime/device init & shutdown (`acc_ev_runtime_shutdown`, device init/shutdown).
  - Data: enter/exit data, data alloc/free, data construct, update directive.
  - Compute: compute-construct enter/exit, **enqueue kernel launch**, enqueue data transfers.
  - Wait/sync events.
- **Callback signature** (§5.2): each callback receives three structs — a **profiling info** record (event-specific), an **event info** union, and an **API info** record (device/thread context). Plus the **error callback** path with `acc_error_*` codes.
- **Loading the library** (§5.3): the runtime loads the tools library named by `ACC_PROFLIB`; the library exports an initialization routine the runtime calls, which then registers callbacks.
- **Registering callbacks** (§5.4): `acc_prof_register(event, callback, info)` / `acc_prof_unregister`; multiple callbacks per event allowed.
- **Error callbacks**: register a routine called on runtime errors (see `acc_error_*` codes in ch8) — lets a large parallel app release resources / shut down cleanly instead of the default print-and-halt.

## Key Concepts
- **Asynchronous errors**: because device ops run async, an error callback may fire *later* than the originating call, when the error is detected. `acc_error_system` may fire anytime the device becomes unavailable.
- **Default error behavior**: print a message and halt. Registering a custom callback overrides this for cleanup/shutdown.
- **Event ordering**: enter/exit pairs bracket regions; enqueue events mark when work hits the device queue (vs. when it completes — relevant to async, ch7).
- This interface is how **NVIDIA Nsight / nvprof-style tools** and vendor profilers hook OpenACC programs.

## Worked Example
Registering an error callback for graceful shutdown (conceptual):
```c
#include <acc_prof.h>
static void on_error(acc_prof_info *pi, acc_event_info *ei, acc_api_info *ai) {
  // log, release MPI resources, flush files, then exit cleanly
  fprintf(stderr, "OpenACC error on device %d\n", ai->device_number);
  mpi_graceful_abort();
}
// the runtime calls this after loading ACC_PROFLIB
void acc_register_library(acc_prof_reg reg, acc_prof_reg unreg, acc_prof_lookup l) {
  reg(acc_ev_runtime_shutdown, (acc_prof_callback)on_error, 0);
  // ... register data/compute events for profiling
}
```
- **Demonstrates**: the library-init entry point the runtime calls, and registering a callback to replace default print-and-halt with cleanup.

## Anti-patterns
- **Doing heavy work in a callback**: callbacks run in the runtime's context, possibly on the critical path — keep them light; defer analysis.
- **Assuming synchronous error delivery**: errors from async ops arrive later — don't assume the failing call site is current.
- **Relying on default halt-on-error in production HPC**: register a callback to release MPI/coarray/file resources so one failed image doesn't leak a cluster's worth of state.
- **Forgetting `ACC_PROFLIB`**: without it the runtime loads no tools library and your callbacks never register.

## Key Takeaways
1. The runtime fires **event callbacks** (init/data/compute/launch/wait) and **error callbacks** at defined points; tools and apps register handlers.
2. Set `ACC_PROFLIB` to inject the tools library; it registers via `acc_prof_register` from its init routine.
3. Errors may arrive **asynchronously**; the callback may fire after the originating call — design handlers accordingly.
4. Register an error callback to replace default print-and-halt with resource release / clean shutdown in large parallel runs.
5. Keep callbacks lightweight — they may sit on the runtime's critical path.

## Connects To
- **Ch 8**: runtime library — `acc_error_*` codes delivered here.
- **Ch 9**: `ACC_PROFLIB` loads this library.
- **Ch 1**: runtime errors overview and async error semantics.
