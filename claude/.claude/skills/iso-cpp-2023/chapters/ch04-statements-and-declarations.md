# Chapter 4: Statements & Declarations (Clauses 8, 9)

## Core Idea
Declarations bind specifiers (storage class, `auto`, `constexpr`/`consteval`/`constinit`, attributes) to declarators. The constant-evaluation specifier family and structured bindings are the modern workhorses; C++23 adds the `[[assume]]` optimization attribute.

## Frameworks Introduced

- **The constant-evaluation specifier family** (§9.2.6 `[dcl.constexpr]`):
  - **`constexpr`** — *may* be evaluated at compile time; functions are implicitly `inline`; usable in constant expressions if all inputs are. C++23 hugely relaxes what `constexpr` functions may do (e.g. `goto`, non-literal types in unevaluated paths, `static constexpr` locals).
  - **`consteval`** — an *immediate function*: every call must produce a constant; no runtime calls. C++23: an immediate function may call other immediate functions freely (`if consteval` interplay).
  - **`constinit`** — guarantees **static-initialization** (no dynamic init, no static-init-order fiasco); does **not** imply `const`.
  - When to use: `constexpr` for "can run at compile time," `consteval` for "must," `constinit` for "initialize before `main` with no ordering surprise."

- **Structured bindings** (§9.6 `[dcl.struct.bind]`): `auto [a, b, c] = expr;` decomposes arrays, `tuple`-likes (via `get<>`/`tuple_size`), and public-data-member structs.
  - C++20: can be `[[maybe_unused]]`; capturable in lambdas.

- **`auto` deduction** (§9.2.x `[dcl.type.auto]`): template-argument-deduction rules; `decltype(auto)` preserves value category/reference; placeholder return types; abbreviated function templates `auto f(auto x)`.

- **Attributes** (§9.12 `[dcl.attr]`): `[[noreturn]]`, `[[deprecated]]`, `[[fallthrough]]`, `[[nodiscard]]`/`[[nodiscard("reason")]]`, `[[maybe_unused]]`, `[[likely]]`/`[[unlikely]]`, **C++23 `[[assume(expr)]]`**.

## Key Concepts
- **Selection/iteration with init-statement** (C++17/20): `if (auto x = f(); cond)`, `switch (init; cond)`, and range-`for` with init `for (auto v = g(); auto& e : v.items())` (C++20).
- **`[[assume(expr)]]`** (C++23): `expr` is *not evaluated*; if it would be false at that point, behavior is UB — pure optimizer hint. **Never put side effects in it.**
- **`[[likely]]`/`[[unlikely]]`**: branch-probability hints on statements.
- **Range-based for temporaries** (C++23 fix): lifetime of temporaries in the range-initializer is extended for the whole loop (closing a long-standing dangling-reference footgun).

## Mental Models
- **`constinit` ≠ `const`** — it controls *when* (static init), not mutability. Use it for global mutable state that must avoid the init-order fiasco.
- **`[[assume]]` is a loaded gun**: a false assumption is UB the optimizer will exploit destructively. Use only for invariants you can prove, never to "document."
- **`decltype(auto)` when you need to preserve referenceness** — plain `auto` strips top-level cv and reference.
- **Structured bindings + `if`-init** is the idiom for map/insertion: `if (auto [it, ok] = m.insert(...); ok) …`.

## Code Examples
```cpp
auto [it, inserted] = m.try_emplace(key, value);   // structured binding
if (auto* p = lookup(id); p != nullptr) use(*p);    // if with init-statement

constinit int counter = compute_seed();             // static init, no order fiasco
consteval int square(int n) { return n * n; }       // must be compile-time

int fast_div(int x) {
    [[assume(x > 0)]];                                // C++23 optimizer hint (UB if false)
    return x / 2;
}
```
- **What it demonstrates**: structured bindings, init-statements, and the C++23/20 specifier + attribute set.

## Reference Tables

| Specifier | Compile-time? | Implies | Use |
|---|---|---|---|
| `constexpr` (fn) | may | `inline` | run at compile or runtime |
| `consteval` (fn) | must | `inline` | immediate function |
| `constexpr` (var) | yes | `const` | compile-time constant |
| `constinit` (var) | static init | — (NOT const) | avoid init-order fiasco |

| Attribute | Role | Since |
|---|---|---|
| `[[nodiscard]]` | warn if return ignored | C++17 |
| `[[likely]]`/`[[unlikely]]` | branch hint | C++20 |
| `[[assume(e)]]` | UB-if-false optimizer hint | C++23 |
| `[[no_unique_address]]` | allow empty-member overlap | C++20 |

## Key Takeaways
1. `constexpr` *may*, `consteval` *must* run at compile time; `constinit` guarantees static init without implying const.
2. Structured bindings decompose arrays/tuples/structs; pair with `if`-init for clean error handling.
3. C++23 `[[assume(e)]]` is a non-evaluated optimizer hint — UB if false; never place side effects inside.
4. Init-statements in `if`/`switch`/range-`for` scope a variable to the construct.
5. C++23 fixes range-`for` temporary lifetime — temporaries in the range-initializer now live for the whole loop.

## Connects To
- **Ch 03 (Constant expressions)**: `if consteval` and core-constant-expression rules.
- **Ch 12 (Utilities)**: structured bindings over `std::tuple`/`std::pair`/`std::expected`.
- **Ch 05 (Classes)**: `[[no_unique_address]]` and special-member `= default`.
