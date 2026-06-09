---
name: openmp-6.0
description: "Authoritative knowledge base from the OpenMP API v6.0 specification (Nov 2024) + the Nov-2025 errata (corrections applied inline). CONSULT THIS BEFORE ANSWERING — do not answer OpenMP questions from memory; directive/clause semantics, data-sharing vs data-mapping rules, the flush memory model, schedule/tasking/offload behavior, and the runtime API are subtle and version-sensitive. TRIGGER whenever a question concerns: writing/reading/debugging any OpenMP directive (#pragma omp / !$omp); multithreading or GPU/device offload in C/C++/Fortran via OpenMP; data-sharing clauses (shared/private/firstprivate/lastprivate/reduction) or data-mapping (map/target); parallel/teams/simd/masked, worksharing (for/sections/single/distribute/schedule), tasking (task/taskloop/taskgraph/depend), synchronization (barrier/critical/atomic/ordered/flush), the device model (target/declare target), memory allocators/spaces, variant directives (metadirective/declare variant), the omp_* runtime API, OMP_* environment variables/ICVs, OMPT/OMPD tools, or a v6.0 / errata detail. SKIP only when the user explicitly wants OpenACC, CUDA, or a vendor-compiler-specific (gcc/llvm/nvhpc) behavior rather than the OpenMP standard."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, directive/clause, omp_ routine, OMP_ env var, or chapter (e.g. ch07)]
---

# OpenMP Application Programming Interface — Version 6.0
**Source**: OpenMP API v6.0 (Nov 2024) + **Errata Nov 2025** (11 corrections applied inline) | **Pages**: ~964 | **Chapters**: 19 (grouped from 37 spec chapters + appendices) | **`_OPENMP`**: 202411 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the execution/memory model + data-environment core below.
- **With a topic** — ask about `data clauses`, `map`, `tasking`, `target`, `schedule`, `atomic`, `metadirective`; I read the relevant chapter.
- **With a directive/clause** — name it (`firstprivate`, `taskloop`, `distribute`); I find the chapter.
- **With an `omp_` routine / `OMP_` var** — → ch17 / ch04.
- **With a chapter** — `ch07` (data), `ch12` (parallelism), `ch14` (tasking), `ch15` (device).

This is the *specification* (+ errata), not a tutorial — answers cite sections. Errata corrections are marked ⚠ in ch07/08/10/14/17. Pairs with `openacc-3.4`, `fortran-2023-standard`, and `CLAUDE-gpu.md`.

---

## Core Frameworks & Mental Models

### Execution model (Ch 1) — three parallelism axes
- **threads** (`parallel` → team, fork-join, end barrier), **tasks** (`task` → deferrable work units with `depend` DAG), **devices** (`target` → offload), plus **SIMD** (`simd`). Modern code composes all four.
- Entity hierarchy: device ⊃ **contention group** (thread pool) ⊃ **team**; `teams` makes a **league**. No portable synchronization across teams/contention groups (deadlock risk).
- **User-directed**: the implementation checks nothing — *you* own race/deadlock/dependence correctness.

### Two attribute systems (Ch 7) — never conflate
- **data-sharing** (thread level): `shared` / `private` / `firstprivate` / `lastprivate` / `reduction` / `linear`. Use **`default(none)`** to force explicit classification (like `implicit none`).
- **data-mapping** (device level): `map(to/from/tofrom/alloc)` moves data to/from a device data environment. A variable can be both privatized *and* mapped.

### Memory model (Ch 16) — visibility is not automatic
- Cross-thread visibility needs **synchronizing flushes**: a **release flush** before an **acquire flush** of the same data establishes **happens-before**. `barrier`, `critical`, `atomic` (with order), and task scheduling imply flushes. Without them, threads see stale values.

### Worksharing & scheduling (Ch 13)
- `for`/`do` (thread worksharing), `sections`, `single`, `distribute` (across teams), `loop` (descriptive/portable). **`schedule`**: `static` (uniform, cache-friendly), `dynamic`/`guided` (irregular), `runtime` (`OMP_SCHEDULE`). `nowait` drops the end barrier (only when independent).

### Device offload (Ch 15) — the GPU model
- **`target teams distribute parallel for`** is the canonical offload idiom. **Hoist data**: `target enter data map(to:)` once + resident kernels + `target exit data map(from:)` — avoid per-kernel transfers (the dominant perf lever). `map(to/from)` not blanket `tofrom`. `OMP_TARGET_OFFLOAD=MANDATORY` to catch silent host fallback.

### Tasking (Ch 14)
- `task depend(in/out/inout: ...)` builds a data-flow DAG the runtime schedules — replace manual barriers. **`taskgraph`** (6.0) records/replays a stable task graph. Generate tasks from one thread (`single`/`masked`); cut recursion with `final`.

### Correctness traps (cross-referenced to your memory)
- **`cpu_time`/`clock()` for parallel timing is wrong** — use `omp_get_wtime` + synchronization (a missing join/barrier fakes huge speedups; cf. `feedback_gpu_benchmark_timing`).
- **Consumer NVIDIA GPUs**: 1:64 FP64:FP32 → FP32-store/FP64-compute is *slower* than full FP64 (`reference_consumer_gpu_fp64_trap`).
- **Manual accumulation into a `shared` var** is a race — use `reduction`. **`atomic`** only for irregular scatter.

