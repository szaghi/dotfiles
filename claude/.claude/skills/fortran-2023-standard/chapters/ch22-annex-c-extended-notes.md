# Chapter 22 (Annex C, informative): Extended notes

## Core Idea
Informative, tutorial-style explanations and worked examples for the harder normative clauses, plus **C.1's consolidated list of what was new in Fortran 2018** — the single best map of the F2018 feature set (which, with the F2023 deltas elsewhere, defines "modern Fortran").

## What was new in Fortran 2018 (C.1) — the modern-feature inventory
- **Data / computation**: COMMON/EQUIVALENCE/block-data made obsolescent; **FORALL** made obsolescent; **SELECT RANK** for assumed-rank arrays; implied-DO variable type/kind specifiable in constructors; IEEE-aware `<`/`<=`/`>`/`>=` are *signaling* compares, `==`/`/=` are *quiet*.
- **I/O**: `SIZE=` on advancing input; a file may be open on more than one unit; `G0.d` for integer/logical/character; zero field width for `D/E/EN/ES` and zero exponent width; **`EX`** hex-significand output; hex-significand FP input.
- **Execution control**: **arithmetic IF deleted**; labeled DO obsolescent; nonblock DO deleted; **DO CONCURRENT locality** specifiable; **nonconstant stop codes**; controllable stop-code/exception-summary output.
- **Intrinsics**: `CMPLX` needs no KIND keyword for complex arg; `DIM` may be a present optional dummy in reductions; new **`COSHAPE`**, **`OUT_OF_RANGE`**, **`REDUCE`**, **`RANDOM_INIT`**; most integer/logical intrinsic args freed from default-kind requirement; specific intrinsic names obsolescent; most `ISO_C_BINDING` procedures pure; `SIGN` args may differ in kind.
- **Program units / procedures**: **`IMPORT`** usable in contained subprograms/BLOCK with restriction; the **`GENERIC` statement**; argument *count* used in generic resolution; separate control of default accessibility for accessed vs declared entities; `IMPLICIT NONE (EXTERNAL)`; recursion is the **default** (`RECURSIVE` advisory; `NON_RECURSIVE` to forbid); `ERROR STOP` allowed in pure subprograms.
- **From TS 29113 (assumed-rank/type interop)**: **assumed-rank `a(..)`** and **assumed-type `TYPE(*)`** dummies; interoperable procedures with allocatable/assumed-shape/optional/pointer dummies; `C_LOC`/`C_F_POINTER`/`C_FUNLOC` on noninteroperable entities; new **`C_PTRDIFF_T`**.
- **IEEE (60559:2020 conformance)**: new rounding mode **`IEEE_AWAY`**; new `IEEE_MODES_TYPE`; expanded IEEE procedures (`IEEE_FMA`, `IEEE_MAX/MIN` family, `IEEE_INT`, `IEEE_SIGNBIT`, …).

## Selected clause notes worth knowing (C.3–C.10)
- **C.3.6 Final subroutines**: finalization semantics, ordering caveats (order is processor-dependent — see ch20).
- **C.4 VOLATILE**: when the optimizer must reload (memory-mapped / async-modified data).
- **C.7 DO CONCURRENT**: valid vs invalid examples; coarray team/event examples; failed-image-tolerant patterns.
- **C.10.2 Dependent compilation**: how modules create build dependencies — the rationale for **submodules** (ch14) to cut recompilation cascades.

## Mental Models
- "Modern Fortran" ≈ **F2018 (C.1 list) + the F2023 deltas** scattered through the other chapters (conditional expressions, SIMPLE, enum types, TYPEOF/CLASSOF, REDUCE locality, SPLIT/TOKENIZE, AT/LZ descriptors). Use C.1 as the F2018 baseline and the per-chapter "F2023" callouts as the increment.
- Annex C is the **why**, not the **what** — read it when a normative rule's intent is unclear, or for a worked example of a construct.

## Anti-patterns
- **Treating Annex C as normative**: it's informative — the binding rules are in Clauses 1–19. Use C for intent and examples only.
- **Ignoring C.10.2 on dependent compilation**: not understanding module→user build dependencies leads to giant rebuilds; submodules are the fix.

## Key Takeaways
1. **C.1 is the F2018 feature inventory** — the baseline of "modern Fortran"; combine with the F2023 per-chapter callouts for the full modern set.
2. Recursion became the default in F2018 (`RECURSIVE` advisory; `NON_RECURSIVE` to forbid).
3. The `GENERIC` statement, `IMPLICIT NONE (EXTERNAL)`, and argument-count-in-generic-resolution are F2018 ergonomics worth adopting.
4. Annex C is informative (intent + examples), not normative — defer to Clauses 1–19 for binding rules.
5. C.10.2 explains module build dependencies — the rationale for submodules.

## Connects To
- **Ch 4**: Conformance — F2018/F2008 compatibility deltas (the normative complement to C.1).
- **All chapters**: C is the cross-cutting "why/example" companion to the normative clauses.
- **cheatsheet.md**: the consolidated F2023+F2018 new-feature table.
