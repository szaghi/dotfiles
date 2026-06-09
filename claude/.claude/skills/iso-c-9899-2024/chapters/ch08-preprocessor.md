# Chapter 8: Preprocessing Directives (Clause 6.10)

## Core Idea
The preprocessor runs in translation phase 4: conditional inclusion, file inclusion, macro replacement, line/diagnostic/pragma control. C23 adds `#embed`, `#elifdef`/`#elifndef`, `__VA_OPT__`, and the `__has_*` feature-probe operators.

## Frameworks Introduced

- **C23 new directives & operators**:
  - **`#embed`** (§6.10.4): embed a binary resource as a comma-separated list of integer values at compile time — replaces hand-rolled `xxd`-to-array tooling. Parameters: `limit(N)`, `prefix(…)`, `suffix(…)`, `if_empty(…)`.
  - **`#elifdef` / `#elifndef`** (§6.10.2): shorthand for `#elif defined` / `#elif !defined`.
  - **`#warning`** (§6.10.7): emit a diagnostic without halting (companion to `#error`).
  - **`__has_include(header)`** (§6.10.2): true if the header is available — portable conditional inclusion.
  - **`__has_embed(resource)`**: true/conditionally-true if a resource is embeddable.
  - **`__has_c_attribute(attr)`**: query standard-attribute support, returns the attribute's value macro.

- **`__VA_OPT__`** (§6.10.5): expands its content only when the variadic argument list is non-empty — solves the "trailing comma" problem in variadic macros.
  - When to use: `#define LOG(fmt, ...) printf(fmt __VA_OPT__(,) __VA_ARGS__)` — no dangling comma when no variadic args.

- **Conditional inclusion controlling expression** (§6.10.2): an integer constant expression where `defined`, `__has_include`, `__has_embed`, `__has_c_attribute` are treated as defined macros; all remaining identifiers replace to `0`.

## Key Concepts
- **`#define` object-like vs function-like**; `#` stringizes; `##` token-pastes.
- **`_Pragma("…")`** (§6.10.8): operator form of `#pragma`, usable inside macros.
- **Standard pragmas**: `#pragma STDC FP_CONTRACT on|off`, `STDC FENV_ACCESS on|off`, `STDC FENV_ROUND`, `STDC CX_LIMITED_RANGE`.
- **`#line`** (§6.10.6): set `__LINE__`/`__FILE__`.
- **Predefined macros** (§6.10.10): `__STDC__` (1), `__STDC_VERSION__` (`202311L` for C23), `__DATE__`, `__TIME__`, `__FILE__`, `__LINE__`, `__STDC_HOSTED__`, plus conditional `__STDC_IEC_60559_BFP__`, `__STDC_IEC_60559_DFP__`, `__STDC_NO_ATOMICS__`, `__STDC_NO_THREADS__`, `__STDC_NO_VLA__`, `__STDC_NO_COMPLEX__`.
- **`__func__`** is a predefined identifier (not a macro) holding the current function name.

## Mental Models
- **Use `__has_include` + `__has_c_attribute` to write forward/backward-portable headers** rather than guessing compiler versions.
- **`__VA_OPT__` is the canonical fix for variadic-macro trailing commas** — drop the old `, ## __VA_ARGS__` GNU hack.
- **`#embed` is the standard way to bake binary blobs into a program** — fonts, firmware, lookup tables.

## Code Examples
```c
/* §6.10.2 — portable feature probing */
#if __has_include(<optional.h>)
#  include <optional.h>
#endif

#ifndef __has_c_attribute
#  define __has_c_attribute(x) 0
#endif
#if __has_c_attribute(fallthrough)
#  define FALLTHROUGH [[fallthrough]]
#else
#  define FALLTHROUGH
#endif

/* §6.10.4 — embed a binary file as an initializer list */
const unsigned char logo[] = {
#embed "logo.png"
};

/* §6.10.5 — __VA_OPT__ kills the trailing comma */
#define LOG(fmt, ...) printf(fmt __VA_OPT__(,) __VA_ARGS__)
```
- **What it demonstrates**: the four headline C23 preprocessor features — `__has_include`, `__has_c_attribute`, `#embed`, `__VA_OPT__`.

## Reference Tables

| Feature-test / macro | Meaning |
|---|---|
| `__STDC_VERSION__ == 202311L` | C23 |
| `__has_include(<h>)` | header available |
| `__has_c_attribute(a)` | attribute supported (value) |
| `__has_embed(r)` | resource embeddable |
| `__STDC_NO_ATOMICS__` | atomics unsupported |
| `__STDC_NO_THREADS__` | `<threads.h>` unsupported |
| `__STDC_IEC_60559_BFP__` | IEC 60559 binary FP conformance |

## Key Takeaways
1. `#embed` embeds binary resources as compile-time integer lists — no external preprocessing tool needed.
2. `__VA_OPT__(,)` is the standard variadic trailing-comma fix.
3. `#elifdef`/`#elifndef` and `#warning` round out conditional/diagnostic directives.
4. `__has_include` / `__has_c_attribute` / `__has_embed` enable robust portable feature detection.
5. `__STDC_VERSION__ == 202311L` selects C23; the `__STDC_NO_*` macros gate optional features.

## Connects To
- **Ch 01 (Conformance)**: feature-test macros guard conditional features in strictly conforming code.
- **Ch 06 (Attributes)**: `__has_c_attribute` probes the `[[…]]` attribute set.
- **Ch 12 (Annex F)**: `FP_CONTRACT`/`FENV_ACCESS` pragmas and `__STDC_IEC_60559_BFP__`.
