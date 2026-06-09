---
name: fortran-2023-standard
description: "Authoritative knowledge base from the ISO/IEC 1539-1:2023 Fortran standard (J3/23-007r1). CONSULT THIS BEFORE ANSWERING — do not answer Fortran-standard questions from memory; the standard's exact rules, constraints (Cxxx), and version deltas are easy to misremember. TRIGGER whenever a question concerns: what the Fortran standard requires/permits/forbids; whether code is standard-conforming; any modern-Fortran feature (conditional expressions, SIMPLE/PURE/ELEMENTAL, enum/enumeration types, TYPEOF/CLASSOF, DO CONCURRENT incl. REDUCE locality, coarrays/teams, C interoperability, IEEE arithmetic); a syntax rule (Rxxx) or constraint (Cxxx); a difference between Fortran versions (F2023/F2018/F2008/F2003/F95/F90); or whether a feature is deleted/obsolescent. SKIP only for pure build/tooling questions (use the fobis skill) or when the user explicitly wants compiler-specific (gfortran/nvfortran/ifx) behavior rather than the standard."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, clause number (e.g. ch07), Rxxx/Cxxx, or feature name]
---

# ISO/IEC 1539-1:2023 — Fortran 2023 (Base Language)
**Source**: J3/23-007r1 working draft (13 Jun 2023) | **Pages**: ~687 | **Chapters**: 22 (19 clauses + Annexes A–C) | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core type/conformance/modern-feature frameworks below.
- **With a topic** — ask about `pointers`, `do concurrent`, `enum`, `intent`, `C interop`, `IEEE`; I read the relevant chapter.
- **With a clause** — ask for `ch07` (Types), `ch15` (Procedures), `ch11` (Execution control), etc.
- **With a rule/constraint** — give an `Rxxx`/`Cxxx` number or feature name; I locate the governing chapter.
- **"What's new in F2023?"** — see Core Frameworks below and `cheatsheet.md`.

When you ask about something not in Core Frameworks, I read the relevant chapter file before answering. This is the normative standard, not a tutorial — answers cite clauses/constraints.

---

## Core Frameworks & Mental Models

### The conformance contract (Ch 4)
- The standard binds **programs**, not processors — a processor's only duty is correct execution **plus** the capability to *detect and report* 10 violation classes (deleted/obsolescent use, bad kinds/source, scope violations, nonstandard intrinsics).
- **`Rsnn`** = BNF syntax rule; **`Csnn`** = a *detectable* constraint. A constraint annotated `(Rxxx)` is part of that rule everywhere it appears. **The BNF is not a complete grammar** — constraints + prose complete it.
- **Processor-dependent** = deliberately unspecified (Annex A / ch20). Don't rely on it for portability.
- F2023 is upward-compatible from F2018 **except** a short list (notably `SYSTEM_CLOCK` now requires all integer args to share kind).

### The type system (Ch 7)
- Five intrinsic types; nonintrinsic = derived / enum / enumeration.
- **Two parameter species**: *kind* (compile-time constant, drives generic resolution) vs *length* (runtime-variable, does not).
- **Declared type vs dynamic type** is the master distinction for polymorphism — resolve dynamic type with `SELECT TYPE` (ch11); `CLASS(t)` polymorphic, `CLASS(*)`/`TYPE(*)` unlimited/assumed-type.

### Purity hierarchy (Ch 15) — strongest contracts win for parallelism
- `PURE` (no side effects) ⊃ **`SIMPLE`** (F2023: result depends *only* on arguments — no use/host/COMMON state). `ELEMENTAL` applies a scalar kernel array-wide and is implicitly pure.
- Modern dummies (assumed-shape/rank, optional, allocatable, pointer, elemental, bind(c)) **require an explicit interface** → keep procedures in **modules**.

### Argument & data discipline (Ch 8, 9, 19)
- **INTENT(OUT)** makes the dummy *undefined on entry* and *deallocates* allocatables — not a value-preserving update; use INTENT(INOUT) for that.
- **Assumed-shape `a(:)` rebases the lower bound to 1** — use explicit bounds `a(lb:ub)` for ghost/halo arrays.
- Prefer **ALLOCATABLE** over POINTER unless aliasing is required.
- A non-SAVE, uninitialized local is **undefined** every entry — not zero.
- Fortran does **not** short-circuit `.AND.`/`.OR.` — never guard-and-access in one logical expression.

### What's new in Fortran 2023 (use these)
- **Conditional expressions** `( cond ? a : b )` — only the chosen branch evaluates (ch10).
- **`SIMPLE`** procedures — referential transparency for parallel/GPU kernels (ch15).
- **Enum types** `ENUM :: t` and **enumeration types** `ENUMERATION TYPE :: t` — real, type-checked, distinct from legacy `ENUM, BIND(C)` integer constants (ch7).
- **`TYPEOF` / `CLASSOF`** — declare an entity mirroring another's type (ch7).
- **`DO CONCURRENT ... REDUCE(op:var)`** — the standard parallel-reduction primitive (ch11).
- **`SPLIT` / `TOKENIZE`** string parsing, **`SELECTED_LOGICAL_KIND`**, circular trig (`SINPI`…) and degree trig (`SIND`…) (ch16).
- **`C_F_STRPOINTER` / `F_C_STRING`** C-string interop (ch18); **`AT`** and **`LZS/LZP/LZ`** edit descriptors (ch13); rank-from-bounds-array `ALLOCATE` (ch9).

### Modern-style defaults (Ch 21 says avoid the rest)
`implicit none` everywhere · `use mod, only:` · kinds from `ISO_FORTRAN_ENV` · procedures in modules, heavy bodies in submodules · free form · `DO CONCURRENT` not FORALL · `SELECT CASE` not computed GOTO · module variables not COMMON/EQUIVALENCE.

