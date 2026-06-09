# Glossary — HPC Numerics

**arithmetic intensity** — FLOPs per byte of memory traffic; sets the roofline ceiling (Ch 9).
**Barnes-Hut** — O(N log N) tree code approximating distant particle clusters (Ch 12).
**BLAS levels** — 1 (vector), 2 (matrix-vector), 3 (matrix-matrix/gemm); only L3 reaches peak (Ch 10).
**block algorithm** — factorization restructured so most work is gemm (Ch 10).
**cache blocking / tiling** — restructure loops so working data fits and is reused in cache (Ch 9).
**catastrophic cancellation** — subtracting near-equal numbers; amplifies relative error (Ch 3).
**CFL condition** — explicit time-step cap from grid spacing (Courant-Friedrichs-Lewy) (Ch 6).
**condition number κ** — problem sensitivity to input perturbation; κ(A)=‖A‖‖A⁻¹‖ (Ch 4).
**conditioning** — property of the problem (input sensitivity) (Ch 4).
**Conjugate Gradient (CG)** — Krylov solver for symmetric positive definite matrices (Ch 8).
**CRS** — Compressed Row Storage for sparse matrices (Ch 7).
**explicit Euler** — `u_{k+1}=u_k+Δt·f(u_k)`; cheap, conditionally stable (Ch 5).
**fill-in** — new nonzeros created during sparse LU elimination (Ch 7).
**finite difference** — derivative ≈ weighted neighbor difference (stencil) (Ch 6).
**Fast Multipole Method (FMM)** — O(N) N-body via multipole expansions (Ch 12).
**gemm** — BLAS-3 matrix-matrix product; near-peak FLOPS (Ch 10).
**GMRES** — Krylov solver for general nonsymmetric matrices (Ch 8).
**guard digit** — extra digit during an operation for correct rounding (Ch 3).
**implicit Euler** — `u_{k+1}=u_k+Δt·f(u_{k+1})`; solve per step, unconditionally stable (Ch 5).
**iterative method** — solve Ax=b by repeated improvement using matvecs (Ch 8).
**Krylov subspace** — span{b, Ab, A²b, …}; basis for CG/GMRES (Ch 8).
**LU factorization** — A=LU; Gaussian elimination direct solve (Ch 7).
**machine epsilon (ε_mach)** — relative error of one rounded operation (~2.2e-16 double) (Ch 3).
**memory wall** — memory too slow to feed the processor (von Neumann bottleneck) (Ch 2).
**method of lines** — discretize space first (→ ODE system), then time-step (Ch 6).
**Monte Carlo** — integration by random sampling; error ∝ 1/√N, dimension-independent (Ch 12).
**multigrid** — O(N) optimal solver/preconditioner for elliptic PDEs (Ch 8).
**N-body** — every-particle-interacts problem; naive O(N²) (Ch 12).
**non-associativity** — `(a+b)+c ≠ a+(b+c)` in floating point (Ch 3).
**partial pivoting** — row-swap largest element into the pivot for stability (Ch 7).
**peak performance** — theoretical max FLOP/s; rarely achieved (memory wall) (Ch 2, 9).
**preconditioning** — transform Ax=b to improve conditioning → faster convergence (Ch 8).
**roofline** — model: attainable FLOP/s vs arithmetic intensity (Ch 9).
**sorting network** — oblivious compare-exchange sort (bitonic, odd-even); parallel (Ch 11).
**sparse matrix** — mostly zeros; stored compactly (Ch 6, 7).
**spectral radius** — largest |eigenvalue|; governs stationary-iteration convergence (Ch 8).
**stability (algorithm)** — round-off amplification; backward-stable = exact answer to perturbed problem (Ch 4).
**stencil** — finite-difference pattern (e.g. 5-point star) applied at each grid point (Ch 6).
**stiffness** — widely separated timescales; forces implicit methods (Ch 5).
**temporal/spatial locality** — reuse data / use whole cache line (Ch 2, 9).
**truncation error** — discretization approximation error → 0 as h→0 (Ch 5, 6).
**von Neumann architecture** — control-flow processor over one memory bus (Ch 2).
