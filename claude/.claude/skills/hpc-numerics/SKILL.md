---
name: hpc-numerics
description: "Practitioner knowledge base for the numerical and algorithmic theory of high-performance scientific computing — the science beneath the parallel-programming mechanics. Use when reasoning about numerical correctness, algorithm design, or performance modeling: floating-point arithmetic and round-off error (machine epsilon, catastrophic cancellation, non-associativity, Kahan summation); conditioning vs stability (condition number, backward stability); ODE/PDE discretization (finite differences, stencils, explicit vs implicit Euler, stiffness, CFL condition, method of lines); numerical linear algebra (LU factorization, pivoting, sparse matrices, fill-in, reordering); iterative and Krylov solvers (Jacobi/Gauss-Seidel, CG, GMRES, preconditioning, multigrid); performance programming (the memory wall, cache blocking/tiling, the roofline model, arithmetic intensity); high-performance linear algebra (BLAS levels, gemm, block algorithms); combinatorial algorithms (parallel sorting networks, graph algorithms as sparse linear algebra, graph coloring); and N-body (cutoffs, cell lists, Barnes-Hut, FMM) and Monte Carlo methods (1/sqrt(N) error, variance reduction). Covers the algorithmic theory and error/stability/performance analysis — not the MPI/OpenMP/CUDA implementation mechanics."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, method (CG/multigrid/FMM), or chapter (e.g. ch04)]
---

# HPC Numerics — The Science of Scientific Computing
**Scope**: floating-point & error analysis · conditioning & stability · ODE/PDE discretization · numerical linear algebra · iterative/Krylov solvers · performance modeling · BLAS/block algorithms · combinatorial & graph algorithms · N-body & Monte Carlo | **Chapters**: 12 | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core diagnostic rules below.
- **With a topic** — ask about `cancellation`, `conditioning`, `stiffness`, `CFL`, `fill-in`, `preconditioning`, `roofline`, `BLAS levels`; I find and read the relevant chapter.
- **With a method** — ask about `conjugate gradient`, `multigrid`, `Barnes-Hut`; I load that chapter.
- **With a chapter** — ask for `ch04`; I load that file.

When you ask about something not in the Core section, I read the relevant chapter (and `cheatsheet.md` / `patterns.md` / `glossary.md`).

## Core Diagnostic Framework

### Scientific computing = three branches (Ch 1)
Modeling × numerical mathematics × computer architecture. A wrong/slow result is a failure in one of them — diagnose which. Everything funnels into **numerical linear algebra**; computation in **finite precision** makes error analysis fundamental.

### Diagnose a bad numerical result: problem or algorithm? (Ch 3, 4)
- **Conditioning** (problem): κ large → ill-conditioned, *no* algorithm helps → reformulate/precondition. `output error ≤ κ × input error`.
- **Stability** (algorithm): round-off grows over steps → unstable → switch algorithm. Backward-stable = exact answer to a slightly perturbed problem.
- **Floating point**: never test equality; `(a+b)+c ≠ a+(b+c)` (reassociation/parallel reductions break reproducibility); hunt **catastrophic cancellation** in subtractions of near-equal values and rewrite; use Kahan summation for long disparate sums.

### Time-stepping (Ch 5, 6)
Explicit (cheap, conditionally stable, Δt < 2/λ or CFL-limited) vs implicit (solve per step, unconditionally stable). **Stiffness decides** — separated timescales force implicit. PDEs discretize via stencils → sparse linear systems (method of lines).

### Linear solvers (Ch 7, 8)
Small/moderate dense or many-RHS → **direct LU** (always pivot). Large sparse → **iterative Krylov** (CG for SPD, GMRES for general; matvec-only, no fill-in). Convergence ∝ √κ — so the **preconditioner dominates** (Jacobi → ILU → multigrid, optimal for elliptic PDEs). Sparse direct → watch fill-in, reorder to cut it.

### Performance (Ch 2, 9, 10)
The **memory wall** limits most code (memory-bound). Engineer locality (spatial: unit stride/SoA; temporal: blocking/tiling). The **roofline** (arithmetic intensity = FLOPs/byte) triages memory- vs compute-bound. Dense LA → cast as **BLAS-3** (`gemm`, near-peak); matrix-vector and sparse matvec are memory-bound by nature. Never hand-code `gemm`/LU — call LAPACK.

