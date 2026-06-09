# Chapter 13: Numerical Libraries — BLAS/LAPACK, FFTW, PETSc, Trilinos

## Core Idea
Don't reimplement numerical kernels — decades of expert, hardware-tuned work live in standard libraries. **BLAS/LAPACK** for dense linear algebra, **FFTW** for transforms, and **PETSc/Trilinos** for large sparse/distributed solvers. Using them is both faster and more correct than hand-rolling, and it's the second rung of the performance ladder (right after "pick the right algorithm").

## Frameworks Introduced

- **BLAS / LAPACK** (dense linear algebra):
  - **BLAS** levels: 1 (vector ops, `axpy`/`dot`), 2 (matrix-vector, `gemv`), 3 (matrix-matrix, **`gemm`** — the high-arithmetic-intensity workhorse that hits near-peak FLOPS). Optimized implementations: OpenBLAS, Intel MKL, BLIS — multi-threaded, blocked, SIMD.
  - **LAPACK** builds on BLAS for solvers: LU/Cholesky/QR factorizations, linear solves, eigenvalue/SVD. Call the high-level routine (`dgesv`, `dsyev`), never hand-code factorizations.

- **FFTW** (Fastest Fourier Transform in the West):
  - Computes discrete Fourier transforms in any dimension. Uses a **plan** abstraction: `fftw_plan_dft(...)` measures and selects the best algorithm for your size/hardware once, then `fftw_execute(plan)` runs it repeatedly. Multi-threaded and MPI-distributed variants exist.

- **PETSc** (Portable, Extensible Toolkit for Scientific Computation):
  - Distributed sparse linear algebra for PDEs: **Vec** (distributed vectors), **Mat** (distributed sparse matrices), **KSP** (Krylov solvers: GMRES, CG), **PC** (preconditioners), **SNES** (nonlinear), **TS** (time steppers). Built on MPI; scales to thousands of ranks. You assemble the matrix/vector and choose solver+preconditioner; PETSc handles the parallel distribution.

- **Trilinos** (a large ecosystem of HPC numerical packages):
  - Modular packages including **Tpetra** (next-gen distributed linear algebra, Kokkos-backed for GPU portability; Epetra is the legacy version), plus solvers, preconditioners, and discretization tools. The Kokkos-based design gives performance portability across CPU/GPU.

## Key Concepts
- **Sparse vs dense**: dense (BLAS/LAPACK) for small/full matrices; sparse (PETSc/Trilinos) for the large, mostly-zero matrices from discretized PDEs — store only nonzeros, solve iteratively.
- **Krylov solvers + preconditioners**: large sparse systems are solved iteratively (GMRES/CG); the **preconditioner** (ILU, multigrid, Jacobi) determines convergence speed — choosing it well is the main performance lever.
- **Plan/setup amortization**: FFTW plans and PETSc solver setups cost up front but amortize over repeated executions — set up once, run many times.
- **GPU portability**: Trilinos/Tpetra (via Kokkos) and modern PETSc run on GPUs; the library abstracts the device.

## Mental Models
- **Never hand-code GEMM, an FFT, or a sparse solve** — the library beats your version on speed and correctness, and it's tuned per hardware. This is rung 2 of the performance ladder (use libraries).
- **`gemm` (BLAS-3) is where dense performance lives** — restructure dense linear algebra into matrix-matrix products to hit near-peak FLOPS; BLAS-1/2 are memory-bound.
- **For PDE solvers, the preconditioner choice dominates** — a good preconditioner (multigrid for elliptic problems) can turn thousands of iterations into tens.
- **Set up plans/solvers once, execute many times** — amortize the planning cost across timesteps.

## Code Examples
```cpp
// BLAS-3 GEMM: C = αAB + βC — near-peak FLOPS, never hand-rolled
cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
            M, N, K, 1.0, A, K, B, N, 0.0, C, N);

// FFTW: plan once, execute repeatedly
fftw_plan plan = fftw_plan_dft_1d(n, in, out, FFTW_FORWARD, FFTW_MEASURE);
for (int step = 0; step < nsteps; ++step) fftw_execute(plan);   // reuse the plan
fftw_destroy_plan(plan);

// PETSc: assemble distributed system, choose Krylov solver + preconditioner
KSP ksp; KSPCreate(PETSC_COMM_WORLD, &ksp);
KSPSetOperators(ksp, A, A);
KSPSetType(ksp, KSPGMRES);                 // Krylov method
PC pc; KSPGetPC(ksp, &pc); PCSetType(pc, PCILU);   // preconditioner
KSPSolve(ksp, b, x);                       // PETSc handles the MPI distribution
```
- **What it demonstrates**: BLAS-3 GEMM, FFTW plan reuse, and a PETSc distributed Krylov solve with preconditioner.

## Reference Tables

| Need | Library | Key abstraction |
|---|---|---|
| dense linear algebra | BLAS/LAPACK (MKL/OpenBLAS) | `gemm`, factorizations |
| Fourier transforms | FFTW | plan + execute |
| sparse distributed solvers | PETSc | Vec/Mat/KSP/PC |
| portable HPC numerics | Trilinos (Tpetra) | Kokkos-backed |

| BLAS level | Op | Bound |
|---|---|---|
| 1 | vector (axpy, dot) | memory |
| 2 | matrix-vector (gemv) | memory |
| 3 | matrix-matrix (**gemm**) | compute (near-peak) |

## Key Takeaways
1. Use standard libraries instead of hand-coding numerical kernels — faster, more correct, hardware-tuned (rung 2 of the performance ladder).
2. BLAS-3 `gemm` hits near-peak FLOPS; restructure dense work into matrix-matrix products. LAPACK for factorizations/solves.
3. FFTW uses plans — measure/plan once, execute repeatedly.
4. PETSc provides distributed sparse Vec/Mat + Krylov solvers (KSP) and preconditioners (PC) over MPI; the preconditioner choice dominates convergence.
5. Trilinos/Tpetra (Kokkos-backed) gives GPU-portable distributed numerics.

## Connects To
- **Ch 07 (MPI)**: PETSc/Trilinos build on MPI for distribution.
- **Ch 10 (Kokkos)**: Tpetra's performance-portability backend.
- **Ch 01 (Toolchain)**: linking these via CMake `find_package`/Spack.
