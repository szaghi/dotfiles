# Chapter 6: PDEs — Discretization, Stencils & Sparse Structure

## Core Idea
Partial Differential Equations are discretized by replacing spatial derivatives with **finite-difference stencils** applied at every grid point. This turns the continuous PDE into a large **sparse linear system** (for steady/implicit problems) or a stencil update (for explicit time-stepping). The matrix structure — block tridiagonal, mostly zeros — is what makes PDE solving both tractable and a numerical-linear-algebra problem.

## Frameworks Introduced

- **The PDE taxonomy** (each needs a different approach):
  - **Elliptic** (e.g. Poisson `∇²u = f`) — steady-state/equilibrium; a **boundary value problem** → solve one big linear system.
  - **Parabolic** (e.g. heat equation `uₜ = ∇²u`) — diffusion; an **initial-boundary value problem** → time-step a spatial discretization.
  - **Hyperbolic** (e.g. wave/advection) — propagation; time-step with a CFL-limited scheme.

- **Finite-difference stencils**: approximate a spatial derivative by a weighted combination of neighboring grid values. The **5-point star stencil** (center − neighbors) discretizes the 2D Laplacian: `(u_{i-1,j} + u_{i+1,j} + u_{i,j-1} + u_{i,j+1} − 4u_{i,j})/h²`. Applying it at every interior point couples each point to its neighbors.

- **The resulting sparse matrix**: discretizing a 2D domain with the 5-point stencil yields a **block tridiagonal** matrix — tridiagonal blocks on a tridiagonal block structure, with only ~5 nonzeros per row regardless of grid size. The matrix is huge (N² unknowns for an N×N grid) but **sparse** (O(N²) nonzeros, not N⁴).

- **The CFL condition** (explicit time-stepping limit): for explicit schemes on time-dependent PDEs, the timestep is capped by the spatial resolution — `Δt ≤ C·h^p/(wave speed)` (the **Courant-Friedrichs-Lewy** condition). Physically: information must not cross more than one grid cell per step. Violating it makes the explicit scheme unstable (the spatial analogue of Ch 5's Δt cap).

## Key Concepts
- **Discretization error**: the stencil approximates the derivative to order `h^p` (central differences are second order, O(h²)); finer grids reduce error but enlarge the system.
- **Finite difference vs finite element**: FD applies stencils on a structured grid (simple, regular sparse matrix); FEM uses basis functions on (possibly unstructured) meshes (flexible geometry, more complex assembly) — both yield sparse linear systems.
- **Boundary conditions**: Dirichlet (prescribed value), Neumann (prescribed derivative) — they modify the matrix rows/RHS at the domain boundary.
- **Sparsity is the whole point**: a dense solve of an N²×N² system is infeasible; exploiting sparsity (storage + algorithms) is what makes PDE computation possible (Ch 7–8).
- **Method of lines**: discretize space first (→ a large system of ODEs), then apply a time integrator (Ch 5) — separating spatial and temporal discretization.

## Mental Models
- **A discretized PDE *is* a sparse linear-algebra problem** — elliptic PDEs → solve `Au = f`; the structure (block tridiagonal, 5 nonzeros/row) determines which solver to use (Ch 7–8). This is the bridge from physics to numerical LA.
- **Explicit PDE time-stepping inherits a CFL limit** — refine the grid (smaller h) and you must shrink Δt too; implicit schemes lift the CFL cap at the cost of a sparse solve per step (the explicit-vs-implicit trade from Ch 5, now spatial).
- **Never store the PDE matrix densely** — it's mostly zeros; sparse storage + sparse solvers turn an impossible N⁴-entry matrix into a tractable O(N²)-nonzero one.
- **Match the solver to the stencil structure** — the regular sparse structure of FD matrices is exactly what direct (banded) and iterative (Krylov + geometric multigrid) solvers exploit.

## Code Examples
```text
2D Poisson, 5-point stencil on an N×N grid (h = 1/(N+1)):

   (u[i-1,j] + u[i+1,j] + u[i,j-1] + u[i,j+1] - 4·u[i,j]) / h²  =  f[i,j]

  ⟹ sparse linear system  A·u = h²·f   with A block tridiagonal:
        A = | T  -I        |     T = | 4 -1       |
            |-I   T  -I     |         |-1  4 -1    |   (each block N×N)
            |    -I   T  -I |         |   -1  4 -1 |
            |        -I   T |         |      -1  4 |
        ~5 nonzeros per row, N² unknowns

CFL (explicit, advection speed a):   Δt ≤ C · h / a      (else unstable)
```
- **What it demonstrates**: the 5-point stencil producing a block-tridiagonal sparse system, and the CFL step-size limit.

## Reference Tables

| PDE type | Example | Nature | Solve via |
|---|---|---|---|
| elliptic | Poisson | steady, BVP | one sparse linear solve |
| parabolic | heat | diffusion, IBVP | time-step spatial discretization |
| hyperbolic | wave/advection | propagation, IBVP | CFL-limited time-stepping |

| Discretization | Grid | Matrix |
|---|---|---|
| finite difference | structured | regular sparse (block tridiagonal) |
| finite element | unstructured | irregular sparse |

## Key Takeaways
1. PDEs are discretized by finite-difference stencils (the 5-point star for the 2D Laplacian) applied at every grid point, coupling each point to its neighbors.
2. The result is a huge but **sparse** (block tridiagonal, ~5 nonzeros/row) linear system — a discretized PDE is a numerical-linear-algebra problem.
3. Elliptic → one sparse solve; parabolic/hyperbolic → time-step a spatial discretization (method of lines).
4. Explicit PDE time-stepping is CFL-limited (Δt capped by grid spacing); implicit schemes lift it at the cost of a sparse solve per step.
5. Never store the PDE matrix densely — sparsity is what makes PDE computation feasible; match the solver to the regular stencil structure.

## Connects To
- **Ch 05 (ODEs)**: the time-stepping applied after spatial discretization (method of lines), and the CFL analogue of the Δt cap.
- **Ch 07 (Numerical LA)**: the sparse linear system and its fill-in under direct factorization.
- **Ch 08 (Iterative solvers)**: Krylov + multigrid exploit the stencil's sparse structure.
