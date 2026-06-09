# Chapter 1: Unix for HPC

## Core Idea
Every HPC cluster is driven from a Unix shell — there is no GUI on a compute node. Fluency with the shell (navigation, pipes, redirection, text processing, scripting) is the irreducible baseline skill: it's how you move data, launch jobs, inspect results, and automate everything.

## Frameworks Introduced

- **Shell navigation & files**: `cd`/`ls`/`pwd`, `find` (locate files by criteria), `cp`/`mv`/`rm`, `chmod`/`chown` (permissions). On shared clusters you can't enter others' home directories — permissions are enforced.

- **Pipes & redirection** (the composition model): `|` chains commands (stdout → stdin), `>`/`>>` redirect stdout (overwrite/append), `2>` redirects stderr, `2>&1` merges them. This composition is the heart of shell power — small tools combined into pipelines.

- **Text processing** (the data-wrangling toolkit): `grep` (pattern match, e.g. `grep "[0-9]$" file` for lines ending in a digit), `sed` (stream edit), `awk` (field-oriented processing with variables and BEGIN/END blocks), `cut`/`sort`/`uniq`/`wc`/`head`/`tail`. These turn log files and data dumps into answers without writing a program.

- **Remote & persistent work**: `ssh` (connect to the cluster), `scp`/`rsync` (transfer files; `rsync` for incremental sync), `tmux`/`screen` (persistent sessions that survive disconnection — essential for long-running interactive work).

- **Environment modules**: `module load`/`module list`/`module avail` select compilers, MPI, and libraries on shared clusters — the standard mechanism for managing software environments without conflicts.

## Key Concepts
- **Everything is a file / a stream**: commands read stdin and write stdout/stderr; composing them via pipes is more powerful than any monolithic tool.
- **`awk` for quick data extraction**: field-based (`$1`, `$2`), with variables and patterns — the fastest way to pull columns/statistics from text without a script.
- **`rsync` over `scp` for large/repeated transfers**: it transfers only differences and resumes — critical for moving big datasets to/from a cluster.
- **`tmux` to survive disconnects**: a dropped SSH connection kills foreground jobs; run them inside `tmux`/`screen` so they persist.
- **Modules avoid environment chaos**: `module load gcc/12 openmpi/4` sets up a consistent toolchain; record the modules used with your results for reproducibility.

## Mental Models
- **Compose small tools with pipes** — reach for `grep | awk | sort` before writing a program; the Unix toolkit answers most data questions in one line.
- **Run long work in `tmux`** — never launch a multi-hour interactive job in a bare SSH session; a disconnect loses it.
- **Use `rsync` for cluster data movement** — incremental, resumable, far better than `scp` for big or repeated transfers.
- **Load modules and record them** — the environment (compiler/MPI/library versions) is part of reproducibility; capture `module list` with results.

## Code Examples
```bash
# Pipes + text processing: count error lines per category
grep ERROR run.log | awk '{print $4}' | sort | uniq -c | sort -rn

# awk with BEGIN/END and a variable
awk 'BEGIN{s=0} {s+=$2} END{print "sum:", s}' data.txt

# rsync large dataset to a cluster (incremental, resumable)
rsync -avzP ./data/ user@cluster:/scratch/user/data/

# Persistent session + module setup
tmux new -s run
module load gcc/12 openmpi/4.1
```
- **What it demonstrates**: a one-line pipeline analysis, awk aggregation, resumable transfer, and module-based environment setup.

## Reference Tables

| Tool | Use |
|---|---|
| `grep`/`sed`/`awk` | pattern match / stream edit / field processing |
| `find` | locate files by criteria |
| `ssh`/`rsync`/`scp` | remote access / sync / copy |
| `tmux`/`screen` | persistent sessions |
| `module` | load compilers/MPI/libraries |
| `\|` `>` `2>` `2>&1` | pipe / redirect stdout / stderr / merge |

## Key Takeaways
1. The cluster is driven entirely from a Unix shell — command-line fluency is the baseline HPC skill.
2. Compose small tools with pipes and redirection (`grep | awk | sort`) — it answers most data questions without a program.
3. Use `rsync` (incremental, resumable) for large/repeated cluster transfers; `ssh` to connect.
4. Run long interactive work inside `tmux`/`screen` so it survives disconnection.
5. Use environment modules to select a consistent toolchain, and record them for reproducibility.

## Connects To
- **Ch 02–03 (Make/CMake)**: build automation driven from the shell.
- **Ch 08 (SLURM)**: batch scripts are shell scripts with scheduler directives.
- **Ch 07 (Profiling)**: profilers run from the command line and emit text to parse.
