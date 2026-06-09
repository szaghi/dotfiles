---
name: iso-cpp-2023
description: "Authoritative knowledge base from the ISO/IEC 14882 C++23 standard (working draft N4950). CONSULT THIS BEFORE ANSWERING — do not answer C++-standard questions from memory; the standard's exact rules, value categories, overload-resolution ranking, the memory model, template/concept subsumption, and C++23 version deltas are easy to misremember. TRIGGER whenever a question concerns: what the C++ standard requires/permits/forbids; whether code is well-formed / ill-formed / IFNDR / undefined behavior; value categories (lvalue/xvalue/prvalue) and move semantics; any C++20/23 feature (concepts, modules, coroutines, ranges, three-way comparison <=>, deducing this, if consteval, [[assume]], multidimensional operator[], std::expected, std::mdspan, std::print, std::generator, flat_map, <stdfloat>, import std;); overload resolution / ADL / templates / SFINAE; the memory model, atomics, memory_order, data races, jthread; constexpr/consteval/constinit; RAII / special members / exception safety / noexcept; the standard library (optional/variant/expected/tuple/format, containers, iterators, ranges/algorithms, chrono, <bit>, <charconv>). SKIP only for pure build/tooling questions, plain C (use iso-c-9899-2024), or when the user explicitly wants compiler-specific (gcc/clang/msvc) behavior rather than the ISO standard."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, clause (e.g. ch07), feature name, or [stable.tag]]
---

# ISO/IEC 14882 — C++23
**Source**: N4950 working draft (2023-05-10) | **Pages**: ~2134 | **Chapters**: 16 (Clauses 4–33 condensed + C++23 deltas) | **Generated**: 2026-06-09

## How to Use This Skill

- **Without arguments** — load the core decision rules below.
- **With a topic** — ask about `value categories`, `overload resolution`, `concepts`, `std::expected`, `ranges`, `memory_order`; I find and read the relevant chapter.
- **With a chapter** — ask for `ch07`; I load that file.
- **Browse** — ask "what chapters do you have?" for the full index.

When you ask about a topic not in the Core section, I read the relevant chapter file (and `cheatsheet.md` / `glossary.md` / `patterns.md`) before answering.

---

## Core Rules & Mental Models

