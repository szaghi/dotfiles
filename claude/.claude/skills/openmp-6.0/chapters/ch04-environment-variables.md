# Chapter 4: Environment Variables

## Core Idea
The `OMP_*` (and `OMP_TOOL*`/`OMP_DEBUG`) environment variables set the *initial* values of ICVs at program start. Reference chapter — grouped by function.

## Reference Tables
### Parallel-region / threading
| Variable | Controls (ICV) |
|---|---|
| `OMP_NUM_THREADS` | thread count(s) for `parallel` (`nthreads-var`; list for nesting) |
| `OMP_DYNAMIC` | dynamic thread adjustment (`dyn-var`) |
| `OMP_MAX_ACTIVE_LEVELS` | nested-parallelism depth |
| `OMP_THREAD_LIMIT` | max threads in a contention group |
| `OMP_PLACES` | place list (cores/sockets/threads) for affinity |
| `OMP_PROC_BIND` | binding policy: `true`/`false`/`primary`/`close`/`spread` |

### Teams / execution
| Variable | Controls |
|---|---|
| `OMP_NUM_TEAMS` | teams in a league (`nteams-var`) |
| `OMP_TEAMS_THREAD_LIMIT` | threads per team |
| `OMP_SCHEDULE` | `schedule(runtime)` kind+chunk (`run-sched-var`) |
| `OMP_STACKSIZE` | worker thread stack size |
| `OMP_WAIT_POLICY` | `ACTIVE`/`PASSIVE` spin-wait behavior |
| `OMP_CANCELLATION` | enable `cancel` |
| `OMP_MAX_TASK_PRIORITY` | priority ceiling for `task priority` |

### Device / offload
| Variable | Controls |
|---|---|
| `OMP_DEFAULT_DEVICE` | default `target` device |
| `OMP_TARGET_OFFLOAD` | `MANDATORY`/`DISABLED`/`DEFAULT` offload policy |
| `OMP_AVAILABLE_DEVICES` | which devices are visible (6.0) |
| `OMP_THREADS_RESERVE` | reserve threads (6.0) |

### Memory / affinity display / tools
| Variable | Controls |
|---|---|
| `OMP_ALLOCATOR` | default memory allocator (`def-allocator-var`) |
| `OMP_DISPLAY_AFFINITY` / `OMP_AFFINITY_FORMAT` | thread-affinity reporting |
| `OMP_DISPLAY_ENV` | dump ICVs at startup (`TRUE`/`VERBOSE`) |
| `OMP_TOOL` / `OMP_TOOL_LIBRARIES` / `OMP_TOOL_VERBOSE_INIT` | OMPT tool loading |
| `OMP_DEBUG` | enable OMPD (`debug-var`) |

## Key Concepts
- **`OMP_PROC_BIND` + `OMP_PLACES`** together pin threads to hardware — critical for NUMA/cache locality in HPC. `spread` for bandwidth, `close` for cache sharing.
- **`OMP_TARGET_OFFLOAD=MANDATORY`** makes missing-device a fatal error instead of silently falling back to host — use it to catch offload misconfiguration.
- **`OMP_DISPLAY_ENV=VERBOSE`** at startup is the fastest way to see the actual ICV state a run will use.
- Env var sets *initial* ICV; API/clause override later (ch3).

## Anti-patterns
- **Tuning thread count in source only**: `OMP_NUM_THREADS` lets one binary scale per node/run; pair with `OMP_PROC_BIND`/`OMP_PLACES` for affinity.
- **Silent host fallback for offload**: without `OMP_TARGET_OFFLOAD=MANDATORY`, a `target` region quietly runs on host when the device is absent — a perf cliff that looks like correctness.
- **Ignoring affinity on NUMA**: unbound threads migrate; set `OMP_PROC_BIND=close|spread` + `OMP_PLACES=cores`.

## Key Takeaways
1. `OMP_NUM_THREADS` + `OMP_PROC_BIND` + `OMP_PLACES` are the core HPC tuning trio.
2. `OMP_TARGET_OFFLOAD=MANDATORY` turns silent host-fallback into a hard error.
3. `OMP_DISPLAY_ENV=VERBOSE` dumps the effective ICV state at startup.
4. `OMP_SCHEDULE` feeds `schedule(runtime)`; `OMP_ALLOCATOR` sets the default allocator.
5. Env vars are *initial* ICV values; API routines and construct clauses override them.

## Connects To
- **Ch 3**: ICVs these variables initialize.
- **Ch 12**: `parallel`/`teams` clauses overriding these.
- **Ch 18**: `OMP_TOOL*`/`OMP_DEBUG` for OMPT/OMPD.
- **CLAUDE-gpu.md**: NUMA/affinity tuning for HPC runs.
