# Chapter 13: Non-Normality, the Numerical Range & Crouzeix Bounds

## Core Idea
For a **normal** matrix (A*A = AA*) the eigenvalues tell the whole story: ‖f(A)‖ = max over the spectrum of |f|. Discretizations of **convection-dominated** operators (upwind, inflow boundaries, Chimera interpolation rows, linearized Navier–Stokes about a shear flow) are strongly **non-normal**: eigenvalues can sit safely inside a stability region or away from 0 while powers, exponentials and Krylov residuals grow by many orders of magnitude. The robust replacement for the spectrum is the **numerical range** (field of values) W(A) = {x*Ax : ‖x‖ = 1}. The **Crouzeix theorem** turns W(A) into a norm bound with a universal constant **2**.

## Frameworks Introduced

- **Numerical range W(A)**: a compact convex set that contains the spectrum (Toeplitz–Hausdorff). For normal A it is the convex hull of the eigenvalues; for non-normal A it can be much larger. Facts you need:
  - ω(A) := max Re W(A) = λ_max((A+A*)/2), the **numerical abscissa**.
  - ‖e^{tA}‖ ≤ e^{tω} (Lumer–Phillips). If ω ≤ 0 the semi-discretization is energy-stable in the Euclidean norm.
  - W(A⊗I + I⊗B) = W(A) + W(B), which makes tensor-product/dimension-split operators cheap to analyse.
  - W is translation- and scale-covariant: W(αA+βI) = αW(A)+β.

- **Crouzeix theorem (constant 2)**: for every square matrix A, and every bounded operator on a Hilbert space, and every polynomial, rational function with poles outside the closure of W(A), or function holomorphic near it:
  `‖f(A)‖ ≤ 2 · max_{z∈W(A)} |f(z)|`.
  The **complete** form has the same constant for matrix-valued f, i.e. f(A) = Σ A^k ⊗ B_k. The constant 2 is sharp.
  - **Provenance.** The conjecture is Crouzeix 2004. The proven constant was 11.08 (2007), then 1+√2 (Crouzeix–Palencia 2017), then 2 for the scalar case (2026 proofs). The **complete** and Hilbert-space forms with 2 appear in OpenAI-model preprints from Sept 2026, Lean-formalized but unrefereed (github.com/openai/math, family 325, Oct 2026).
  - **For practice**, the change from 1+√2 to 2 is cosmetic. What matters is the *framework*: replace "eigenvalues in the region" with "**W(A) in the region**".

- **Structural companion: optimal similarity.** Take Ω ⊃ W(A) strictly, convex, with an analytic boundary, and f a conformal map Ω → unit disk. Then there is S with ‖S‖‖S⁻¹‖ ≤ 2 that makes Sf(A)S⁻¹ a contraction. In practice: an **energy norm ‖x‖_H = ‖Sx‖**, equivalent to ‖·‖₂ within a factor 2, in which every step of a scheme whose stability region contains Ω is contractive.
  - **Caveat:** containment must be strict. Consistent semi-discretizations usually have W touching 0, which is exactly where stability regions are tangent, and no limiting result is asserted there.
  - For a disk Ω this is the older Okubo–Ando theorem.

- **Pseudospectra** Λ_ε(A) = {z : ‖(zI−A)⁻¹‖ > 1/ε} (Trefethen–Embree): finer than W. Use it when W is too pessimistic, e.g. when W crosses the imaginary axis but the transient is short. The Kreiss matrix theorem links the resolvent to sup_n ‖Aⁿ‖ with a dimension-dependent constant (≤ e·N·K). The Crouzeix bound is **dimension-free**.

## Key Concepts — the usable inequalities

| Use | Bound (constant 2 = Crouzeix) | Condition |
|---|---|---|
| GMRES | ‖r_k‖/‖r₀‖ ≤ 2 min_{p(0)=1, deg p≤k} max_{W(A)} \|p\| | 0 ∉ W(A), else vacuous |
| GMRES, W in disk D(c,ρ) | ≤ 2 (ρ/\|c\|)^k | ρ < \|c\| |
| GMRES, W in ellipse (foci c±d, semi-axes a,b) | ≤ 2 (R^k+R^{−k})/(R₀^k+R₀^{−k}), with R=(a+b)/\|d\| and R₀=\|c/d+√((c/d)²−1)\| > R | 0 ∉ ellipse |
| One-step integrator R(hA) (RK, Padé, θ-scheme) | ‖R(hA)ⁿ‖ ≤ 2 (sup_{hW(A)} \|R\|)ⁿ, so **≤ 2 for all n** if hW(A) ⊆ {\|R\| ≤ 1} | poles of R outside hW(A) |
| …with forcing u_{n+1}=Ru_n+hQg_n | ‖u_n‖ ≤ 2‖u₀‖ + 2h sup_{hW}\|Q\| Σ‖g_j‖ | same |
| Systems u_t + B u_x = 0, L = D⊗B (complete form) | ‖R(hL)ⁿ‖ ≤ 2 max_{z∈W(D)} ‖R(hzB)ⁿ‖ (an m×m check) | B non-normal is where it is new |
| Krylov/Arnoldi f(A)v (exponential integrators) | error ≤ 4 min_{deg p<k} max_W \|f−p\| ‖v‖ | W(H_k) ⊆ W(A) |
| e^{tA}, φ_k(tA) | use Lumer–Phillips e^{tω} instead | Crouzeix gives 2e^{tω}, which is worse |

