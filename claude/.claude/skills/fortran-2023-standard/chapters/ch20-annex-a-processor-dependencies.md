# Chapter 20 (Annex A, informative): Processor dependencies

## Core Idea
The consolidated list of everything the standard **deliberately leaves to the processor** — the portability-hazard catalogue. If portable behavior matters, every item here is a place where two conforming compilers may legitimately differ.

## Key Concepts (the hazards that bite HPC code)
- **Unspecified (A.1)**: the Clause-1 exclusions; error-detection beyond 4.2; which *extra* intrinsics/modules exist; number/kind of companion processors. Guaranteed only: ≥2 real representation methods, and a complex method per real method.
- **Processor-dependent (A.2)** — high-impact selections:
  - **Order of evaluation of specification expressions** in a procedure's spec part.
  - **The set of values of each intrinsic type** (except logical) and **which kinds exist** — never assume `real(16)`/`int(16)` is available; query.
  - **Result kind of mixed-kind binary operations** when ranges/precisions tie (10.1.9.3) — mixed-kind arithmetic result kind is *not* fully pinned.
  - **Finalization order** of components / of multiple objects finalized by one event; whether a pointer-allocated object is finalized when it becomes unreachable.
  - **Whether an array is contiguous** (except as forced by CONTIGUOUS, 8.5.7).
  - **ALLOCATE/DEALLOCATE error condition set**, **STAT values**, **ERRMSG text**, and **deallocation order** of multiple objects.
  - **Image failure**: what causes it, whether it's detectable, the value of a coindexed object on a failed image, how fast other images terminate.
  - **Process exit status** support and value.
  - **Collating sequence**, **blank padding char for nondefault character kinds**, **source-form selection mechanism**, **max statement labels**, **include nesting depth**.

## Mental Models
- Treat Annex A as the **"do not rely on this for portability" index**. When a result differs between compilers, check here first — it's usually a sanctioned divergence, not a bug.
- For reproducible numerics across processors, the dangerous items are: mixed-kind result kind, evaluation order of spec expressions, and contiguity assumptions — pin them explicitly (kinds via `ISO_FORTRAN_ENV`, order via parentheses, contiguity via CONTIGUOUS).

## Anti-patterns
- **Assuming a kind exists** (`real(16)`): query `SELECTED_REAL_KIND`/`IEEE_SUPPORT_DATATYPE` — kind availability is processor-dependent.
- **Relying on finalization order**: it's unspecified for sibling components and multi-object events — never sequence side effects through finalizers.
- **Depending on a specific STAT/ERRMSG value**: only zero-vs-nonzero is portable; the positive codes and message text are processor-dependent.
- **Assuming mixed-kind arithmetic picks "the bigger kind"**: when ranges/precisions tie, the result kind is processor-dependent — convert explicitly.
- **Treating a strided section as contiguous**: contiguity is processor-dependent unless CONTIGUOUS forces it.

## Key Takeaways
1. Annex A is the portability-hazard index — sanctioned divergences, not bugs.
2. Kind availability, mixed-kind result kind, contiguity, finalization order, and STAT/ERRMSG specifics are all processor-dependent.
3. Pin numerics explicitly: kinds from `ISO_FORTRAN_ENV`, evaluation order via parentheses, contiguity via CONTIGUOUS.
4. Image-failure semantics are largely processor-dependent — handle via STAT= and the `STAT_FAILED_IMAGE` constant, don't assume detection.

## Connects To
- **Ch 1 & 4**: Scope/conformance — the source of "processor-dependent" as a category.
- **Ch 17**: IEEE — `IEEE_SUPPORT_*` queries cover the FP processor-dependencies.
- **Ch 7 / 16**: Types/intrinsics — kind selection in the face of processor-dependent kinds.
