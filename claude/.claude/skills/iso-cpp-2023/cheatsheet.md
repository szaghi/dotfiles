# C++23 Cheatsheet — Decision Rules & Tells

## Legality bucket (decision rule)
- Compiles but wrong-link, no diagnostic owed → **IFNDR** (ODR violation across TUs).
- Anything-may-happen, optimizer assumes it can't occur → **UB** (data race, OOB, signed overflow, use-after-lifetime, false `[[assume]]`).
- Must error → **ill-formed** (constraint/syntax/type violation).
- Maybe-supported, diagnostic if not → **conditionally-supported**.

## Value category (tell)
- Has a name / is an lvalue ref → **lvalue**.
- `std::move(x)`, `static_cast<T&&>` → **xvalue** (movable-from, has identity).
- Literal, `T{...}`, function returning by value → **prvalue** (materialized lazily).

## Special members (Rule of Five suppression)
| You declare | implicit copy | implicit move |
|---|---|---|
| nothing | yes | yes |
| destructor | deprecated | **gone** |
| any copy op | yes | **gone** |
| any move op | **deleted** | — |
→ **Aim for Rule of Zero**: RAII members, declare none.

## C++23 "use this, not that"
| Want | C++23 | Drop |
|---|---|---|
| recoverable error | `std::expected<T,E>` | error codes / out-params |
| formatted output | `std::print`/`println` | `cout <<` |
| number↔string | `<charconv>` to_chars/from_chars | stringstream/stoi |
| type punning | `std::bit_cast` | reinterpret_cast/union |
| const/ref overloads | deducing-this | 4 hand-written overloads |
| compile-time branch | `if consteval` | `is_constant_evaluated()` |
| multidim index | `m[i,j]` | `m(i,j)` |
| lazy sequence | `std::generator` | stateful iterator class |
| worker thread | `jthread` + stop_token | raw `thread` |
| materialize view | `ranges::to<C>()` | manual loop |
| whole stdlib | `import std;` | dozens of `#include` |
| 2D/3D array view | `std::mdspan` | raw pointer math |

## Comparisons
- `auto operator<=>(const T&) const = default;` → all six relationals.
- integral → `strong_ordering`; **floating → `partial_ordering`** (NaN ⇒ unordered).

## noexcept tells
- Move ctor/assign NOT `noexcept` → `vector` growth **copies** instead of moving.
- Destructor throws during unwind → `std::terminate`.
- Throw by value, **catch by `const&`** (catch-by-value slices).

## memory_order picker
| situation | order |
|---|---|
| default / unsure | `seq_cst` |
| publish data | `release` (store) |
| read published | `acquire` (load) |
| CAS / fetch_add | `acq_rel` |
| counter/stat only | `relaxed` |

## Concepts / templates
- Constrain: `template<C T>` or `requires C<T>`. Branch: `if constexpr`. Reduce pack: `(xs op ...)`.
- `requires requires` → factor into a **named concept** (also needed for subsumption ordering).
- Non-template beats template; more-specialized beats less; **more-constrained beats less**.

## Feature gating (portable)
- `#if __cpp_lib_expected`, `#if __cpp_concepts`, `__has_cpp_attribute(assume)`.
- `__cplusplus == 202302L` → C++23. Include `<version>` for all `__cpp_lib_*`.

## Containers tells
- Need iterators stable across insert? → tree `map`/`list`, NOT `vector`/`flat_map`.
- Read/iteration-heavy, batched inserts? → C++23 `flat_map`.
- `vector` reallocation invalidates everything → `reserve()` first.

## Ranges
- Views are lazy + non-owning → never store a view to a temporary (dangling).
- Pipeline with `|`, materialize with `ranges::to<C>()`, sort with projection `{}, &T::member`.

## FP discipline (carries from C / Annex F)
- `reduce`/`transform_reduce` assume associativity → may not match sequential sum. Use `accumulate`/`ranges::fold_left` for reproducibility.
- `steady_clock` for timing, never `system_clock`. `numeric_limits<T>::is_iec559` to require IEEE 754.
