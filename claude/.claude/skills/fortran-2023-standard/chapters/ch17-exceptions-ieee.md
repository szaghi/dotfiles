# Chapter 17 (Clause 17): Exceptions and IEEE arithmetic

## Core Idea
Fortran's binding to **ISO/IEC/IEEE 60559:2020** floating-point: exception flags, rounding modes, halting control, NaN/Inf handling, and the support-inquiry functions — all via the three IEEE intrinsic modules. The clause that makes FP behavior portable *and* inspectable.

## Frameworks Introduced
- **Three modules**:
  - `IEEE_EXCEPTIONS`: flag types, `IEEE_GET/SET_FLAG`, `IEEE_GET/SET_HALTING_MODE`, `IEEE_GET/SET_STATUS`, `IEEE_GET/SET_MODES`.
  - `IEEE_ARITHMETIC`: the arithmetic ops + `IEEE_VALUE`, `IEEE_CLASS`, `IEEE_IS_*`, `IEEE_FMA`, `IEEE_MAX/MIN[_MAG/_NUM]`, `IEEE_RINT`, `IEEE_INT`, `IEEE_SCALB`, `IEEE_NEXT_AFTER`, rounding mode get/set, and the `IEEE_SUPPORT_*` inquiries.
  - `IEEE_FEATURES`: named feature constants to request specific IEEE support.
- **Five exceptions** (17.3): `IEEE_OVERFLOW`, `IEEE_UNDERFLOW`, `IEEE_DIVIDE_BY_ZERO`, `IEEE_INVALID`, `IEEE_INEXACT`. Each has a sticky flag (quiet/signaling) set when the condition occurs.
- **Rounding modes** (17.4): `IEEE_NEAREST` (default, round-half-even), `IEEE_TO_ZERO`, `IEEE_UP`, `IEEE_DOWN`, `IEEE_AWAY` (round-half-away). Get/set with `IEEE_GET/SET_ROUNDING_MODE`.
- **Halting** (17.6): `IEEE_SET_HALTING_MODE(flag, halting)` — whether an exception traps (aborts) or just sets the flag.
- **Support inquiries** (17.11.55+): `IEEE_SUPPORT_DATATYPE`, `IEEE_SUPPORT_NAN`, `IEEE_SUPPORT_INF`, `IEEE_SUPPORT_FLAG`, `IEEE_SUPPORT_HALTING`, `IEEE_SUPPORT_ROUNDING` — *always query before relying on a feature*; not every kind/processor supports full IEEE.

## Key Concepts
- **Sticky flags**: once an exception flag is signaling it stays signaling until explicitly cleared — `IEEE_GET_FLAG` reads, `IEEE_SET_FLAG` clears/sets. Flags are saved/restored around procedure calls by the standard.
- **`IEEE_FMA(a,b,c)`** = fused multiply-add `a*b+c` with a single rounding — better accuracy and the building block for compensated algorithms.
- **`IEEE_VALUE(x, class)`**: construct special values (`IEEE_QUIET_NAN`, `IEEE_POSITIVE_INF`, …); `IEEE_CLASS(x)` classifies; `IEEE_IS_NAN`/`IEEE_IS_FINITE`/`IEEE_IS_NORMAL` test.
- **Save/restore pattern**: bracket a region that changes rounding/halting with `IEEE_GET_MODES`/`IEEE_SET_MODES` (or get/set status) so callers are unaffected.
- **F2023 NaN-number rule**: `IEEE_MAX_NUM`/`IEEE_MIN_NUM` with one number + one signaling NaN now return the **number** (was NaN in F2018) — ch04 delta.

## Reference Tables
### Exceptions and rounding
| Exception | Trigger |
|---|---|
| `IEEE_OVERFLOW` | result too large |
| `IEEE_UNDERFLOW` | result subnormal/too small |
| `IEEE_DIVIDE_BY_ZERO` | x/0 |
| `IEEE_INVALID` | 0/0, sqrt(-1), Inf−Inf |
| `IEEE_INEXACT` | rounded result |

| Rounding mode | Behavior |
|---|---|
| `IEEE_NEAREST` | round half to even (default) |
| `IEEE_TO_ZERO` | truncate |
| `IEEE_UP` / `IEEE_DOWN` | toward +∞ / −∞ |
| `IEEE_AWAY` | round half away from zero |

## Worked Example
Detect exceptions around a kernel, restoring caller state:
```fortran
use, intrinsic :: ieee_exceptions
use, intrinsic :: ieee_arithmetic
logical :: flags(5), divz
type(ieee_status_type) :: save_status

call ieee_get_status(save_status)            ! save caller FP state
call ieee_set_flag(ieee_all, .false.)        ! clear flags
call ieee_set_halting_mode(ieee_overflow, .false.)  ! flag, don't trap

y = risky_kernel(x)                          ! compute

call ieee_get_flag(ieee_divide_by_zero, divz)
if (divz) print *, 'division by zero occurred'
call ieee_set_status(save_status)            ! restore caller state

! FMA for compensated accuracy:
r = ieee_fma(a, b, c)                         ! a*b + c, one rounding
```
- **Demonstrates**: save/restore of FP status, non-trapping exception detection via sticky flags, and `IEEE_FMA`.

## Anti-patterns
- **FP32-store + FP64-compute on consumer NVIDIA GPUs**: a *trap* — consumer GPUs have a 1:64 FP64:FP32 throughput ratio (vs 1:2 on datacenter parts), so mixed precision is **strictly slower** than full FP64; the storage saving doesn't pay for the compute penalty (`reference_consumer_gpu_fp64_trap`).
- **Naive `sum()` for FP64-quality diagnostics**: O(N·eps) accumulation error masks true kernel behavior — use pairwise/Kahan or `IEEE_FMA`-based compensation (`feedback_diagnostic_precision_floor`).
- **Changing rounding/halting without restoring**: corrupts caller FP state — always bracket with get/set status or modes.
- **Assuming full IEEE support**: query `IEEE_SUPPORT_*` first; some kinds (e.g. extended/half) or processors lack NaN/Inf/halting.
- **Comparing with `==` a value that may be NaN**: NaN ≠ NaN; use `IEEE_IS_NAN`.

## Key Takeaways
1. Five sticky exception flags; query with `IEEE_GET_FLAG`, clear with `IEEE_SET_FLAG`; saved/restored around calls.
2. Default rounding is `IEEE_NEAREST` (round-half-even); change/restore via get/set rounding mode, bracketed by status save/restore.
3. `IEEE_FMA` (single-rounding `a*b+c`) is the accuracy primitive for compensated summation/dot products.
4. **Always `IEEE_SUPPORT_*`-query before relying on a feature** — IEEE support is per-kind, per-processor.
5. Mixed FP32-store/FP64-compute is a performance trap on consumer GPUs; verify precision *and* throughput against measurements.

## Connects To
- **Ch 2**: Normative references — ISO/IEC/IEEE 60559:2020.
- **Ch 10**: Expressions — parentheses pin evaluation order for reproducibility.
- **Ch 13**: I/O editing — rounding edit descriptors mirror IEEE modes.
- **Ch 16**: Intrinsics — numeric model inquiries (EPSILON/HUGE/SPACING).
