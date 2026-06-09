# Chapter 18 (§31–37): OMPT & OMPD Tool Interfaces

## Core Idea
Two standardized interfaces for tools: **OMPT** (first-party — profilers/tracers linked *into* the program, observing via callbacks) and **OMPD** (third-party — debuggers running *out-of-process*, inspecting OpenMP state of a target). The basis for portable OpenMP profiling and debugging across implementations.

## Frameworks Introduced
- **OMPT** (§32–35): first-party tool interface.
  - **`ompt_start_tool`**: the tool exports this; the runtime calls it at init to (optionally) activate the tool and get the initializer.
  - **Callbacks**: registered for events — `parallel-begin/end`, `task-create/schedule`, `target` enter/exit, `mutex-acquired`, `work` (worksharing), `device-initialize`, `sync-region`, etc. The runtime dispatches them on the relevant thread.
  - **Runtime entry points** + **types**: the tool queries state (thread/task/parallel data, frames, place/proc info) via the entry points the runtime supplies.
  - **Trace records / device tracing** (§35, 37): buffered event records for device (GPU) activity, since device events can't always use synchronous host callbacks.
- **OMPD** (§33-ish/OMPD chapters): third-party tool interface for debuggers.
  - A separate **OMPD library** (named per the implementation) the debugger loads; it provides callbacks to read the target's memory/registers, and APIs to walk OpenMP state (threads, tasks, parallel regions, ICVs) **out-of-process** — even on a core dump.
  - Enabled via `OMP_DEBUG` / `debug-var`.
- **`omp_control_tool(command, modifier, arg)`** (§31): the program-side hook to start/pause/flush/stop a connected OMPT tool. *(Errata adds `omp_control_tool_max = INT32_MAX` to its enum — ch17.)*

## Key Concepts
- **OMPT = in-process profiling** (low overhead, callback-driven, what NVIDIA Nsight Systems / Score-P / TAU hook); **OMPD = out-of-process debugging** (what GDB-style tools use to inspect OpenMP state).
- **Device tracing** decouples from synchronous callbacks: GPU activity is recorded into buffers the tool drains, because the host can't synchronously call back from device execution.
- **`ompt_start_tool`** is the contract — define it in a tool library; set `OMP_TOOL_LIBRARIES` so the runtime finds it.
- These are for **tool authors and advanced profiling**; most users consume them indirectly through a profiler.

## Anti-patterns
- **Heavy work in OMPT callbacks**: they run on the application's threads, on the critical path — record and defer analysis.
- **Expecting synchronous host callbacks for device events**: use the device-tracing/trace-record buffers instead.
- **Assuming a tool is active**: `omp_control_tool` returns `omp_control_tool_notool`/`nocallback` if no tool/callback is connected — check it.
- **Forgetting `OMP_TOOL_LIBRARIES`/`OMP_DEBUG`**: OMPT tool / OMPD support won't engage without them.

## Key Takeaways
1. **OMPT** = first-party, in-process, callback-driven profiling (`ompt_start_tool` + event callbacks).
2. **OMPD** = third-party, out-of-process debugging (separate library the debugger loads; walks OpenMP state, even on core dumps).
3. Device (GPU) events use **trace-record buffers**, not synchronous host callbacks.
4. `omp_control_tool` lets the program drive a connected OMPT tool (start/pause/flush/stop).
5. Engage via `OMP_TOOL`/`OMP_TOOL_LIBRARIES` (OMPT) and `OMP_DEBUG` (OMPD); most users hit these through a profiler.

## Connects To
- **Ch 17**: `omp_control_tool` and the errata enum addition.
- **Ch 4**: `OMP_TOOL*`/`OMP_DEBUG` environment variables.
- **Ch 1**: tool interfaces sit outside the abstract execution model (their observations may reflect implementation deviations).
- **openacc-3.4 ch10**: the analogous (simpler) OpenACC profiling/error-callback interface.
