# Chapter 5: Asynchronous Execution — Streams & Events

## Core Idea
CUDA is an **asynchronous interface**: kernel launches and `*Async` calls return immediately, before the work starts or finishes. To recover correctness you re-synchronize when results are needed. The two primitives that express this are **streams** (in-order work queues you can run concurrently) and **events** (markers you drop into a stream to track progress or measure time). Concurrency lets you overlap host compute, device compute, and PCIe/NVLink transfers — but *whether* operations actually overlap depends on compute capability and resources.

## Frameworks Introduced

- **CUDA Stream** (`cudaStream_t`): a work-queue. Operations enqueued into one stream execute **in order**; the runtime picks ready work across streams to run concurrently. The mental baseline for all overlap.
  - When to use: any time you want transfers and compute to overlap, or multiple independent kernels to co-run.
- **CUDA Event** (`cudaEvent_t`): a tracer marker inserted into a stream. Reaches the front → records a timestamp. Used for (a) fine-grained sync ("wait until *this point* in the stream"), (b) cross-stream dependencies, (c) timing.
- **Host callbacks** (`cudaLaunchHostFunc`): run a host C function when the stream reaches that point. The host function **must not call any CUDA API**.
- **Three synchronization styles**: *blocking* (wait until done), *non-blocking/polling* (query status, return immediately), *callback* (pre-registered function fires on completion).
- **Stream capture → CUDA Graphs**: record a sequence/DAG of stream ops once, instantiate, then replay many times to cut per-launch CPU overhead.

## Key Concepts
- **Default stream (stream 0 / NULL stream)**: operations with no stream specified go here. The **legacy default stream** is a *blocking* stream shared across host threads — it serializes against all other blocking streams.
- **Blocking vs non-blocking streams**: the names refer *only* to how a stream synchronizes with the default stream. `cudaStreamCreate` → blocking. `cudaStreamCreateWithFlags(&s, cudaStreamNonBlocking)` → does not sync with the default stream.
- **Per-thread default stream** (CUDA 7+): each host thread gets its own independent default stream via `--default-stream per-thread` or `#define CUDA_API_PER_THREAD_DEFAULT_STREAM`. Removes the global serialization of the legacy NULL stream.
- **In-order guarantee**: an op cannot leap-frog earlier ops in its stream; memory copies complete before the next op, so dependent kernels see valid data.
- **Pinned-memory requirement**: `cudaMemcpyAsync` is only truly async if host buffers are **page-locked** (`cudaMallocHost`). With pageable memory it silently reverts to synchronous.
- **Asynchronous error reporting**: stream errors may not surface until you synchronize. `cudaGetLastError()` returns *and clears*; `cudaPeekAtLastError()` returns *without clearing*.
- **Stream priority**: a *hint* only — affects mainly kernel launches, not memcpy; never preempts running work or guarantees order.

## Mental Models
- Think of a stream as a **conveyor belt**: items ride in the order placed; belts run in parallel; an event is a tag stuck to one item that trips a sensor when it passes.
- Think of the **legacy default stream as a global lock**: touching it forces a rendezvous with every other blocking stream. Per-thread default streams (or non-blocking streams) remove that lock.
- Think of **events as the edges of a future graph**: cross-stream `cudaStreamWaitEvent` dependencies *are* a DAG — which is exactly what stream capture freezes into a CUDA Graph.

## Anti-patterns
- **Forgetting to pin host memory for `cudaMemcpyAsync`**: you pay full async API complexity but get synchronous behavior and zero overlap.
- **Using `cudaDeviceSynchronize()` as your only sync tool**: it stalls *all* streams of *all* host threads. Prefer `cudaStreamSynchronize` / `cudaStreamWaitEvent` / events for surgical sync.
- **Issuing a NULL-stream op between two independent stream ops**: serializes them (unless those streams are non-blocking). Issue all independent work first, delay sync as long as possible.
- **Calling CUDA APIs inside a host callback**: forbidden — undefined behavior.
- **Treating stream priority as a scheduling guarantee**: it is a hint; may be ignored, especially for transfers.

## Reference Tables

**Stream & event API**