### Legality taxonomy (Ch 1)
**well-formed** (must accept+execute) · **ill-formed** (diagnostic required) · **IFNDR** = ill-formed-no-diagnostic-required (ODR violations — silent mis-link) · **undefined behavior** (no requirements; optimizer assumes it can't happen) · **conditionally-supported** (impl choice, diagnostic if unsupported).

### Value categories (Ch 1)
Every expression is exactly one of **lvalue** (named) / **xvalue** (expiring, movable-from — `std::move`) / **prvalue** (pure value, lazily materialized). glvalue = lvalue∪xvalue; rvalue = xvalue∪prvalue. `std::move(x)` is a *cast to xvalue*, not a move.

### Memory model (Ch 1, 15)
A **data race** (conflicting access, ≥1 write, unordered, ≥1 non-atomic) is **UB**. Order via **happens-before** = sequenced-before (intra-thread) + synchronizes-with (atomics/mutexes). Default atomics to `seq_cst`; weaken to acquire/release only with a proof.

### Special members & RAII (Ch 5, 8)
**Rule of Zero**: hold resources in RAII members, declare none of the five. Declaring one affects the others (a destructor kills implicit moves). **Make moves `noexcept`** or `vector` copies instead of moving. Polymorphic base ⇒ `virtual` destructor. RAII + unwinding = exception safety; throw by value, catch by `const&`.

### Overload resolution (Ch 6)
Rank per-argument implicit conversion sequences: exact > promotion > conversion > user-defined > ellipsis. Tie-breakers: non-template > template > less-specialized; **more-constrained > less-constrained**. ADL finds free `swap`/`begin`. Prefer concepts over `enable_if` SFINAE.

### Templates & concepts (Ch 7)
The metaprogramming trio: **concepts** (constrain), **`if constexpr`** (branch, discard untaken), **fold expressions** `(xs op ...)` (reduce packs). Subsumption (the overload tie-break) needs *named* concepts.

### Comparison (Ch 3, 5)
`auto operator<=>(const T&) const = default;` synthesizes all six relationals member-wise. Integral → `strong_ordering`; **floating → `partial_ordering`** (NaN ⇒ unordered).

### C++23 headline features (Ch 3, 4, 9, 12–16)
deducing this (`this Self&& self`) · `if consteval` · `[[assume(e)]]` · multidim `operator[]` (`m[i,j]`) · `std::expected<T,E>` + monadic ops · `std::mdspan` · `std::print`/`println` · `std::generator` · `flat_map`/`flat_set` · `<stdfloat>` (`float32_t`…) · `import std;` · `ranges::to` + `zip`/`enumerate`/`chunk`/`stride` views · `ranges::fold_left` · `std::byteswap`/`move_only_function`/`to_underlying`. Gate on `__cpp_*` macros; `__cplusplus == 202302L`.

---

## Chapter Index

| # | Title | Key Topics |
|---|-------|-----------|
| [ch01](chapters/ch01-general-principles-and-memory-model.md) | General Principles & Memory Model | well-formed/UB/IFNDR, value categories, ODR, data races |
| [ch02](chapters/ch02-lexical-types-scope-linkage.md) | Lexical, Types, Scope & Linkage | 9 phases, `<stdfloat>`, module linkage |
| [ch03](chapters/ch03-expressions-operators-lambdas.md) | Expressions, Operators & Lambdas | `<=>`, deducing-this lambdas, `if consteval`, conversions |
| [ch04](chapters/ch04-statements-and-declarations.md) | Statements & Declarations | constexpr/consteval/constinit, structured bindings, `[[assume]]` |
| [ch05](chapters/ch05-classes-and-special-members.md) | Classes & Special Members | Rule of Zero/Five, RAII, virtual dtor, defaulted `<=>` |
| [ch06](chapters/ch06-overloading-and-operators.md) | Overload Resolution & Operators | ICS ranking, ADL, multidim `[]`, concepts vs SFINAE |
| [ch07](chapters/ch07-templates-and-concepts.md) | Templates & Concepts | concepts, `if constexpr`, fold, CTAD, subsumption |
| [ch08](chapters/ch08-exception-handling.md) | Exception Handling | unwinding, `noexcept`, guarantee levels, terminate |
| [ch09](chapters/ch09-modules.md) | Modules | `export`/`import`, partitions, `import std;` |
| [ch10](chapters/ch10-preprocessor-and-cpp23-deltas.md) | Preprocessor & C++23 Deltas | `__cpp_*`/`__has_*`, feature index |
| [ch11](chapters/ch11-library-intro-support-diagnostics.md) | Library Intro, Support & Diagnostics | `<compare>`, `source_location`, `<stacktrace>` |
| [ch12](chapters/ch12-general-utilities.md) | General Utilities | `optional`/`variant`/`expected`/`tuple`/`format`, smart pointers |
| [ch13](chapters/ch13-containers-and-iterators.md) | Containers & Iterators | invalidation, `flat_map`, `mdspan`, iterator concepts |
| [ch14](chapters/ch14-ranges-and-algorithms.md) | Ranges & Algorithms | views, projections, `ranges::to`, `fold_left` |
| [ch15](chapters/ch15-concurrency-and-coroutines.md) | Concurrency & Coroutines | `memory_order`, `jthread`, latch/barrier, `std::generator` |
| [ch16](chapters/ch16-numerics-time-io-strings.md) | Numerics, Time, I/O & Bit | `<stdfloat>`, `<bit>`, `<chrono>`, `print`, `<charconv>` |

## Topic Index

- **ADL / overload resolution** → ch06
- **atomics / memory_order / data race** → ch01, ch15
- **`[[assume]]` / attributes** → ch04
- **`<bit>` / `bit_cast` / byteswap** → ch16
- **`<charconv>` to_chars/from_chars** → ch16
- **`<chrono>` / time / steady_clock** → ch16
- **classes / RAII / Rule of Zero/Five** → ch05
- **concepts / `requires` / subsumption** → ch06, ch07
- **constexpr / consteval / constinit** → ch04
- **coroutines / `std::generator`** → ch15
- **deducing this** → ch03, ch06
- **exceptions / noexcept / safety** → ch08
- **`std::expected` / `optional` / `variant`** → ch12
- **feature-test macros (`__cpp_*`)** → ch10
- **flat_map / flat_set** → ch13
- **`std::format` / `print` / `println`** → ch12, ch16
- **`if consteval` / `if constexpr`** → ch03, ch07
- **iterators (concept hierarchy)** → ch13
- **lambdas** → ch03
- **`std::mdspan`** → ch13
- **memory model / happens-before** → ch01, ch15
- **modules / `import std;`** → ch09
- **multidimensional `operator[]`** → ch06
- **numerics / random / numeric_limits** → ch16
- **ranges / views / `ranges::to` / projections** → ch14
- **smart pointers (unique/shared/weak)** → ch12
- **`source_location` / `<stacktrace>`** → ch11
- **`<stdfloat>` / floating-point types** → ch02, ch16
- **structured bindings** → ch04
- **templates / CTAD / fold / variadics** → ch07
- **threads / jthread / latch / barrier** → ch15
- **three-way comparison `<=>`** → ch03, ch05
- **undefined behavior / IFNDR** → ch01
- **value categories (lvalue/xvalue/prvalue)** → ch01

## Supporting Files

- [glossary.md](glossary.md) — every key term with its defining chapter
- [patterns.md](patterns.md) — concrete C++23 techniques (Rule of Zero, `expected` chaining, ranges pipelines, `jthread`, …)
- [cheatsheet.md](cheatsheet.md) — decision rules: legality bucket, value-category tells, special-member suppression, `memory_order` picker, C++23 use-this-not-that

---

## Scope & Limits

Covers the C++23 working draft (N4950, which became ISO/IEC 14882:2024) — language and library, Clauses 4–33 + Annexes, condensed into 16 thematic chapters with the C++20/23 deltas front-loaded. Extracted via `pdftotext`, so grammar productions and large synopsis tables are summarized, not reproduced verbatim; for exact normative wording cite the `[stable.tag]` and verify against the PDF. For plain C use the **iso-c-9899-2024** skill; for compiler-specific behavior (gcc/clang/msvc) consult that toolchain, not this skill.
