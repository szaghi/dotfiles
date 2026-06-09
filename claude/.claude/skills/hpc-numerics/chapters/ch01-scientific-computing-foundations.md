# Chapter 1: The Science of Scientific Computing

## Core Idea
Scientific computing sits at the intersection of three disciplines: **modeling** a scientific process, the **numerical mathematics** that turns the model into a computable algorithm, and the **computer architecture** the algorithm runs on. You cannot be good at the field by mastering only one — efficiency demands reasoning across all three at once.

## Frameworks Introduced

- **The three branches** (the lens for every problem):
  1. **Modeling** — translating a physical/scientific process into mathematics (usually differential equations or an optimization/combinatorial problem).
  2. **Numerical mathematics** — turning continuous math into a finite, computable algorithm (discretization, linear algebra, error analysis). Because we compute in finite bit-strings, not real numbers, *accuracy must be analyzed*.
  3. **Computing** — implementing the algorithm efficiently on *actually existing* hardware (memory hierarchy, parallelism), not a hypothetical machine.
  - When to use: when a computation is slow or wrong, diagnose which branch is the cause — a bad model, an unstable algorithm, or an architecture-hostile implementation.

- **The constructive-mathematics shift**: scientific computing requires *constructive* solutions — not merely proving a solution exists, but producing it (and "preferably yesterday"). Efficiency of both the algorithm and its implementation is a first-class concern, not an afterthought.

- **The continuous-to-discrete pipeline** (the recurring workflow): continuous model → discretized equations → (usually) a linear-algebra problem (matrix-vector, linear system, eigenvalue) → implemented on parallel hardware. Most application problems funnel into **numerical linear algebra**, which is why it dominates HPC.

## Key Concepts
- **Finite precision is fundamental**: computing happens in finite bit-string representations, so round-off and its accumulation are intrinsic — accuracy analysis predates and underpins everything (Ch 3–4).
- **Efficiency is twofold**: algorithmic efficiency (operation count, convergence rate) *and* implementation efficiency (locality, parallelism). A good algorithm implemented architecture-blind can lose to a worse one that respects the hardware.
- **Linear algebra is the common substrate**: PDEs, optimization, graph problems, and data analysis all reduce to matrix/vector operations — master numerical linear algebra and you have leverage over most of the field.
- **Theory vs practice**: this knowledge base covers the *theory* — the algorithms, their error/stability properties, and performance models. The mechanics of MPI/OpenMP/CUDA implementation are separate concerns (see the parallel-programming skills).

## Mental Models
- **Reason across all three branches simultaneously** — a "numerical bug" is often a modeling error or an architecture mismatch in disguise; diagnose by asking which branch failed.
- **Everything becomes linear algebra** — when facing a new application, ask "what matrix/vector problem does this reduce to?" — it usually does, and the numerical-LA toolkit applies.
- **Efficiency is a requirement, not a luxury** — in scientific computing you actually need the answer, fast; design algorithms and implementations with operation count *and* locality in mind from the start.
- **Finite precision is always in play** — never reason as if you compute in real numbers; round-off, conditioning, and stability shape which algorithms are usable.

## Reference Tables

| Branch | Question it answers | Failure mode |
|---|---|---|
| Modeling | Is the math the right model? | wrong physics/equations |
| Numerical math | Is the algorithm accurate & stable? | instability, ill-conditioning |
| Computing | Is the implementation efficient? | poor locality, no parallelism |

| Stage | Output |
|---|---|
| continuous model | differential/optimization problem |
| discretization | algebraic equations |
| numerical LA | matrix/vector problem |
| implementation | parallel/cache-aware code |

## Key Takeaways
1. Scientific computing is the intersection of modeling, numerical mathematics, and computer architecture — competence requires all three.
2. The recurring pipeline is continuous model → discretization → numerical linear algebra → efficient implementation.
3. Computation in finite precision makes round-off and accuracy analysis fundamental, not optional.
4. Efficiency is twofold — algorithmic (operations, convergence) and implementation (locality, parallelism) — and both matter from the start.
5. Most application problems reduce to numerical linear algebra, the field's common substrate.

## Connects To
- **Ch 02 (Architecture)**: the "computing" branch — memory hierarchy and performance.
- **Ch 03–04 (Arithmetic & stability)**: why finite precision shapes algorithm choice.
- **Ch 07 (Numerical LA)**: the common substrate most problems reduce to.
- **Ch 09 (Performance)**: implementation efficiency and the roofline model.
