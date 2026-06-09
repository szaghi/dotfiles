# Chapter 13: OpenMP GPU Offload — The Device Model in Depth

## Core Idea
OpenMP offloads computation to a GPU (or any accelerator) with the **`target`** construct, which creates a **device data environment** and runs a structured block on the device. The two hard parts are getting parallelism onto the device's **hierarchy** (`teams` → threads via `distribute`/`parallel`) and controlling **data movement** (the `map` clause and target-data regions) — data movement, not compute, is where offload performance is won or lost.

## Frameworks Introduced

### The host/device model
Execution begins on the **host** (CPU) and offloads to zero or more attached **devices**, each with its own memory (its **data environment**). When the host task hits a `target` construct, the runtime builds a device data environment, packages the structured block into a **kernel**, and runs it on the device while — by default — the host **waits** for completion.

```c
#pragma omp target                       // offload this block to the default device
{
    for (int i = 0; i < n; ++i)          // runs on the device (serially so far!)
        y[i] = a*x[i] + y[i];
}
```
`target` *alone* moves execution to the device but does **not** parallelize — you must add the parallelism hierarchy.

### The parallelism hierarchy: teams → distribute → parallel → simd
A GPU has many compute units, each running many threads. OpenMP maps onto this with nested levels:
- **`teams`** — launches a **league** of thread teams (≈ CUDA blocks); teams run independently with **no synchronization between them** (so the hardware schedules them freely across compute units). Must appear immediately inside `target`.
- **`distribute`** — splits loop iterations **across teams**.
- **`parallel for`** — splits iterations **across the threads within a team**.
- **`simd`** — vectorizes within a thread.
- The full combined construct is the workhorse:

```c
#pragma omp target teams distribute parallel for simd \
        map(to: x[0:n]) map(tofrom: y[0:n])
for (int i = 0; i < n; ++i)
    y[i] = a*x[i] + y[i];
```
- **`num_teams(N)`** / **`thread_limit(M)`** tune the league size and per-team thread count.
- **`loop`** is the descriptive alternative: `#pragma omp target teams loop` tells the compiler the iterations are independent and lets it choose the mapping — often the most portable choice.

### The `map` clause (explicit data movement)
`map` controls what crosses the host↔device boundary and when. **Data mapping is separate from data sharing** — it moves bytes, it doesn't declare thread visibility.
| Map type | Behavior |
|---|---|
| `map(to: a[0:n])` | copy host→device on entry, nothing back |
| `map(from: a[0:n])` | allocate on device, copy device→host on exit |
| `map(tofrom: a[0:n])` | copy both directions (the default for scalars/arrays) |
| `map(alloc: a[0:n])` | allocate on device, no copy |
| `map(release:)` / `map(delete:)` | decrement / force-remove from the device |

Array sections use `array[start:length]` syntax. Mapping is **reference-counted**: a variable already present on the device isn't re-copied — nested regions reuse it.

### Target-data regions (keep data resident)
The most important offload optimization: **don't copy data in and out on every kernel.** Establish a data region that spans many `target` compute regions:
```c
#pragma omp target data map(to: x[0:n]) map(tofrom: y[0:n])   // one transfer in/out
{
    for (int step = 0; step < nsteps; ++step) {
        #pragma omp target teams distribute parallel for       // no map → data stays resident
        for (int i = 0; i < n; ++i) y[i] = stencil(x, y, i);
    }
}                                                              // copy back once at the end
```
- **`target enter data` / `target exit data`** — unstructured versions: begin/end residency without a lexical block (for data whose lifetime crosses function boundaries).
- **`target update to/from`** — synchronize specific arrays mid-region without re-establishing the mapping (e.g. refresh a halo each step).

### Functions and globals on the device
- **`declare target`** — compile a function or global variable for the device so it can be called/used inside a target region:
```c
#pragma omp declare target
double stencil(const double* u, int i);   // callable from device kernels
#pragma omp end declare target
```

### Unified Shared Memory (USM)
`#pragma omp requires unified_shared_memory` declares that host and device share an address space (migrated on demand) — `map` clauses become optional and pointers Just Work. Great for productivity and pointer-rich data structures, but explicit mapping still wins for performance-critical movement.

### Asynchronous offload & multiple devices
- **`nowait`** turns a `target` region into a deferred **task** so it runs asynchronously with the host and other target tasks; **`depend(in:/out:)`** orders them into a DAG. Combine with `target enter data ... nowait` for asynchronous transfers overlapping compute.
- **Device control**: `omp_get_num_devices()`, `omp_set_default_device(d)`/`omp_get_default_device()`, and the **`device(d)`** clause on any target construct route work to a specific GPU — the basis for multi-GPU offload.
- **`if(cond)`** clause — conditional offload: run on the device only when the problem is big enough to amortize transfer, else on the host.

