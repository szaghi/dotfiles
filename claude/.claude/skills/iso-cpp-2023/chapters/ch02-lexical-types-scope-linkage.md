# Chapter 2: Lexical Conventions, Types, Scope & Linkage (Clauses 5, 6)

## Core Idea
Translation runs in **9 phases** (one more than C — module/import handling). The type system layers **fundamental → compound → cv-qualified** types, and every name has a **scope**, a **linkage** (external/internal/module/none), and (for objects) a **storage duration**.

## Frameworks Introduced

- **The 9 translation phases** (§5.2 `[lex.phases]`): like C's 8, plus the C++ specifics.
  1. Map physical chars → translation character set (UTF-8 internally in C++23).
  2. Splice `\`-newline.
  3. Decompose into preprocessing tokens + whitespace; comments → space.
  4. Execute preprocessing directives, expand macros, `_Pragma`; **`#include`/`import` resolved**; `__VA_OPT__`.
  5. Convert characters in literals to the execution encoding.
  6. Concatenate adjacent string literals.
  7. Tokens analyzed/translated; templates' definitions noted.
  8. **Instantiate** required template specializations.
  9. Link translation/instantiation units into the program image.

- **Type layers** (§6.8 `[basic.types]`):
  - **Fundamental** (§6.8.2): `void`, `std::nullptr_t`, arithmetic (`bool`, character types incl. C++20 `char8_t`, signed/unsigned integers, floating `float`/`double`/`long double`, and C++23 fixed-width float types via `<stdfloat>`: `std::float16_t`/`float32_t`/`float64_t`/`float128_t`/`bfloat16_t`).
  - **Compound** (§6.8.4): arrays, functions, pointers, references (lvalue `&` / rvalue `&&`), pointers-to-member, classes, unions, enumerations.
  - **cv-qualified**: `const` / `volatile` versions are distinct types.

- **Linkage** (§6.6 `[basic.link]`): **external** (visible across TUs), **internal** (`static`/anonymous-namespace, one TU), **module** (C++20: visible within the named module, exported names go external), **none** (locals, etc.).

## Key Concepts
- **Scope kinds** (§6.4): block, function-parameter, **lambda**, namespace, class, enumeration, template-parameter. C++ uses *locus*-based name lookup (point of declaration).
- **Storage duration**: static, thread (`thread_local`), automatic, dynamic.
- **C++ string/char literals**: prefixes `u8`/`u`/`U`/`L`, raw strings `R"(…)"`, user-defined literals (`"…"_suffix`), `char8_t`-typed `u8` literals (C++20).
- **`consteval`/`constinit`/`constexpr`** as the constant-evaluation specifiers (full treatment in Ch 4).
- **Conversion rank** (§6.8.6 `[conv.rank]`): integer and floating ranks drive the usual arithmetic conversions and overload ordering.

## Mental Models
- **C++23 brings extended floating-point types** (`std::float32_t` etc. in `<stdfloat>`) with explicit conversion-rank rules — distinct from `float`/`double`, never implicitly narrowing across them.
- **`module` linkage is the third kind** — an entity in a module is reachable by importers only if `export`ed; otherwise it's module-internal even with a global name.
- **References are not objects** — they have no storage of their own; "rebinding" a reference is impossible.

## Code Examples
```cpp
#include <stdfloat>
std::float32_t a = 1.0f32;   // C++23 fixed-width float literal & type
auto raw = R"(C:\path\no\escapes)";   // raw string literal
constexpr auto pi = 3.14159;          // constant
```
- **What it demonstrates**: C++23 `<stdfloat>` types/literals and raw strings.

## Reference Tables

| Linkage | Visibility | Trigger |
|---|---|---|
| external | all TUs | default for non-static namespace-scope |
| internal | one TU | `static`, anonymous namespace, `const` namespace vars |
| module | named module | C++20 module entities |
| none | local | block-scope names |

| C++23 float type (`<stdfloat>`) | Macro |
|---|---|
| `std::float16_t` | `__STDCPP_FLOAT16_T__` |
| `std::float32_t` | `__STDCPP_FLOAT32_T__` |
| `std::float64_t` | `__STDCPP_FLOAT64_T__` |
| `std::float128_t` | `__STDCPP_FLOAT128_T__` |
| `std::bfloat16_t` | `__STDCPP_BFLOAT16_T__` |

## Key Takeaways
1. Translation has 9 phases; phase 8 is template instantiation, phase 4 now also resolves `import`.
2. C++23 adds `<stdfloat>` fixed-width floating types with their own conversion ranks — no implicit narrowing.
3. Linkage has four kinds; **module linkage** is the C++20 addition that gates cross-TU visibility by `export`.
4. References are not objects and cannot be rebound; cv-qualified types are distinct types.
5. `char8_t` (C++20) types `u8` literals — `u8"x"` is `const char8_t[]`, not `const char[]`.

## Connects To
- **Ch 04 (Declarations)**: storage-class/specifier syntax, `auto`, structured bindings.
- **Ch 03 (Conversions)**: conversion rank and the standard conversion sequences.
- **Ch 09 (Modules)**: module linkage and `export`.
- **Ch 16 (Numerics)**: `<stdfloat>` usage in numerical code.
