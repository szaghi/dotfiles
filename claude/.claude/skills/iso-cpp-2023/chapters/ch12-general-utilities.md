# Chapter 12: General Utilities — optional, variant, expected, tuple, format, smart pointers (Clause 22)

## Core Idea
The utilities library provides the vocabulary types for modern C++: **sum/product types** (`variant`, `tuple`, `pair`), **maybe-a-value** (`optional`), the C++23 **value-based error channel** (`expected`), type-safe **formatting** (`format`/`print`), and **RAII ownership** (`unique_ptr`/`shared_ptr`).

## Frameworks Introduced

- **`std::expected<T, E>`** (C++23, §22.8 `[expected]`): holds either a `T` (success) or an `E` (error) — the value-based alternative to exceptions and error codes.
  - `.has_value()`, `.value()` (throws `bad_expected_access` if error), `.error()`, `.value_or(default)`.
  - **Monadic operations**: `.and_then(f)`, `.transform(f)`, `.or_else(f)`, `.transform_error(f)` — chain fallible computations without nested `if`s.
  - Construct errors via `std::unexpected<E>{e}`.
  - When to use: recoverable, expected failures where exceptions are too heavy or banned (hot paths, `-fno-exceptions`).

- **The vocabulary types**:
  - **`std::optional<T>`** (§22.5): a value or nothing; monadic `.and_then`/`.transform`/`.or_else` (C++23).
  - **`std::variant<Ts...>`** (§22.6): type-safe tagged union; access via `std::get`/`std::get_if`/`std::visit`.
  - **`std::tuple<Ts...>`** / **`std::pair`** (§22.4): heterogeneous fixed sequences; decompose with structured bindings; `std::apply` to call with the tuple as args.

- **Formatting** (§22.14 `[format]`): `std::format("...{}...", args)` — type-safe, positional, locale-aware. C++23 `std::print`/`std::println` (`<print>`) write formatted output directly (faster than iostreams, no `<<` chains).

- **Smart pointers** (`<memory>`, Ch 20 cross-ref): `unique_ptr` (unique ownership, zero overhead), `shared_ptr` (shared, ref-counted), `weak_ptr` (non-owning observer). `make_unique`/`make_shared` are the construction idioms.

## Key Concepts
- **`std::visit`** over a `variant`: dispatches to the active alternative — the type-safe replacement for a tagged-union `switch`.
- **`std::move_only_function`** (C++23): a movable-only `std::function` for capturing move-only callables (e.g. `unique_ptr` captures).
- **`std::byteswap`** (C++23): endianness byte reversal for integers.
- **`std::to_underlying`** (C++23): convert a scoped enum to its underlying integer.
- **`std::string_view` / `std::span`**: non-owning views (no allocation, no copy) — pass by value.

## Mental Models
- **`expected<T,E>` over exceptions for expected failures** — chain with `.and_then`/`.transform` to keep the happy path linear; reserve exceptions for truly exceptional conditions.
- **`unique_ptr` by default, `shared_ptr` only when ownership is genuinely shared** — `shared_ptr` has atomic-refcount overhead and cycle risk (break with `weak_ptr`).
- **`std::format`/`std::print` over iostreams** — type-safe, faster, no manipulator state, no `<<` precedence traps.
- **Pass `string_view`/`span` by value** — they're cheap views; never return one referring to a temporary (dangling).

## Code Examples
```cpp
// C++23 expected with monadic chaining — linear happy path
std::expected<Config, Error> load(std::string_view path);
auto result = load("cfg")
    .and_then(validate)          // only runs on success
    .transform(normalize)        // maps the value
    .or_else(use_defaults);      // handles the error

// variant + visit
std::variant<int, std::string> v = 42;
std::visit([](auto&& x){ std::print("{}\n", x); }, v);

// C++23 print, type-safe formatting
std::println("{1} {0} = {2:.3f}", "x", "value", 3.14159);
```
- **What it demonstrates**: C++23 `expected` monadic chaining, `variant` visitation, and `std::println`.

## Reference Tables

| Type | Holds | Access |
|---|---|---|
| `optional<T>` | T or none | `*`, `.value()`, `.value_or()` |
| `expected<T,E>` | T or E | `.value()`, `.error()`, `.and_then()` |
| `variant<Ts…>` | one of Ts | `get`, `get_if`, `visit` |
| `tuple<Ts…>` | all of Ts | `get<I>`, structured binding, `apply` |

| Smart pointer | Ownership | Overhead |
|---|---|---|
| `unique_ptr` | unique | none (zero-cost) |
| `shared_ptr` | shared | atomic refcount + control block |
| `weak_ptr` | none (observer) | breaks shared cycles |

## Key Takeaways
1. C++23 `std::expected<T,E>` is the value-based error channel; chain with `.and_then`/`.transform`/`.or_else`.
2. `optional`/`variant`/`tuple` are the vocabulary types; `std::visit` replaces tagged-union switches type-safely.
3. `std::format`/`std::print`/`std::println` (C++20/23) are type-safe and faster than iostreams.
4. `unique_ptr` by default; `shared_ptr` only for genuine shared ownership (break cycles with `weak_ptr`).
5. C++23 adds `move_only_function`, `byteswap`, `to_underlying`; pass `string_view`/`span` by value.

## Connects To
- **Ch 08 (Exceptions)**: `expected` is the alternative when exceptions are unsuitable.
- **Ch 04 (Structured bindings)**: decompose `tuple`/`pair`/`expected`.
- **Ch 16 (Formatting/IO)**: `std::format` underlies `std::print` and `<<`-formatting.
