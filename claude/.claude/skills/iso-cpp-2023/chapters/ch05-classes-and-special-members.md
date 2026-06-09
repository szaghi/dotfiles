# Chapter 5: Classes, Special Members & RAII (Clause 11)

## Core Idea
A class controls its own lifetime through **special member functions** (default ctor, copy/move ctor, copy/move assignment, destructor). The interaction of declared-vs-implicit special members is governed by precise rules that drive **RAII** and the **Rule of Zero / Rule of Five**.

## Frameworks Introduced

- **The six special member functions** (§11.4.4 `[special]`):
  - Default constructor, copy constructor, move constructor, copy assignment, move assignment, destructor.
  - Each is implicitly declared/defaulted unless suppressed; `= default` requests the implicit one, `= delete` forbids it.

- **The Rule of Zero / Rule of Five** (idiom from the special-member interaction rules):
  - **Rule of Zero**: declare none of the five — let the compiler generate them. Hold resources in RAII members (`unique_ptr`, `vector`) so the defaults are correct. *This is the default you should aim for.*
  - **Rule of Five**: if you declare *any* of destructor / copy-ctor / copy-assign / move-ctor / move-assign, you almost certainly need to consider *all five* — declaring one suppresses or deprecates others.
  - Suppression rules: a user-declared destructor or copy operation **deprecates** implicit copy and **suppresses** implicit move; a user-declared move operation **deletes** implicit copy.

- **RAII** (Resource Acquisition Is Initialization): acquire in the constructor, release in the destructor. Destructors run deterministically at scope exit (reverse order of construction), making RAII the backbone of C++ resource and exception safety.

## Key Concepts
- **`= default` / `= delete`** (§11.4.5): explicitly defaulted (use the implicit definition, possibly `constexpr`/`noexcept`) or deleted (participate in overload resolution but make selection ill-formed).
- **Trivial / standard-layout / literal types** (§11.4): triviality enables `memcpy` relocation and `constexpr` usage; standard-layout enables C interop.
- **`virtual` functions & destructors** (§11.7.3 `[class.virtual]`): a polymorphic base needs a `virtual` (or `protected` non-virtual) destructor; `override`/`final` specifiers catch signature mistakes.
- **Defaulted comparisons** (§11.10 `[class.compare]`): `auto operator<=>(const T&) const = default;` generates member-wise comparison; `bool operator==(const T&) const = default;` separately.
- **`[[no_unique_address]]`** (C++20): lets an empty member share storage — zero-overhead policy/allocator members.
- **`explicit(bool)`** (C++20): conditional explicitness for templated converting constructors.

## Mental Models
- **Aim for Rule of Zero** — if your class declares a destructor to free a raw resource, refactor the resource into a `unique_ptr`/RAII wrapper and delete the destructor.
- **Polymorphic base ⇒ virtual destructor**, or deleting through a base pointer is UB.
- **`= default` your `<=>`** for value types — member-wise, correct, and synthesizes all relational operators.
- **Moved-from is valid-but-unspecified** — a moved-from standard-library object is in a usable but unspecified state; only re-assign or destroy it.

## Code Examples
```cpp
// Rule of Zero: defaults are correct because members are RAII
struct Widget {
    std::unique_ptr<Impl> impl;   // owns; move-only propagates automatically
    std::vector<int>      data;
    auto operator<=>(const Widget&) const = default;   // all comparisons
};

// Rule of Five only when managing a raw resource
struct Buffer {
    char* p; size_t n;
    ~Buffer() { delete[] p; }
    Buffer(const Buffer&);            // must define all five if you define one
    Buffer& operator=(const Buffer&);
    Buffer(Buffer&&) noexcept;
    Buffer& operator=(Buffer&&) noexcept;
};
```
- **What it demonstrates**: Rule of Zero as the target; Rule of Five only when a raw resource forces it.

## Reference Tables

| You declare | Implicit copy | Implicit move |
|---|---|---|
| nothing | provided | provided |
| destructor | deprecated | **suppressed** |
| copy ctor/assign | provided | **suppressed** |
| move ctor/assign | **deleted** | — |

| Specifier | Effect |
|---|---|
| `= default` | request implicit definition |
| `= delete` | forbid (ill-formed if selected) |
| `override` | must override a virtual; else error |
| `final` | no further override/derivation |
| `[[no_unique_address]]` | overlap empty member storage |

## Key Takeaways
1. Prefer the **Rule of Zero**: hold resources in RAII members and declare none of the five.
2. Declaring one special member affects the others — a destructor suppresses implicit moves (Rule of Five).
3. A polymorphic base class needs a `virtual` destructor or deletion through a base pointer is UB.
4. `= default` your `<=>` for value semantics; use `override`/`final` to catch virtual-signature bugs.
5. Moved-from objects are valid-but-unspecified — only reassign or destroy them.

## Connects To
- **Ch 03 (`<=>`)**: defaulted three-way comparison generates the relational operators.
- **Ch 08 (Exceptions)**: RAII + `noexcept` move operations underpin the strong exception guarantee.
- **Ch 12 (Utilities)**: `unique_ptr`/`shared_ptr` are the RAII building blocks for Rule of Zero.
