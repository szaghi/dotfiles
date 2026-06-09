# Chapter 1: General Principles, Conformance & the Memory Model (Clauses 4, 6.7, 6.9)

## Core Idea
C++ semantics rest on a five-way diagnosis taxonomy (**well-formed / ill-formed / ill-formed-no-diagnostic-required / undefined behavior / conditionally-supported**) and a thread-aware **memory model** built on bytes, memory locations, and the happens-before relation. Master these and every later rule has a place to land.

## Frameworks Introduced

- **The conformance taxonomy** (§4.1 `[intro.compliance]`):
  - **Well-formed** — obeys all syntax/semantic/ODR rules; the implementation must accept and (resource limits permitting) correctly execute it.
  - **Ill-formed** — violates a rule; a diagnostic is **required**.
  - **Ill-formed, no diagnostic required (IFNDR)** — a rule is violated but the standard places **no requirement** on the implementation (e.g. ODR violations across TUs). Effectively undefined, undiagnosed.
  - **Undefined behavior (UB)** — no requirements whatsoever; the optimizer assumes it never happens.
  - **Conditionally-supported** — a construct an implementation may or may not support; if unsupported, it must issue a diagnostic.
  - When to use: classify any "is this legal?" question into one of these five buckets first.

- **The memory model** (§6.7.1 `[intro.memory]`, §6.9.2 `[intro.races]`):
  - The fundamental unit is the **byte**; every byte has a unique address; bits-per-byte is implementation-defined (≥ 8).
  - A **memory location** is a scalar object (not a bit-field) or a maximal sequence of adjacent nonzero-width bit-fields. Distinct memory locations can be updated concurrently without interference.
  - **Data race** = two conflicting actions (≥1 write) on the same memory location, not ordered by happens-before, at least one non-atomic ⇒ **UB**.
  - **happens-before** is built from *sequenced-before* (intra-thread) + *synchronizes-with* (inter-thread, via atomics/mutexes).

- **Value categories** (§7.2.1 `[basic.lval]`): the expression taxonomy.
  - **glvalue** — determines the identity of an object/function. Splits into **lvalue** (named, persistent) and **xvalue** (expiring — resources reusable, e.g. `std::move(x)`).
  - **prvalue** — initializes an object or computes an operand's value (a pure value; the source of *guaranteed copy elision*).
  - **rvalue** = prvalue ∪ xvalue. Every expression is exactly one of lvalue / xvalue / prvalue.

## Key Concepts
- **One-Definition Rule (ODR)** (§6.3 `[basic.def.odr]`): every TU may declare; exactly one definition program-wide for each used entity; multiple definitions of inline/template entities must be token-identical — violation is **IFNDR**.
- **Hosted vs freestanding** (§4.1): freestanding supports the full language (Clauses 5–15) + a library subset; hosted supports everything.
- **Lifetime** (§6.7.3 `[basic.life]`): begins when storage is obtained and initialization completes; using an object outside its lifetime is generally UB.
- **Sequenced-before / indeterminately-sequenced / unsequenced** (§6.9.1 `[intro.execution]`): as in C — unsequenced side effects on one scalar ⇒ UB (but C++17 tightened many operator orderings).

## Mental Models
- **UB is a license, IFNDR is a trap.** UB the compiler may exploit at the point of occurrence; IFNDR (e.g. an ODR violation) silently mis-links with no diagnostic owed — often nastier.
- **`std::move(x)` produces an xvalue, not a move** — it's a cast to rvalue reference that *enables* a move; the move happens (or not) at the call site.
- **prvalues are materialized lazily** (C++17): a prvalue isn't an object until it must be (temporary materialization), which is what makes guaranteed copy elision work.
- **Two threads writing adjacent non-bit-field members race-free**; two threads writing adjacent bit-fields in the same run *do* race.

## Code Examples
```cpp
int   x = init();
int&& r = std::move(x);   // std::move yields an xvalue; r binds it. No move yet.
std::string s = std::string("hi");  // RHS is a prvalue → guaranteed elision, no copy/move
```
- **What it demonstrates**: value categories in practice — `std::move` makes an xvalue; a prvalue initializer elides.

## Reference Tables

| Diagnosis | Diagnostic? | Meaning |
|---|---|---|
| well-formed | n/a | must accept + execute |
| ill-formed | **required** | rule violation, compiler errors |
| IFNDR | none owed | violated but no requirement (ODR) |
| undefined behavior | none | anything may happen |
| conditionally-supported | if unsupported | impl choice |

| Value category | Identity? | Movable-from? |
|---|---|---|
| lvalue | yes | no |
| xvalue | yes | yes |
| prvalue | (materialized) | yes |

## Key Takeaways
1. Classify legality into well-formed / ill-formed / IFNDR / UB / conditionally-supported — they have very different consequences.
2. A data race (conflicting access, ≥1 non-atomic, unordered) is UB; the model is byte- and memory-location-based.
3. Every expression is exactly one of lvalue / xvalue / prvalue; `std::move` yields an xvalue.
4. ODR violations are IFNDR — silent mis-linking, no diagnostic required.
5. happens-before = sequenced-before (intra-thread) + synchronizes-with (inter-thread atomics/mutexes).

## Connects To
- **Ch 03 (Expressions)**: value categories drive overload resolution and reference binding.
- **Ch 15 (Concurrency)**: the happens-before relation and atomics realize the memory model.
- **Ch 05 (Classes)**: lifetime and special-member semantics.
