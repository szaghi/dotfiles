---
name: hpc-cluster-tooling
description: "Practitioner knowledge base for the practical workflow tooling of HPC clusters — the command-line skills around writing, building, debugging, profiling, and running scientific code at scale. Use when working on a cluster or HPC project's toolchain: Unix shell for HPC (pipes, grep/sed/awk, ssh/rsync, tmux, environment modules); build automation with Make (targets, rules, automatic variables, pattern rules, parallel make); the CMake build system (out-of-source builds, find_package, target-based commands, build types); git version control with HPC discipline (gitignore, LFS, reproducibility tagging); debugging with GDB (breakpoints, watchpoints, backtrace, core dumps); memory and parallel debugging (Valgrind, AddressSanitizer/ThreadSanitizer, MPI debugging, DDT/TotalView); profiling and benchmarking (gprof, perf, PAPI hardware counters, TAU parallel profiling/tracing); and SLURM batch job management (sbatch/squeue/scancel, #SBATCH directives, job arrays, dependencies, login vs compute nodes). Covers the cluster workflow and command-line tooling — not numerical algorithms or parallel-programming model APIs."
allowed-tools:
  - Read
  - Grep
argument-hint: [tool (slurm/cmake/gdb/tau), topic, or chapter (e.g. ch08)]
---

# HPC Cluster Tooling
**Scope**: Unix shell · Make · CMake · git · GDB · memory/parallel debugging · profiling (gprof/PAPI/TAU) · SLURM batch jobs | **Chapters**: 8 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core workflow below.
- **With a tool** — ask about `SLURM`, `CMake`, `GDB`, `TAU`, `Valgrind`; I find and read the relevant chapter.
- **With a topic** — ask about `job arrays`, `watchpoints`, `hardware counters`, `out-of-source build`; I find the chapter.
- **With a chapter** — ask for `ch08`; I load that file.

When you ask about something not in the Core section, I read the relevant chapter (and `cheatsheet.md` / `patterns.md` / `glossary.md`).

## Core Workflow

### The cluster is a Unix terminal (Ch 1)
Everything happens at the shell: compose tools with pipes (`grep | awk | sort`), transfer data with `rsync` (incremental/resumable), run long work in `tmux` (survives disconnect), select the toolchain with `module load`. Record modules with results.

### Build: Make → CMake (Ch 2, 3)
**Make** rebuilds incrementally by timestamp (`target: prereqs` + TAB recipe; `$@`/`$<`/`$^`; `make -j`). **CMake** is the meta-build system: declarative `CMakeLists.txt` generates Make/Ninja; always build **out-of-source** (`cmake -B build`), use `find_package` + target-based commands, set `CMAKE_BUILD_TYPE`. Don't hand-write Makefiles for portable projects.

### Version control (Ch 4)
Version source + build recipe in git; keep artifacts/large data out (`.gitignore`/LFS). Commit often on branches; **tag and record the commit hash + environment with every result** — reproducibility = commit + modules.

### Debug: correctness (Ch 5, 6)
**GDB** (build `-g -O0`): on a crash, `gdb prog core` → `backtrace` first; `watch var` for corruption; conditional breakpoints to skip to the failing iteration. **Memory errors** are silent in C/C++ — run **sanitizers** (`-fsanitize=address`/`thread`/`undefined`) routinely, Valgrind for exhaustive coverage. **Parallel bugs** (deadlock = mismatched blocking exchange; race = run TSan) — reproduce at the smallest rank count; GDB-per-rank (few) or DDT/TotalView (many).

### Profile: performance (Ch 7)
Measure before optimizing (Amdahl). `gprof`/`perf` for *where* (hot functions), **PAPI** counters for *why* (cache/branch/FLOP), **TAU** for *which rank/phase* (parallel imbalance). Benchmark reproducibly: warm up, pin nodes, repeat, report spread.

### Run: SLURM (Ch 8)
**Never compute on the login node** — submit a batch script (`#SBATCH` resource directives + `module load` + `srun`). `sbatch`/`squeue`/`scancel`. Realistic wall time (`-t`: shorter backfills sooner, overruns killed). Job arrays (`--array`) for parameter sweeps; `--dependency=afterok` to chain workflows. Record job id (`%j`) + commit for reproducibility.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-unix-for-hpc.md) | Unix for HPC | pipes, grep/sed/awk, ssh/rsync, tmux, modules |
| [ch02](chapters/ch02-make-build-automation.md) | Make | targets/rules, automatic variables, pattern rules, `-j` |
| [ch03](chapters/ch03-cmake-build-system.md) | CMake | out-of-source, find_package, target-based, build types |
| [ch04](chapters/ch04-git-version-control.md) | Git | branches, .gitignore/LFS, reproducibility tagging |
| [ch05](chapters/ch05-debugging-with-gdb.md) | Debugging with GDB | breakpoints, watchpoints, backtrace, core dumps |
| [ch06](chapters/ch06-memory-and-parallel-debugging.md) | Memory & Parallel Debugging | Valgrind, sanitizers, MPI debugging, DDT/TotalView |
| [ch07](chapters/ch07-profiling-and-benchmarking.md) | Profiling & Benchmarking | gprof, perf, PAPI, TAU/ParaProf/Jumpshot |
| [ch08](chapters/ch08-slurm-batch-jobs.md) | SLURM & Batch Jobs | sbatch/squeue, #SBATCH, job arrays, dependencies |

## Topic Index

- **awk / sed / grep / pipes** → ch01
- **batch script / #SBATCH** → ch08
- **CMake / find_package / out-of-source** → ch03
- **core dump / post-mortem** → ch05
- **DDT / TotalView / parallel debugging** → ch06
- **GDB / breakpoints / watchpoints / backtrace** → ch05
- **git / .gitignore / LFS / reproducibility** → ch04
- **gprof / perf** → ch07
- **job arrays / dependencies** → ch08
- **Make / targets / automatic variables** → ch02
- **memory errors / sanitizers / Valgrind** → ch06
- **modules / environment** → ch01
- **PAPI / hardware counters** → ch07
- **rsync / ssh / tmux** → ch01
- **SLURM / sbatch / squeue / srun** → ch08
- **TAU / parallel profiling / tracing** → ch07

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete techniques (shell pipelines, out-of-source build, reproducibility tagging, post-mortem GDB, sanitizers-first, profile-then-optimize, batch submission, parameter sweeps)
- [cheatsheet.md](cheatsheet.md) — command reference: Make/CMake/git/GDB/SLURM tables, debugging-tool picker, profiling-tool picker, #SBATCH directives

---

## Scope & Limits

Covers the *practical cluster workflow and command-line tooling* of HPC — shell, build systems, version control, debugging, profiling, and the batch scheduler. For the *numerical algorithms and theory*, see **hpc-numerics**; for *parallel-programming models* (MPI/OpenMP/CUDA/Kokkos APIs), see **gpu-multithreading** / **cpp-hpc** / **mpi-5.0** / **openmp-6.0** / **cuda-programming**; for *Fortran build tooling* specifically, see **fobis**. Specific scheduler/tool options vary by site and version — verify against your cluster's documentation and `man` pages.
