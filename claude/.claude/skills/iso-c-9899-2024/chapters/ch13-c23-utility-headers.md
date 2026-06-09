# Chapter 13: C23 Utility Headers — `<stdbit.h>`, `<stdckdint.h>`, `<stdint.h>`, `<stddef.h>`

## Core Idea
C23 adds two genuinely new headers — `<stdbit.h>` (portable bit utilities) and `<stdckdint.h>` (overflow-checked arithmetic) — and extends `<stddef.h>` with `unreachable()` and `nullptr_t`. These replace the most common compiler-builtin / hand-rolled hazards (`__builtin_clz`, manual overflow checks) with standard, type-generic interfaces.

## Frameworks Introduced

- **`<stdbit.h>` — bit utilities** (§7.18): type-generic macros (and per-type `_uc/_us/_ui/_ul/_ull` functions), all marked `[[unsequenced]]`.
  - **Endianness**: `__STDC_ENDIAN_LITTLE__`, `__STDC_ENDIAN_BIG__`, `__STDC_ENDIAN_NATIVE__` — compile-time constants; compare `NATIVE` to `LITTLE`/`BIG`.
  - **Counts**: `stdc_leading_zeros`, `stdc_leading_ones`, `stdc_trailing_zeros`, `stdc_trailing_ones`, `stdc_count_zeros`, `stdc_count_ones` (popcount).
  - **Find-first**: `stdc_first_leading_zero/one`, `stdc_first_trailing_zero/one`.
  - **Power-of-two**: `stdc_has_single_bit` (is power of two), `stdc_bit_width` (⌊log2⌋+1), `stdc_bit_floor`, `stdc_bit_ceil`.
  - When to use: replace `__builtin_clz`/`__builtin_popcount` with portable, type-generic equivalents.

- **`<stdckdint.h>` — checked integer arithmetic** (§7.20): type-generic macros that return `bool` (true ⇒ overflow), storing the wrapped result.
  - `ckd_add(&r, a, b)`, `ckd_sub(&r, a, b)`, `ckd_mul(&r, a, b)`.
  - Operands and result may be different integer types; the macro computes in infinite precision then checks representability in `*r`'s type.
  - When to use: any size/length/index arithmetic where signed overflow (UB) or unsigned wrap would be a security bug.

- **`unreachable()`** (§7.21.1, `<stddef.h>`): asserts a code path is never reached; reaching it at runtime is **UB** (license for the optimizer). Use only where you can prove unreachability.

## Key Concepts
- **`<stdint.h>` families** (§7.22): `intN_t`/`uintN_t` (exact width, optional), `int_leastN_t` (smallest ≥ N), `int_fastN_t` (fastest ≥ N), `intptr_t`/`uintptr_t`, `intmax_t`/`uintmax_t`; limit macros `INTN_MAX`, `SIZE_MAX`, plus C23 `BITINT_MAXWIDTH` (max `_BitInt` width).
- **`<stddef.h>`**: `size_t`, `ptrdiff_t`, `max_align_t`, `wchar_t`, `nullptr_t`, `NULL`, `offsetof(type, member)`, `unreachable()`.
- **`<stdckdint.h>` `__STDC_VERSION_STDCKDINT_H__`** and each header's `__STDC_VERSION_<HDR>_H__` macro identify the header version.

## Mental Models
- **Reach for `ckd_*` instead of pre-checking ranges** — `if (ckd_mul(&n, count, size)) abort();` is correct by construction; manual `count > SIZE_MAX/size` is error-prone.
- **`stdc_bit_ceil` for hash-table / ring-buffer sizing** — round capacity up to a power of two portably.
- **`unreachable()` is a sharp tool**: it's UB if hit, so use it only at the end of a fully-covered `switch`, never as a lazy "can't happen."

## Code Examples
```c
#include <stdckdint.h>
size_t bytes;
if (ckd_mul(&bytes, count, sizeof(elem)))   /* true ⇒ overflow */
    return ERROR;
void *p = malloc(bytes);

#include <stdbit.h>
unsigned cap = stdc_bit_ceil(requested);    /* next power of two */
if (stdc_has_single_bit(x)) /* x is a power of two */ ;
unsigned lz = stdc_leading_zeros(x);        /* portable CLZ */
```
- **What it demonstrates**: overflow-safe allocation sizing and portable bit math — the two headline C23 utilities.

## Reference Tables

| Need | C23 standard | Replaces |
|---|---|---|
| overflow-checked add/sub/mul | `ckd_add/sub/mul` | manual range pre-checks |
| count leading zeros | `stdc_leading_zeros` | `__builtin_clz` |
| popcount | `stdc_count_ones` | `__builtin_popcount` |
| next power of two | `stdc_bit_ceil` | hand-rolled shifts |
| is power of two | `stdc_has_single_bit` | `x && !(x&(x-1))` |
| native endianness | `__STDC_ENDIAN_NATIVE__` | `<endian.h>` / probes |

## Key Takeaways
1. `<stdckdint.h>`'s `ckd_add/sub/mul` return `bool` overflow and store the wrapped result — the correct way to do size arithmetic.
2. `<stdbit.h>` standardizes CLZ/CTZ/popcount/bit-width/bit-ceil as type-generic `stdc_*` macros — drop the compiler builtins.
3. `__STDC_ENDIAN_NATIVE__` gives compile-time endianness portably.
4. `unreachable()` asserts impossibility — reaching it is UB; use sparingly.
5. Prefer `int_leastN_t`/`int_fastN_t` for portability when exact-width `intN_t` may be absent.

## Connects To
- **Ch 03 (`_BitInt`)**: `BITINT_MAXWIDTH` from `<stdint.h>`; `ckd_*` works across `_BitInt`.
- **Ch 05 (Expressions)**: `ckd_*` is the defined-behavior answer to signed-overflow UB.
- **Ch 06 (Attributes)**: `stdbit` functions carry `[[unsequenced]]`.
