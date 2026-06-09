# Chapter 5: ODEs & Time-Stepping — Discretization & Stability

## Core Idea
Initial Value Problems (`u' = f(t,u)`, `u(0) = u₀`) are solved by **discretizing time** into steps and replacing the derivative with a finite difference. The central trade-off is **explicit vs implicit** methods: explicit is cheap per step but only **conditionally stable** (the step size is capped); implicit costs a solve per step but is **unconditionally stable**.

## Frameworks Introduced

- **Finite-difference discretization**: approximate `u'(t) ≈ (u(t+Δt) − u(t))/Δt`. This turns the continuous ODE into a recurrence for discrete `uₖ ≈ u(tₖ)`. The approximation has a **truncation error** that → 0 as Δt → 0.

- **Explicit (forward) Euler**: `uₖ₊₁ = uₖ + Δt·f(tₖ, uₖ)`.
  - Cheap: just evaluate `f` at the known point.
  - **Conditionally stable**: for the test equation `u' = −λu` (λ > 0, a decaying/stable problem), the numerical solution only stays bounded if **Δt is small enough** (`Δt < 2/λ`). Too large a step → the numerical solution oscillates and blows up even though the true solution decays.

- **Implicit (backward) Euler**: `uₖ₊₁ = uₖ + Δt·f(tₖ₊₁, uₖ₊₁)`.
  - The unknown appears on both sides → requires *solving an equation* (a linear/nonlinear system) each step.
  - **Unconditionally stable**: for `u' = −λu`, `uₖ → 0` for *any* Δt — no step-size restriction. You can take large steps for stiff problems, paying with a solve per step.

- **Order of accuracy**: Euler methods are **first order** (global error ∝ Δt). Higher-order methods (Runge-Kutta, multistep) reduce error faster as Δt shrinks, at more work per step.

## Key Concepts
- **Stable problem vs stable method**: the *continuous* problem `u' = −λu` is stable (perturbations decay) when λ > 0; the *numerical method* adds its own stability condition (the Δt cap for explicit). Both must hold.
- **Conditional vs unconditional stability**: explicit methods cap Δt by the fastest timescale (λ); implicit methods remove the cap. The **region of absolute stability** formalizes which `λΔt` values keep the method bounded.
- **Stiffness**: a problem with widely separated timescales (large λ range) forces explicit methods to tiny Δt (governed by the fastest mode) even when the solution is smooth → implicit methods win decisively for **stiff** problems.
- **Local vs global error**: local (per-step) truncation error accumulates into global error; a first-order *local* scheme typically gives first-order *global* error.

## Mental Models
- **Explicit is cheap-but-capped; implicit is costly-but-unconditional** — choose by stiffness. Non-stiff, smooth problem → explicit with a modest Δt. Stiff problem (separated timescales) → implicit, take big steps, eat the per-step solve.
- **A blowing-up time integration on a decaying problem is a stability violation, not a bug** — your Δt exceeded the explicit method's stability limit; shrink Δt or switch to implicit.
- **Stiffness is the deciding question** — if the fastest mode forces absurdly small explicit steps while you only care about the slow dynamics, go implicit.
- **Higher order buys accuracy per step, not stability** — Runge-Kutta reduces truncation error but explicit RK still has a stability cap; don't confuse accuracy order with stability.

## Code Examples
```text
Test equation:  u' = -λu,  λ > 0   (true solution u(t) = u₀ e^{-λt} → 0)

Explicit Euler:  u_{k+1} = u_k + Δt·(-λ u_k) = (1 - λΔt) u_k
   stable (|1 - λΔt| < 1)  ⟺  Δt < 2/λ        ← CONDITIONAL

Implicit Euler:  u_{k+1} = u_k + Δt·(-λ u_{k+1})  ⟹  u_{k+1} = u_k / (1 + λΔt)
   |1/(1 + λΔt)| < 1  for ALL Δt > 0           ← UNCONDITIONAL

Order: global error ∝ Δt  (first order)
```
- **What it demonstrates**: why explicit Euler caps Δt at 2/λ while implicit Euler is stable for any step.

## Reference Tables

| Method | Cost/step | Stability | Use |
|---|---|---|---|
| explicit (forward) Euler | cheap (eval f) | conditional (Δt < 2/λ) | non-stiff, smooth |
| implicit (backward) Euler | solve per step | unconditional | stiff problems |
| explicit Runge-Kutta | several f evals | conditional, higher order | non-stiff, accuracy |
| implicit RK / BDF | solve per step | strong | stiff, accuracy |

## Key Takeaways
1. Time-stepping discretizes `u' = f(t,u)` with finite differences; truncation error → 0 as Δt → 0.
2. Explicit Euler is cheap but **conditionally stable** (Δt < 2/λ for `u'=−λu`); implicit Euler costs a solve per step but is **unconditionally stable**.
3. Stiffness (widely separated timescales) forces explicit methods to tiny steps — implicit methods win for stiff problems.
4. A decaying problem whose numerical solution blows up means Δt exceeded the explicit stability limit — not a code bug.
5. Higher-order methods (Runge-Kutta, multistep) improve accuracy per step but explicit ones still have a stability cap.

## Connects To
- **Ch 06 (PDEs)**: time-dependent PDEs add spatial discretization; explicit schemes inherit a CFL step-size limit.
- **Ch 04 (Stability)**: this is the time-dependent face of numerical stability.
- **Ch 08 (Iterative solvers)**: implicit methods require solving a system each step.
