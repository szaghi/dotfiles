# Chapter 1: The HPC Software Toolchain — Linux, Version Control & Build Systems

## Core Idea
Productive HPC work rests on three foundations before any code runs fast: fluency at the **Linux command line** (where every cluster lives), disciplined **version control** with git, and a reproducible **build system**. These are the unglamorous prerequisites that determine whether a project is maintainable at scale.

## Frameworks Introduced

- **The Linux command line** (the cluster is a terminal):
  - File/process navigation (`ls`, `cd`, `find`, `grep`, `ps`, `top`), redirection and pipes (`|`, `>`, `>>`, `2>`), permissions (`chmod`, `chown`, ACLs for fine-grained access), environment modules (`module load`) on shared clusters.
  - Remote work: `ssh`, `scp`/`rsync`, `tmux`/`screen` for persistent sessions, job schedulers (SLURM `sbatch`/`squeue`/`srun`) as the gateway to compute nodes.

- **Version control with git** (reproducibility + collaboration):
  - The local model: working tree → staging (`add`) → commits → branches → remotes (`push`/`pull`/`fetch`). Fork-and-PR workflow for shared repositories.
  - HPC-specific discipline: keep large data and generated artifacts **out** of the repo (`.gitignore`, Git LFS); tag releases; record the exact commit + environment with results for reproducibility.

- **Build systems** (turning source into optimized binaries):
  - **The compile pipeline**: preprocess → compile (per TU) → link. Compilers `g++`/`clang++`/`icpx`/`nvc++`; **LLVM** is the modern toolchain infrastructure. Optimization levels `-O0`…`-O3`/`-Ofast`, `-march=native`, `-g` for debug info.
  - **Make** for simple projects; **CMake** as the de-facto standard for portable, multi-target builds (out-of-source builds, `find_package`, toolchain files for cross-compilation to accelerators).
  - Dependency and environment management: package managers (Spack is the HPC standard), modules, containers.

## Key Concepts
- **Out-of-source builds**: keep generated objects separate from source (`cmake -B build`), so `git status` stays clean and multiple configurations coexist.
- **Optimization vs debuggability**: `-O0 -g` for debugging, `-O2`/`-O3` for production; higher levels diverge in behavior (and can expose latent UB) — always test the optimized build.
- **`-march=native`**: compile for the exact CPU's instruction set (AVX-512, etc.) — large wins, but the binary won't run on older hardware (a portability trap on heterogeneous clusters).
- **Reproducibility**: a result is only reproducible if you can reconstruct the compiler version, flags, dependencies, and source commit.

## Mental Models
- **The cluster is a Linux terminal** — command-line fluency is the baseline skill; everything (editing, building, submitting jobs, inspecting results) happens there.
- **Commit early, keep data out** — version the source and build recipe, never the multi-gigabyte outputs; record the commit hash with every result.
- **Use CMake + out-of-source builds** — it's the portable standard and keeps configurations isolated; reach for Spack to manage the dependency tangle on clusters.
- **Test the optimized build, not just the debug build** — `-O3` can surface undefined behavior the debug build hid.

## Code Examples
```bash
# Out-of-source CMake build with optimization + native arch
cmake -B build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-O3 -march=native"
cmake --build build -j$(nproc)

# SLURM job submission on a cluster
sbatch --nodes=4 --ntasks-per-node=8 --time=01:00:00 run.sh

# Keep artifacts out of git
echo "build/" >> .gitignore
git tag -a v1.0 -m "reproducible release"   # tag the exact source state
```
- **What it demonstrates**: the portable build invocation, job submission, and reproducibility hygiene.

## Reference Tables

| Tool | Role |
|---|---|
| `ssh`/`rsync`/`tmux` | remote access + persistent sessions |
| SLURM (`sbatch`/`srun`) | job scheduling on clusters |
| git + LFS | source version control (not big data) |
| CMake | portable multi-target build |
| Spack | HPC dependency/package management |
| modules | environment selection on clusters |

| Flag | Effect |
|---|---|
| `-O0 -g` | debug (no opt, symbols) |
| `-O3` | production optimization |
| `-march=native` | target this CPU's ISA (not portable) |
| `-Ofast` | aggressive, may break IEEE FP |

## Key Takeaways
1. Command-line Linux fluency is the baseline HPC skill — clusters are accessed and driven entirely from a terminal.
2. Version the source and build recipe with git; keep large data/artifacts out (`.gitignore`/LFS) and record commit + environment for reproducibility.
3. Use CMake with out-of-source builds for portability; Spack/modules manage cluster dependencies.
4. Match optimization to purpose (`-O0 -g` debug, `-O3` production) and always test the optimized build — high `-O` can expose latent UB.
5. `-march=native` wins big but ties the binary to one CPU — a heterogeneous-cluster portability trap.

## Connects To
- **Ch 02 (Modern C++)**: the language the toolchain compiles.
- **Ch 12 (Debugging/profiling)**: GDB/perf build on `-g` and the toolchain.
- **Ch 13 (Numerical libraries)**: `find_package`/Spack pull in BLAS/PETSc/Trilinos.
