# Chapter 11: Library Introduction, Language Support & Diagnostics (Clauses 16, 17, 19)

## Core Idea
The standard library is specified with precise conventions: **named requirements** (now largely **concepts**), allocator/`Cpp17*` requirements, and freestanding subsets. The language-support library (`<initializer_list>`, `<compare>`, `<coroutine>`, `<source_location>`) provides the runtime hooks the *language* needs, and the diagnostics library adds C++23 `<stacktrace>`.

## Frameworks Introduced

- **Library conventions** (Clause 16 `[library]`):
  - **Named requirements** (`Cpp17CopyConstructible`, `Cpp17LessThanComparable`, …) and C++20 **concepts** specify what a type must model.
  - **Reserved names**: identifiers with `__`, a leading `_`+uppercase, names in `std` (you may not add to `namespace std` except permitted specializations).
  - **`[[nodiscard]]`** is applied liberally across the library (e.g. `empty()`, allocation).
  - **Freestanding** subset is enumerated per facility.

- **Language-support library** (Clause 17 `[support]`): the facilities the core language requires.
  - `<compare>` — `strong_ordering`/`weak_ordering`/`partial_ordering` for `<=>`.
  - `<coroutine>` — `coroutine_handle`, `coroutine_traits`, `suspend_always`/`suspend_never`.
  - `<initializer_list>` — backs braced-init lists.
  - `<source_location>` (C++20) — `std::source_location::current()` replaces `__FILE__`/`__LINE__` macros.
  - `<typeinfo>`, `<new>`, `<limits>` (`std::numeric_limits`), `<cstdint>`, `<version>` (feature-test macro aggregator).

- **Diagnostics library** (Clause 19 `[diagnostics]`):
  - `<stdexcept>` exception hierarchy; `<system_error>` (`error_code`/`error_condition`/`error_category`).
  - **C++23 `<stacktrace>`**: `std::stacktrace`/`std::stacktrace_entry` — capture and print a call stack portably.
  - `<cassert>` `assert`, and the `<contracts>` direction.

## Key Concepts
- **`std::numeric_limits<T>`**: `max()`, `min()`, `epsilon()`, `infinity()`, `quiet_NaN()`, `is_iec559` — the type-traits gateway to floating-point properties.
- **`<version>`**: include it to get every `__cpp_lib_*` feature-test macro without pulling a real header.
- **`std::source_location`**: pass `= std::source_location::current()` as a default argument to capture the caller's location — the modern logging idiom.
- **`error_code` vs exceptions**: value-based error reporting for recoverable, expected failures (e.g. filesystem, networking TS).

## Mental Models
- **Use `<version>` + `__cpp_lib_*` to detect library features** — more reliable than testing for a header.
- **`std::source_location::current()` as a defaulted parameter** beats `__FILE__`/`__LINE__` macros — it's type-safe and composes through wrappers.
- **C++23 `<stacktrace>` for diagnostics** — capture `std::stacktrace::current()` in an error path instead of platform-specific backtrace APIs.
- **`numeric_limits<T>::is_iec559`** tells you whether IEEE 754 guarantees hold — gate FP-sensitive code on it.

## Code Examples
```cpp
// C++20 source_location — caller-aware logging without macros
void log(std::string_view msg,
         std::source_location loc = std::source_location::current()) {
    std::clog << loc.file_name() << ':' << loc.line() << ": " << msg << '\n';
}

// C++23 stacktrace
void on_error() { std::cerr << std::stacktrace::current() << '\n'; }

static_assert(std::numeric_limits<double>::is_iec559);   // require IEEE 754
```
- **What it demonstrates**: `source_location`-based logging, C++23 `<stacktrace>`, and `numeric_limits` IEEE gating.

## Reference Tables

| Facility | Header | Since |
|---|---|---|
| ordering categories | `<compare>` | C++20 |
| coroutine primitives | `<coroutine>` | C++20 |
| caller location | `<source_location>` | C++20 |
| feature-test macros | `<version>` | C++20 |
| call stack | `<stacktrace>` | C++23 |
| numeric properties | `<limits>` | — |

## Key Takeaways
1. Library facilities are specified by named requirements / concepts; you may not add to `namespace std` (except allowed specializations).
2. `<version>` aggregates all `__cpp_lib_*` macros — the canonical library-feature probe.
3. `std::source_location::current()` as a default argument is the modern, macro-free way to capture caller info.
4. C++23 `<stacktrace>` gives portable call-stack capture for diagnostics.
5. `std::numeric_limits<T>` (esp. `is_iec559`, `epsilon`) is the gateway to type/FP properties.

## Connects To
- **Ch 03 (`<=>`)**: `<compare>` ordering categories.
- **Ch 15 (Coroutines)**: `<coroutine>` primitives.
- **Ch 12 (Utilities)**: `std::expected` as the value-based error channel alongside `<system_error>`.
