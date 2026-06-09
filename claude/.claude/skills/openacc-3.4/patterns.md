# Patterns — OpenACC GPU offload idioms

Concrete techniques. Format: **When / How / Trade-offs.**

## Persistent data across a time loop (the #1 optimization)
**When**: an iterative solver reuses the same arrays across many kernel launches.
**How**: `enter data copyin(fields)` before the loop, `present(fields)` on every kernel inside, `exit data copyout(results)` after. (Ch4)
**Trade-offs**: eliminates per-iteration H2D/D2H — usually the difference between offload winning and losing. Must track lifetimes manually.

## Combined construct as the default
**When**: a single loop nest you want offloaded.
**How**: `#pragma acc parallel loop` / `!$acc parallel loop` (+ `collapse`, `reduction`, `present`). (Ch3, 5)
**Trade-offs**: avoids the "bare `parallel` runs redundantly per gang" trap; clearest common form.

## kernels for compiler-driven exploration
**When**: you're unsure of the best mapping or whether loops are independent.
**How**: wrap a block in `#pragma acc kernels`; let the compiler split/parallelize. (Ch3)
**Trade-offs**: safer (compiler checks dependencies) but may under-parallelize; switch to `parallel loop` once you know the structure.

## collapse + reduction for dense nests
**When**: a tightly-nested rectangular loop nest with an accumulator.
**How**: `parallel loop collapse(2) reduction(+:err)`; use `collapse(force:n)` (v3.4) for non-tight nests. (Ch5)
**Trade-offs**: more exposed parallelism; requires rectangular bounds (unless `force`).

## Double-buffered async pipeline
**When**: overlapping host↔device transfer with compute over blocks/tiles.
**How**: alternate `async(q)` queues per block — same queue keeps H2D→compute→D2H ordered; different queues overlap; final `wait`. (Ch7)
**Trade-offs**: hides transfer latency; needs careful queue bookkeeping and a join.

## host_data for library / device-aware MPI interop
**When**: passing device data to CUDA/cuBLAS/device-aware MPI.
**How**: `#pragma acc host_data use_device(a)` around the call; `a` resolves to its device address. (Ch5)
**Trade-offs**: the bridge to non-OpenACC device code; data must already be present.

## routine for device-callable functions
**When**: a kernel calls a helper function.
**How**: annotate the function `#pragma acc routine seq` (or gang/worker/vector to match its internal parallelism). (Ch7)
**Trade-offs**: `seq` is callable anywhere; higher levels constrain call sites. Required — un-annotated device calls fail to compile.

## atomic for irregular scatter
**When**: histogram/counter/scatter where `reduction` doesn't fit.
**How**: `#pragma acc atomic update` on the contended location; `atomic capture` for fetch-and-modify. (Ch6)
**Trade-offs**: serializes contended addresses — prefer `reduction` for true reductions.

## Partial sync for halo exchange
**When**: MPI halo exchange between device kernels.
**How**: `update self(halo)` (D2H) → MPI exchange → `update device(halo)` (H2D); or `host_data use_device` for device-aware MPI (no staging). (Ch6, 5)
**Trade-offs**: `update` moves only the halo, not the whole field; device-aware MPI avoids the host bounce entirely.

## declare create for module/global fields
**When**: persistent device data tied to a module's lifetime (e.g. solver state).
**How**: `!$acc declare create(field)` in the module declaration section. (Ch6)
**Trade-offs**: device copy exists for the program's life; pairs with `update` to sync.

## default(none) discipline
**When**: any non-trivial compute construct.
**How**: add `default(none)`; declare every variable's data attribute explicitly. (Ch3)
**Trade-offs**: verbose, but surfaces accidental implicit copies — the OpenACC analog of `implicit none`.
