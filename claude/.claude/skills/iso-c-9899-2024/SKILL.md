---
name: iso-c-9899-2024
description: "Authoritative knowledge base from the ISO/IEC 9899:2024 C standard (C23, working draft N3220). CONSULT THIS BEFORE ANSWERING — do not answer C-standard questions from memory; the standard's exact rules, constraints, undefined-behavior catalogue (Annex J), and C23 version deltas are easy to misremember. TRIGGER whenever a question concerns: what the C standard requires/permits/forbids; whether code is standard-conforming or has undefined/unspecified/implementation-defined behavior; any C23 feature (_BitInt, constexpr, typeof, auto type inference, nullptr, enum with fixed underlying type, [[attributes]], #embed, __VA_OPT__, _Generic, <stdbit.h>, <stdckdint.h>, decimal floats); integer promotion / usual arithmetic conversions / conversion rank; the C memory model (atomics, memory_order, data races); the floating-point model (Annex F / IEC 60559, <fenv.h>, fma, rounding); sequence points and evaluation order; the preprocessor; the standard library headers; or bounds-checking (Annex K _s functions). SKIP only for pure build/tooling questions, C++ (use iso-c++ if present), or when the user explicitly wants compiler-specific (gcc/clang/msvc) behavior rather than the ISO standard."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, clause (e.g. ch05), header (e.g. stdckdint), or feature name]
---

# ISO/IEC 9899:2024 — C23
**Source**: N3220 working draft | **Pages**: ~759 | **Chapters**: 14 (Clauses 1–7 + Annexes F/J/K/L) | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core decision rules below for reference.
- **With a topic** — ask about `undefined behavior`, `integer promotion`, `memory_order`, `constexpr`, `#embed`; I find and read the relevant chapter.
- **With a chapter** — ask for `ch05`; I load that file.
- **Browse** — ask "what chapters do you have?" for the full index.

When you ask about a topic not in the Core section, I read the relevant chapter file (and `cheatsheet.md` / `glossary.md` / `patterns.md`) before answering. For UB/portability questions, the authoritative enumeration is **Annex J** (Ch 14).

---

## Core Rules & Mental Models

### The behavior taxonomy (the foundation — Ch 1)
Every non-portable construct is one of four kinds, each catalogued in an Annex J subclause:
- **Undefined behavior (UB)** — no requirements; compiler may do anything and optimizes assuming it never happens. → **J.2**.
- **Unspecified** — ≥2 outcomes allowed, none chosen (e.g. argument evaluation order). → **J.1**.
- **Implementation-defined** — documented per implementation (sign of `char`, `>>` of negatives). → **J.3**.
- **Locale-specific** — depends on locale. → **J.4**.

**"shall" rule**: a `shall`/`shall not` violation **outside a "Constraints" subclause ⇒ silent UB**. Constraint violations are the *only* errors a compiler must diagnose.

### The UB hot-list (Ch 5, 10, 11)
Signed `+ - *` overflow; `/0`, `%0`, `INT_MIN/-1`; shift count `< 0` or `≥ width`; **two unsequenced writes (or write+read) of one object** (`i = i++`); out-of-bounds or one-past dereference; pointer arithmetic outside `[0, n]`; `memcpy`/`strcpy` on overlapping operands; accessing a member of an *atomic* struct; **data races**; reaching `unreachable()`. *Unsigned overflow is the lone defined wrap.*

### Conversions (Ch 3)
**Rank → integer promotion (small→`int`/`unsigned int`, but `_BitInt` exempt) → usual arithmetic conversions.** Mixed signed/unsigned of equal rank ⇒ result is **unsigned** (the `-1 > 0u` trap).

### Sequencing (Ch 2, 5)
Only `&&`, `||`, `?:`, `,` (operator), and function-call argument evaluation introduce sequence points inside an expression. Everything else leaves operands **unsequenced** → same-object conflict is UB. FP reassociation `(x*y)*z ≠ x*(y*z)` is non-conforming by default.

### Concurrency (Ch 11)
Data race = UB. `memory_order` lattice: default **`seq_cst`**; weaken to release(store)/acquire(load) for a publish-protect handoff; `relaxed` = atomicity only, no ordering. Only `atomic_flag` is guaranteed lock-free.

### Floating-point (Ch 12)
Annex F binds IEC 60559 (IEEE 754-2019), gated by `__STDC_IEC_60559_BFP__`. Changing rounding or reading FP flags **requires `#pragma STDC FENV_ACCESS ON`**. `NaN != NaN` — use `isnan`. Use `fma` for one-rounding accuracy.

