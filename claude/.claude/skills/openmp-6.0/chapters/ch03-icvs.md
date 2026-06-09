# Chapter 3: Internal Control Variables (ICVs)

## Core Idea
ICVs are the implementation-maintained state that controls OpenMP behavior (thread count, schedule, binding, device, allocator…). They have **scopes**, an **initialization order** (env var → API → clause), and **override relationships** that decide which setting wins.

## Frameworks Introduced
- **ICV scopes** (one copy per scope instance):
  - **global** — one per program (e.g. `cancel-var`, `max-task-priority-var`, `num-devices-var`).
  - **device** — one per device (e.g. `nteams-var`, `num-procs-var`, `affinity-format-var`).
  - **implicit task** — one per implicit task (e.g. `place-assignment-var`, `def-allocator-var`).
  - **data environment** — one per task data environment (e.g. `nthreads-var`, `bind-var`, `run-sched-var`, `max-active-levels-var`).
- **Setting precedence** (§3.2–3.5): initial value → environment variable → API routine (`omp_set_*`) → clause on a construct (`num_threads`, `schedule`, `proc_bind`). Inner scopes override outer; a clause overrides the ICV for that region.
- **Per-data-environment ICVs** (§3.4): inherited by child tasks/regions; modifying in a region affects nested regions per the override rules.

## Key Concepts
- **`nthreads-var`** — thread count for the next `parallel` (set by `OMP_NUM_THREADS` / `omp_set_num_threads` / `num_threads` clause). May be a *list* for nested levels.
- **`run-sched-var`** — schedule for `schedule(runtime)` loops (`OMP_SCHEDULE`).
- **`bind-var` / `place-partition-var`** — thread→place affinity (`OMP_PROC_BIND` / `OMP_PLACES`).
- **`max-active-levels-var`** — nested-parallelism depth (`OMP_MAX_ACTIVE_LEVELS`).
- **`def-allocator-var`** — default memory allocator (`OMP_ALLOCATOR`).
- **`default-device-var`** / **`nteams-var`** / **`teams-thread-limit-var`** — device & teams defaults.
- New in 6.0: **`available-devices-var`**, **`free-agent-var` / `free-agent-thread-limit-var`** (free-agent threads), **`league-size-var`**.

## Mental Models
- **Env var = process default; API = thread-level override; clause = region-level override.** When a thread count "isn't what you set," walk this chain: `num_threads` clause > `omp_set_num_threads` > `OMP_NUM_THREADS` > implementation default.
- **Scope determines inheritance**: a data-environment ICV is per-task and inherited by children; a global ICV is one knob for the whole program.

## Anti-patterns
- **Setting `OMP_NUM_THREADS` and expecting it to override a `num_threads` clause**: the clause wins (inner overrides outer).
- **Assuming `omp_set_num_threads` affects the current team**: it sets `nthreads-var` for *future* `parallel` regions, not the running one.
- **Ignoring `OMP_MAX_ACTIVE_LEVELS` for nested parallelism**: nested teams collapse to one thread if the level cap (or dynamic adjustment) forbids more.

## Key Takeaways
1. ICV scopes: global / device / implicit-task / data-environment — scope sets inheritance.
2. Precedence: initial → env var → API routine → construct clause (inner/clause wins).
3. `nthreads-var`, `run-sched-var`, `bind-var`, `max-active-levels-var`, `def-allocator-var` are the everyday knobs.
4. `omp_set_*` affects *future* regions, not the running one.
5. OpenMP 6.0 adds free-agent-thread and device-availability ICVs.

## Connects To
- **Ch 4**: environment variables that initialize ICVs.
- **Ch 12**: `parallel`/`teams` clauses (`num_threads`, `proc_bind`) that override ICVs.
- **Ch 13**: `schedule(runtime)` reads `run-sched-var`.
- **Ch 17 (runtime library)**: `omp_set_*`/`omp_get_*` query/modify ICVs.
