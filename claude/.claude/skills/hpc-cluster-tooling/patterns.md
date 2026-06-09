# Patterns & Techniques — HPC Cluster Tooling

## Shell pipeline for log analysis
**When to use**: extracting answers from logs/output.
**How**: compose `grep | awk | sort | uniq -c` rather than writing a program.
**Trade-offs**: one line answers most data questions; reach for the Unix toolkit first.

## Persistent remote session
**When to use**: long-running interactive work over SSH.
**How**: run inside `tmux`/`screen`; detach/reattach across disconnects.
**Trade-offs**: a dropped connection won't kill the job; essential for multi-hour interactive runs.

## Incremental data transfer
**When to use**: moving large/repeated datasets to/from a cluster.
**How**: `rsync -avzP src/ user@host:dst/` — transfers only differences, resumable.
**Trade-offs**: far better than `scp` for big or repeated transfers.

## Out-of-source CMake build
**When to use**: any non-trivial C/C++/Fortran project.
**How**: `cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j`; `find_package` for deps.
**Trade-offs**: clean source tree, coexisting Release/Debug configs, trivial clean.

## Incremental Make
**When to use**: build automation with correct dependencies.
**How**: declare `target: prereqs` + TAB recipe; automatic variables (`$@`/`$<`/`$^`); `make -j`.
**Trade-offs**: rebuilds only stale targets; missing deps cause silent stale builds.

## Reproducibility tagging
**When to use**: every result you might need to reproduce.
**How**: version source + build recipe in git (artifacts/data in `.gitignore`/LFS); `git tag`; record commit hash + module versions + job id with output.
**Trade-offs**: makes a run reconstructible months later; cheap insurance.

## Post-mortem crash analysis
**When to use**: a segfault.
**How**: `ulimit -c unlimited`, run, then `gdb prog core` → `backtrace` → `frame`/`print`.
**Trade-offs**: pinpoints the failure without interactive reproduction; needs `-g`.

## Catch a corrupted value
**When to use**: a variable is mysteriously wrong.
**How**: GDB `watch var` — stops the instant anything modifies it.
**Trade-offs**: finds the writer directly, unlike a breakpoint-and-step hunt.

## Sanitizers-first memory debugging
**When to use**: any memory bug or crash.
**How**: `-fsanitize=address` (memory), `-fsanitize=thread` (races), `-fsanitize=undefined` (UB); Valgrind for exhaustive coverage.
**Trade-offs**: sanitizers are fast enough to run routinely; Valgrind is the slow thorough fallback.

## Shrink parallel bugs
**When to use**: a deadlock or race at scale.
**How**: reproduce at the smallest rank/thread count that triggers it; use GDB-per-rank (few) or DDT/TotalView (many).
**Trade-offs**: a bug at 1024 ranks is far easier to find at 2–4.

## Profile-then-optimize
**When to use**: any performance work.
**How**: `gprof`/`perf` for *where* (hot functions), PAPI for *why* (cache/branch/FLOP), TAU for *which rank* (parallel imbalance); then optimize the dominant cost.
**Trade-offs**: Amdahl caps the gain of optimizing anything but the bottleneck; never guess.

## Batch job submission
**When to use**: running on a shared cluster.
**How**: write a `#SBATCH` batch script (resources + `module load` + `srun`); `sbatch`, `squeue`, `scancel`. Realistic `-t`.
**Trade-offs**: never compute on the login node; realistic wall time schedules sooner and avoids kills.

## Parameter sweep & workflow chaining
**When to use**: same job over many parameters, or multi-stage pipelines.
**How**: `--array=0-N` (sweep, indexed by `$SLURM_ARRAY_TASK_ID`); `--dependency=afterok:ID` to chain stages.
**Trade-offs**: one submission for a sweep; dependencies sequence preprocess → solve → postprocess.
