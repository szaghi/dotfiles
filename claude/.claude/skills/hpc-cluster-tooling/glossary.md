# Glossary — HPC Cluster Tooling

**AddressSanitizer (ASan)** — fast compile-time detector of OOB/use-after-free/leaks (`-fsanitize=address`) (Ch 6).
**awk** — field-oriented text processing with variables and BEGIN/END (Ch 1).
**backtrace** — GDB command showing the call stack at the current point/crash (Ch 5).
**batch script** — shell script with `#SBATCH` directives describing job resources (Ch 8).
**breakpoint** — a point where GDB pauses execution (`break file:line`) (Ch 5).
**CMake** — meta-build system generating native build files from `CMakeLists.txt` (Ch 3).
**compute node** — cluster node where scheduler-allocated jobs run (Ch 8).
**core dump** — saved crash state for post-mortem `gdb prog core` (Ch 5).
**DDT / TotalView** — full-screen parallel debuggers controlling many ranks (Ch 6).
**find_package** — CMake command locating an installed library (Ch 3).
**Git LFS** — Large File Storage for versioning big binaries out-of-band (Ch 4).
**.gitignore** — excludes artifacts/data from version control (Ch 4).
**gprof** — function-level profiler requiring `-pg` instrumentation (Ch 7).
**job array** — SLURM `--array` running one script over a parameter range (Ch 8).
**login node** — shared cluster node for editing/compiling/submitting, NOT computing (Ch 8).
**Makefile** — declares targets, prerequisites, recipes for incremental builds (Ch 2).
**module** — environment-module command selecting compilers/MPI/libraries (Ch 1).
**out-of-source build** — CMake configured into a separate `build/` directory (Ch 3).
**PAPI** — portable interface to hardware performance counters (Ch 7).
**ParaProf / Jumpshot** — TAU's profile / trace visualizers (Ch 7).
**pattern rule** — Make rule like `%.o: %.c` for any matching file (Ch 2).
**partition** — a SLURM queue (`-p`) (Ch 8).
**phony target** — Make target that isn't a file (`.PHONY: clean`) (Ch 2).
**rsync** — incremental, resumable file transfer (Ch 1).
**sanitizer** — compile-time error detector (ASan/TSan/UBSan) (Ch 6).
**sbatch** — submit a SLURM batch job (Ch 8).
**scancel** — cancel a SLURM job (Ch 8).
**SLURM** — the dominant cluster job scheduler (Ch 8).
**squeue** — query SLURM job status (Ch 8).
**srun** — SLURM-native parallel task launcher (Ch 8).
**symbol table** — debug info (`-g`) mapping addresses to source (Ch 5).
**TAU** — Tuning and Analysis Utilities: parallel profiling and tracing (Ch 7).
**ThreadSanitizer (TSan)** — data-race detector (`-fsanitize=thread`) (Ch 6).
**tmux / screen** — persistent terminal sessions surviving disconnection (Ch 1).
**Valgrind / Memcheck** — exhaustive memory-error detector (Ch 6).
**wall-time limit** — SLURM `-t`; job killed if exceeded (Ch 8).
**watchpoint** — GDB stop when a variable changes (`watch var`) (Ch 5).
**`$@` / `$<` / `$^`** — Make automatic variables: target / first prereq / all prereqs (Ch 2).
**`-g`** — compile with debug symbols (Ch 5).
**`%j`** — SLURM macro expanding to the job id in filenames (Ch 8).
