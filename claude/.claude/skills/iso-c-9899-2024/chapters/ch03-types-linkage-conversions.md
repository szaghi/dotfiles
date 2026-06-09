# Chapter 3: Concepts — Types, Linkage, Storage Duration & Conversions (Clause 6.2–6.3)

## Core Idea
The type system, the three linkages, the four storage durations, and the **integer-conversion-rank → integer-promotion → usual-arithmetic-conversion** pipeline together determine the type and value of every expression. Get the rank rules wrong and you misread every mixed-signedness expression.

## Frameworks Introduced

- **The conversion pipeline** (§6.3.1.1, §6.3.1.8): how a binary arithmetic operator picks its result type.
  1. **Integer conversion rank** orders all integer types (`bool` < … < `signed char` < `short` < `int` < `long` < `long long`; unsigned == its signed counterpart's rank; `_BitInt(N)` ranks by width and is **exempt from promotion**).
  2. **Integer promotion**: anything with rank ≤ `int` whose values fit in `int` → `int`, else → `unsigned int`. Value- and sign-preserving. `_BitInt` is NOT promoted.
  3. **Usual arithmetic conversions**: after promotion, convert the lower-rank operand to the higher; on equal-rank mixed-signedness, the **signed operand converts to unsigned** (the classic `-1 > 0u` trap).
  - When to use: any time signed and unsigned, or differing widths, meet in `+ - * / % < > == & | ^`.

- **Three linkages** (§6.2.2): **external** (one entity program-wide), **internal** (`static` at file scope — one entity per TU), **none** (block-scope locals, params, tags, typedefs — unique each declaration).

- **Four storage durations** (§6.2.4): **static** (whole program, init once), **thread** (`thread_local`, per-thread), **automatic** (block locals + some compound literals), **allocated** (`malloc` family). Temporary lifetime applies to non-lvalue struct/union objects with array members.

## Key Concepts
- **bool / true / false / nullptr** are now keywords in C23 (no `<stdbool.h>` needed for `bool`); `nullptr` has type `nullptr_t`.
- **`_BitInt(N)`** (§6.2.5): bit-precise integers; exempt from integer promotion — a `_BitInt` binary op yields the higher-ranked `_BitInt`, not `int`.
- **Standard integer types**: `signed char`, `short`, `int`, `long`, `long long` (+ unsigned counterparts, `bool`); plus bit-precise and extended families.
- **Real floating**: `float ⊂ double ⊂ long double` (value-set subsets); decimal floats `_Decimal32/64/128` are a **conditional feature**.
- **Scalar types** = arithmetic + pointer + `nullptr_t`. **Aggregate** = array + struct. **Character types** = `char`, `signed char`, `unsigned char` (`char` matches one of the latter two but is a distinct type).
- **Qualifiers**: `const`, `volatile`, `restrict`, and the separate **`_Atomic`** qualifier (may differ in size/representation/alignment from the unqualified type).
- **Indeterminate / lifetime UB** (§6.2.4): using a pointer after its pointee's lifetime ends ⇒ UB; the pointer representation becomes indeterminate.

## Mental Models
- **Mixed signed/unsigned of equal rank ⇒ everything goes unsigned.** `if (x - 1 < sizeof(a))` with signed `x` is a footgun: `sizeof` yields `size_t` (unsigned), so the comparison is unsigned.
- **Unsigned arithmetic never overflows** — it wraps mod 2^N (defined). Signed overflow is UB.
- **`_BitInt` breaks your promotion intuition**: `_BitInt(4) a, b; a*b` stays `_BitInt(4)`, no widening to `int`.
- **`char`'s signedness is implementation-defined** — never store non-basic-charset values in plain `char` and expect a sign.

## Code Examples
```c
/* §6.3.1.8 EXAMPLE — _BitInt is exempt from integer promotion */
_BitInt(2) a = 1;
_BitInt(3) b = 2;
/* a + b : a converts to _BitInt(3); result type is _BitInt(3), NOT int */
```
- **What it demonstrates**: bit-precise integers convert toward the higher rank, never auto-promoting to `int`.

## Reference Tables

| Operand pair | Result after usual arithmetic conversions |
|---|---|
| same type | unchanged |
| both signed, diff rank | lower → higher rank |
| both unsigned, diff rank | lower → higher rank |
| signed vs unsigned, **unsigned rank ≥ signed rank** | signed → unsigned |
| signed vs unsigned, signed rank > unsigned & can hold all unsigned values | unsigned → signed |
| signed vs unsigned, otherwise | both → unsigned version of signed type |

| Linkage | Scope of identity | Example |
|---|---|---|
| external | whole program | non-`static` file-scope object/function |
| internal | one TU | `static` file-scope object/function |
| none | per declaration | block locals, params, typedefs, tags |

## Key Takeaways
1. Signed+unsigned equal-rank ⇒ result is **unsigned** — source of silent wrap-comparison bugs.
2. Integer promotion lifts small types to `int`/`unsigned int`, **but `_BitInt` is exempt**.
3. `bool`, `true`, `false`, `nullptr` are C23 keywords; `static_assert`, `alignas`, `alignof`, `thread_local` too.
4. Using a pointer past its pointee's lifetime ⇒ UB; representation is indeterminate.
5. `_Atomic T` may differ in size/alignment from `T` — never alias them.

## Connects To
- **Ch 04 (Expressions)**: operators that trigger the usual arithmetic conversions.
- **Ch 05 (Declarations)**: storage-class specifiers that set linkage and duration.
- **Ch 11 (Atomics)**: the `_Atomic` qualifier semantics.
- **Ch 12 (Annex F)**: floating-type representation and IEC 60559 binding.