### v6.0 highlights
Loop-transform constructs + `apply` (ch11) · `taskgraph`/`replayable` (ch14) · free-agent threads · `safesync` · `masked` replaces `master` · expanded allocators/memspaces (ch8) · richer `metadirective`/`declare variant` (ch9) · `atomic compare` CAS (ch16).

---

## Chapter Index

| # | Covers | Key topics |
|---|--------|------------|
| [ch01](chapters/ch01-overview.md) | Ch 1 | execution model, contention groups, OMPT/OMPD, compliance |
| [ch02](chapters/ch02-glossary.md) | Ch 2 | normative terms; data-sharing vs mapping; memory model terms |
| [ch03](chapters/ch03-icvs.md) | Ch 3 | ICVs, scopes, precedence |
| [ch04](chapters/ch04-environment-variables.md) | Ch 4 | `OMP_*` env vars, affinity, offload policy |
| [ch05](chapters/ch05-directive-clause-syntax.md) | Ch 5 | directive/clause syntax, array sections, iterators, `_OPENMP` |
| [ch06](chapters/ch06-base-language.md) | Ch 6 | structured block, canonical loop nest, C/C++/Fortran binding |
| [ch07](chapters/ch07-data-environment.md) ⚠ | Ch 7 | data-sharing + data-mapping clauses, reductions, defaultmap |
| [ch08](chapters/ch08-memory-management.md) ⚠ | Ch 8 | memory spaces, allocators, traits (HBM/NUMA) |
| [ch09](chapters/ch09-variant-directives.md) | Ch 9 | metadirective, declare variant, dispatch, contexts |
| [ch10](chapters/ch10-informational-utility.md) ⚠ | Ch 10 | assume, error, requires (USM) |
| [ch11](chapters/ch11-loop-transforming.md) | Ch 11 | tile/unroll/interchange/fuse + `apply` |
| [ch12](chapters/ch12-parallelism-control.md) | Ch 12 | parallel, teams, simd, masked, num_threads, proc_bind |
| [ch13](chapters/ch13-work-distribution.md) | Ch 13 | for/sections/single/distribute/scan, schedule, loop |
| [ch14](chapters/ch14-tasking.md) ⚠ | Ch 14 | task, taskloop, taskgraph, depend |
| [ch15](chapters/ch15-device-interop.md) | Ch 15-16 | target, map, declare target, interop |
| [ch16](chapters/ch16-synchronization.md) | Ch 17-19 | barrier/critical/atomic/ordered/flush, cancel, composition |
| [ch17](chapters/ch17-runtime-library.md) ⚠ | Ch 20-30 | `omp_*` runtime API, device memory, locks, timing |
| [ch18](chapters/ch18-tool-interfaces.md) | Ch 31-37 | OMPT (profiling), OMPD (debugging) |
| [ch19](chapters/ch19-appendices.md) | App A-D | impl-defined, history, nesting, compound directives |

(⚠ = contains Nov-2025 errata corrections.)

## Topic Index

- **affinity / proc_bind / places** → ch04, ch12
- **allocators / memory spaces (HBM/NUMA)** → ch08, ch17
- **assume / requires / unified_shared_memory** → ch10
- **atomic / critical / flush / memory model** → ch16, ch02
- **barrier / nowait** → ch13, ch16
- **canonical loop / structured block** → ch06
- **cancellation** → ch16, ch01
- **data-mapping / map / target data** → ch07, ch15
- **data-sharing (shared/private/firstprivate/reduction)** → ch07
- **declare target / declare variant** → ch15, ch09
- **depend / task DAG** → ch14, ch16
- **device offload / target / teams** → ch15, ch12
- **environment variables (OMP_*)** → ch04
- **errata (Nov 2025)** → cheatsheet, ch07/08/10/14/17
- **ICVs** → ch03
- **interop (CUDA stream)** → ch15, ch17
- **loop construct / loop transforms (tile/unroll)** → ch13, ch11
- **metadirective / context** → ch09
- **OMPT / OMPD / tools** → ch18
- **parallel / teams / masked / simd** → ch12
- **reduction (incl. scan, task)** → ch07, ch13, ch14
- **runtime API (omp_*)** → ch17
- **schedule (static/dynamic/guided)** → ch13
- **synchronization** → ch16
- **target offload pattern** → ch15
- **taskgraph / replayable (6.0)** → ch14
- **tasking (task/taskloop)** → ch14
- **timing (omp_get_wtime)** → ch17
- **worksharing (for/sections/single/distribute)** → ch13

## Supporting Files

- [glossary.md](glossary.md) — normative terms + directive/clause vocabulary
- [patterns.md](patterns.md) — OpenMP idioms (offload, tasking DAG, NUMA, timing)
- [cheatsheet.md](cheatsheet.md) — errata table + clause decision rules + tells & smells

---

## Scope & Limits

Covers OpenMP API v6.0 (Nov 2024) with the Nov-2025 errata folded in (the 11 corrections are marked ⚠ in their chapters and tabulated in `cheatsheet.md`). Extracted with pdftotext (docling garbles this spec class — see the fortran-2023-standard note). This is the *standard* — implementation-defined behavior (default schedule/thread count, device mapping, lock fairness) lives in ch19/Appendix A and your compiler's docs (GCC libgomp, LLVM, NVHPC). Stubs, interface declarations, examples, and grammar are *separate* OpenMP documents, not in this spec. For OpenACC use `openacc-3.4`; for Fortran base-language rules `fortran-2023-standard`; for GPU/HPC practice `CLAUDE-gpu.md`.
