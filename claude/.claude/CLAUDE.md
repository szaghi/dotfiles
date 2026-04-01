# Global Fortran Project Conventions

## Repository Layout
- Fortran repos live in `~/fortran/`, Python repos in `~/python/`
- When referencing another repo, confirm the correct path first
  (e.g. `~/fortran/PENF`, not `~/PENF` or a submodule copy)

## Build System
- Primary build tool is **FoBiS.py** — use its built-in flags
  (e.g. `-get`, `-ex`) rather than parsing fobos files with awk/sed
- Do NOT substitute make/cmake unless the user explicitly asks
- Dependency management uses `FoBiS.py fetch`, not git submodules

## CI/CD
- GitHub Actions workflows: make minimal changes — remove jobs
  rather than rewriting them when asked to simplify
- Do not hardcode repo-specific names in reusable actions;
  use `${{ github.repository }}` or equivalent
- GPG signing is unavailable (no TTY) — never attempt it

## Documentation
- Docs use **VitePress** (not FORD)
- When migrating or refactoring docs, mirror the structure of
  `~/fortran/StringiFor` or `~/fortran/PENF` as the reference

## Fortran / gfortran Pitfalls

### gfortran -O2 bug: pointer array + assumed-shape dummy with explicit lower bounds
When an actual argument is a **pointer array section** (lb=1, from Fortran section rules) passed
to a dummy with explicit lower bounds (e.g. `q(1-ngc:,...)`), gfortran -O2+ computes a wrong
C data pointer. This causes `errno=14 EFAULT` in HDF5 writes. Works at -O0/-O1 and nvfortran.

**Fix**: use separate routines for pointer-derived actuals — declare dummy as `q(:,:,:,:)` (no
explicit lb) and pass `nijk` directly. For scalar rank-3 fields use explicit-shape
`q(ijk(1,1):ijk(2,1),...)` to bypass the descriptor entirely.
Individual `-fno-*` flags do not isolate the trigger. Do not use allocatable copies as a workaround.

## Commit Messages
- Use Conventional Commits: `type(scope): description`
- NEVER add `Co-authored-by` lines for Claude or any AI
- Do NOT create or amend commits unless explicitly asked
- `/semantic-commit` (and similar skills) means **generate and display** the
  commit message only — never run `git commit` automatically; let the user
  run it in their terminal

@RTK.md
