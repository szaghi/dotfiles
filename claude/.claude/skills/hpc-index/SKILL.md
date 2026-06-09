---
name: hpc-index
description: "Router and disambiguation map for the HPC skill fleet — decides WHICH high-performance-computing skill to consult when a query plausibly matches several. Use ONLY for cross-cutting routing/navigation: when the user asks which HPC skill covers a topic, says 'what HPC skills do I have', wants the map/relationships between them, or poses a parallel/numerical/HPC question that genuinely spans the reference-vs-applied-vs-theory boundary and the right skill is ambiguous (e.g. 'CG solver not converging' = theory vs PETSc API; 'optimize my CUDA kernel' = design playbook vs CUDA reference; an MPI question that could be the standard vs the C++/Python practical layer). SKIP this skill when the query already names one technology unambiguously — a pure MPI-semantics question goes straight to mpi-5.0, a C++23-standard question to iso-cpp-2023, a Numba-CUDA-Python question to python-hpc — those route directly without this router. This is a thin navigation layer over twelve HPC skills, not a knowledge base itself."
allowed-tools:
  - Read
  - Grep
argument-hint: [a topic or question to route to the right HPC skill]
---

# HPC Skill Fleet — Router & Disambiguation Map

A thin routing layer over the twelve HPC skills. It holds **no domain knowledge** — it points you at the skill that does, then that skill answers. Use it only when the right skill is genuinely ambiguous; when a query names one technology, go straight there.

## The fleet, by layer

The single most useful distinction is **reference vs applied vs theory vs workflow** — almost every "which skill?" question resolves on this axis.

| Layer | Question it answers | Skills |
|---|---|---|
| **Language standards** | "what does the *language* standard say / is this conforming?" | `iso-c-9899-2024` (C23), `iso-cpp-2023` (C++23), `fortran-2023-standard` (F2023) |
| **Parallel-model specs** | "what does this *API/spec* say / require?" | `mpi-5.0`, `openmp-6.0`, `openacc-3.4`, `cuda-programming` |
| **Applied / practitioner** | "how do I *build or optimize* this?" | `cpp-hpc` (C++ toolchain+ecosystem), `python-hpc` (Python CPU+GPU), `gpu-multithreading` (cross-language design+optimization playbook) |
| **Theory** | "*why* / is it correct / how fast *can* it be?" | `hpc-numerics` (numerical algorithms, error/stability, roofline) |
| **Workflow** | "how do I *run/build/debug/profile* on a cluster?" | `hpc-cluster-tooling` (SLURM, Make/CMake, GDB/sanitizers, perf/TAU) |

## Routing rules (the disambiguation core)

**The master rule: reference question → spec/standard skill; "how do I do it" → applied skill; "why / is it right / how fast can it be" → `hpc-numerics`; "run/build/debug it" → `hpc-cluster-tooling`.**

| If the query is about… | …and it's a question of… | Route to |
|---|---|---|
| **MPI** | exact routine semantics, completion, deadlock rules | `mpi-5.0` |
| MPI | practical C++ usage, halo exchange, hybrid design | `cpp-hpc` (ch06–07) or `gpu-multithreading` |
| MPI | from Python (mpi4py) | `python-hpc` |
| MPI | modern C++ binding (MPL) | `cpp-hpc` (ch06) |
| **OpenMP** | exact directive/clause semantics, memory model | `openmp-6.0` |
| OpenMP | applying it (reductions, tasks, offload in practice) | `cpp-hpc` (ch08) or `gpu-multithreading` |
| **OpenACC** | any directive/clause semantics | `openacc-3.4` |
| **CUDA** | API/intrinsic/compute-capability reference (C++) | `cuda-programming` |
| CUDA | kernel-optimization design (coalescing, occupancy, tiling) | `gpu-multithreading` or `cpp-hpc` (ch09) |
| CUDA | from Python (Numba-CUDA, CuPy) | `python-hpc` |
| **C / C++ / Fortran** | what the *standard* requires, conformance, UB | `iso-c-9899-2024` / `iso-cpp-2023` / `fortran-2023-standard` |
| C++ | idioms/RAII/STL for HPC (not standard wording) | `cpp-hpc` |
| **A solver / algorithm** | the *math* (CG, GMRES, multigrid, conditioning) | `hpc-numerics` |
| a solver | the *library API* (PETSc KSP/PC, BLAS, FFTW) | `cpp-hpc` (ch13) |
| **"why is it slow / how fast can it be"** | roofline, arithmetic intensity, memory-bound | `hpc-numerics` (model) + `gpu-multithreading` (fix) |
| **"it's wrong / unstable / not reproducible"** | floating point, cancellation, conditioning | `hpc-numerics` |
| **Build / SLURM / debug / profile** | the cluster workflow & tooling | `hpc-cluster-tooling` |
| **Parallel *design*** | decomposition, Amdahl/Gustafson, load balancing | `gpu-multithreading` |
| **Python performance** | profiling, NumPy, Numba, Dask, JAX | `python-hpc` |

## The recurring disambiguation pairs

- **Algorithm vs API**: "conjugate gradient" the *method* → `hpc-numerics`; "PETSc `KSPSolve`" the *call* → `cpp-hpc`. The theory skill explains what KSP/PC implement.
- **Spec vs practice**: "does `MPI_Ssend` block until matched" → `mpi-5.0`; "structure a halo exchange" → `cpp-hpc`/`gpu-multithreading`. Reference wording vs hands-on construction.
- **Design vs reference**: "how should I decompose this / why is it memory-bound" → `gpu-multithreading`/`hpc-numerics`; "what's the signature of `cudaMemcpyAsync`" → `cuda-programming`.
- **Language layer**: "C++/Python/CUDA" — pick by language: C++ → `cpp-hpc`, Python → `python-hpc`, plus the matching spec skill for exact semantics.
- **Theory vs workflow**: "why does my sum drift" → `hpc-numerics` (FP); "why is my SLURM job killed" → `hpc-cluster-tooling`.

## How to use this router

1. Identify the **axis**: reference (spec/standard), applied (build/optimize), theory (why/correct/fast), or workflow (run on cluster).
2. Identify the **technology/language** if named.
3. Read the matching skill's `SKILL.md` and answer from there — this router holds no answers itself.
4. If the query spans layers (common in real work — e.g. "my CG solver in PETSc is slow on the GPU"), consult **multiple**: `hpc-numerics` (is the algorithm/conditioning the issue?) + `cpp-hpc` (PETSc GPU usage) + `gpu-multithreading`/`cuda-programming` (GPU optimization).

## Scope & Limits

This is a navigation layer, not a knowledge base — it never answers HPC questions directly, only routes to the skill that can. It deliberately does **not** trigger when a query already names one technology unambiguously (those route directly to the relevant skill without this hop). If a topic isn't in the table above, fall back to the closest layer and the matching skill's own description.
