# Chapter 4: Lexical Elements (Clause 6.4)

## Core Idea
After preprocessing, the token stream is partitioned into **keywords, identifiers, constants, string literals, and punctuators**. C23 adds new keywords as full keywords (not macros) and several new constant/literal forms.

## Frameworks Introduced

- **The C23 keyword set** (§6.4.1) — note the ones promoted from macros/`_`-spellings:
  - New-as-keyword: `bool`, `true`, `false`, `nullptr`, `constexpr`, `typeof`, `typeof_unqual`, `alignas`, `alignof`, `static_assert`, `thread_local`, `_BitInt`.
  - Still `_`-spelled: `_Atomic`, `_Complex`, `_Imaginary`, `_Decimal32/64/128`.
  - **Alternative spellings now obsolescent**: `_Alignas`→`alignas`, `_Alignof`→`alignof`, `_Bool`→`bool`, `_Static_assert`→`static_assert`, `_Thread_local`→`thread_local`. Use the new spellings in new code.

- **Token categories** (§6.4): keyword / identifier / constant / string-literal / punctuator. Preprocessing tokens additionally include header-names and pp-numbers.

## Key Concepts
- **Universal character names** (§6.4.3): `\uXXXX` / `\UXXXXXXXX`; C23 broadens identifier characters per Unicode (Annex D / UAX #44, XID_Start/XID_Continue).
- **Integer constants** (§6.4.4.1): suffixes `u/U`, `l/L`, `ll/LL`, and C23 `wb/WB` for `_BitInt`. Binary literals `0b`/`0B` are standard in C23. Digit separators `'` are allowed.
- **Floating constants** (§6.4.4.2): hex floats `0x1.8p3`; decimal-float suffixes `df/dd/dl` for `_Decimal32/64/128`.
- **Character constants / string literals** (§6.4.4.4, §6.4.5): prefixes `u8`, `u`, `U`, `L`; `u8` string literals have type `char` array in C23 (`char8_t` in `<uchar.h>` for the type alias).
- **Punctuators** (§6.4.6): include `::` is NOT C; attribute brackets `[[ ]]` are.
- **Predefined macros** (in 6.10.9): `__STDC_VERSION__` is `202311L` for C23.

## Mental Models
- **Prefer the bare keyword spellings** (`bool`, `alignas`, `static_assert`) — the `_`-prefixed forms are obsolescent.
- **`0b` binary, `'` digit separators, and `wb` suffix are the new literal ergonomics** in C23.

## Code Examples
```c
unsigned _BitInt(12) mask = 0b1010'1100'0011wb;  /* binary + separators + _BitInt suffix */
constexpr int N = 42;                            /* constexpr object, a C23 keyword */
```
- **What it demonstrates**: C23 lexical additions — binary literals, digit separators, `wb` suffix, and `constexpr`.

## Reference Tables

| Literal form | Example | Notes |
|---|---|---|
| Binary integer | `0b1011` | C23 |
| Digit separator | `1'000'000` | C23, any radix |
| `_BitInt` suffix | `42wb`, `7uwb` | C23 |
| Hex float | `0x1.8p3` | == 12.0 |
| Decimal float | `3.14df` | conditional feature |
| `u8` string | `u8"abc"` | `char` array (C23) |

## Key Takeaways
1. `bool/true/false/nullptr/constexpr/typeof/static_assert/alignas/alignof/thread_local/_BitInt` are keywords in C23 — no header needed.
2. `_Alignas`, `_Bool`, `_Static_assert`, etc. are obsolescent alternative spellings.
3. Binary literals `0b…`, digit separators `'`, and the `wb`/`WB` suffix are new.
4. `__STDC_VERSION__ == 202311L` identifies C23.

## Connects To
- **Ch 03 (Types)**: `_BitInt`, `bool`, decimal floats.
- **Ch 06 (Declarations)**: `constexpr`, `typeof`, `alignas`, `static_assert` as declaration tools.
- **Ch 08 (Preprocessor)**: predefined macros and feature-test macros.
