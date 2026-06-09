# Chapter 1: Introduction — Execution & Memory Models

## Core Idea
OpenACC is a **host-directed, incremental, directive-based** model for offloading compute regions to an accelerator (or multicore CPU as a device). The two foundations everything else builds on: the **gang/worker/vector** execution model and the **discrete device data environment** memory model.

## Frameworks Introduced
- **Execution model — three levels of parallelism** (mapped to hardware):
  - **gang** = coarse-grain, fully parallel across execution units; organized in a 1–3D grid (gang dims; default uses dim 1 only). *No portable synchronization between gangs.*
  - **worker** = fine-grain, multiple threads within a gang (latency hiding).
  - **vector** = SIMD/vector lanes within a worker.
  - Six ordered levels (high→low): gang-dim3, gang-dim2, gang-dim1, worker, vector, **seq** (no parallelism).
- **Execution modes** (which lanes are active) — the key to reasoning about correctness:
  - **GR (gang-redundant)**: one vector lane of one worker per gang runs the *same* code redundantly (per dim: GR1/GR2/GR3).
  - **GP (gang-partitioned)**: loop iterations split across gangs (GP1/GP2/GP3); still 1 worker, 1 lane active.
  - **WS/WP (worker-single/partitioned)**, **VS/VP (vector-single/partitioned)**: analogous at worker/vector level.
- **Memory model — discrete device data environment**: device memory is (usually) **separate** from host memory. Data has an explicit lifetime (created→deleted). Movement is **implicit, compiler-managed via directives** (vs. explicit in CUDA/OpenCL). On shared-memory devices, no copy is made.
- **local thread / local device**: the thread executing a directive (host or device) and its device — terminology for nested parallelism.

## Key Concepts
- **device thread** = a single vector lane of a single worker of a single gang.
- **weak memory model**: many accelerators give **no coherence** between threads without an explicit fence — racy code can produce inconsistent numerics that compilers may not catch.
- **activity queues**: host enqueues ops (transfers, kernel launches) onto device queues; same-queue ops serialize, different-queue ops run concurrently in any order — the basis of `async`.
- **incremental porting**: add directives to standard C/C++/Fortran; compilers ignore them if support is off.
- **scope exclusions**: OpenACC does *not* do automatic parallelization, automatic offload, or splitting across multiple accelerators.

## Mental Models
- **Think "host orchestrates, device executes"**: the host thread allocates device memory, transfers data, queues kernels, waits, copies results back — much of this implicit.
- **Gangs are islands**: never try to synchronize across gangs (or across workers/vector lanes) — the scheduler may run some to completion before others start; a cross-gang barrier or busy-wait lock can **deadlock**. Restructure instead.
- **Discrete memory is the dominant cost**: compute intensity must justify the host↔device bandwidth; device memory is far smaller than host. A pointer valid on one side is meaningless on the other.

## Anti-patterns
- **Cross-gang / cross-worker synchronization** (barriers, locks, critical sections via atomics + busy-wait): non-portable, likely deadlock. The execution model permits sequential gang completion.
- **Dereferencing a host pointer on the device** (or vice-versa): runtime error or silent garbage — transfer the *data*, not the pointer.
- **Assuming memory coherence without a fence** on weak-memory devices: inconsistent results across runs.
- **Offloading low-compute-intensity regions**: transfer cost dominates; measure bandwidth vs. flops first.

## Key Takeaways
1. Three parallelism levels: **gang** (coarse) → **worker** (fine) → **vector** (SIMD); plus `seq`.
2. Execution modes GR→GP (gang), WS→WP (worker), VS→VP (vector) govern which lanes are active and thus correctness.
3. **No portable synchronization across gangs/workers/vector lanes** — restructure, never barrier.
4. Device memory is discrete; data movement is implicit/compiler-managed but the programmer must respect bandwidth, capacity, and pointer non-portability.
5. Weak memory model → explicit synchronization required for shared data; races may silently corrupt numerics.

## Connects To
- **Ch 3**: Compute constructs — `parallel`/`kernels`/`serial` launch the gang/worker/vector machinery.
- **Ch 5**: loop construct — `gang`/`worker`/`vector`/`seq` clauses select the mode per loop.
- **Ch 4**: data environment — the discrete-memory model is operationalized by data clauses.
- **Ch 7**: async behavior — activity queues underlie `async`/`wait`.
