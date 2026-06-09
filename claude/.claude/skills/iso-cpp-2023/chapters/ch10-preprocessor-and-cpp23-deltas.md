# Chapter 10: Preprocessing Directives & the C++23 Language Deltas (Clause 15 + summary)

## Core Idea
The preprocessor is the same phase-4 machinery as C, extended with `import`/module handling and the `__has_*` probes. This chapter also serves as the **C++23 language-feature index** — the deltas a C++17/20 programmer needs.

## Frameworks Introduced

- **Preprocessor directives** (Clause 15 `[cpp]`): `#include`, `#define`/`#undef`, conditional inclusion (`#if`/`#ifdef`/`#ifndef`/`#elif`/`#elifdef`/`#elifndef`/`#else`/`#endif`), `#error`, **`#warning`** (C++23), `#pragma`, `#line`, and module-related `import`/`module` (also recognized here).
  - Macro operators `#` (stringize) and `##` (paste); `__VA_OPT__`/`__VA_ARGS__` for variadics.

- **Feature-probe operators** (§15.2 `[cpp.cond]`):
  - `__has_include(<h>)` — header availability.
  - `__has_cpp_attribute(attr)` — standard-attribute support (value macro).
  - **Feature-test macros** (`__cpp_*`): `__cpp_concepts`, `__cpp_modules`, `__cpp_lib_expected`, `__cpp_if_consteval`, `__cpp_multidimensional_subscript`, etc. — the canonical way to gate on a feature.
  - `__cplusplus == 202302L` identifies C++23.

- **C++23 language deltas** (the index):
  - **Deducing this** — explicit object parameter `this Self&& self` (Ch 3, 6).
  - **`if consteval`** — compile-time/runtime branch (Ch 3).
  - **`[[assume(expr)]]`** — UB-if-false optimizer hint (Ch 4).
  - **Multidimensional `operator[]`** — `m[i, j]` (Ch 6).
  - **`static` and explicit-object lambdas** (Ch 3).
  - **`#elifdef`/`#elifndef`, `#warning`** — already standard.
  - **`<stdfloat>`** extended floating-point types (Ch 2, 16).
  - **`auto(x)` / `auto{x}`** — decay-copy cast.
  - **Relaxed `constexpr`** — more constructs allowed in constexpr functions (Ch 4).

## Key Concepts
- **Header units** (Ch 9): `import <vector>;` makes an importable header — bridges the preprocessor and modules.
- **`#pragma once`** — ubiquitous but non-standard include guard; standard guards use `#ifndef`.
- **Predefined macros**: `__cplusplus`, `__FILE__`, `__LINE__`, `__DATE__`, `__TIME__`, `__STDC_HOSTED__`, `__STDCPP_FLOAT*_T__`.

## Mental Models
- **Gate features on `__cpp_*` feature-test macros, not compiler-version checks** — `#ifdef __cpp_lib_expected` is portable; `#if __GNUC__ >= 12` is not.
- **Prefer modules/`import` over the preprocessor** for new code — the preprocessor's textual model is the source of macro-collision and include-order bugs.
- **`__has_cpp_attribute` before using a non-core attribute** — attribute support is implementation-defined.

## Code Examples
```cpp
// Portable feature gating — the right way
#if __cpp_lib_expected >= 202202L
#  include <expected>
   using Result = std::expected<int, Error>;
#endif

#if __has_cpp_attribute(assume)
#  define ASSUME(x) [[assume(x)]]
#else
#  define ASSUME(x)
#endif

static_assert(__cplusplus >= 202302L, "needs C++23");
```
- **What it demonstrates**: feature-test-macro gating and attribute probing — portable across toolchains.

## Reference Tables

| Probe / macro | Meaning |
|---|---|
| `__cplusplus == 202302L` | C++23 |
| `__has_include(<h>)` | header available |
| `__has_cpp_attribute(a)` | attribute supported (value) |
| `__cpp_concepts` | concepts language support |
| `__cpp_modules` | modules support |
| `__cpp_lib_expected` | `std::expected` available |
| `__cpp_if_consteval` | `if consteval` support |

| C++23 feature | Chapter |
|---|---|
| deducing this | ch03, ch06 |
| `if consteval` | ch03 |
| `[[assume]]` | ch04 |
| multidim `operator[]` | ch06 |
| `import std;` | ch09 |
| `std::expected`, `std::mdspan`, `std::print` | ch11–16 |

## Key Takeaways
1. Gate features on `__cpp_*` feature-test macros, never on compiler-version checks.
2. C++23 standardizes `#warning`, `#elifdef`/`#elifndef`; use `__has_include`/`__has_cpp_attribute` for portable probing.
3. The C++23 *language* highlights: deducing this, `if consteval`, `[[assume]]`, multidim `operator[]`, `import std;`, `<stdfloat>`.
4. Prefer modules/`import` over the textual preprocessor for new code.
5. `__cplusplus == 202302L` identifies C++23.

## Connects To
- **Ch 09 (Modules)**: `import`, header units, `import std;`.
- **Ch 11–16 (Library)**: the C++23 library additions gated by `__cpp_lib_*`.
- **Ch 04 (Attributes)**: `[[assume]]` and `__has_cpp_attribute`.
