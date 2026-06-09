---
name: openacc-3.4
description: "Authoritative knowledge base from the OpenACC Application Programming Interface v3.4 specification. CONSULT THIS BEFORE ANSWERING — do not answer OpenACC questions from memory; directive/clause semantics, data-clause behavior, and async-queue ordering rules are easy to misremember and version-sensitive. TRIGGER whenever a question concerns: writing/reading/debugging any OpenACC directive (#pragma acc / !$acc); offloading C/C++/Fortran to GPU or multicore; gang/worker/vector parallelism or execution modes; data clauses (copy/copyin/copyout/create/present/no_create/deviceptr/attach) or data-region/reference-counter behavior; loop/collapse/tile/reduction/private mapping; async/wait queues; the routine directive; atomic/declare/update directives; the acc_* runtime API; environment variables (ACC_*); or diagnosing GPU offload, data-movement, or benchmark-timing problems. SKIP only when the user explicitly wants OpenMP-offload, CUDA, or a vendor-compiler-specific (nvhpc/gcc) behavior rather than the OpenACC standard."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, directive/clause name, acc_ routine, or chapter (e.g. ch04)]
---

# OpenACC Application Programming Interface — Version 3.4
**Publisher**: OpenACC-Standard.org | **Pages**: ~175 | **Chapters**: 11 (6 spec chapters; Directives split for navigability) | **`_OPENACC`**: 202506 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the execution/memory model + data-clause core below.
- **With a topic** — ask about `data clauses`, `async`, `loop`, `reduction`, `routine`, `atomic`; I read the relevant chapter.
- **With a directive/clause** — name it (`copyin`, `gang`, `host_data`); I find the governing chapter.
- **With an `acc_` routine** — ask about `acc_copyin`, `acc_wait`, etc. → ch08.
- **With a chapter** — `ch04` (data), `ch03` (compute), `ch05` (loop), `ch07` (async).

This is the *specification*, not a tutorial — answers cite sections. For HPC practice it pairs with `CLAUDE-gpu.md` and the `fortran-2023-standard` skill.

---

## Core Frameworks & Mental Models

### Execution model (Ch 1) — three levels, six modes
- **gang** (coarse, 1–3D grid) ⊃ **worker** (fine) ⊃ **vector** (SIMD) ⊃ **seq** (none). A `loop` maps iterations to a level.
- Modes govern which lanes are active: **GR** (gang-redundant — all gangs run the same code) vs **GP** (gang-partitioned — iterations split); likewise WS/WP, VS/VP.
- **No portable synchronization across gangs/workers/vector lanes** — a cross-gang barrier or busy-wait lock can deadlock (the scheduler may run some to completion first). Restructure instead.

### Memory model (Ch 1, 4) — discrete device data environment
- Device memory is (usually) **separate** from host; movement is implicit/compiler-managed via data clauses. A host pointer is meaningless on the device.
- **Reference-counter model** (structured + dynamic): data allocated at 0→1, freed at →0 — makes nested/repeated data regions compose safely.
- Weak memory model: explicit synchronization needed for shared data; races silently corrupt numerics.

### The three compute constructs (Ch 3)
- **`parallel`** — you assert parallelism + control geometry (`num_gangs`/`num_workers`/`vector_length`). Code *outside* an inner `loop` runs **redundantly per gang** (GR mode) — use **`parallel loop`**.
- **`kernels`** — the compiler analyzes dependencies and parallelizes each loop.
- **`serial`** — one gang/worker/lane; sequential device code without a host round-trip.

### Data clauses (Ch 4) — the dominant optimization lever
- `copyin`=input, `copyout`=output, `copy`=both, `create`=scratch, `present`=already-there, `no_create`=reuse-or-local, `deviceptr`=interop, `attach`=pointer members.
- **Hoist data out of loops**: `enter data copyin(...)` once + `present(...)` in every kernel + `exit data copyout(...)` — eliminates per-iteration H2D/D2H. This single pattern usually decides whether offload wins.
- `default(none)` forces explicit data attributes — adopt it like `implicit none`.

### loop mapping (Ch 5)
- `gang`/`worker`/`vector`/`seq`, `independent` (assert parallel-safe; default on `parallel`), `auto`, `collapse([force:]n)` (fuse nests; `force` for non-tight — v3.4), `tile`, `private`, `reduction`.
- Nesting must be **outer→inner gang⊃worker⊃vector**; equal/higher level nested inside is illegal.
- `host_data use_device(v)` exposes the device address — the bridge to CUDA/cuBLAS/device-aware MPI.

