# Chapter 5: Expressions & Constant Expressions (Clause 6.5–6.6)

## Core Idea
Expression semantics are governed by **lvalue/rvalue conversion**, the **usual arithmetic conversions**, and a precise catalogue of **operators that introduce sequence points** vs those that don't. The biggest hazard cluster in C — overflow, division by zero, bad shifts, evaluation-order conflicts — all live here as undefined behavior.

## Frameworks Introduced

- **The sequence-point operators** (§6.5.13–6.5.18) — the only places mid-expression where one side is sequenced before the other:
  - `&&` (logical AND), `||` (logical OR): left fully sequenced before right; right not evaluated if result is determined (short-circuit).
  - `?:` (conditional): controlling expr sequenced before the chosen branch; only one branch evaluated.
  - `,` (comma operator): left evaluated as void, sequenced before right.
  - Function call (§6.5.3.3): sequence point after evaluating the designator and all arguments, before the call.
  - Everywhere else (e.g. `a + b`, `f() + g()`): operands are **unsequenced** → conflicting side effects on the same object = UB.

- **The arithmetic UB catalogue** (§6.5.5–6.5.9) — memorize these:
  - **Signed overflow** in `+ - * `: UB. Unsigned wraps (defined).
  - **Division/modulo by zero**: UB. `INT_MIN / -1` and `INT_MIN % -1`: UB (result not representable).
  - **Shift** `E1 << E2` / `>>`: UB if `E2 < 0`, `E2 ≥ width(promoted E1)`, or (for `<<` on signed `E1`) the result isn't representable; right shift of negative signed is implementation-defined.
  - **Pointer arithmetic** beyond `[0, n]` of the array (one-past-the-end is the legal limit): UB. Subtracting pointers into different arrays: UB.
  - **Dereferencing**: null, or one-past-the-end via `*`: UB.

- **Generic selection** `_Generic` (§6.5.2.1): compile-time type dispatch. The controlling expression is **not evaluated** — only its type selects the branch; only the selected expression is evaluated.

## Key Concepts
- **lvalue conversion**: an lvalue not of array type, when used where a value is needed, yields the stored value (and drops qualifiers); array → pointer-to-first-element ("array decay"); function → pointer-to-function.
- **Full expression**: an expression that is not a subexpression; there is a sequence point at its end (`;`).
- **`sizeof` / `alignof`** (§6.5.4.4): unevaluated operand (except VLA `sizeof`, which is evaluated); yield `size_t`.
- **Compound literal** `(T){…}` (§6.5.3.6): an unnamed object with automatic (block scope) or static (file scope) storage duration.
- **Atomic member access** (§6.5.3.4): accessing a member of an *atomic* struct/union object is UB.
- **`nullptr`**: the null pointer constant of type `nullptr_t`; converts to any pointer type.

## Mental Models
- **Two writes to the same object with no sequence point between ⇒ UB** — `a[i] = i++;`, `f(i++, i++)` (args unsequenced).
- **`_Generic` is the idiom behind `<tgmath.h>`** — use it to write type-generic wrappers.
- **Don't rely on left-to-right argument evaluation** — it's unspecified (but indeterminately sequenced, so no interleave).

## Code Examples
```c
/* §6.5.2.1 — _Generic compile-time type dispatch */
#define typename(x) _Generic((x),       \
    int:    "int",                      \
    double: "double",                   \
    default:"other")
```
- **What it demonstrates**: `_Generic` selects a branch by the static type of the controlling expression, which is never evaluated.

## Reference Tables

| Construct | Status |
|---|---|
| Signed `+ - *` overflow | UB |
| Unsigned overflow | defined (wraps mod 2^N) |
| `x / 0`, `x % 0` | UB |
| `INT_MIN / -1` | UB |
| `x << n`, `n ≥ width` or `n < 0` | UB |
| `(neg) >> n` | implementation-defined |
| pointer past one-past-end | UB |
| `ptr1 - ptr2` (different arrays) | UB |

## Constant expressions (6.6)
- **Integer constant expression**: required for array bounds (non-VLA), bit-field widths, enum values, `case` labels, `#if`. Only integer/enum constants, `sizeof`, `alignof`, `_Generic`, casts to integer.
- **Arithmetic / address constant expressions**: permitted in static initializers.
- C23 **`constexpr`** objects participate as named constants in constant expressions.

## Key Takeaways
1. Only `&& || ?: ,` and function-call argument evaluation introduce sequence points inside an expression — everything else leaves operands unsequenced.
2. Signed overflow, `/0`, bad shifts, and out-of-bounds pointer arithmetic are all UB; unsigned overflow is the lone defined wrap.
3. `_Generic`'s controlling expression is unevaluated — pure compile-time type selection.
4. Array-to-pointer and function-to-pointer decay happen on lvalue conversion.
5. `sizeof` is unevaluated except on a VLA.

## Connects To
- **Ch 02 (Abstract machine)**: the sequenced-before relation that these operators realize.
- **Ch 01 (Behavior model)**: every UB here is catalogued in Annex J.2.
- **Ch 14 (stdckdint)**: `ckd_add/sub/mul` give defined overflow-checked arithmetic.
