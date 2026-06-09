# Chapter 8: SLURM & Batch Job Management

## Core Idea
On a shared cluster you don't run programs directly — you **submit jobs to a scheduler** that allocates compute nodes from a queue. **SLURM** is the dominant scheduler: you write a batch script (a shell script with `#SBATCH` directives describing the resources you need), submit it, and the scheduler runs it on compute nodes when they're free.

## Frameworks Introduced

- **The login/compute-node model**: you connect to a **login node** (shared, for editing/compiling/submitting — *not* for running computations) and submit jobs that execute on **compute nodes** allocated by the scheduler. Running heavy work on a login node is antisocial and often killed.

- **The batch script** (a shell script + scheduler directives):
  ```bash
  #!/bin/bash
  #SBATCH -J myjob              # job name (shown in squeue)
  #SBATCH -o myjob.o%j          # stdout file (%j = job id)
  #SBATCH -e myjob.e%j          # stderr file
  #SBATCH -p normal             # partition / queue
  #SBATCH -N 4                  # number of nodes
  #SBATCH -n 64                 # number of MPI tasks
  #SBATCH -t 01:00:00           # max wall time hh:mm:ss
  #SBATCH -A myaccount          # account to bill
  module load gcc/12 openmpi/4.1
  srun ./solver                 # launch across the allocation
  ```
  - `#SBATCH` lines are shell comments, so the script is a legal shell script that also carries scheduler directives.

- **Job lifecycle commands**:
  - **`sbatch script`** — submit; returns a **job id**.
  - **`squeue -u you`** / `squeue -j ID` — query status (pending/running) and position.
  - **`scancel ID`** — cancel a job.
  - **`salloc`** — interactive allocation; **`srun`** — launch tasks within an allocation.

- **Key resource directives**:
  - `-N` (nodes), `-n` (total MPI tasks), `-t` (wall-time limit — job is killed if exceeded; shorter jobs schedule sooner), `-p` (partition/queue), `-A` (account), `--mem` (memory per node), `-w`/`--nodelist` (specific nodes, for reproducible timing).
  - **Dependencies**: `--dependency=afterok:123456` starts only after another job succeeds — chains a workflow.
  - **Job arrays**: `--array=0-30` runs the same script over a range of parameter values (a parameter sweep) as one submission.
  - **Notifications**: `--mail-user=you@x --mail-type=begin/end/fail`.

## Key Concepts
- **Submit, don't run**: computation happens on scheduler-allocated compute nodes via a batch script, never directly on a login node.
- **Wall-time honesty**: the `-t` limit kills overruns, but shorter requested times get scheduled sooner (backfill) — request realistically, not maximally.
- **`srun` vs `mpirun`**: `srun` is SLURM's native task launcher that knows the allocation; it's the preferred way to start parallel tasks inside a job.
- **Job arrays for parameter sweeps**: one `--array` submission spawns many independent tasks indexed by `$SLURM_ARRAY_TASK_ID` — the right tool for "run this for 30 parameter values."
- **SLURM environment variables**: the job inherits the submission environment plus SLURM vars (`$SLURM_JOB_ID`, `$SLURM_NTASKS`, `$SLURM_ARRAY_TASK_ID`) — use them inside the script.

## Mental Models
- **Never compute on the login node** — it's for editing/compiling/submitting; submit a batch job so work runs on allocated compute nodes (and you don't get throttled or killed).
- **Request realistic wall time** — overestimating delays scheduling (shorter jobs backfill sooner); underestimating gets your job killed mid-run. Estimate, add margin, no more.
- **Use job arrays for sweeps, dependencies for workflows** — `--array` for "same job, many parameters"; `--dependency=afterok` to chain stages (preprocess → solve → postprocess).
- **Pin nodes only for reproducible timing** — `--nodelist` gives stable benchmarks but increases queue wait; use it for measurement runs, not production.
- **Record the job id and commit hash in output** — `%j` in the output filename plus the git commit makes a run reproducible and traceable.

## Code Examples
```bash
# Submit and track
sbatch run.slurm                    # → "Submitted batch job 5807991"
squeue -j 5807991                   # status (PD pending / R running)
scancel 5807991                     # cancel

# Job array: sweep 31 parameter values as one submission
#SBATCH --array=0-30
srun ./solver --param ${SLURM_ARRAY_TASK_ID}

# Chained workflow with dependencies
pre=$(sbatch --parsable preprocess.slurm)
solve=$(sbatch --parsable --dependency=afterok:$pre solve.slurm)
sbatch --dependency=afterok:$solve postprocess.slurm
```
- **What it demonstrates**: submit/track/cancel, a parameter-sweep job array, and a dependency-chained multi-stage workflow.

## Reference Tables

| Command | Action |
|---|---|
| `sbatch script` | submit a batch job |
| `squeue -u you` / `-j ID` | query status |
| `scancel ID` | cancel |
| `salloc` / `srun` | interactive alloc / launch tasks |

| `#SBATCH` directive | Meaning |
|---|---|
| `-N` / `-n` | nodes / total MPI tasks |
| `-t hh:mm:ss` | wall-time limit (killed if exceeded) |
| `-p` / `-A` | partition / billing account |
| `-o`/`-e` (`%j`) | stdout/stderr files (job-id macro) |
| `--mem` | memory per node |
| `--array=0-N` | job array (parameter sweep) |
| `--dependency=afterok:ID` | start after a job succeeds |

## Key Takeaways
1. On a cluster you submit jobs to a scheduler (SLURM), which allocates compute nodes — never compute on the login node.
2. A batch script is a shell script with `#SBATCH` directives describing resources (`-N`/`-n`/`-t`/`-p`/`-A`); submit with `sbatch`, track with `squeue`, cancel with `scancel`.
3. Launch parallel tasks with `srun` (SLURM-aware); request realistic wall time (shorter backfills sooner, overruns get killed).
4. Use job arrays (`--array`) for parameter sweeps and `--dependency=afterok` to chain multi-stage workflows.
5. Use `%j` in output filenames and record the git commit for reproducible, traceable runs; pin nodes only for benchmark timing.

## Connects To
- **Ch 01 (Unix)**: batch scripts are shell scripts; `module load` sets the environment.
- **Ch 06–07 (Debug/profile)**: parallel debuggers and profilers run as batch jobs.
- **Ch 04 (Git)**: record the commit hash in job output for reproducibility.
