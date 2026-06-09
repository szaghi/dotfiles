# Chapter 6: Overload Resolution & Operators (Clause 12)

## Core Idea
When multiple functions could be called, **overload resolution** picks the unique best match by ranking **implicit conversion sequences** argument-by-argument. Understanding the ranking — and where ties become ambiguities or where templates/SFINAE/concepts intervene — is the key to predictable C++ APIs.

## Frameworks Introduced

- **Overload resolution** (§12.2 `[over.match]`): the three-step process.
  1. **Candidate set**: gather viable functions (member, non-member, operator, template specializations, ADL results).
  2. **Viability**: each must be callable with the arguments (arity, accessible, constraints satisfied).
  3. **Best match**: rank by implicit conversion sequences per argument; the best must be ≥ all others on every argument and strictly better on at least one — else **ambiguous** (ill-formed).

- **Implicit conversion sequence ranking** (best → worst):
  1. **Exact match** (identity, lvalue-to-rvalue, qualification adjustment).
  2. **Promotion** (integral/floating promotion).
  3. **Conversion** (other standard conversions, e.g. `int`→`double`, derived*→base*).
  4. **User-defined conversion** (one converting constructor or conversion operator).
  5. **Ellipsis** (`...`) — worst.
  - A standard conversion sequence always beats a user-defined one, which always beats ellipsis.

- **Tie-breakers** when ICSs are equal: non-template beats template; more-specialized template beats less (partial ordering); more-constrained (concepts) beats less-constrained.

## Key Concepts
- **Argument-dependent lookup (ADL)** (§6.5.x `[basic.lookup.argdep]`): unqualified function names also search the namespaces of their argument types — why `swap(a, b)` and `begin(r)` find user overloads.
- **Operator overloading** (§12.4 `[over.oper]`): most operators overloadable as members or free functions; `<=>` (C++20) auto-generates relational operators; `[]` supports multiple subscripts in C++23 (`m[i, j]`).
- **Conversion functions** (§12.4.x `[class.conv]`): `operator T() const`; mark `explicit` to avoid surprising implicit conversions.
- **SFINAE → Concepts**: substitution failure removes a template from the candidate set silently; C++20 concepts (`requires`) make this readable and improve diagnostics.
- **Deducing this** (C++23): a single explicit-object-parameter member replaces const/non-const/lvalue/rvalue overload sets.

## Mental Models
- **Prefer concepts over SFINAE** for constraining overloads — `requires` clauses give clear candidate-set control and far better errors than `std::enable_if`.
- **Mark single-argument constructors and conversion operators `explicit`** unless implicit conversion is genuinely desired — implicit user-defined conversions are a top source of overload surprises.
- **C++23 multidimensional `operator[]`** (`mdspan`-style `m[i, j, k]`) replaces the old `operator()` workaround.
- **Hidden-friend operators** keep operators out of the enclosing namespace's overload set, reducing ADL pollution.

## Code Examples
```cpp
// C++23 multidimensional subscript
struct Matrix {
    double  operator[](size_t i, size_t j) const;   // m[i, j], not m(i, j)
};

// Concept-constrained overload (preferred over enable_if SFINAE)
template <std::integral T>  void f(T);   // chosen for integral
template <std::floating_point T> void f(T);

// C++23 deducing-this: one member for all qualifier overloads
struct S {
    template <class Self>
    auto&& value(this Self&& self) { return std::forward<Self>(self).v; }
};
```
- **What it demonstrates**: C++23 multi-arg subscript, concept-based overloading, deducing-this collapsing overload sets.

## Reference Tables

| ICS rank | Example |
|---|---|
| 1 exact match | `int`→`int`, array→pointer |
| 2 promotion | `short`→`int`, `float`→`double` |
| 3 conversion | `int`→`double`, `Derived*`→`Base*` |
| 4 user-defined | one converting ctor / `operator T` |
| 5 ellipsis | `...` parameter |

| Tie-break (equal ICS) | Winner |
|---|---|
| template vs non-template | **non-template** |
| two templates | more specialized |
| two constrained | more constrained |

## Key Takeaways
1. Overload resolution ranks per-argument conversion sequences; the winner must be ≥ on all and > on at least one argument, else ambiguous.
2. Standard conversion beats user-defined beats ellipsis; non-template beats template; more-constrained beats less.
3. ADL is why free `swap`/`begin` find user overloads — design "customization points" around it.
4. Prefer concepts (`requires`) over `enable_if` SFINAE for clarity and diagnostics.
5. C++23 adds multidimensional `operator[]` and deducing-this to collapse qualifier overload sets.

## Connects To
- **Ch 07 (Templates/Concepts)**: partial ordering and constraint subsumption drive the tie-breakers.
- **Ch 03 (Conversions)**: the standard conversion sequences being ranked.
- **Ch 05 (Classes)**: defaulted `<=>` and conversion operators.
