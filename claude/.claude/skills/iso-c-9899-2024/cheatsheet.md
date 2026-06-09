# C23 Cheatsheet — Decision Rules & Tells

## Is it defined behavior? (decision rule)
- **Signed `+ - *` overflows** → UB. Unsigned → wraps (defined). → use `ckd_*`.
- **`/0`, `%0`, `INT_MIN/-1`** → UB.
- **Shift count < 0 or ≥ width** → UB; `(neg) >> n` → implementation-defined.
- **Two writes (or write+read) of one object, no sequence point between** → UB (`i = i++`).
- **Pointer past one-past-the-end, or subtracting pointers into different arrays** → UB.
- **`memcpy`/`strcpy` with overlapping operands** → UB → use `memmove`.
- **Accessing a member of an atomic struct/union** → UB.
- **Data race (≥1 non-atomic, unordered)** → UB.
- **Reaching `unreachable()`** → UB.
- *When unsure, grep Annex J.2 — it's the complete UB list.*

## "shall" vs "Constraints" (tell)
- Rule under a **"Constraints"** heading → violation **must** be diagnosed.
- Bare **"shall"** elsewhere → violation is **silent UB**.

## Sequence points (only these order sub-expressions)
`&&` `||` `?:` `,` (comma operator) and the call after evaluating function args. Everything else leaves operands **unsequenced**.

## Usual arithmetic conversions (mixed operands)
| operands | result |
|---|---|
| signed vs unsigned, unsigned rank ≥ signed | → **unsigned** (the `-1 > 0u` trap) |
| both same signedness | lower rank → higher |
| `_BitInt` involved | converts toward higher `_BitInt` rank, **no `int` promotion** |

## C23 "use this, not that"
| Want | C23 | Drop |
|---|---|---|
| typed constant | `constexpr` | `#define` (untyped) |
| overflow-checked math | `ckd_add/sub/mul` | manual range checks |
| CLZ / popcount | `stdc_leading_zeros` / `stdc_count_ones` | `__builtin_*` |
| next power of two | `stdc_bit_ceil` | hand-rolled shifts |
| no-return fn | `[[noreturn]]` | `_Noreturn` |
| variadic macro comma | `__VA_OPT__(,)` | `, ## __VA_ARGS__` |
| keyword spellings | `bool`, `alignas`, `static_assert` | `_Bool`, `_Alignas`, … (obsolescent) |
| string→int | `strtol` | `atoi` |
| bounded output | `snprintf` | `sprintf`, `gets` (removed) |
| binary blob | `#embed` | `xxd`-generated arrays |

## Feature-test macros (gate conditional features)
- `__STDC_VERSION__ == 202311L` → C23.
- `__STDC_NO_ATOMICS__`, `__STDC_NO_THREADS__`, `__STDC_NO_VLA__`, `__STDC_NO_COMPLEX__` → feature absent.
- `__STDC_IEC_60559_BFP__` → Annex F binary FP. `__STDC_LIB_EXT1__` → Annex K `_s` functions.
- `__has_include(<h>)`, `__has_c_attribute(a)`, `__has_embed(r)` → portable probes.

## Floating-point tells
- Changing rounding / reading FP flags **without** `#pragma STDC FENV_ACCESS ON` → silent reorder bug.
- `(x*y)*z == x*(y*z)`? **No** — reassociation is non-conforming; `-ffast-math` breaks Annex F.
- `x == x` to test NaN? **No** — `NaN != NaN`; use `isnan`.
- Need accuracy in `a*b+c`? Use `fma` (one rounding) + control `FP_CONTRACT`.

## memory_order picker
| situation | order |
|---|---|
| default / unsure | `seq_cst` |
| producer publishes | `release` (store) |
| consumer reads published | `acquire` (load) |
| CAS / fetch_add updating shared state | `acq_rel` |
| independent counter/stat | `relaxed` |

## `main` & startup
- `int main(void)` or `int main(int argc, char *argv[])`; `argv[argc] == NULL`; fall off `}` → returns 0.
- `return` from `main` ≡ `exit()`. **C23: `int f()` ≡ `int f(void)`** (no K&R).

## Reserved-name smell
Don't define identifiers `_Upper…`, `__anything`, or names matching included-header symbols → UB.
