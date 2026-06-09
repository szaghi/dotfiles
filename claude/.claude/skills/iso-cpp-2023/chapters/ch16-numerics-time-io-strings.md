# Chapter 16: Numerics, Time, I/O, Strings & Bit Manipulation (Clauses 23, 28, 29, 31; §22.15)

## Core Idea
The numeric, time, and I/O libraries round out the standard library. C++ standardizes IEEE-aware floating-point (`<cmath>`, `<stdfloat>`, `numeric_limits`), a type-safe `<chrono>` time/calendar/timezone system, portable bit manipulation (`<bit>`), and modern formatted I/O (`std::format`/`std::print`).

## Frameworks Introduced

- **Numerics** (Clause 28 `[numerics]`):
  - `<cmath>` math functions; `<complex>`; `<random>` (engines + distributions — never use `rand()`); `<numeric>` (`accumulate`, `reduce`, `transform_reduce`, `inner_product`, `gcd`/`lcm`, `midpoint`); `<valarray>`.
  - `std::numeric_limits<T>` — `epsilon()`, `infinity()`, `quiet_NaN()`, `is_iec559`, `digits`.
  - **C++23 `<stdfloat>`** — `std::float16_t/32_t/64_t/128_t`, `std::bfloat16_t` with explicit conversion ranks.
  - C++17 parallel algorithms via execution policies (`std::execution::par`, `par_unseq`).

- **Bit manipulation `<bit>`** (C++20, §22.15 `[bit]`): `std::bit_cast` (type-pun safely, no UB), `popcount`, `countl_zero`/`countr_zero`/`countl_one`/`countr_one`, `bit_width`, `bit_ceil`/`bit_floor`, `rotl`/`rotr`, `has_single_bit`, `std::endian`. C++23 adds `std::byteswap`.

- **`<chrono>`** (Clause 29 `[time]`): type-safe durations (`seconds`, `milliseconds`), `time_point`, clocks (`system_clock`, `steady_clock`, `high_resolution_clock`), **calendar** (`year`/`month`/`day`, `year_month_day`) and **time zones** (`zoned_time`, `tzdb`) since C++20; `std::format` support for chrono types.

- **I/O & strings** (Clauses 23, 31):
  - `std::string`, `std::string_view`, `std::format`/`std::vformat`, **C++23 `std::print`/`std::println`** (`<print>`), `<spanstream>` (C++23, fixed-buffer streams).
  - iostreams (`<iostream>`, `<fstream>`, `<sstream>`); `<charconv>` `to_chars`/`from_chars` (fast, locale-independent, round-trip-exact number↔string).

## Key Concepts
- **`std::bit_cast` over `reinterpret_cast`/`memcpy` for type punning** — it's `constexpr`, well-defined, and requires equal sizes + trivially-copyable types.
- **`<charconv>` `to_chars`/`from_chars`** are the fast, exact, locale-free conversions — use them over `stringstream`/`stoi` in performance paths.
- **`steady_clock` for measuring intervals**, never `system_clock` (which can jump). (Mirrors the GPU-benchmark-timing discipline: use a monotonic clock + a synchronization point.)
- **`reduce`/`transform_reduce`** are the parallelizable (associative-assuming) successors to `accumulate` — but floating-point reassociation changes results (see C23/Annex-F discipline).

## Mental Models
- **`std::print`/`std::println` over `std::cout <<`** — type-safe, faster, no manipulator state, atomic line output.
- **`from_chars`/`to_chars` over stream/`stoi` parsing** in hot paths — no allocation, no locale, exact round-trip.
- **`steady_clock` + a fixed reference point for benchmarks** — `system_clock` is wall time and can move backward.
- **`reduce` is not `accumulate`** — it assumes associativity/commutativity and may reorder; for floating-point, the result can differ from the sequential left-fold. Use `accumulate`/`fold_left` when bitwise-reproducibility matters.

## Code Examples
```cpp
// C++23 print + chrono formatting
using namespace std::chrono;
std::println("now: {:%Y-%m-%d %H:%M}", zoned_time{current_zone(), system_clock::now()});

// safe type punning (C++20)
float  f = 3.14f;
auto   bits = std::bit_cast<std::uint32_t>(f);   // constexpr, well-defined

// fast, exact parse — no allocation, no locale
double d; auto [ptr, ec] = std::from_chars(s.data(), s.data()+s.size(), d);

// monotonic timing
auto t0 = steady_clock::now();
work();
auto dt = duration_cast<microseconds>(steady_clock::now() - t0);
```
- **What it demonstrates**: C++23 `println` + chrono formatting, `bit_cast`, `from_chars`, and `steady_clock` timing.

## Reference Tables

| Need | Use | Avoid |
|---|---|---|
| formatted output | `std::print`/`println` (C++23) | `cout <<` chains |
| number↔string (fast) | `<charconv>` `to_chars`/`from_chars` | `stringstream`, `stoi` |
| type punning | `std::bit_cast` | `reinterpret_cast`, union |
| interval timing | `steady_clock` | `system_clock` |
| random numbers | `<random>` engines+distributions | `rand()` |
| popcount/CLZ | `<bit>` | compiler builtins |

| C++23 numeric/IO addition | Header |
|---|---|
| `std::print`/`println` | `<print>` |
| `std::float32_t` etc. | `<stdfloat>` |
| `std::byteswap` | `<bit>` |
| fixed-buffer streams | `<spanstream>` |

## Key Takeaways
1. Prefer `std::print`/`std::println` (C++23) over iostreams — type-safe, faster, atomic line output.
2. `<charconv>` `to_chars`/`from_chars` are the fast, exact, locale-free number conversions.
3. `std::bit_cast` (C++20) is the well-defined, `constexpr` type-pun; `<bit>` standardizes popcount/CLZ/rotate (+ C++23 `byteswap`).
4. Use `steady_clock` for interval timing; `<chrono>` gives type-safe durations, calendars, and time zones.
5. `reduce`/`transform_reduce` parallelize but assume associativity — for FP-reproducible sums use `accumulate`/`fold_left` (Annex-F discipline applies).

## Connects To
- **Ch 02 (`<stdfloat>`)**: the C++23 fixed-width floating types.
- **Ch 14 (Algorithms)**: `reduce`/`fold_left` and execution policies.
- **C23 skill (Annex F)**: identical IEEE 754 / reassociation discipline applies to C++ floating-point.
- **GPU/benchmark memories**: monotonic-clock timing and FP-reproducibility concerns carry over.
