# Chapter 16 (Clause 16): Intrinsic procedures and modules

## Core Idea
The catalogue of built-in procedures (≈200) and the standard intrinsic modules. The largest clause; treated here as an organized index emphasizing **F2023 additions** (degree/circular trig, string SPLIT/TOKENIZE, SELECTED_LOGICAL_KIND) and the four intrinsic modules.

## Frameworks Introduced
- **Intrinsic classes** (16.1, the trailing letter in the 16.7 table): **E**lemental, **T**ransformational, **I**nquiry, **S**ubroutine, **SS** simple subroutine, **A**tomic, **C**ollective, **P**ure.
- **Numeric / bit models** (16.3–16.4): the abstract integer/real/bit models that define `DIGITS`, `EPSILON`, `HUGE`, `TINY`, `RADIX`, `PRECISION`, `RANGE`, `SPACING`, etc. — the basis of kind selection and FP reasoning.
- **Reduction functions**: `SUM`, `PRODUCT`, `MAXVAL`, `MINVAL`, `ALL`, `ANY`, `COUNT`, `NORM2`, `DOT_PRODUCT`, `MATMUL`, and the general `REDUCE(array, operation, ...)`.
- **Atomic / collective / image** (16.5–16.6): `ATOMIC_*`, `CO_SUM`/`CO_MAX`/`CO_MIN`/`CO_REDUCE`/`CO_BROADCAST`, `THIS_IMAGE`/`NUM_IMAGES`/`IMAGE_INDEX` — the coarray parallel toolkit.

## F2023 new intrinsics (the headline additions)
| Intrinsic | Class | Purpose |
|---|---|---|
| `SPLIT(string, set, pos[, back])` | SS (simple) | parse one token at a time from a string |
| `TOKENIZE(string, set, tokens[, separator])` | SS (simple) | split a string into all tokens at once |
| `SELECTED_LOGICAL_KIND(bits)` | T | logical kind with ≥ bits storage |
| `ACOSPI ASINPI ATANPI ATAN2PI COSPI SINPI TANPI` | E | circular trig (argument/result in half-turns: `sinpi(x)=sin(πx)`) |
| `ACOSD ASIND ATAND COSD SIND TAND` (+ `ATAND(Y,X)`) | E | degree trig |

Also: `MOVE_ALLOC` (noncoarray FROM), `SPLIT`, `TOKENIZE`, and elemental `MVBITS` are now **SIMPLE** (ch15).

## Intrinsic modules (16.10)
- **ISO_FORTRAN_ENV**: kind constants `INT8/16/32/64`, `REAL32/64/128`, `LOGICAL8…`; `INPUT_UNIT`/`OUTPUT_UNIT`/`ERROR_UNIT`; `IOSTAT_END`/`IOSTAT_EOR`; `COMPILER_VERSION()`/`COMPILER_OPTIONS()`; sync types `EVENT_TYPE`, `LOCK_TYPE`, `NOTIFY_TYPE`, `TEAM_TYPE`; `STAT_*` constants.
- **ISO_C_BINDING**: `C_INT`, `C_DOUBLE`, … kinds; `C_PTR`, `C_FUNPTR`, `C_NULL_PTR`; `C_LOC`, `C_F_POINTER`, `C_ASSOCIATED`, `C_SIZEOF`, `C_F_PROCPOINTER` (ch18).
- **IEEE_ARITHMETIC / IEEE_EXCEPTIONS / IEEE_FEATURES**: IEEE rounding, exceptions, NaN/Inf handling (ch17).

## Worked Example
F2023 string tokenizing and degree/circular trig:
```fortran
use iso_fortran_env, only: real64
character(:), allocatable :: tokens(:)
call tokenize('a,bb,ccc', set=',', tokens=tokens)   ! tokens = ['a  ','bb ','ccc']

real(real64) :: x = 0.5_real64
print *, sinpi(x)      ! sin(pi*0.5) = 1.0 exactly-ish — no pi round-off in the arg
print *, sind(90.0)    ! 1.0  (degrees)
print *, cospi(1.0_real64)  ! cos(pi) = -1.0
```
Kind selection from the numeric model:
```fortran
integer, parameter :: wp = selected_real_kind(15, 307)   ! ~ double
real(wp) :: a
print *, epsilon(a), huge(a), precision(a)               ! model inquiries
```
- **Demonstrates**: F2023 `TOKENIZE`, the circular-trig family (avoids manual `pi` round-off), degree trig, and numeric-model kind selection.

## Anti-patterns
- **Manual `sin(pi*x)`**: prefer `SINPI(x)` (F2023) — it avoids representing π inexactly in the argument, improving accuracy at integer/half multiples.
- **Hand-rolled string splitting**: use `SPLIT`/`TOKENIZE` (F2023) instead of index/scan loops.
- **Hardcoded kind numbers** (`real(8)`): use `ISO_FORTRAN_ENV` (`real64`) or `SELECTED_REAL_KIND` — kind integers are processor-dependent.
- **Naive `SUM` over many elements for FP64-quality results**: gives O(N·eps) error; use a pairwise/Kahan scheme in diagnostics (`feedback_diagnostic_precision_floor`). `NORM2` is already accurate for the 2-norm.
- **Assuming `SYSTEM_CLOCK` integer args may differ in kind**: F2023 requires same kind (ch04) — fix benchmark timing code.

## Key Takeaways
1. **F2023 adds `SPLIT`/`TOKENIZE`** (string parsing), **`SELECTED_LOGICAL_KIND`**, the **circular trig** (`SINPI`…) and **degree trig** (`SIND`…) families.
2. Use circular trig (`SINPI`) over `sin(pi*x)` for accuracy at rational multiples of π.
3. Numeric-model inquiries (`EPSILON`/`HUGE`/`PRECISION`/`RADIX`) are the rigorous basis for kind selection and FP reasoning.
4. Always source kinds from `ISO_FORTRAN_ENV` or `SELECTED_*_KIND`, never literal kind integers.
5. Coarray parallelism uses `CO_*` collectives, `ATOMIC_*`, and image-query intrinsics; `REDUCE` generalizes array reduction.

## Connects To
- **Ch 7**: Types — kind type parameters chosen via SELECTED_*_KIND.
- **Ch 15**: Procedures — SIMPLE/ELEMENTAL classification of intrinsics.
- **Ch 17**: IEEE modules — IEEE_ARITHMETIC/EXCEPTIONS/FEATURES.
- **Ch 18**: C interop — ISO_C_BINDING contents.
- **glossary.md / cheatsheet.md**: F2023-new-feature quick table.