### Async (Ch 7)
- `async[(value)]` enqueues on an activity queue. **Same value = same queue = ordered; different values = may overlap.** `wait[(q)]` blocks host; `wait(q1) async(q2)` builds a device-side dependency. Special: `acc_async_sync`/`_noval`/`_default`.
- `async` on `data` overlaps only transfers and is **not inherited** by nested constructs — a race source.

### Correctness & accuracy (`routine`, `atomic`)
- Device-called procedures need **`routine [gang|worker|vector|seq]`** (`seq` is universal). v3.4 generalized *implicit* `routine` to all procedures.
- `reduction(op:vars)` for accumulation; `atomic update`/`capture` for irregular scatter (histograms/counters).

### GPU practice traps (cross-referenced to your memory)
- **`>100×` speedup ≈ a missing `wait`** before the timer (async returns immediately); time with `system_clock`, not `cpu_time`.
- **Consumer NVIDIA GPUs**: 1:64 FP64:FP32 ratio → FP32-store/FP64-compute is *slower* than full FP64, not an optimization.

---

## Chapter Index

| # | Covers | Key topics |
|---|--------|------------|
| [ch01](chapters/ch01-introduction.md) | Ch 1 | execution model (gang/worker/vector, GR/GP), discrete memory model |
| [ch02](chapters/ch02-directive-basics.md) | §2.1–2.4 | directive syntax, `_OPENACC`, ICVs, `device_type`/`dtype` |
| [ch03](chapters/ch03-compute-constructs.md) | §2.5 | `parallel` / `kernels` / `serial`, geometry, reduction |
| [ch04](chapters/ch04-data-environment-clauses.md) | §2.6–2.7 | data clauses, reference counters, `enter/exit data`, attach |
| [ch05](chapters/ch05-loop-host-cache-combined.md) | §2.8–2.11 | `loop`, `collapse`/`tile`, `host_data`, `cache`, combined |
| [ch06](chapters/ch06-atomic-declare-executable.md) | §2.12–2.14 | `atomic`, `declare`, `update`/`wait`/`init`/`set` |
| [ch07](chapters/ch07-procedures-async-fortran.md) | §2.15–2.17 | `routine`, async queues, Fortran-specific |
| [ch08](chapters/ch08-runtime-library.md) | Ch 3 | `acc_*` runtime API; directive↔API map |
| [ch09](chapters/ch09-environment-variables.md) | Ch 4 | `ACC_DEVICE_TYPE`/`_NUM`/`ACC_PROFLIB` |
| [ch10](chapters/ch10-profiling-interface.md) | Ch 5 | event/error callbacks, tools interface |
| [ch11](chapters/ch11-glossary.md) | Ch 6 | normative terminology |

## Topic Index

- **async / wait / queues** → ch07, ch06
- **atomic** → ch06
- **attach / detach / pointers** → ch04
- **cache** → ch05
- **collapse / tile** → ch05
- **combined constructs** → ch05
- **compute constructs (parallel/kernels/serial)** → ch03
- **conditional compilation / `_OPENACC`** → ch02
- **data clauses (copy/copyin/copyout/create/present)** → ch04
- **declare** → ch06
- **default(none|present)** → ch03, ch04
- **device_type / dtype** → ch02
- **enter data / exit data** → ch04, ch06
- **environment variables** → ch09
- **execution model / gang-worker-vector** → ch01, ch05
- **firstprivate / private** → ch03, ch05
- **host_data / use_device** → ch05
- **ICVs** → ch02
- **if clause** → ch03, ch04
- **loop / independent / seq / auto** → ch05
- **memory model / discrete / shared** → ch01, ch04
- **MPI interop / device-aware** → ch05, ch07
- **profiling / error callbacks** → ch10
- **reduction** → ch03, ch05
- **reference counters / present** → ch04
- **routine** → ch07
- **runtime API (acc_*)** → ch08
- **update (self/device)** → ch06
- **v3.4 changes** → cheatsheet, ch05/ch07/ch08

## Supporting Files

- [glossary.md](glossary.md) — normative terms + directive/clause vocabulary
- [patterns.md](patterns.md) — GPU offload idioms (persistent data, pipelines, interop)
- [cheatsheet.md](cheatsheet.md) — clause/construct decision rules + GPU tells & smells

---

## Scope & Limits

Covers the OpenACC API v3.4 specification (June 2025, updated October 2025), extracted with pdftotext (docling garbles this class of spec PDF — see the fortran-2023-standard note). This is the *spec*, not a vendor manual — device-specific behavior, supported architectures, and launch-geometry tuning are implementation-defined (NVHPC, GCC, etc.). For Fortran base-language rules use `fortran-2023-standard`; for the broader GPU/HPC practice (FP64 traps, benchmark timing) see `CLAUDE-gpu.md`.
