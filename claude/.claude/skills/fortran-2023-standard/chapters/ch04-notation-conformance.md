# Chapter 4 (Clause 4): Notation, conformance, and compatibility

## Core Idea
Defines the **BNF notation** used for every syntax rule, the precise meaning of **standard-conforming** (for both programs and processors), and the **backward-compatibility deltas** against every prior Fortran standard. This is the clause that tells you how to *read* the rest of the document and what "conforming" actually obligates.

## Frameworks Introduced
- **Syntax rule numbering Rsnn**: `s` = clause number (1–2 digits), `nn` = sequence within clause. Rules in Clauses 5–6 may be repeated in a later clause `s` where fully described. Rules are **not** a complete parser grammar — constraints + prose complete them.
  - Metasymbols: `is` (defines a class), `or` (alternative), `[ ]` (optional), `[ ] ...` (zero-or-more repeat).
- **Constraint numbering Csnn**: a requirement a conforming **processor must be able to detect and report**. A constraint annotated `(Rxxx)` is part of that rule's definition and applies everywhere the term appears. Unannotated constraints act like prose restrictions but with the detect/report obligation.
  - When to use: the broad requirement may be in prose, with a *subset* restated as a constraint — the program must obey the prose; the processor need only diagnose the constraint.
- **Assumed syntax rules**: `R401 xyz-list is xyz [, xyz]...`, `R402 xyz-name is name`, `R403 scalar-xyz is xyz` (+ C401: scalar-xyz shall be scalar). An explicit rule overrides the assumed one.

## Key Concepts
- **standard-conforming program**: uses only forms/relationships described herein and has an interpretation per the document.
- **standard-conforming processor**: executes conforming programs correctly AND has the *capability* to detect+report the 10 enumerated violation classes (obsolescent use, non-permitted forms incl. deleted features, unsupported kinds, bad source form, scope violations, nonstandard intrinsics/modules, etc.).
- **processor-dependent**: semantics the standard deliberately leaves to the processor; must be *provided*, not necessarily *specified* (catalogue in Annex A / ch20).
- **obsolescent feature**: redundant since F90/F95, still common, printed in *smaller type*; a future revision may delete it.
- **deleted feature**: removed entirely (Annex B / ch21).

## Reference Tables

### Prior editions (Table 4.3)
| Designation | Informal name |
|---|---|
| ISO R 1539-1972 | Fortran 66 |
| ISO 1539-1980 | Fortran 77 |
| ISO/IEC 1539:1991 | Fortran 90 |
| ISO/IEC 1539-1:1997 | Fortran 95 |
| ISO/IEC 1539-1:2004 | Fortran 2003 |
| ISO/IEC 1539-1:2010 | Fortran 2008 |
| ISO/IEC 1539-1:2018 | Fortran 2018 |

### F2023 vs F2018 — incompatibilities that bite (4.3.3)
| Area | F2018 allowed | F2023 requires |
|---|---|---|
| `SYSTEM_CLOCK` | integer args of any kind | args ≥ default-int exponent range; **all integer args same kind** |
| BLOCK + DATA | use a DATA-only variable *before* its DATA stmt | not permitted |
| `ASSOCIATED(P,T)` | POINTER/TARGET of different rank | same rank required |
| `IEEE_MAX_NUM` etc. w/ number+sNaN | result is NaN | result is the **number** |

## Worked Example
Reading a rule + constraint together — the name rule:
```
R603  name  is  letter [ alphanumeric-character ] ...
C601  (R603) The maximum length of a name is 63 characters.
```
R603 says a name is a letter optionally followed by letters/digits/underscores. R603 alone permits arbitrary length; **C601 restricts it to 63 characters** and, being annotated `(R603)`, applies *everywhere* `name` appears. A conforming processor must diagnose a 64-character name. This is the rule+constraint pairing pattern you apply throughout the document.

## Anti-patterns
- **Treating the BNF as a complete grammar**: it isn't — you *cannot* auto-generate a Fortran parser from R-rules alone; constraints and prose are load-bearing.
- **Assuming upward compatibility is total**: F2023 is *mostly* upward-compatible from F2018, but the 4.3.3 list (esp. `SYSTEM_CLOCK` same-kind rule) breaks real code — see `feedback_gpu_benchmark_timing`-style timing code.
- **Ignoring obsolescent type-size cues**: the smaller font is normative signal, not typography.

## Key Takeaways
1. `Rsnn` = syntax rule, `Csnn` = detectable constraint; a `(Rxxx)`-annotated constraint is part of that rule everywhere.
2. "Conforming processor" = correct execution **plus** capability to detect+report 10 violation classes — diagnosis is mandated, not optional.
3. F2023 is upward-compatible from F2018 *except* the 4.3.3 list — the `SYSTEM_CLOCK` "all integer args same kind" rule is the most likely to break existing timing code.
4. Obsolescent (smaller font) ≠ deleted (Annex B); obsolescent still works, deleted does not.
5. Processor-dependent behavior must be *documented* by the processor; it is intentionally unspecified here.

## Connects To
- **Ch 1**: Scope — the detect/report duties referenced from item lists.
- **Ch 20 (Annex A)**: full processor-dependency catalogue.
- **Ch 21 (Annex B)**: the deleted features this clause references.
