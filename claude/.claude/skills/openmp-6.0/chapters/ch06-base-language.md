# Chapter 6: Base Language Formats and Restrictions

## Core Idea
How OpenMP binds to each base language (C, C++, Fortran) — the structured-block rules, the canonical loop-nest form that worksharing/SIMD/loop constructs require, and the language-specific restrictions. The contract for *what code a directive may legally be attached to*.

## Frameworks Introduced
- **structured block**: a single statement or block with one entry at the top and one exit at the bottom (no branching in/out except via OpenMP cancellation/`exit`-equivalent). Most constructs apply to a structured block.
- **canonical loop nest** (the form `for`/`do` loops must take to be parallelized):
  - loop variable of integer (or C++ random-access iterator / pointer) type,
  - bounds and stride **loop-invariant** within the construct,
  - test is a relational operator, increment is `++`/`+=`/etc. — so the **iteration count is computable on entry**.
  - `collapse(n)` requires the outer `n` loops to be **perfectly** (rectangular or, in 6.0, certain non-rectangular) nested.
- **loop-iteration vs logical-iteration space**: constructs operate on *logical* iterations (the computed sequence), decoupled from the source loop form.
- **Base-language data environment rules**: how C/C++/Fortran scoping interacts with `shared`/`private` (e.g. Fortran `COMMON`, C `static`, C++ references and lambdas).

## Key Concepts
- **C/C++ vs Fortran binding**: directives are pragmas (C/C++) or comment sentinels (Fortran); the *associated* code must meet the structured-block / canonical-loop rules either way.
- **Fortran specifics**: `!$omp` on `DO`/`DO CONCURRENT`; `workshare` for array-syntax; module/COMMON variable sharing; assumed-shape array handling under `map`.
- **C++ specifics**: random-access iterators in canonical loops, lambda captures interacting with data-sharing, exceptions across regions (restricted), reference members.
- **threadprivate** and storage duration: how static/global storage maps to per-thread copies.

## Anti-patterns
- **Putting a `break`/`goto`/`return` out of a structured block**: illegal — a worksharing/parallel structured block has one entry, one exit (cancellation aside).
- **Non-canonical loops under worksharing/`simd`**: variable bounds inside the loop, non-integer/non-iterator counters, or a `while` loop can't be a parallelized loop nest — restructure to canonical form.
- **`collapse(n)` over non-perfectly-nested loops**: code between the loops (outside the innermost body) breaks collapse (with limited 6.0 non-rectangular allowances).
- **Relying on C++ exception propagation out of a parallel region**: heavily restricted; don't throw across the region boundary.

## Key Takeaways
1. Most constructs attach to a **structured block** (one entry, one exit) — no branching out.
2. Worksharing/`simd`/`loop` need a **canonical loop nest**: integer/iterator counter, loop-invariant bounds/stride, computable trip count.
3. `collapse(n)` requires (near-)perfect nesting of the outer n loops.
4. Base-language scoping (Fortran COMMON/module, C static, C++ references/lambdas) interacts with data-sharing attributes — know the per-language rules.
5. The directive operates on the *logical* iteration space, not the source loop form.

## Connects To
- **Ch 13**: worksharing-loop and `distribute` rely on the canonical loop nest.
- **Ch 11**: loop-transforming constructs reshape the canonical nest.
- **Ch 7**: data-sharing interacts with base-language storage/scoping.
- **fortran-2023-standard**: the Fortran base-language rules OpenMP binds to (DO CONCURRENT, modules, COMMON).