### Performance portability: variant directives
- **`declare variant`** + a **`match`** clause provides device- or implementation-specific versions of a function, selected at compile time by context (vendor, architecture) — one code base, tuned implementations.
- **`metadirective`** picks a directive variant by context — e.g. a different mapping on GPU vs CPU.

## The Eightfold Path to Performance
The decision checklist for performant offload, in priority order:
1. **Only write portable code** — portable programming models, test across vendors.
2. **Only write the code you need** — use optimized libraries (BLAS, FFT) instead of hand kernels.
3. **Pick the right algorithm** — algorithmic choice dominates micro-tuning.
4. **Keep the GPU fully occupied** — expose enough parallelism for high **occupancy** (enough teams/threads to hide latency).
5. **Converged execution flow** — minimize divergence so threads in a group stay on the same path.
6. **Minimize data movement** — the biggest lever: keep data resident (target-data regions), copy only what's needed.
7. **Memory coalescence** — consecutive threads access consecutive memory.
8. **Balance the load** — the slowest task sets the pace.

## Mental Models
- **`target` moves execution; `teams distribute parallel for` moves *parallelism*** — `target` alone runs serially on the device. The combined construct is what you almost always want; `target teams loop` is the portable "let the compiler decide" form.
- **Data movement is the offload bottleneck** — wrap iterative kernels in a `target data` region so arrays cross PCIe once, not once per step; use `target update` to refresh only what changes.
- **`map` is data movement, not data sharing** — it controls host↔device copies; thread visibility is the separate `shared`/`private` concern (the top offload confusion).
- **Mapping is reference-counted** — already-present data isn't recopied; structure regions so inner kernels find data already resident.
- **Reach for USM for productivity, explicit `map` for performance** — USM removes mapping boilerplate but explicit movement is still faster on critical paths.
- **Walk the Eightfold Path top-down** — portability and libraries and algorithm before occupancy, and *minimize data movement* before micro-optimizing the kernel.

## Reference Tables

| Construct | Role |
|---|---|
| `target` | offload execution; create device data environment |
| `teams` | league of teams (≈ blocks), no inter-team sync |
| `distribute` | split iterations across teams |
| `parallel for` | split iterations across threads in a team |
| `target data` / `enter/exit data` | keep data resident across kernels |
| `target update to/from` | sync specific arrays mid-region |
| `declare target` | compile function/global for the device |
| `declare variant` / `metadirective` | context-selected tuned variants |

| Clause | Effect |
|---|---|
| `map(to/from/tofrom/alloc)` | host↔device data movement |
| `num_teams` / `thread_limit` | league / per-team sizing |
| `device(d)` | target a specific GPU |
| `nowait` + `depend` | async offload as a task DAG |
| `if(cond)` | conditional offload (host vs device) |
| `requires unified_shared_memory` | USM address space |

## Key Takeaways
1. `target` offloads execution and builds a device data environment but runs serially — add `teams distribute parallel for [simd]` (or `target teams loop`) to use the device's parallelism hierarchy.
2. `map` controls host↔device data movement (separate from thread data-sharing); it's reference-counted so present data isn't recopied.
3. The biggest performance lever is minimizing data movement — wrap iterative kernels in a `target data` region (or `target enter/exit data`) and `target update` only what changes.
4. `declare target` makes functions/globals usable on the device; USM (`requires unified_shared_memory`) trades explicit mapping for productivity.
5. Use `nowait`+`depend` for async/overlapped offload, `device(d)` for multi-GPU, and `declare variant`/`metadirective` for performance portability; follow the Eightfold Path top-down (portability → libraries → algorithm → occupancy → converged flow → data movement → coalescence → load balance).

## Connects To
- **Ch 09 (OpenMP)**: the host-side fork-join model, data-sharing clauses, and the `target` overview this chapter deepens.
- **Ch 07 (CUDA)**: `teams`/threads ≈ blocks/threads; `map` ≈ explicit `cudaMemcpy`; the same occupancy/coalescing levers underneath.
- **Ch 08 (OpenCL)**: an alternative portable offload model; `declare variant` is OpenMP's performance-portability answer.
- **Ch 12 (Optimization)**: data-movement minimization, coalescing, and benchmark-timing discipline apply directly.
