# 2026 AI-math results: triage for CFD / HPC

Snapshot: **2026-10-07**. Sources:
- `github.com/openai/math` @ adc7f12 (2026-10-06)
- openai.com/index/sharing-ai-progress-in-mathematics (2026-10-06)
- openai.com/index/navier-stokes-solution (2026-09-08)

Re-check before citing: the repo versions its corrections, and none of this is refereed.

## Release facts
- Model: unreleased internal OpenAI model. About 3 h of "ChatGPT Pro thinking" compute per result, about 4,000 problems posed, **722 manuscripts / 372 families**. Exceptions to the fixed procedure: zeta zero-free region (human-edited write-up) and Hodge for CM abelian varieties.
- Lean library: v4.34.1 plus Mathlib and about 20 patched dependencies.
  - Scope notes exist for 235 families (`lean/docs/NNN.md`), and there are 405 Comparator challenges.
  - The catalogue says `automation: agent`, `review.status: unchecked`.
  - The formalization often covers a *selected* statement only, so read the scope note.
- Building the whole library can hit `vm.max_map_count`. Build parts, or use `-DMMAP=OFF` / `GLIBC_TUNABLES=glibc.malloc.mmap_max=0:glibc.malloc.arena_max=1`.
- Reasoning traces (10 families) are abridged summaries showing:
  - prompts engineered as specs listing forbidden shortcuts
  - reduction to a known criterion, with most effort spent on hypothesis matching
  - mass exploration of dead ends
  - counterexample hunting before proof
  - essentially no numerical experiments (discouraged by the prompts)

## Triage (relevance to CFD/HPC, highest first)

| Family / result | Statement (short) | Tier | Practical takeaway |
|---|---|---|---|
| **325 Complete Crouzeix** | ‖f(A)‖ ≤ 2 max_{W(A)} \|f\|, matrix-valued f, Hilbert operators; optimal similarity with κ ≤ 2 | preprints + Lean (4 challenges) | **Yes**, via the framework: GMRES bounds and ‖R(hA)ⁿ‖ ≤ 2 from hW(A) ⊆ stability region. Over 1+√2 (2017), only the constant improves. → `hpc-numerics` ch13 |
| **NS blowup (Sept release, separate)** | Smooth finite-energy forced 3-D incompressible NS from rest develops a finite-time singularity (claims Fefferman (C)/(D)); 166-page proof + Lean; about 10k agents over 88 h | Lean claimed; **Clay has not ruled**; statement fidelity under community review | **Conceptual**. Smooth *forced* NS can lose regularity, so "DNS converges to a smooth solution" is no longer a theorem for arbitrary smooth forcing. It says nothing about unforced or generic turbulence, and nothing about LES/RANS practice. Watch for the singular profile (inward-spiralling, elongating vortex) as a stress test for under-resolved codes and BKM-type (∫‖ω‖∞dt) diagnostics. Related: forced-Euler blowup by Alpöge–Buckmaster (Anthropic model), github.com/tristanbuckmaster/fluid_lean |
| 376 Universal computation in forced NS | Designed smooth forcing makes a fluid particle's entry into a box equivalent to Turing halting (T³ and R³, any computable ν > 0) | partial Lean | None for solvers. Exact-arithmetic encoding; papers disclaim robustness under perturbation or finite precision. At most a citation: "Lagrangian reachability under arbitrary forcing is undecidable" |
| 363 Boltzmann nonuniqueness | Two distinct entropy solutions with exact local conservation from the same rough (non-Maxwellian-bounded) datum | Lean covers only the weaker Sept version | Entropy plus conservation does not select a solution for singular data. DSMC/DVM/LBM run on bounded data (uniqueness regime). Keep V&V data Maxwellian-bounded |
| 364 Kinetic limits | Boltzmann derived from Newtonian particles (attractive wells allowed) over the whole regular lifespan; fluctuating Boltzmann CLT | no Lean | Citation that DSMC targets the right equation, including fluctuations; no rates |
| 362 Relativistic Vlasov–Maxwell | Global smooth solutions for large data (Glassey–Strauss, open since 1986) | **full Lean** | The PIC target exists for all time. The bound is doubly exponential and useless for sizing runs |
| 374 Brenier stability | ‖T_μ − T_ν‖ ≤ C W₂^{1/3}, exponent sharp | Lean | OT/Monge–Ampère mesh redistribution: map is only cube-root stable under target perturbations |
| 107 / 130 / 109 | ω ≤ 9/4; exact DFT in O(n (log n)^{1−δ}), δ = 1e−13; integer multiplication below n log n | 107, 130 Lean | **None.** Galactic algorithms: constants and exponents (δ = 1e−13, κ = 2^{−182}) never pay off. FFTW/cuFFT/BLAS practice is unchanged |
| 369, 372, 360 | hot spots; elastic Calderón; weak-MTW OT | Lean | none for CFD |

**Not in the collection:** Euler/NS regularity *numerics*, shocks, turbulence, finite-volume or numerical-analysis families. The grep found only false positives: "Euler products", "numerical dimension", "hyperbolic groups".

## book-to-skill verdict
Not worth running on this corpus. It is 722 pure-math manuscripts with under 1 % CFD-adjacent content, and book-to-skill extracts one author's frameworks from one coherent text. Even the Crouzeix papers would yield proof machinery, not usable numerics. Hand-distilling into `hpc-numerics` ch13 plus this file is the efficient path. Revisit if a *textbook* on non-normal operators appears in the library (Trefethen–Embree, *Spectra and Pseudospectra*, 2005). That would be a good book-to-skill target to deepen ch13.
