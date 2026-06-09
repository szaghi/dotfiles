# Chapter 3: Expressions, Conversions, Operators & Lambdas (Clause 7)

## Core Idea
Expressions carry a **type** and a **value category**; operands undergo **standard conversion sequences** and the **usual arithmetic conversions**; operators (including `<=>` and overloaded ones) resolve via overloading. Lambdas are closure-type prvalues, hugely extended in C++23 (`[]` with explicit object parameter, `constexpr`/`consteval` lambdas).

## Frameworks Introduced

- **Standard conversion sequence** (§7.3 `[conv]`): the ordered chain applied implicitly.
  1. lvalue-to-rvalue / array-to-pointer / function-to-pointer.
  2. integral/floating promotions and conversions, pointer/bool/qualification conversions.
  3. qualification adjustment.
  - Narrowing conversions are ill-formed in braced `{}` init.

- **The three-way comparison `<=>`** (§7.6.8 `[expr.spaceship]`): yields an ordering category prvalue.
  - Integral operands → `std::strong_ordering`; floating → `std::partial_ordering` (handles `unordered` for NaN); user types → whatever the operator returns.
  - `= default`ing `<=>` synthesizes all six relational operators (and `==` separately); this is the C++20 "spaceship" rewrite that collapsed comparison boilerplate.

- **Lambda expressions** (§7.5.5 `[expr.prim.lambda]`): `[capture](params) specifiers -> ret { body }`.
  - Captures: by-copy `[=]`/`[x]`, by-reference `[&]`/`[&x]`, init-capture `[y = expr]`, `[this]`/`[*this]`.
  - Specifiers: `mutable`, `constexpr`, `consteval`, `noexcept`, `static` (C++23 — for captureless lambdas).
  - **C++23: explicit object parameter** (`[](this Self&& self, …)`) — "deducing this" in lambdas enables recursive lambdas and perfect-forwarding call operators.
  - Templated lambdas: `[]<class T>(T x){…}` (C++20).

- **Constant expressions** (§7.7 `[expr.const]`): a **core constant expression** is one the abstract machine can evaluate at translation time with no UB, no non-constexpr calls, no modification of objects outside the evaluation.
  - **C++23 `if consteval`** (§7.5.x): branch on whether evaluation is happening in a constant-evaluated context — cleaner than `std::is_constant_evaluated()`.

## Key Concepts
- **Usual arithmetic conversions** (§7.4): bring operands to a common type via rank (mirrors C; extended for `<stdfloat>` types).
- **Temporary materialization** (§7.3.5 `[conv.rval]`): converts a prvalue to an xvalue (creates the temporary) only when needed — the mechanism behind guaranteed elision.
- **Operator evaluation order** (C++17): for `a.b`, `a->b`, `a[b]`, `a << b`, `a >> b`, assignment, and function-call argument-vs-postfix, the order is now defined (left operand sequenced before right for most).
- **Overflow**: signed integer overflow is UB; unsigned wraps. `INT_MIN/-1`, `/0` are UB.

## Mental Models
- **Default `<=>` to get all comparisons for free** — `auto operator<=>(const T&) const = default;` plus `== = default;` replaces six operators.
- **C++23 deducing-this unifies const/non-const/rvalue overloads** into one templated member — write the call operator once.
- **`if consteval` over `std::is_constant_evaluated()`** — the latter is a runtime-looking function that's easy to misuse inside `if constexpr`.
- **Braced init forbids narrowing** — `int{2.0}` is ill-formed; use it to catch lossy conversions at compile time.

## Code Examples
```cpp
// C++20 spaceship: one line → all comparisons
struct P { int x, y; auto operator<=>(const P&) const = default; };

// C++23 deducing this — recursive lambda, no Y-combinator
auto fact = [](this auto self, int n) -> int { return n <= 1 ? 1 : n * self(n - 1); };

// C++23 if consteval
constexpr int f(int n) {
    if consteval { return n * 2; }   // compile-time path
    else         { return n + 1; }   // runtime path
}
```
- **What it demonstrates**: the three headline C++20/23 expression features — `<=>`, deducing-this lambdas, `if consteval`.

## Reference Tables

| `<=>` operand type | Result category |
|---|---|
| integral | `std::strong_ordering` |
| floating-point | `std::partial_ordering` (NaN ⇒ `unordered`) |
| pointers | `std::strong_ordering` |
| user `= default` | member-wise, weakest of members |

| Lambda specifier | Effect | Since |
|---|---|---|
| `mutable` | non-const call operator | C++11 |
| `constexpr` | usable in constant expr | C++17 |
| `consteval` | immediate function | C++20 |
| `static` | static call operator (no captures) | C++23 |
| `this Self&& self` | explicit object param | C++23 |

## Key Takeaways
1. `<=>` plus `= default` synthesizes all comparisons; floating-point yields `partial_ordering` (NaN-aware).
2. C++23 deducing-this (`this Self&& self`) collapses const/ref overloads and enables recursive lambdas.
3. `if consteval` cleanly splits compile-time vs runtime paths — prefer it over `std::is_constant_evaluated()`.
4. Braced `{}` initialization rejects narrowing conversions — a free correctness check.
5. C++17 defined the evaluation order of most operators; signed overflow remains UB.

## Connects To
- **Ch 01 (Value categories)**: prvalue/xvalue/lvalue drive conversions and reference binding.
- **Ch 04 (constexpr/consteval/constinit)**: the constant-evaluation specifier family.
- **Ch 06 (Overloading)**: how operator and conversion candidates are ranked.
- **Ch 07 (Concepts)**: constrained lambdas `[]<C T>(T)`.