### Beyond linear algebra (Ch 11, 12)
Best parallel algorithm ≠ best sequential parallelized (sorting networks). Graphs = adjacency matrices (BFS = sparse matvec). N-body: never naive O(N²) → cutoffs/cell-lists/Barnes-Hut/FMM. Monte Carlo: 1/√N error, dimension-independent, for high-D integration.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-scientific-computing-foundations.md) | Foundations | the three branches, continuous→discrete→linear algebra |
| [ch02](chapters/ch02-processor-architecture-and-memory.md) | Architecture & Memory | von Neumann, memory wall, cache, locality, pipelining |
| [ch03](chapters/ch03-computer-arithmetic-and-floating-point.md) | Floating-Point Arithmetic | ε_mach, cancellation, non-associativity, Kahan |
| [ch04](chapters/ch04-conditioning-and-stability.md) | Conditioning & Stability | κ, backward stability, problem vs algorithm |
| [ch05](chapters/ch05-odes-and-time-stepping.md) | ODEs & Time-Stepping | explicit/implicit Euler, stability, stiffness |
| [ch06](chapters/ch06-pdes-and-discretization.md) | PDEs & Discretization | stencils, 5-point star, sparse systems, CFL |
| [ch07](chapters/ch07-numerical-linear-algebra.md) | Numerical Linear Algebra | LU, pivoting, sparse, fill-in, reordering |
| [ch08](chapters/ch08-iterative-and-krylov-solvers.md) | Iterative & Krylov Solvers | Jacobi/GS, CG, GMRES, preconditioning, multigrid |
| [ch09](chapters/ch09-performance-programming-and-roofline.md) | Performance & Roofline | cache blocking, tiling, arithmetic intensity, roofline |
| [ch10](chapters/ch10-high-performance-linear-algebra.md) | HP Linear Algebra | BLAS levels, gemm, block algorithms |
| [ch11](chapters/ch11-combinatorial-and-graph-algorithms.md) | Combinatorial & Graph | sorting networks, graphs as sparse LA, coloring |
| [ch12](chapters/ch12-n-body-and-monte-carlo.md) | N-Body & Monte Carlo | cutoffs, Barnes-Hut, FMM, 1/√N sampling |

## Topic Index

- **arithmetic intensity / roofline** → ch09
- **BLAS levels / gemm / block algorithms** → ch10
- **Barnes-Hut / FMM / N-body** → ch12
- **cache blocking / tiling / locality** → ch02, ch09
- **catastrophic cancellation** → ch03
- **CFL condition** → ch06
- **condition number / conditioning** → ch04
- **Conjugate Gradient / GMRES / Krylov** → ch08
- **explicit vs implicit / stiffness** → ch05
- **fill-in / reordering** → ch07
- **finite difference / stencils** → ch06
- **floating-point / machine epsilon / Kahan** → ch03
- **graph algorithms / coloring** → ch11
- **LU factorization / pivoting** → ch07
- **memory wall / von Neumann** → ch02
- **method of lines** → ch05, ch06
- **Monte Carlo / variance reduction** → ch12
- **multigrid** → ch08
- **non-associativity / reproducibility** → ch03, ch09
- **preconditioning** → ch08
- **sorting (networks/parallel)** → ch11
- **sparse matrices** → ch06, ch07, ch08
- **stability (algorithm/numerical)** → ch04, ch05
- **truncation error / discretization** → ch05, ch06

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete techniques (diagnose problem-vs-algorithm, avoid cancellation, preconditioning, cache blocking, cast-as-BLAS-3, roofline triage, beat O(N²))
- [cheatsheet.md](cheatsheet.md) — decision rules: solver picker, time-stepping picker, floating-point rules, BLAS levels, roofline triage

---

## Scope & Limits

Covers the *numerical and algorithmic theory* of HPC — error analysis, stability, discretization, linear-algebra algorithms, performance modeling, and the algorithm-design principles behind scientific computing. It is the "science" layer beneath the parallel-programming *mechanics*. For the implementation tooling, see the sibling skills: **gpu-multithreading** and **cpp-hpc** (parallel programming models, MPI/OpenMP/CUDA/Kokkos), **python-hpc** (Python performance), and the spec skills **mpi-5.0** / **openmp-6.0** / **cuda-programming**. For exact numerical-library APIs (BLAS/LAPACK/PETSc) consult their documentation; this skill explains the algorithms they implement.