| Function | Role |
|---|---|
| `cudaStreamCreate(&s)` | create blocking stream |
| `cudaStreamCreateWithFlags(&s, cudaStreamNonBlocking)` | create non-blocking stream |
| `cudaStreamCreateWithPriority(&s, flags, prio)` | create with priority (lower number = higher prio) |
| `cudaDeviceGetStreamPriorityRange(&min,&max)` | query valid priority range |
| `cudaStreamDestroy(s)` | destroy (completes pending work first) |
| `cudaStreamSynchronize(s)` | block until stream empty |
| `cudaStreamQuery(s)` | poll: `cudaSuccess` empty / `cudaErrorNotReady` busy |
| `cudaStreamWaitEvent(s, e)` | make stream `s` wait on event `e` |
| `cudaEventCreate(&e)` / `cudaEventDestroy(e)` | lifecycle |
| `cudaEventRecord(e, s)` | insert event into stream |
| `cudaEventSynchronize(e)` | block until event passed |
| `cudaEventQuery(e)` | poll event status |
| `cudaEventElapsedTime(&ms, start, stop)` | ms between two recorded events |
| `cudaLaunchHostFunc(s, fn, data)` | enqueue host callback (preferred) |
| `cudaDeviceSynchronize()` | block until *all* work in *all* streams done |

**Default-stream behavior**

| Mode | Enable | Effect |
|---|---|---|
| Legacy default stream | default | NULL stream blocks/serializes vs all blocking streams (shared across threads) |
| Per-thread default stream | `--default-stream per-thread` or `CUDA_API_PER_THREAD_DEFAULT_STREAM` | each thread's default stream is independent, no cross-stream serialization |

## Worked Example
Timing a kernel with a start/stop event pair — the canonical event-based measurement:

```cpp
cudaStream_t stream;
cudaStreamCreate(&stream);

cudaEvent_t start;
cudaEvent_t stop;
cudaEventCreate(&start);
cudaEventCreate(&stop);

cudaEventRecord(start, stream);          // record before
kernel<<<grid, block, 0, stream>>>(...); // work in the stream
cudaEventRecord(stop, stream);           // record after

cudaStreamSynchronize(stream);           // both events have fired

float elapsedTime;
cudaEventElapsedTime(&elapsedTime, start, stop);
std::cout << "Kernel execution time: " << elapsedTime << " ms" << std::endl;

cudaEventDestroy(start);
cudaEventDestroy(stop);
cudaStreamDestroy(stream);
```
- **What it demonstrates**: events are enqueued *in stream order*, so they bracket exactly the work between them; `cudaStreamSynchronize` guarantees both fired before `cudaEventElapsedTime` reads the delta. This is the correct GPU timing idiom — host-side `cpu_time`-style clocks would miss the async dispatch.

## Key Takeaways
1. Async means "returns before completion" — every result access needs a matching synchronization.
2. Streams are in-order queues; concurrency comes from *multiple* streams, not from within one.
3. Synchronize at three granularities: event (`cudaEventSynchronize`), stream (`cudaStreamSynchronize`), device (`cudaDeviceSynchronize` — the heavy hammer).
4. The legacy default stream is blocking and shared; use per-thread default streams or `cudaStreamNonBlocking` to avoid accidental serialization.
5. `cudaMemcpyAsync` overlaps only with **pinned** host memory; otherwise it silently goes synchronous.
6. Events bracket time, build cross-stream DAGs, and feed directly into CUDA Graphs via stream capture.
7. Stream priority and any concurrency are hints/best-effort, gated by compute capability.

## Connects To
- **Ch 1**: host launches async work, both processors run concurrently — this chapter is the *how*.
- **Ch 6**: pinned (page-locked) host memory — the prerequisite for async transfers; `cudaMallocHost`.
- **Ch 7**: `--default-stream per-thread` is an nvcc compiler option; `CUDA_LAUNCH_BLOCKING=1` for debugging async errors.
- **CUDA Graphs (§4.1)**: stream capture (`cudaStreamBeginCapture`/`EndCapture`, `cudaGraphInstantiate`, `cudaGraphLaunch`) is the production form of repeated async DAGs.
- **MPI/OpenACC async queues**: same overlap discipline (`!$acc async`, nonblocking MPI) on the same hardware (see `openacc-3.4`, `mpi-5.0`).
