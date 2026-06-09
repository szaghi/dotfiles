# Chapter 8: Exception Handling (Clause 14)

## Core Idea
Exceptions propagate by **stack unwinding**, running destructors of fully-constructed automatic objects in reverse order — the mechanism that makes **RAII** the foundation of exception safety. `noexcept` is both a specifier (a promise) and an operator (a query), and it materially changes whether moves and containers behave optimally.

## Frameworks Introduced

- **Throw / unwind / handle** (§14.2–14.4):
  - `throw expr;` copy-initializes the exception object, then unwinds the stack to the nearest matching handler.
  - **Unwinding** destroys each fully-constructed automatic object in reverse construction order (RAII cleanup).
  - A handler matches by type (exact, base class, or `...` catch-all); rethrow with bare `throw;`.
  - If a destructor or unwinding throws while already unwinding ⇒ `std::terminate`.

- **The exception-safety guarantee levels** (idiom enforced by RAII):
  - **No-throw** (`noexcept`): operation never throws.
  - **Strong**: commit-or-rollback — on failure, state is unchanged (copy-and-swap idiom).
  - **Basic**: no leaks, invariants preserved, but state may change.
  - **None**: avoid.

- **`noexcept`** (§14.5 `[except.spec]`): specifier `noexcept`/`noexcept(expr)` and operator `noexcept(expr)`.
  - A `noexcept` function that throws calls `std::terminate`.
  - **Move operations should be `noexcept`** — `std::vector` reallocation uses a moved-from element's move only if it's `noexcept`; otherwise it *copies* (for the strong guarantee). Non-`noexcept` moves silently cost performance.

## Key Concepts
- **`std::terminate`** (§14.6.2): called on uncaught exception, throwing during unwind, throwing from `noexcept`, or a few other fatal cases; default calls `std::abort`.
- **Constructor/destructor unwinding** (§14.3 `[except.ctor]`): an exception during construction destroys already-constructed subobjects/bases; the object's own destructor does **not** run (it was never fully constructed).
- **`std::exception` hierarchy**: `logic_error`/`runtime_error` families; throw by value, catch by `const&`.
- **Function-try-block**: `try`/`catch` wrapping a whole function body (mainly for constructor member-init failures).

## Mental Models
- **RAII is exception safety** — if every resource is owned by an object with a destructor, unwinding cleans up automatically; raw `new`/`delete` between possible throws leaks.
- **Make move constructors/assignments `noexcept`** — it's the difference between `vector` growth doing moves vs copies, and between strong and basic guarantees.
- **Throw by value, catch by `const&`** — catching by value slices and copies.
- **Never let a destructor throw** — during unwinding it calls `std::terminate`; mark destructors `noexcept` (the default).

## Code Examples
```cpp
// noexcept move enables fast vector growth and strong guarantees
struct Buf {
    Buf(Buf&&) noexcept;             // vector reallocation will MOVE, not copy
    Buf& operator=(Buf&&) noexcept;
};

// Strong guarantee via copy-and-swap
T& operator=(T other) {              // by value = copy (may throw here, before mutation)
    swap(*this, other);              // noexcept swap commits
    return *this;
}

void f() {
    auto lk = std::lock_guard{m};    // RAII: unlocks on any exit, including throw
    risky();                          // if this throws, lk's destructor runs
}
```
- **What it demonstrates**: `noexcept` moves, copy-and-swap strong guarantee, RAII cleanup on throw.

## Reference Tables

| Guarantee | Promise | Idiom |
|---|---|---|
| no-throw | never throws | `noexcept`, swap |
| strong | commit-or-rollback | copy-and-swap |
| basic | no leak, valid state | RAII |
| none | — | avoid |

| `noexcept` matters for | Effect if NOT noexcept |
|---|---|
| move ctor/assign | `vector` copies instead of moves |
| destructor | terminate if it throws during unwind |
| swap | breaks strong-guarantee idioms |

## Key Takeaways
1. Exceptions unwind the stack, running destructors in reverse order — RAII makes this automatic cleanup.
2. Mark move operations `noexcept` — `vector` reallocation and the strong guarantee depend on it.
3. Throwing from a `noexcept` function, or from a destructor during unwinding, calls `std::terminate`.
4. Throw by value, catch by `const&`; aim for the strong guarantee via copy-and-swap.
5. A constructor that throws does not run the object's destructor — only the already-built subobjects are destroyed.

## Connects To
- **Ch 05 (Classes/RAII)**: destructors and special members provide the cleanup.
- **Ch 12 (Utilities)**: `std::expected` (C++23) is the value-based alternative to exceptions.
- **Ch 15 (Concurrency)**: `std::terminate` on exceptions escaping a thread's start function.