---

## Chapter Index

| # | Clause | Title | Key topics |
|---|--------|-------|------------|
| [ch01](chapters/ch01-scope.md) | 1 | Scope | what the standard does/doesn't specify |
| [ch02](chapters/ch02-normative-references.md) | 2 | Normative references | IEEE 60559:2020, ISO 646/10646 |
| [ch03](chapters/ch03-terms-definitions.md) | 3 | Terms and definitions | 243 normative terms; declared/dynamic type |
| [ch04](chapters/ch04-notation-conformance.md) | 4 | Notation, conformance, compatibility | Rxxx/Cxxx, conformance, F-version deltas |
| [ch05](chapters/ch05-fortran-concepts.md) | 5 | Fortran concepts | program-unit hierarchy, statement order |
| [ch06](chapters/ch06-lexical-tokens.md) | 6 | Lexical tokens and source form | names, operators, free form (10k chars) |
| [ch07](chapters/ch07-types.md) | 7 | Types | type params, polymorphism, enums, TYPEOF |
| [ch08](chapters/ch08-attribute-declarations.md) | 8 | Attribute declarations | INTENT, array shapes, ALLOCATABLE/POINTER |
| [ch09](chapters/ch09-data-objects.md) | 9 | Use of data objects | sections, ALLOCATE, coarrays, image selectors |
| [ch10](chapters/ch10-expressions-assignment.md) | 10 | Expressions and assignment | precedence, conditional expr, WHERE/FORALL |
| [ch11](chapters/ch11-execution-control.md) | 11 | Execution control | DO CONCURRENT+REDUCE, SELECT TYPE/RANK, BLOCK |
| [ch12](chapters/ch12-io-statements.md) | 12 | Input/output statements | OPEN/READ/WRITE, stream, async, NEWUNIT |
| [ch13](chapters/ch13-io-editing.md) | 13 | Input/output editing | edit descriptors, AT, LZ, rounding |
| [ch14](chapters/ch14-program-units.md) | 14 | Program units | modules, submodules, USE association |
| [ch15](chapters/ch15-procedures.md) | 15 | Procedures | interfaces, PURE/SIMPLE/ELEMENTAL, generics |
| [ch16](chapters/ch16-intrinsic-procedures.md) | 16 | Intrinsic procedures and modules | intrinsics, SPLIT/TOKENIZE, IEEE/C/ENV modules |
| [ch17](chapters/ch17-exceptions-ieee.md) | 17 | Exceptions and IEEE arithmetic | flags, rounding, FMA, support inquiries |
| [ch18](chapters/ch18-c-interoperability.md) | 18 | Interoperability with C | ISO_C_BINDING, BIND(C), descriptors, strings |
| [ch19](chapters/ch19-scope-association.md) | 19 | Scope, association, definition | scoping, associations, defined/undefined |
| [ch20](chapters/ch20-annex-a-processor-dependencies.md) | A | Processor dependencies | the portability-hazard catalogue |
| [ch21](chapters/ch21-annex-b-deleted-obsolescent.md) | B | Deleted & obsolescent features | what not to use + replacements |
| [ch22](chapters/ch22-annex-c-extended-notes.md) | C | Extended notes | F2018 feature list, worked examples |

## Topic Index

- **allocate / deallocate** → ch09
- **arrays / sections / shapes** → ch08, ch09
- **assignment (intrinsic/defined/pointer)** → ch10
- **assumed-rank / assumed-type** → ch07, ch08, ch11
- **C interoperability / BIND(C)** → ch18, ch16
- **coarrays / images / teams** → ch09, ch11, ch16
- **conditional expressions (F2023)** → ch10
- **conformance / Rxxx / Cxxx** → ch04
- **deleted / obsolescent features** → ch21, ch04
- **DO CONCURRENT / REDUCE** → ch11
- **edit descriptors / formats** → ch13
- **enum / enumeration types (F2023)** → ch07
- **generic resolution** → ch15
- **IEEE / floating-point / exceptions** → ch17, ch02
- **INTENT / dummy arguments** → ch08, ch15
- **interfaces (explicit/abstract)** → ch15
- **intrinsic procedures** → ch16
- **I/O (OPEN/READ/WRITE/stream/async)** → ch12
- **kind / length type parameters** → ch07, ch16
- **modules / submodules / USE** → ch14, ch19
- **pointers / TARGET / association** → ch08, ch09, ch19
- **polymorphism / CLASS / SELECT TYPE** → ch07, ch11
- **processor-dependent behavior** → ch20, ch04
- **PURE / SIMPLE / ELEMENTAL** → ch15
- **scope / host/use association / definition status** → ch19
- **source form / lexical tokens** → ch06
- **string parsing (SPLIT/TOKENIZE, F2023)** → ch16
- **trig (circular SINPI / degree SIND, F2023)** → ch16
- **TYPEOF / CLASSOF (F2023)** → ch07

## Supporting Files

- [glossary.md](glossary.md) — key normative terms with definitions and clause refs
- [patterns.md](patterns.md) — modern Fortran idioms the standard enables
- [cheatsheet.md](cheatsheet.md) — F2023 new-feature table + decision rules + tells/smells

---

## Scope & Limits

Covers the J3/23-007r1 working draft of ISO/IEC 1539-1:2023 (base language), extracted with pdftotext (the layout-aware docling pass garbled this document's custom font and inlined margin line-numbers into the grammar, so pdftotext was the more faithful source). This is the *language standard*, not a compiler manual or tutorial — for build/tooling use the `fobis` skill; for HPC directives consult OpenMP/OpenACC/MPI references. Where the standard says "processor-dependent," consult your compiler's documentation (ch20 lists where this applies).
