---
title: Global instructions
---

# Global instructions

`claude/.claude/CLAUDE.md` is loaded into every session on every account. It is short on purpose and delegates
detail to two topic files and to skills. Read the file itself; this page is the map.

## What the global CLAUDE.md instructs

| Section | Instruction in one line |
|---|---|
| Interaction Style | Analytic peer: unhedged honesty, challenge premises, steel-man before disagreeing, propose a better alternative. Review order: correctness, numerics, memory, MPI, GPU, architecture, portability; no style nits. |
| Repository Layout | Fortran repos in `~/fortran/`, Python in `~/python/`; verify a path with `ls` before using it. |
| Build System | FoBiS (`fobis`, 3.8+) with double-dash flags; no make/cmake unless asked; `fobis fetch`, not submodules. |
| Toolchains | nvfortran 26.9 and gfortran 16.2.0 + Open MPI 5.0.11; build clean after a compiler switch; cluster and WSL environment recipes. |
| CI/CD | Minimal workflow changes; no repo names hardcoded in reusable actions. |
| Documentation | VitePress, modelled on `~/fortran/StringiFor` or `~/fortran/PENF`. |
| WSL and Windows | `HDF5_USE_FILE_LOCKING=FALSE` for Windows readers of WSL files; map drives from a non-elevated prompt. |
| Fortran, GPU | Load `CLAUDE-fortran.md` / `CLAUDE-gpu.md`; consult the standard skills instead of answering from memory. |
| Verbatim-Edit, Verification | `verbatim-edit` skill for byte-exact edits; `ai-research-verification` skill for agent claims. |
| Commit Messages | Conventional Commits; never an AI `Co-authored-by`; never commit or amend unless asked; `/semantic-commit` only prints the message; no GPG from agents. |
| Python Conventions | Load the `python-conventions` skill before writing Python. |

## Topic files

`CLAUDE-fortran.md` and `CLAUDE-gpu.md` are not loaded globally. The `load-context-by-cwd.sh` hook injects both
only when the session's project lives under `~/fortran`.
The gate is described under [Hooks](/claude/hooks#load-context-by-cwd).
