# Chapter 11: CUDA Graphs

## Core Idea
A CUDA graph **decouples work description from execution**: define a DAG of operations + dependencies once, instantiate it into an executable, then launch it repeatedly with near-zero CPU overhead. Streams pay per-operation launch overhead every time; a graph pays it once at *instantiation*, and presenting the whole workflow up front unlocks optimizations streams can't see. The three stages are **definition → instantiation → execution**. Beyond static DAGs, graphs grow teeth: in-place **updates** without re-instantiation, **conditional nodes** (IF/WHILE/SWITCH) for device-side control flow, **memory nodes** with GPU-ordered lifetimes and driver-managed reuse, and **device launch** so a running kernel can launch graphs without a host round-trip.

## Frameworks Introduced
- **Creation — two paths**: explicit Graph API (`cudaGraphCreate`, `cudaGraphAddNode`, `cudaGraphAddKernelNode`/`...MemcpyNode`/`...MemsetNode`/`...HostNode`) or **stream capture** (`cudaStreamBeginCapture` … `cudaStreamEndCapture`; `cudaStreamBeginCaptureToGraph` to append to an existing graph).
- **Instantiate & launch**: `cudaGraphInstantiate(&graphExec, graph, ...)` → `cudaGraphExec_t`; `cudaGraphLaunch(graphExec, stream)`.
- **Update**: whole-graph `cudaGraphExecUpdate(graphExec, newGraph, &errNode, &result)` (topologically identical); individual-node `cudaGraphExec*NodeSetParams()`; enable/disable `cudaGraphNodeSetEnabled` / `cudaGraphNodeGetEnabled`.
- **Conditional nodes**: `cudaGraphConditionalHandleCreate` (optional `cudaGraphCondAssignDefault`); node types `cudaGraphCondTypeIf` / `...While` / `...Switch`; device-side `cudaGraphSetConditional(handle, value)`.
- **Memory nodes**: `cudaGraphNodeTypeMemAlloc` / `...MemFree` (or capture `cudaMallocAsync`/`cudaFreeAsync`); footprint query `cudaDeviceGetGraphMemAttribute`; `cudaDeviceGraphMemTrim`; peer access via `accessDescs`.
- **Device launch**: instantiate with `cudaGraphInstantiateFlagDeviceLaunch`; upload via `cudaGraphUpload`; device-only launch streams `cudaStreamGraphFireAndForget` / `...TailLaunch` / `...FireAndForgetAsSibling`; `cudaGetCurrentGraphExec()`.
- **User objects**: `cudaUserObjectCreate`, `cudaGraphRetainUserObject` — refcounted resource lifetime management for graphs.

