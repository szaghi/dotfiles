# Chapter 12: Floating-Point — `<math.h>`, `<fenv.h>`, `<float.h>` & Annex F (IEC 60559)

## Core Idea
C's floating-point model is normative IEC 60559 (IEEE 754-2019) binding via **Annex F**, gated by `__STDC_IEC_60559_BFP__`. The dynamic floating-point environment (`<fenv.h>`) — rounding mode and exception flags — is a **side effect** the optimizer must respect *only* when `FENV_ACCESS` is on.

## Frameworks Introduced

- **The floating-point environment** (§7.6 `<fenv.h>`):
  - **Exception flags**: `FE_DIVBYZERO`, `FE_INEXACT`, `FE_INVALID`, `FE_OVERFLOW`, `FE_UNDERFLOW`, `FE_ALL_EXCEPT`. Test/clear/raise with `fetestexcept`, `feclearexcept`, `feraiseexcept`.
  - **Rounding modes**: `FE_TONEAREST` (default), `FE_DOWNWARD`, `FE_UPWARD`, `FE_TOWARDZERO`, C23 `FE_TONEARESTFROMZERO`. Get/set with `fegetround`/`fesetround`.
  - **Environment save/restore**: `fegetenv`/`fesetenv`/`feholdexcept`/`feupdateenv`; C23 mode objects `fegetmode`/`fesetmode`.
  - **`#pragma STDC FENV_ACCESS ON`** is mandatory before reading flags or changing rounding — otherwise the implementation may assume the default environment and reorder FP ops across your `fesetround`.

- **Classification & macros** (§7.12 `<math.h>`):
  - `fpclassify` → `FP_NAN`/`FP_INFINITE`/`FP_NORMAL`/`FP_SUBNORMAL`/`FP_ZERO`; `isnan`, `isinf`, `isfinite`, `isnormal`, `signbit`.
  - `HUGE_VAL[F|L]`, `INFINITY`, `NAN` (note: bare `INFINITY`/`NAN` use in `<math.h>` is *obsolescent* in C23 — prefer the typed forms).
  - `math_errhandling` (`MATH_ERRNO` | `MATH_ERREXCEPT`) tells you whether errors arrive via `errno` or FP exceptions.
  - `fma(x,y,z)` — fused multiply-add, single rounding (key for accurate dot products / Kahan-style algorithms).

- **`<float.h>` characteristics** (§7.7): `FLT_EPSILON`/`DBL_EPSILON`/`LDBL_EPSILON`, `*_MANT_DIG`, `*_MIN`/`*_MAX`, `FLT_RADIX`, `DBL_DECIMAL_DIG`, `FLT_EVAL_METHOD` (how intermediate FP results are evaluated), `*_HAS_SUBNORM`, `*_DECIMAL_DIG`, `INFINITY`/`NAN`-related width macros.

## Key Concepts
- **`__STDC_IEC_60559_BFP__ == 202311L`** ⇒ Annex F binary FP conformance (also defines `__STDC_IEC_559__`). `__STDC_IEC_60559_DFP__` ⇒ decimal FP.
- **`FLT_EVAL_METHOD`**: `0` = evaluate in each type; `1` = `float`/`double` evaluated as `double`; `2` = all as `long double`; this drives the classic x87 "extended precision" surprises.
- **`FP_CONTRACT` pragma**: controls whether `a*b+c` may contract to a single `fma` (changes rounding) — `#pragma STDC FP_CONTRACT OFF` to forbid.
- **`CX_LIMITED_RANGE` pragma**: permits the naive complex multiply/divide formulas (faster, less robust to overflow).
- **Reassociation is forbidden by default** (§5.1.2.4 EXAMPLE 5): `(x*y)*z ≠ x*(y*z)` — Annex F makes the IEC 60559 operations the contract.

## Mental Models
- **Wrap any rounding-mode change in `#pragma STDC FENV_ACCESS ON`** or the compiler may hoist FP ops across your `fesetround` — silent wrong results.
- **Use `fma` for accuracy, not speed** — it removes one rounding from `a*b+c`; pair with `FP_CONTRACT` control so you know which you got.
- **`-ffast-math` is non-conforming**: it enables reassociation, drops NaN/Inf handling, and assumes the default environment — incompatible with Annex F.
- **`NaN != NaN`** — test with `isnan`, never `x == x`.

## Code Examples
```c
#pragma STDC FENV_ACCESS ON
#pragma STDC FP_CONTRACT OFF        /* forbid implicit fma contraction */

feclearexcept(FE_ALL_EXCEPT);
fesetround(FE_UPWARD);              /* directed rounding for interval bound */
double up = a + b;
if (fetestexcept(FE_OVERFLOW)) handle_overflow();

double s = fma(a, b, c);            /* one rounding instead of two */
```
- **What it demonstrates**: correct directed-rounding usage guarded by `FENV_ACCESS`, plus explicit `fma`.

## Reference Tables

| Macro / pragma | Role |
|---|---|
| `__STDC_IEC_60559_BFP__` | IEC 60559 binary FP conformance (202311L) |
| `FLT_EVAL_METHOD` | intermediate-result evaluation width |
| `math_errhandling` | `MATH_ERRNO` and/or `MATH_ERREXCEPT` |
| `FENV_ACCESS ON` | required to read flags / change rounding |
| `FP_CONTRACT OFF` | forbid `a*b+c` → `fma` contraction |
| `fma(x,y,z)` | single-rounding multiply-add |

## Key Takeaways
1. Annex F binds IEC 60559 (IEEE 754-2019); conformance is signaled by `__STDC_IEC_60559_BFP__`.
2. Changing rounding or reading FP flags **requires** `#pragma STDC FENV_ACCESS ON`.
3. FP reassociation is non-conforming by default; `-ffast-math` breaks Annex F semantics.
4. Use `fma` for one-rounding accuracy and control `FP_CONTRACT` to know what you get.
5. `NaN != NaN`; classify with `fpclassify`/`isnan`, and bare `INFINITY`/`NAN` in `<math.h>` is obsolescent.

## Connects To
- **Ch 02 (Abstract machine)**: FP operations as side effects; reassociation prohibition.
- **Ch 03 (Real floating types)**: `float ⊂ double ⊂ long double` and decimal floats.
- **Consumer-GPU FP64 trap** (user reference): FP32-store + FP64-compute interplay; `fma` and `FLT_EVAL_METHOD` precision discipline mirror the same numerical-floor concerns.
- **Ch 08 (pragmas)**: `FENV_ACCESS`/`FP_CONTRACT`/`FENV_ROUND` directives.
