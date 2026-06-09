# Chapter 12: N-Body & Monte Carlo Methods

## Core Idea
Two important problem classes round out scientific computing. **N-body problems** (every particle interacts with every other) are naively O(N²) but reduced to O(N log N) or O(N) by exploiting spatial structure — cutoffs, cell lists, and tree codes. **Monte Carlo methods** trade determinism for statistical sampling, turning high-dimensional integration into random sampling whose error shrinks as 1/√N.

## Frameworks Introduced

- **N-body / particle methods** (molecular dynamics, gravitation):
  - Each of N particles exerts a force on every other (Coulomb, gravity, Lennard-Jones); compute forces, then integrate motion (`F = ma`, with a time integrator from Ch 5, e.g. Verlet).
  - **Naive cost: O(N²)** — all pairs. The whole game is reducing it:
    - **Cutoff + cell lists**: short-range forces vanish beyond a cutoff `r_c`; bin particles into a spatial grid (cells ≥ `r_c`) so each particle only checks neighboring cells → **O(N)** for short-range. Cell lists must be rebuilt as particles move.
    - **Tree codes (Barnes-Hut)**: approximate a distant *cluster* of particles by its center of mass → **O(N log N)** for long-range forces.
    - **Fast Multipole Method (FMM)**: multipole expansions of far-field interactions → **O(N)** even for long-range. The asymptotically optimal N-body method.
  - The force matrix (all-pairs) is dense and **skew-symmetric** (`Fᵢⱼ = −Fⱼᵢ`) — Newton's third law halves the work.

- **Monte Carlo methods** (sampling instead of solving):
  - Estimate an integral/expectation by **random sampling**: average the integrand over random points. The error decreases as **1/√N** *independent of dimension* — which is why Monte Carlo dominates high-dimensional integration where grid methods suffer the curse of dimensionality.
  - **Variance reduction** (importance sampling, stratification, control variates) lowers the constant in the 1/√N error — the main efficiency lever, since the √N rate itself is fixed.
  - Embarrassingly parallel: independent samples → trivial parallelism (functional parallelism), but requires a good **parallel random number generator** (independent, reproducible streams).

## Key Concepts
- **Exploit spatial structure to beat O(N²)**: cutoffs and trees turn the all-pairs sum into near-linear work — the defining technique of scalable particle simulation.
- **The 1/√N curse and blessing**: Monte Carlo's error is slow (halving error needs 4× samples) but *dimension-independent* — a blessing in high dimensions, a curse for low-dimensional smooth integrands (where quadrature wins).
- **Newton's third law**: the force matrix is skew-symmetric, so computing `Fᵢⱼ` gives `Fⱼᵢ` for free — halving the all-pairs work.
- **Parallel RNG correctness**: parallel Monte Carlo needs streams that are independent across processes and reproducible — a naively seeded per-process RNG can produce correlated streams (a correctness bug, not just a quality issue).

## Mental Models
- **Never compute N-body naively at scale** — the O(N²) all-pairs sum is intractable for large N; use cutoffs + cell lists (short-range, O(N)) or tree codes/FMM (long-range, O(N log N)/O(N)). Exploiting spatial locality is the whole point.
- **Monte Carlo for high-dimensional integration** — when grid/quadrature methods drown in the curse of dimensionality, random sampling's dimension-independent 1/√N error wins; lower the constant with variance reduction.
- **Monte Carlo is embarrassingly parallel — if the RNG is right** — independent samples parallelize trivially, but you must give each process an independent, reproducible random stream.
- **Use the physics to cut work** — Newton's third law (skew-symmetric forces), force cutoffs, and far-field approximations all exploit problem structure to reduce the operation count.

## Reference Tables

| N-body method | Cost | Use |
|---|---|---|
| naive all-pairs | O(N²) | small N, reference |
| cutoff + cell lists | O(N) | short-range forces |
| Barnes-Hut tree | O(N log N) | long-range forces |
| Fast Multipole (FMM) | O(N) | long-range, optimal |

| Monte Carlo property | Implication |
|---|---|
| error ∝ 1/√N | dimension-independent; slow rate |
| variance reduction | lowers the constant, not the rate |
| independent samples | embarrassingly parallel |
| parallel RNG | needs independent reproducible streams |

## Key Takeaways
1. N-body problems are naively O(N²) (all pairs); reduce with cutoffs + cell lists (O(N) short-range) or tree codes/FMM (O(N log N)/O(N) long-range).
2. Exploit problem structure: Newton's third law makes the force matrix skew-symmetric (half the work); spatial locality enables cell lists.
3. Monte Carlo estimates integrals by random sampling with **1/√N error, independent of dimension** — the method of choice for high-dimensional integration.
4. Variance reduction (importance sampling, stratification) lowers the error constant; the √N rate itself is fixed.
5. Monte Carlo is embarrassingly parallel but requires independent, reproducible parallel random-number streams — a correctness requirement, not just quality.

## Connects To
- **Ch 05 (ODEs)**: the time integrator (Verlet) that advances particle motion.
- **Ch 11 (Combinatorial)**: spatial data structures (cell lists, trees) and irregular access.
- **Ch 02 (Architecture)**: particle methods' irregular memory access and locality concerns.
- **Ch 03 (Arithmetic)**: long force sums need careful summation order (reproducibility).