## Key Concepts
- **Node types**: kernel, host (CPU) function, memcpy, memset, empty, event wait/record, external-semaphore signal/wait, conditional, memory (alloc/free), child graph.
- **Edge data** (CUDA 12.3+): outgoing port + incoming port + type; only non-default use today is `cudaGraphDependencyTypeProgrammatic` enabling PDL between kernel nodes. Zero = default full dependency.
- **Update wins over re-instantiate** when topology is unchanged — much cheaper. Individual-node update skips topology checks.
- **GPU-ordered lifetime** (memory nodes): an allocation's lifetime begins when GPU execution *reaches* the alloc node and ends at the free node / `cudaFreeAsync` / `cudaFree`. Non-overlapping lifetimes share physical memory; virtual addresses are fixed across launches.
- **Device-launch modes**: fire-and-forget (child, immediate, ≤120/launch), tail (runs when the graph's environment completes, serial, ≤255 pending), sibling (child of *parent* environment).
- **Execution environment**: encapsulates a graph's work + its fire-and-forget children; "complete" only when all child work is done.

## Mental Models
- **A graph is a compiled workload; a stream is an interpreter.** Pay the launch tax once at instantiation, amortize over many launches. Worth it for short, repeated workflows where per-op overhead dominates.
- **Capture = "record my existing stream code into a DAG."** Bracket working stream code; cross-stream `event`/`waitEvent` become graph edges — but every forked stream must rejoin the origin before `cudaStreamEndCapture`.
- **Conditional nodes move the `if`/`while` onto the device.** The condition is evaluated on the GPU when dependencies are met; the host CPU is freed for other work. A handle is the channel; an upstream kernel (or default) sets it.
- **Memory nodes own memory with GPU-execution timing, not API timing.** Two allocations whose GPU lifetimes don't overlap alias the same physical bytes — so a free must be ordered after *all* device work, not just an in-kernel flag.
- **Device launch = device-side control flow.** Tail launch substitutes for the forbidden `cudaDeviceSynchronize()` to chain serial graphs; a graph can even tail-launch itself for a relaunch loop.

## Anti-patterns
- **Capturing on the legacy/NULL stream** (`cudaStreamLegacy`): invalid. Use a created stream or `cudaStreamPerThread`.
- **Synchronizing/querying a stream or event mid-capture** (or `cudaMemcpy`, which enqueues to the legacy stream and syncs): invalid — captured items aren't scheduled. Any invalid op *invalidates the whole capture graph*.
- **Failing to rejoin a forked capture stream to the origin** before `cudaStreamEndCapture`: capture fails.
- **`cudaGraphExecUpdate` with a non-identical topology or mismatched dependency order**: fails; fall back to destroy + re-instantiate. Some changes (op type, context, >1D memset/memcpy) are never updatable.
- **Accessing graph-allocated memory not ordered after the alloc node, or after a free**: undefined / illegal. Out-of-band (kernel-internal) sync is insufficient to order a free — physical memory may be aliased.
- **Launching a device graph twice from the device concurrently**: `cudaErrorInvalidValue`. Host+device simultaneous launch: UB.
- **Calling CUDA APIs from a user-object destructor** (same restriction as `cudaLaunchHostFunc`): blocks CUDA's internal thread.
- **Concurrent access to one `cudaGraph_t` from multiple threads**: not thread-safe.

## Reference Tables

**Three stages**

| Stage | API | Cost |
|---|---|---|
| Definition | Graph API or stream capture | cheap, repeatable |
| Instantiation | `cudaGraphInstantiate` → `cudaGraphExec_t` | expensive (validation, setup) — do once |
| Execution | `cudaGraphLaunch(exec, stream)` | minimal overhead, repeatable |

**Conditional node types**

| Type | Semantics |
|---|---|
| `cudaGraphCondTypeIf` | body once if value ≠ 0 (optional else body if = 0) |
| `cudaGraphCondTypeWhile` | re-run body while value ≠ 0 (re-evaluated each iter) |
| `cudaGraphCondTypeSwitch` | run nth body if value == n; none if out of range |

**Device-launch streams**

| Stream | Mode | Relation |
|---|---|---|
| `cudaStreamGraphFireAndForget` | immediate, independent | child (≤120) |
| `cudaStreamGraphTailLaunch` | runs when env complete, serial | sequencing (≤255 pending) |
| `cudaStreamGraphFireAndForgetAsSibling` | immediate | child of *parent* env |

## Worked Example
Stream capture — turn existing stream code into a graph, then instantiate and launch repeatedly:

```cpp
cudaGraph_t graph;

cudaStreamBeginCapture(stream);          // stream stops executing, starts recording

kernel_A<<< ..., stream >>>(...);
kernel_B<<< ..., stream >>>(...);
libraryCall(stream);                     // even opaque library work is captured
kernel_C<<< ..., stream >>>(...);

cudaStreamEndCapture(stream, &graph);    // returns the built graph

cudaGraphExec_t graphExec;
cudaGraphInstantiate(&graphExec, graph, NULL, NULL, 0);  // pay setup once
cudaGraphLaunch(graphExec, stream);                      // launch cheaply, repeatedly
```
- **Demonstrates**: capture records (does not execute) stream work into a DAG, including opaque library calls; instantiation is the one-time expensive step; the executable graph then launches with minimal overhead. For dynamic workflows, re-capture and `cudaGraphExecUpdate` instead of re-instantiating.

## Key Takeaways
1. Graphs trade per-launch overhead for a one-time instantiation cost, and expose the whole workflow for optimizations streams can't do — win for short, repeated work.
2. Build via Graph API or stream capture; capture cannot use the NULL stream, must rejoin forked streams, and forbids sync/query mid-capture (any violation invalidates the graph).
3. Prefer `cudaGraphExecUpdate` / individual-node update over re-instantiation when topology is unchanged; node enable/disable lets one graph be a customizable superset.
4. Conditional nodes (IF/WHILE/SWITCH) put data-dependent control flow on the device via a conditional handle set by `cudaGraphSetConditional`, freeing the host.
5. Memory nodes have GPU-ordered lifetimes enabling driver memory reuse and fixed virtual addresses; frees must be ordered after all device access (in-kernel sync is insufficient).
6. Device graph launch (fire-and-forget / tail / sibling) drives device-side control flow without host round-trips; user objects manage refcounted resource lifetimes for graph-owned work.

## Connects To
- **Ch 8**: PDL (the one non-default edge-data use) and `cudaLaunchKernelEx` attributes.
- **Ch 9**: graphs catalogued as a launch-latency feature; combinable with streams.
- **Ch 10**: graph memory nodes reuse stream-ordered allocation (`cudaMallocAsync`/`cudaFreeAsync`) semantics.
- **§4.18 Dynamic Parallelism**: the alternative device-side launch mechanism (forbidden inside device graphs and conditional bodies).
- **`openmp-6.0`**: `taskgraph` is the directive-level analogue of record-once/replay execution.
