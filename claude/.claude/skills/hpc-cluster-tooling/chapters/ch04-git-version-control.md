# Chapter 4: Git — Version Control for HPC

## Core Idea
Git tracks the full history of your source, enabling collaboration, reproducibility, and safe experimentation. For HPC the discipline is specific: version the *source and build recipe*, keep large data and generated artifacts *out*, and tag/record the exact commit alongside every result so a run can be reproduced.

## Frameworks Introduced

- **The git model** (working tree → staging → commits → remotes):
  - **Working tree** (your files) → `git add` (stage changes) → `git commit` (snapshot with a message) → `git push`/`pull`/`fetch` (sync with a remote).
  - Each commit is an immutable snapshot identified by a hash; the history is a DAG of commits.

- **Branching & collaboration**: `git branch`/`git checkout`/`git switch` create and move between lines of development; `git merge`/`git rebase` integrate them. The **fork-and-pull-request** workflow (fork a repo, clone your fork, branch, PR back) is the standard for contributing to shared projects.

- **Inspecting & undoing**: `git status` (what's changed), `git diff` (line-level changes), `git log` (history), `git checkout <commit>`/`git revert` (recover/undo). `git stash` shelves work-in-progress.

- **HPC-specific hygiene**:
  - **`.gitignore`**: exclude build artifacts (`build/`, `*.o`), large outputs, and machine-specific files.
  - **Git LFS** (Large File Storage): for large binary inputs that must be versioned, stored out-of-band.
  - **Tags**: `git tag -a v1.0` marks releases; record the commit hash with results.

## Key Concepts
- **Commits are immutable snapshots**: the hash identifies an exact source state — the basis of reproducibility (a result is tied to a commit + environment).
- **Branches are cheap**: experiment on a branch, merge if it works, discard if not — safe exploration without risking `main`.
- **Don't version generated/large files**: the repo is for source and build recipes; outputs and big data belong in `.gitignore` or LFS, or out of git entirely.
- **Reproducibility = commit + environment**: a run is reproducible only if you can recover the exact source (commit hash) *and* the build environment (compiler/module versions, Ch 1).

## Mental Models
- **Commit early and often, on a branch** — small frequent commits make history navigable and bisectable; branch for any non-trivial change so `main` stays working.
- **Version the recipe, not the results** — source + `CMakeLists.txt`/`Makefile` + scripts go in git; multi-gigabyte outputs and datasets do not (`.gitignore`/LFS).
- **Tag and record the commit with every result** — "this figure came from commit `a1b2c3` built with gcc/12" is what makes science reproducible months later.
- **Use fork-and-PR for shared projects** — it isolates your work and gives a review point before integration.

## Code Examples
```bash
# Core workflow
git add solver.cpp CMakeLists.txt
git commit -m "feat: add multigrid preconditioner"
git push origin feature/multigrid

# Branch for safe experimentation
git switch -c experiment/new-scheme
# ... if it works: merge; if not: git switch main && git branch -D experiment/new-scheme

# Keep artifacts and data out
printf "build/\n*.o\n*.h5\nresults/\n" >> .gitignore

# Tag a reproducible state; record the hash with results
git tag -a v1.0 -m "paper submission"
git rev-parse HEAD      # record this commit hash alongside the run
```
- **What it demonstrates**: the add/commit/push cycle, branching for experiments, `.gitignore` hygiene, and reproducibility tagging.

## Reference Tables

| Command | Role |
|---|---|
| `git add` / `commit` | stage / snapshot changes |
| `git push` / `pull` / `fetch` | sync with remote |
| `git branch` / `switch` | create / move between branches |
| `git merge` / `rebase` | integrate branches |
| `git status` / `diff` / `log` | inspect changes / history |
| `git tag -a` | mark a release/result state |
| `.gitignore` / LFS | exclude / store-large-files |

## Key Takeaways
1. Git tracks immutable commit snapshots — the basis of reproducibility (a result ties to a commit hash).
2. Commit early and often on branches; branch for any non-trivial change to keep `main` working.
3. Version source and build recipes, never generated artifacts or large data — use `.gitignore` and Git LFS.
4. Tag and record the exact commit (plus build environment) with every result for reproducible science.
5. Use the fork-and-pull-request workflow for contributing to shared projects.

## Connects To
- **Ch 01 (Unix)**: the shell environment git runs in; record modules with commits.
- **Ch 03 (CMake)**: version `CMakeLists.txt`, ignore the `build/` directory.
- **Ch 08 (SLURM)**: record the commit hash in job output for reproducibility.
