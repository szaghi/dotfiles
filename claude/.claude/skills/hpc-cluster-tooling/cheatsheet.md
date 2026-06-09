# HPC Cluster Tooling Cheatsheet

## Unix for HPC
- Compose: `grep | awk | sort | uniq -c` beats writing a program.
- Long interactive work → run inside `tmux`/`screen` (survives disconnect).
- Big/repeated transfers → `rsync -avzP` (incremental, resumable), not `scp`.
- `module load gcc/12 openmpi/4` for the toolchain; record `module list` with results.

## Make
- Rule: `target: prereqs` + **TAB**-indented recipe. "missing separator" = you used spaces.
- Automatic vars: `$@` target, `$<` first prereq, `$^` all prereqs. Pattern: `%.o: %.c`.
- `.PHONY: clean all`; build in parallel with `make -j$(nproc)`.
- Missing dependency → silent stale build.

## CMake
- `cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j` (out-of-source).
- `find_package(MPI REQUIRED)` → link `MPI::MPI_CXX`; modern target-based commands.
- Release = `-O3`, Debug = `-g`. Never hand-write Makefiles for portable projects.

## Git (HPC discipline)
- Version source + build recipe; artifacts/data → `.gitignore` or LFS.
- Commit often on branches; `git tag` + record commit hash with every result.
- Fork-and-PR for shared projects.

## GDB
| Need | Command |
|---|---|
| build for debug | `g++ -g -O0` |
| crash analysis | `ulimit -c unlimited` → `gdb prog core` → `backtrace` |
| stop at line/cond | `break file:line if cond` |
| catch a write | `watch var` |
| inspect | `print expr`, `info locals`, `frame N` |
- Optimized builds confuse line mapping → debug at `-O0 -g`.

## Memory & parallel debugging
| Bug | Tool |
|---|---|
| OOB/leak/use-after-free | `-fsanitize=address` (ASan) |
| data race | `-fsanitize=thread` (TSan) |
| undefined behavior | `-fsanitize=undefined` |
| exhaustive memory | Valgrind `--leak-check=full --track-origins=yes` |
| MPI bug, few ranks | `mpirun -np 4 xterm -e gdb` |
| MPI bug, many ranks | DDT / TotalView (via batch system) |
- Reproduce parallel bugs at the **smallest** rank count that triggers them.
- Hang = mismatched blocking exchange (deadlock); wrong-but-running = data race (TSan).

## Profiling
| Question | Tool |
|---|---|
| where (functions)? | `gprof` (`-pg`) / `perf record` (sampling) |
| why (cache/branch/FLOP)? | PAPI hardware counters |
| which rank/phase (parallel)? | TAU + ParaProf/Jumpshot |
- Profile first; optimize only the dominant cost (Amdahl).
- Benchmark: warm up, pin nodes, repeat, report spread. A single number isn't a measurement.

## SLURM
| Command | Action |
|---|---|
| `sbatch script` | submit (returns job id) |
| `squeue -u you` / `-j ID` | status (PD pending / R running) |
| `scancel ID` | cancel |
| `salloc` / `srun` | interactive alloc / launch tasks |

| `#SBATCH` | Meaning |
|---|---|
| `-N` / `-n` | nodes / MPI tasks |
| `-t hh:mm:ss` | wall-time limit (killed if exceeded) |
| `-p` / `-A` | partition / account |
| `-o myjob.o%j` | output file (%j = job id) |
| `--array=0-30` | parameter sweep |
| `--dependency=afterok:ID` | chain after success |

- **Never compute on the login node** — submit a batch job.
- Realistic `-t`: shorter backfills sooner, overruns get killed.
- `srun` (SLURM-aware) to launch parallel tasks.
- Job arrays for sweeps (`$SLURM_ARRAY_TASK_ID`); dependencies for multi-stage workflows.
- Record job id (`%j`) + git commit + modules in output for reproducibility.
