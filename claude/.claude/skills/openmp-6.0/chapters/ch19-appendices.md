# Chapter 19 (Appendices A–D)

## Core Idea
Reference material: what's left implementation-defined (the portability-hazard list), the version-by-version feature history, region-nesting legality, and the canonical compound-directive forms.

## Key Concepts
- **Appendix A — Implementation-Defined Behaviors**: the consolidated list of everything OpenMP leaves to the implementation (analogous to OpenACC's processor-dependencies / Fortran's Annex A). Includes: default thread count, default schedule, what memory spaces actually map to, device-number assignment, `omp_get_wtick` resolution, behavior when offload target is unavailable, lock fairness, etc. **For portability, treat every item here as "don't rely on a specific value."**
- **Appendix B — Features History**: what changed across versions. 6.0 highlights (vs 5.2): the `loop`-transforming constructs + `apply`, `taskgraph`/`replayable`, free-agent threads, `safesync`, expanded memory-allocator/memspace APIs, `groupprivate`, improved `metadirective`, device-UID routines, `assume` extensions. Earlier moves: stubs/interface declarations/examples/C++ grammar moved to *separate* documents (no longer appendices).
- **Appendix C — Nesting of Regions**: the legality table for nesting constructs (e.g. a worksharing region must not be closely nested in another worksharing/`critical`/`atomic`/`master` region; `barrier` nesting rules; `ordered` requires an enclosing `ordered`-clause loop). The authority on "can construct X be nested in Y."
- **Appendix D — Conforming Compound Directives**: the legal combined/composite directive forms (e.g. `parallel for`, `target teams distribute parallel for simd`) and how clauses distribute across their leaf constructs.

## Mental Models
- **Appendix A is the portability index**: when behavior differs between compilers (GCC libgomp vs LLVM vs NVHPC), check here — it's likely sanctioned, not a bug.
- **Appendix C is the nesting-legality oracle**: before nesting constructs, confirm it's permitted (closely-nested worksharing is the classic illegal case).
- **Appendix B answers "is feature X in 6.0 or earlier?"** — useful when targeting a compiler that supports only 5.x.

## Anti-patterns
- **Relying on a default schedule / thread count**: implementation-defined (Appendix A) — set `OMP_SCHEDULE`/`OMP_NUM_THREADS` explicitly.
- **Closely nesting two worksharing constructs**: illegal (Appendix C) — separate them with a `parallel` region or restructure.
- **Assuming a 6.0 feature works on a 5.2 compiler**: check Appendix B and the compiler's support matrix.
- **Looking for stub/interface/example code in the spec**: moved to separate documents — not in this PDF.

## Key Takeaways
1. **Appendix A** = implementation-defined behaviors → the portability-hazard list; set defaults explicitly.
2. **Appendix B** = feature history; confirms which version introduced a feature (6.0 adds loop-transform `apply`, `taskgraph`, free-agent threads, `safesync`).
3. **Appendix C** = region-nesting legality (closely-nested worksharing is forbidden).
4. **Appendix D** = conforming compound directives and clause distribution.
5. Stubs, interface declarations, examples, and grammar are now *separate* documents, not appendices.

## Connects To
- **Ch 3/4**: implementation-defined defaults set via ICVs/env vars.
- **Ch 13**: worksharing nesting rules (Appendix C).
- **Ch 12/15**: compound directives like `target teams distribute parallel for` (Appendix D).
- **openacc-3.4 ch20 / fortran-2023-standard ch20**: the analogous implementation-/processor-dependency catalogues.
