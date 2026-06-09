# Patterns & Techniques — C23

## Overflow-safe size arithmetic (`ckd_*`)
**When to use**: any multiply/add producing a buffer size, length, or index.
**How**: `if (ckd_mul(&bytes, count, sizeof elem)) return ERROR; p = malloc(bytes);`
**Trade-offs**: requires `<stdckdint.h>` (C23); replaces error-prone `count > SIZE_MAX/size` pre-checks. The defined-behavior answer to signed-overflow UB.

## Portable feature detection
**When to use**: writing headers that must compile across compilers/versions.
**How**: `#if __has_include(<h>)`, `#if __has_c_attribute(nodiscard)`, `#ifdef __STDC_NO_ATOMICS__`, gate on `__STDC_VERSION__ == 202311L`.
**Trade-offs**: define a fallback `#ifndef __has_c_attribute / #define __has_c_attribute(x) 0` for pre-C23 toolchains.

## `_Generic` type dispatch
**When to use**: type-generic functions/macros (the mechanism behind `<tgmath.h>`).
**How**: `#define abs_g(x) _Generic((x), int: abs, long: labs, double: fabs)(x)`
**Trade-offs**: controlling expression is unevaluated — no side effects from it; all branches must be valid for their types.

## Release/acquire publish-protect handoff
**When to use**: one thread produces data then signals another.
**How**: writer `atomic_store_explicit(&flag, 1, memory_order_release)` after writing payload; reader spins on `atomic_load_explicit(&flag, memory_order_acquire)` then reads payload.
**Trade-offs**: cheaper than `seq_cst` but you must prove the happens-before edge; default to `seq_cst` until profiling justifies weakening.

## One-time initialization
**When to use**: lazy init of a shared resource across threads.
**How**: `static once_flag f = ONCE_FLAG_INIT; call_once(&f, init);`
**Trade-offs**: portable; `init` runs exactly once with a happens-before to all callers.

## Directed-rounding interval bound
**When to use**: rigorous numerics, interval arithmetic.
**How**: `#pragma STDC FENV_ACCESS ON`, `fesetround(FE_UPWARD)`, compute, restore.
**Trade-offs**: REQUIRES `FENV_ACCESS ON` or the compiler may reorder FP ops across the mode change → wrong results.

## Single-rounding accumulation (`fma`)
**When to use**: accurate dot products, polynomial evaluation, compensated summation.
**How**: `s = fma(a, b, s);` plus `#pragma STDC FP_CONTRACT OFF` to control implicit contraction elsewhere.
**Trade-offs**: `fma` removes one rounding; not always faster — use for accuracy.

## Safe bounded string output
**When to use**: building strings into fixed buffers.
**How**: `int n = snprintf(buf, sizeof buf, fmt, …); if (n < 0 || (size_t)n >= sizeof buf) truncated();`
**Trade-offs**: universally portable (no Annex K needed); always null-terminates; detect truncation via the return value.

## Overlap-safe copy
**When to use**: ranges may overlap (shifting within a buffer).
**How**: `memmove(dst, src, n)` — never `memcpy`, which is `restrict` (UB on overlap).
**Trade-offs**: `memmove` slightly slower; correctness wins.

## `strncpy` field fill (with forced terminator)
**When to use**: fixed-width fields; NOT general bounded copy.
**How**: `strncpy(d, s, sizeof d); d[sizeof d - 1] = '\0';`
**Trade-offs**: `strncpy` does not null-terminate when `strlen(s) >= n` — always force it.

## Typed compile-time constants
**When to use**: replacing `#define` constants that need type/scope.
**How**: `constexpr double PI = 3.14159265358979;` usable in further constant expressions.
**Trade-offs**: must be exactly representable; not for atomic/VLA/volatile/restrict types.

## Fixed-ABI enums
**When to use**: enums crossing ABI boundaries or needing a known size.
**How**: `enum Color : unsigned char { RED, GREEN, BLUE };`
**Trade-offs**: values must fit the underlying type; gives stable size and well-defined conversions.

## Flexible array member allocation
**When to use**: a struct with a variable-length trailing array.
**How**: `struct p { size_t n; char d[]; }; struct p *q = malloc(sizeof *q + n);`
**Trade-offs**: the FAM contributes 0 to `sizeof`; you must add the tail size yourself.
