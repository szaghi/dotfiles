# Chapter 14: Portability & Safety Annexes — J (UB catalogue), K (bounds-checking), L (analyzability)

## Core Idea
Annex J is the **canonical index of every non-portable construct** — the lookup table behind "is this defined?" Annex K adds optional bounds-checked `_s` library variants with runtime-constraints. Annex L defines optional *bounded*/*critical* UB classes for analyzable implementations.

## Frameworks Introduced

- **Annex J — the portability catalogue** (informative, but the authoritative enumeration):
  - **J.1 Unspecified behavior** — every place the standard allows ≥2 outcomes without choosing (e.g. argument evaluation order, `realloc(p,0)`).
  - **J.2 Undefined behavior** — the complete list of every UB in the standard (signed overflow, OOB access, data races, modifying a string literal, etc.). This is the single most useful reference for auditing C code.
  - **J.3 Implementation-defined behavior** — everything an implementation must document (sign of `char`, right-shift of negative, size of types).
  - **J.4 Locale-specific behavior** — locale-dependent outcomes.
  - When to use: to answer any "is X portable / defined?" question, grep the relevant J subclause rather than reasoning from memory.

- **Annex K — bounds-checking interfaces** (normative, optional): the `_s` function family.
  - Gated by `__STDC_LIB_EXT1__` (implementation) and `__STDC_WANT_LIB_EXT1__` (user, must be defined identically before every relevant header include).
  - Functions take an explicit destination-size argument and return `errno_t`: `memcpy_s`, `memmove_s`, `strcpy_s`, `strncpy_s`, `strcat_s`, `strncat_s`, `sprintf_s`, `snprintf_s`, `scanf_s`/`fscanf_s` (note: `%s`/`%c`/`%[` take a following `rsize_t` size), `gets_s` (the safe replacement for the removed `gets`), `fopen_s`/`freopen_s`, `getenv_s`, `qsort_s`, `bsearch_s`.
  - **Runtime-constraints** (§K.3.1.4): violations invoke the installed handler via `set_constraint_handler_s` (`abort_handler_s`, `ignore_handler_s`, or custom) rather than being silent UB. `rsize_t` values must be ≤ `RSIZE_MAX`.
  - **Caveat**: Annex K is controversial and patchily implemented (notably absent/different on glibc); don't assume availability — probe `__STDC_LIB_EXT1__`.

- **Annex L — analyzability** (normative, optional): `__STDC_ANALYZABLE__`.
  - Partitions UB into **bounded undefined behavior** (does not perform an OOB write or trap, effects are limited) vs **critical undefined behavior** (may, e.g., write OOB — the dangerous class).
  - Lets static analyzers and safety-critical tooling reason about the blast radius of UB.

## Key Concepts
- **`gets` is removed** from C (UB-by-design); use `fgets` or Annex K `gets_s`.
- **`__STDC_WANT_LIB_EXT1__` must be defined before including** the affected standard header, and consistently across all includes in a TU.
- **Runtime-constraint ≠ constraint** (§3.21): a runtime-constraint is checked at *library-call* time, not translation time.

## Mental Models
- **Annex J.2 is your UB audit checklist** — when reviewing C, walk the J.2 list against the code rather than recalling rules ad hoc.
- **Don't depend on Annex K for portability** — it's optional and unevenly supported; prefer `snprintf` + explicit length discipline, which is universally available.
- **Annex L's bounded/critical split is the model behind sanitizers** — "critical UB" is what ASan/UBSan most want to catch.

## Code Examples
```c
#define __STDC_WANT_LIB_EXT1__ 1   /* MUST precede the include */
#include <string.h>

errno_t e = strcpy_s(dst, sizeof dst, src);  /* checked; runtime-constraint on overflow */
if (e != 0) handle_error();

/* portable alternative that needs no Annex K */
int n = snprintf(dst, sizeof dst, "%s", src);
if (n < 0 || (size_t)n >= sizeof dst) handle_truncation();
```
- **What it demonstrates**: the Annex K `_s` pattern (with its `__STDC_WANT_LIB_EXT1__` gate) versus the universally-portable `snprintf` discipline.

## Reference Tables

| Annex | Macro gate | Provides |
|---|---|---|
| J | — (informative) | full UB / unspecified / impl-defined / locale catalogues |
| K | `__STDC_LIB_EXT1__` + `__STDC_WANT_LIB_EXT1__` | `_s` bounds-checked functions, runtime-constraints |
| L | `__STDC_ANALYZABLE__` | bounded vs critical UB classification |

| Removed / unsafe | Use instead |
|---|---|
| `gets` (removed) | `fgets`, `gets_s` |
| unchecked `strcpy` | `snprintf` / `strcpy_s` |
| `sprintf` overflow | `snprintf` / `sprintf_s` |

## Key Takeaways
1. Annex J.2 is the definitive list of all UB — use it as the audit checklist, not memory.
2. Annex K `_s` functions are optional (`__STDC_LIB_EXT1__`); `__STDC_WANT_LIB_EXT1__` must precede includes; runtime-constraints replace silent UB.
3. `gets` is removed — never use it; `snprintf` is the portable bounded-output primitive.
4. Annex L splits UB into bounded vs critical, the conceptual basis for sanitizers and safety tooling.
5. For portable safety, prefer `snprintf` + length checks over Annex K, which is unevenly implemented.

## Connects To
- **Ch 01 (Behavior model)**: J-annexes are the catalogues the behavior taxonomy refers to.
- **Ch 05 (Expressions)** & **Ch 10 (strings)**: the specific UBs (overflow, overlap, OOB) enumerated in J.2.
- **Ch 13 (`stdckdint`)**: `ckd_*` is the defined-behavior alternative to overflow UB.