### C23 "prefer this" (Ch 4, 6, 8, 13)
`constexpr` over `#define`; `ckd_add/sub/mul` (`<stdckdint.h>`) over manual overflow checks; `stdc_*` (`<stdbit.h>`) over `__builtin_clz`/popcount; `[[noreturn]]` over `_Noreturn`; `__VA_OPT__(,)` over the `,##__VA_ARGS__` hack; bare keywords (`bool`, `alignas`, `static_assert`) over `_`-spellings (obsolescent); `#embed` over `xxd`-arrays; `auto`/`typeof` for inference; `enum E : T {…}` for fixed ABI. **Breaking change: `int f()` ≡ `int f(void)`** (K&R prototypes removed); `gets` removed.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-conformance-and-behavior-model.md) | Scope, Conformance & Behavior Model | UB taxonomy, "shall" rule, strictly-conforming, hosted/freestanding |
| [ch02](chapters/ch02-environment-abstract-machine.md) | Environment & Abstract Machine | 8 translation phases, observable behavior, sequenced-before, `main` |
| [ch03](chapters/ch03-types-linkage-conversions.md) | Types, Linkage & Conversions | rank, integer promotion, usual arithmetic conv., `_BitInt`, linkage, storage duration |
| [ch04](chapters/ch04-lexical-elements.md) | Lexical Elements | C23 keywords, binary/separator literals, `wb` suffix, UCNs |
| [ch05](chapters/ch05-expressions.md) | Expressions & Constant Expressions | sequence points, arithmetic UB, `_Generic`, `sizeof`, constant exprs |
| [ch06](chapters/ch06-declarations.md) | Declarations | `constexpr`, `typeof`/`auto`, fixed-underlying enums, `[[attributes]]`, FAM, `restrict` |
| [ch07](chapters/ch07-statements-external-defs.md) | Statements & External Definitions | `[[fallthrough]]`, `f()`≡`f(void)`, tentative definitions |
| [ch08](chapters/ch08-preprocessor.md) | Preprocessor | `#embed`, `__VA_OPT__`, `__has_include`/`__has_c_attribute`, predefined macros |
| [ch09](chapters/ch09-library-io-and-utilities.md) | Library, I/O & Utilities | reserved identifiers, streams, `strto*`, allocation, `free_sized` |
| [ch10](chapters/ch10-strings-and-memory.md) | Strings & Memory | `memcpy`/`memmove` overlap, `strncpy` trap, `restrict` |
| [ch11](chapters/ch11-atomics-and-threads.md) | Atomics & Threads | `memory_order`, data races, `<threads.h>`, `call_once` |
| [ch12](chapters/ch12-floating-point-and-math.md) | Floating-Point & Math | Annex F / IEC 60559, `<fenv.h>`, `fma`, `FENV_ACCESS`, `FLT_EVAL_METHOD` |
| [ch13](chapters/ch13-c23-utility-headers.md) | C23 Utility Headers | `<stdbit.h>`, `<stdckdint.h>`, `<stdint.h>`, `<stddef.h>`, `unreachable()` |
| [ch14](chapters/ch14-portability-bounds-checking-annexes.md) | Portability & Safety Annexes | Annex J (UB list), Annex K (`_s` functions), Annex L (analyzability) |

## Topic Index

- **abstract machine / observable behavior** → ch02
- **alignment / `alignas`** → ch03, ch06
- **arithmetic conversions / rank / promotion** → ch03
- **atomics / `memory_order` / data race** → ch11
- **attributes `[[…]]`** → ch06, ch08
- **`auto` / `typeof` type inference** → ch04, ch06
- **`_BitInt`** → ch03, ch04, ch13
- **bit utilities (`stdbit`, CLZ, popcount)** → ch13
- **bounds-checking `_s` (Annex K)** → ch14
- **`constexpr`** → ch04, ch06
- **conversions (usual arithmetic)** → ch03
- **`#embed`** → ch08
- **enum (fixed underlying type)** → ch06
- **feature-test macros (`__STDC_*`, `__has_*`)** → ch08
- **floating-point / IEC 60559 / Annex F** → ch12
- **`fma` / rounding / `FENV_ACCESS`** → ch12
- **`_Generic`** → ch05
- **integer promotion** → ch03
- **linkage / storage duration** → ch03, ch07
- **`main` / startup / termination** → ch02, ch09
- **memory management (`malloc`, `free_sized`)** → ch09
- **overflow-checked arithmetic (`ckd_*`)** → ch13
- **preprocessor / macros / `__VA_OPT__`** → ch08
- **`restrict`** → ch06, ch10
- **reserved identifiers** → ch09
- **sequence points / evaluation order** → ch02, ch05
- **strings (`memcpy`/`strncpy`/`memmove`)** → ch10
- **threads (`<threads.h>`)** → ch11
- **undefined behavior (catalogue)** → ch01, ch14 (Annex J)
- **`unreachable()`** → ch13

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete C23 techniques (overflow-safe sizing, release/acquire, directed rounding, …)
- [cheatsheet.md](cheatsheet.md) — decision rules: is-it-UB, conversion rules, `memory_order` picker, C23 use-this-not-that

---

## Scope & Limits

Covers the C23 standard (N3220 working draft) — language, library, and Annexes F/J/K/L. Extracted via `pdftotext`, so some grammar productions and wide tables are summarized rather than reproduced verbatim; for exact normative wording cite the clause number and verify against the PDF. For C++ use a dedicated skill; for compiler-specific behavior (gcc/clang/nvc) consult that toolchain's docs, not this skill.
