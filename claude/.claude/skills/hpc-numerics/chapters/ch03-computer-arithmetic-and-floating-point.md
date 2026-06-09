# Chapter 3: Computer Arithmetic & Floating-Point Error

## Core Idea
Computers compute in finite bit-strings, not real numbers, so every operation can introduce **round-off error**. The defining facts are: most decimals (even 0.1) aren't exactly representable, floating-point addition/multiplication are **not associative**, and subtracting nearly-equal numbers causes **catastrophic cancellation**. Numerical algorithm design is largely the art of controlling these.

## Frameworks Introduced

- **The floating-point representation** (significand × base^exponent):
  - A number is stored as a **sign**, a **significand/mantissa** (t digits), and an **exponent** e ∈ [L, U]. **Normalized** numbers have a nonzero leading digit, so (in binary) the leading 1 is implicit and free.
  - **IEEE 754** is the standard: single (32-bit) and double (64-bit) precision, with special values **±∞**, **NaN**, signed zero, and **subnormals** (gradual underflow near zero, using the smallest exponent).
  - **Integer overflow** is separate: exceeding the integer range wraps (unsigned) or is **undefined behavior** (signed, per the C standard).

- **The error model** (how round-off enters):
  - **Machine epsilon (ε_mach / unit round-off)**: the gap between 1 and the next representable number — the relative error bound of a single rounded operation. ~1.1e-16 for double, ~6e-8 for single.
  - **Representation error**: storing a real number costs up to ε_mach relative error (1/10 is inexact in binary).
  - **Guard digits**: extra digits during an operation needed to round correctly; one is not always enough.
  - Under addition, **relative errors add**; this is benign *unless* cancellation amplifies them.

- **The three error hazards** (memorize these):
  1. **Non-associativity**: `(a + b) + c ≠ a + (b + c)` in floating point — round-off depends on order. This is why compilers can't freely reassociate (and why `-ffast-math`/parallel reductions change results).
  2. **Catastrophic cancellation**: subtracting two nearly-equal numbers cancels the leading (accurate) digits, promoting tiny relative input errors to a *large* relative output error — the dominant cause of numerical disaster.
  3. **Overflow/underflow**: results too large/small for the exponent range → ±∞ or 0 (or subnormals).

## Key Concepts
- **Cancellation example (the abc-formula)**: solving `ax² + bx + c = 0` via the textbook formula loses accuracy when `b² ≫ 4ac` (the `-b + √(b²−4ac)` subtraction cancels). The stable form computes one root via the formula and the other via `x₊x₋ = c/a` — avoiding the subtraction. Residual `f(x)` drops from ~ε to ~ε³.
- **Relative vs absolute error**: relative error (error/value) is the meaningful measure for floating point; cancellation is exactly the case where small relative *input* error becomes large relative *output* error.
- **Order matters**: summing many numbers is most accurate **smallest-to-largest** (or with compensated summation); largest-first loses the small contributions to round-off.
- **Parallel reductions reorder** additions → bitwise-different results across thread/process counts (a direct consequence of non-associativity).

## Mental Models
- **Never test floating-point equality** — `a == b` after arithmetic is almost always wrong; compare `|a − b| < tol` with a tolerance scaled to the magnitudes.
- **Hunt for cancellation in any subtraction of similar quantities** — rewrite the formula to avoid it (conjugate multiplication, the abc-formula trick, `expm1`/`log1p`). This is the single highest-leverage numerical fix.
- **Reassociation changes results** — `-ffast-math`, compiler reordering, and parallel reductions all break bitwise reproducibility; if you need it, fix the summation order or use compensated (Kahan/pairwise) summation.
- **Sum smallest-to-largest, or use Kahan** — for long sums of disparate magnitudes, naive accumulation loses the small terms; compensated summation recovers them (relevant to conservation diagnostics and precision floors).

## Code Examples
```text
Machine epsilon (double):  ε_mach ≈ 2.22e-16     (single ≈ 1.19e-7)
Non-associativity:         fl(fl(a+b)+c) ≠ fl(a+fl(b+c))

Stable quadratic roots (avoid cancellation when b² ≫ 4ac):
    q  = -0.5 * (b + sign(b)*sqrt(b*b - 4*a*c))
    x1 = q / a
    x2 = c / q                 // second root via product, no cancelling subtraction

Kahan compensated summation (recovers lost low-order bits):
    sum = 0; comp = 0
    for x in data:
        y = x - comp;  t = sum + y;  comp = (t - sum) - y;  sum = t
```
- **What it demonstrates**: ε_mach, non-associativity, the cancellation-free quadratic, and Kahan summation.

## Reference Tables

| Hazard | Cause | Fix |
|---|---|---|
| non-associativity | round-off order-dependent | fixed order / Kahan; don't reassociate |
| catastrophic cancellation | subtracting near-equal values | rewrite formula to avoid subtraction |
| overflow/underflow | exceed exponent range | scale; check for ±∞/0 |
| accumulation error | long naive sums | sort smallest-first / compensated sum |

| Type | ε_mach | significand bits |
|---|---|---|
| single (float) | ~1.19e-7 | 23 (+1 implicit) |
| double | ~2.22e-16 | 52 (+1 implicit) |

## Key Takeaways
1. Floating point is finite-precision: most decimals are inexact, ε_mach bounds the relative error of one operation.
2. Floating-point add/multiply are **not associative** — order changes results, so reassociation (`-ffast-math`, parallel reductions) breaks bitwise reproducibility.
3. **Catastrophic cancellation** (subtracting near-equal numbers) is the dominant numerical hazard — rewrite formulas to avoid it (e.g. the stable quadratic).
4. Never test FP equality; compare with a magnitude-scaled tolerance.
5. For long sums of disparate magnitudes, sum smallest-first or use compensated (Kahan/pairwise) summation to preserve accuracy.

## Connects To
- **Ch 04 (Conditioning & stability)**: how error propagates through whole algorithms.
- **Ch 07 (Numerical LA)**: round-off drives pivoting and the need for stable factorizations.
- **Ch 09 (Performance)**: the reproducibility cost of parallel-reduction reordering.
