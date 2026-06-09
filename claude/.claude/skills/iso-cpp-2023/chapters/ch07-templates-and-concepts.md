# Chapter 7: Templates & Concepts (Clauses 13, 18)

## Core Idea
Templates are C++'s compile-time generic-programming engine. C++20 **concepts** turned ad-hoc SFINAE constraints into first-class, named, **subsumption-ordered** predicates that constrain templates and produce readable diagnostics.

## Frameworks Introduced

- **Template constraints & concepts** (§13.5 `[temp.constr]`, §13.7.9 `[temp.concept]`):
  - A **concept** is a named compile-time bool predicate: `template<class T> concept C = requires(T t){ … };`.
  - A **`requires`-clause** constrains a template: `template<C T> void f(T)` or `template<class T> requires C<T> void f(T)`.
  - A **`requires`-expression** tests validity: simple (`t + t`), type (`typename T::value_type`), compound (`{ expr } -> Concept`), nested (`requires C<T>`).
  - **Subsumption**: a more-constrained overload is preferred; the partial order on constraints (built from atomic constraints) breaks overload ties.

- **Template argument deduction** (§13.10.3 `[temp.deduct]`): deduce parameters from call arguments; forwarding references `T&&` collapse references; **CTAD** (class template argument deduction, C++17) plus deduction guides let `std::vector v{1,2,3}` deduce `vector<int>`.

- **Variadic templates & fold expressions** (§13.7.4 `[temp.variadic]`): `template<class... Ts>`; parameter packs expand with `...`; **fold expressions** `(args + ...)`, `(... && preds)` collapse a pack with a binary operator.

## Key Concepts
- **Fundamental library concepts** (Clause 18 `[concepts]`): `same_as`, `convertible_to`, `derived_from`, `integral`, `floating_point`, `assignable_from`, `swappable`, `movable`, `copyable`, `semiregular`, `regular`, `equality_comparable`, `totally_ordered`, `invocable`, `predicate`, `relation`.
- **Abbreviated function templates**: `auto f(std::integral auto x)` — constrained `auto` parameters.
- **`if constexpr`**: compile-time branch that discards the untaken branch — replaces tag dispatch and much SFINAE.
- **Alias templates / variable templates**: `template<class T> using X = …;`, `template<class T> constexpr bool v = …;`.
- **Non-type template parameters (NTTP)**: C++20 allows class-type NTTPs (structural types), enabling compile-time strings as template args.

## Mental Models
- **Constrain with concepts, branch with `if constexpr`, fold with fold-expressions** — these three replace nearly all classic SFINAE/tag-dispatch metaprogramming.
- **`requires requires` is a smell** — `template<class T> requires requires(T t){ t.foo(); }` should usually be a named concept.
- **CTAD removes the type-spelling boilerplate** — write `std::lock_guard lk(m);` not `std::lock_guard<std::mutex>`.
- **Subsumption only works through named concepts** — two syntactically different `requires`-clauses that aren't decomposed into shared atomic constraints won't order; factor shared constraints into concepts.

## Code Examples
```cpp
// Named concept + constrained template
template <class T>
concept Hashable = requires(T t) { { std::hash<T>{}(t) } -> std::convertible_to<std::size_t>; };

template <Hashable K, class V> class HashMap { /* ... */ };

// Fold expression: variadic sum and all-of
template <class... Ts> auto sum(Ts... xs) { return (xs + ... + 0); }
template <class... Ps> bool all(Ps... ps) { return (... && ps); }

// if constexpr replaces tag dispatch
template <class T> auto serialize(const T& x) {
    if constexpr (std::integral<T>) return to_int_bytes(x);
    else                            return to_generic(x);
}
```
- **What it demonstrates**: named concepts, fold expressions, and `if constexpr` — the modern metaprogramming trio.

## Reference Tables

| Constraint tool | Use |
|---|---|
| `template<C T>` | constrain by concept |
| `requires C<T>` | requires-clause |
| `requires(T t){…}` | requires-expression (validity test) |
| `if constexpr` | compile-time branch, discard untaken |
| `(pack op ...)` | fold expression |

| Library concept | Meaning |
|---|---|
| `regular<T>` | semiregular + equality_comparable |
| `semiregular<T>` | copyable + default_initializable |
| `invocable<F,Args…>` | `F` callable with `Args…` |
| `totally_ordered<T>` | `< <= > >= ==` consistent |
| `convertible_to<F,T>` | implicit + explicit conversion valid |

## Key Takeaways
1. Concepts are named, subsumption-ordered predicates — they replace SFINAE for constraining and ordering overloads.
2. The metaprogramming trio: **concepts** (constrain), **`if constexpr`** (branch), **fold expressions** (reduce packs).
3. CTAD + deduction guides eliminate redundant template-argument spelling.
4. Subsumption requires shared *named* atomic constraints — factor common predicates into concepts to get ordering.
5. C++20 allows class-type (structural) NTTPs — compile-time strings as template parameters.

## Connects To
- **Ch 06 (Overloading)**: constraint subsumption is the overload tie-breaker.
- **Ch 14 (Ranges)**: the ranges library is built entirely on iterator/range concepts.
- **Ch 03 (Lambdas)**: constrained generic lambdas `[]<C T>(T)`.