## Worked Example — upwind advection with inflow BC (numerically verified)
Take u_t + a u_x = 0, first-order upwind, inflow Dirichlet, N cells: hA = −ν(I − J), with J the down-shift and ν = aΔt/Δx.

- **Spectrum** = {−ν}, a single defective eigenvalue. Forward Euler gives G = (1−ν)I + νJ, with spectral radius |1−ν|. The **eigenvalue test says stable for ν ≤ 2. That is false.**
- **Numerical range.** W(J) is the disk of radius cos(π/(N+1)), so hW(A) is the disk with centre −ν and radius ν cos(π/(N+1)). This lies in the forward-Euler region |1+z| ≤ 1 iff ν ≤ 1, giving ‖Gⁿ‖ ≤ 2 for all n. **That is the true CFL limit.**
- **Measured, N = 100, ν = 1.5:** the spectral radius is 0.5, yet ‖G^{50}‖ ≈ 1e15 and ‖G^{200}‖ ≈ 1e46. At ν = 0.9 and ν = 1, ‖Gⁿ‖ ≤ 1.
- **GMRES on implicit Euler** I − hA = (1+ν)I − νJ: the rate bound is ν cos(π/(N+1))/(1+ν), about 0.8 at ν = 4. It is mesh-independent but deteriorates as ν grows, which is the familiar convection-dominated slowdown.
- **Steady problem (h → ∞):** W(A) approaches 0 as N grows, so the unpreconditioned GMRES bound → 1. Precondition, or reorder along the flow direction (for this matrix, Gauss–Seidel in the upwind order is exact).

## Computing W(A) — Johnson's algorithm (matvec-only)
For θ_j = 2πj/M:
1. Form H_θ = (e^{iθ}A + e^{−iθ}A*)/2.
2. Compute λ_max(H_θ) and its unit eigenvector x_θ. Use Lanczos for sparse A; it needs A·v and A*·v only.
3. **Inner** boundary point: z_θ = x_θ* A x_θ.
4. **Outer** polygon: ∩_θ {z : Re(e^{iθ} z) ≤ λ_max(H_θ)}.

Use the **outer** polygon to *certify* containment in a stability region; the inner one only illustrates. θ = 0 gives ω(A). Cost: M symmetric extreme-eigenvalue solves, with M ≈ 32–128 for a smooth boundary.

```python
def numrange(A, M=128):                       # dense, for small model problems
    pts, sup = [], []
    for th in np.linspace(0, 2*np.pi, M, endpoint=False):
        H = (np.exp(1j*th)*A + np.exp(-1j*th)*A.conj().T) / 2
        w, V = np.linalg.eigh(H); x = V[:, -1]
        pts.append(x.conj() @ A @ x); sup.append((th, w[-1]))   # inner pts, outer half-planes
    return np.array(pts), sup
```

## Mental Models
- **Eigenvalues certify asymptotics, not transients.** For non-normal A, "all eigenvalues in the stability region" is necessary, **not sufficient**. "W(hA) in the stability region" is sufficient (constant 2), and pseudospectra tell you how sharp that is.
- **Check ω(A) first.** One symmetric eigenproblem: ω > 0 means real transient energy growth for every scheme. Fix the semi-discretization (BC closure, interpolation weights, SBP/SAT), not the time step.
- **GMRES stagnation with nice eigenvalues means non-normality, not a bug.** Look at W(A) or W(M⁻¹A). If 0 ∈ W, the preconditioner must move W, not just cluster eigenvalues.
- **The inner-product choice is part of the analysis.** W is norm-dependent: in an M-inner product, W_M(A) = W(M^{1/2}AM^{−1/2}). SBP energy norms are exactly such choices; changing the norm costs κ(M^{1/2}) in the final bound.
- **Systems reduce to small matrices.** For D⊗B operators, scan z over W(D), a 1-D disk or ellipse, and check the m×m matrix R(hzB). This is cheap even for 5×5 Euler flux Jacobians.

## Key Takeaways
1. Convection, inflow BCs and overset interpolation make discretization matrices non-normal: eigenvalue-based stability and convergence estimates can be wrong by orders of magnitude (1e46 in the example above).
2. Crouzeix: ‖f(A)‖ ≤ 2 max_{W(A)} |f|. This gives dimension-free GMRES bounds and n-uniform time-stepping bounds from the numerical range alone.
3. The time-stepping criterion is hW(A) ⊆ stability region, which gives ‖Rⁿ‖ ≤ 2. The upwind example shows it recovers the true CFL limit where the eigenvalue test fails.
4. Compute W with Johnson's rotating-Hermitian-part algorithm, matvec-only. Certify with the outer polygon.
5. For e^{tA}, use the numerical abscissa ω (Lumer–Phillips) directly. Crouzeix helps for polynomial and rational schemes and for Krylov approximation errors.

## Connects To
- **Ch 04 (Conditioning)**: eigenvalue ill-conditioning ⇔ non-normality, and the departure from normality drives both.
- **Ch 05 (Time-stepping)**: absolute-stability regions are tested against hW(A), not just the spectrum.
- **Ch 06 (PDEs)**: CFL for non-periodic and convection-dominated discretizations.
- **Ch 08 (Krylov)**: GMRES convergence theory beyond eigenvalues, and the goals of preconditioning.
