# Chapter 2: Modern C++ for HPC — From Primitive to Idiomatic

## Core Idea
HPC C++ rewards *idiomatic modern* code: **RAII** and **smart pointers** for safe memory, `auto`/type deduction and templates for zero-overhead abstraction, `move` semantics to avoid copies, and `constexpr` to push work to compile time. The goal is abstraction that costs nothing at runtime ("you don't pay for what you don't use").

## Frameworks Introduced

- **RAII & smart pointers** (the memory-ownership model):
  - **RAII**: acquire a resource in a constructor, release it in the destructor — cleanup is automatic at scope exit, including on exceptions. The backbone of safe, leak-free C++.
  - **`std::unique_ptr<T>`** — unique ownership, non-copyable (movable), zero overhead vs raw pointer. The default owner.
  - **`std::shared_ptr<T>`** — reference-counted shared ownership; the count is atomic (thread-safe count, not thread-safe object). Use only when ownership is genuinely shared; break cycles with `weak_ptr`.
  - The win: smart pointers call the destructor automatically when they leave scope — no manual `delete`, no leaks on early return/throw.

- **`auto` & type deduction** (taming template-heavy code):
  - `auto x = expr;` deduces the type at compile time — essential when types are long templated names. `auto (*f)() -> double;` and trailing return types pair with lambdas and templates. `decltype(auto)` preserves references/cv.

- **Move semantics** (avoid copies of big objects):
  - `std::move(x)` casts to an rvalue reference so the target can *steal* `x`'s resources instead of copying — critical for large arrays/containers in hot paths. Make move constructors/assignments `noexcept` so containers use them.

- **Templates & `constexpr`** (zero-overhead generic + compile-time):
  - Templates generate specialized code per type (no runtime dispatch). `constexpr` functions/variables compute at compile time. Lambdas (`[capture](args){...}`) give local, inlinable function objects for STL algorithms.

## Key Concepts
- **Const-correctness**: mark everything `const` that doesn't mutate — documents intent, enables optimization, and catches accidental writes. Pass large read-only args by `const&`.
- **The Rule of Zero / Five**: prefer declaring *no* special members (let RAII members handle it); if you declare one of destructor/copy/move, consider all five.
- **`std::array` vs `std::vector`**: `array<T,N>` for compile-time fixed size (stack, no allocation, intent-documenting); `vector<T>` for dynamic size (heap, `reserve()` to avoid reallocation).
- **Floating-point reality**: IEEE 754 is not exact (`0.1 + 0.2 ≠ 0.3`); reassociation changes results — never test FP equality, and beware `-Ofast`/`-ffast-math` breaking IEEE semantics.

## Mental Models
- **RAII everything** — never `new`/`delete` by hand; own resources through `unique_ptr`/`vector`/containers so cleanup is automatic and exception-safe.
- **`unique_ptr` by default, `shared_ptr` only when sharing is real** — `shared_ptr`'s atomic refcount and cycle risk aren't free.
- **Move large objects into hot paths** — `std::move` turns an O(n) copy into an O(1) pointer steal; make moves `noexcept`.
- **Mark it `const` unless it mutates** — const-correctness is free documentation and optimization.
- **Abstraction should be zero-overhead** — templates, `constexpr`, and inlined lambdas give high-level code that compiles to the same assembly as hand-written loops.

## Code Examples
```cpp
#include <memory>
#include <vector>

// RAII + unique ownership: no manual delete, exception-safe
auto buf = std::make_unique<double[]>(n);   // freed automatically at scope exit
std::vector<double> v;
v.reserve(n);                                // avoid reallocations

// Move semantics: steal, don't copy
std::vector<double> make() { std::vector<double> r(n); /* fill */ return r; }
auto data = make();                          // moved (or elided), not copied

// const-correctness + auto
double dot(const std::vector<double>& a, const std::vector<double>& b) {
    auto s = 0.0;
    for (std::size_t i = 0; i < a.size(); ++i) s += a[i] * b[i];
    return s;
}

constexpr int factorial(int n) { return n <= 1 ? 1 : n * factorial(n-1); }
static_assert(factorial(5) == 120);          // computed at compile time
```
- **What it demonstrates**: RAII ownership, move/elision, const-correctness, and compile-time `constexpr`.

## Reference Tables

| Tool | Use |
|---|---|
| `unique_ptr` | default unique ownership (zero overhead) |
| `shared_ptr` | genuine shared ownership (atomic refcount) |
| `std::move` | enable resource steal vs copy |
| `auto` / `decltype(auto)` | deduce / deduce-preserving types |
| `constexpr` | compile-time computation |
| `std::array` / `std::vector` | fixed / dynamic size |

| Principle | Why |
|---|---|
| RAII | automatic, exception-safe cleanup |
| const-correctness | documents intent, enables optimization |
| Rule of Zero | let RAII members manage specials |
| `noexcept` moves | containers move instead of copy |

## Key Takeaways
1. Use RAII and smart pointers (`unique_ptr` default, `shared_ptr` only when sharing) — never hand-manage `new`/`delete`.
2. Move large objects into hot paths with `std::move`; make move operations `noexcept` so containers use them.
3. Be const-correct and prefer `auto` for template-heavy types; use `constexpr` to push work to compile time.
4. `std::array` for fixed size, `std::vector` (with `reserve`) for dynamic — both over raw arrays.
5. IEEE floating-point is inexact and order-sensitive — never test FP equality; `-Ofast` breaks IEEE semantics.

## Connects To
- **Ch 03 (STL)**: containers and algorithms built on these idioms.
- **Ch 04 (Parallel patterns)**: lambdas + `std::move` in parallel STL.
- **Ch 12 (Debugging)**: sanitizers catch the leaks/UB these idioms prevent.
