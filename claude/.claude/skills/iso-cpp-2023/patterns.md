# Patterns & Techniques — C++23

## Rule of Zero
**When to use**: any class holding resources.
**How**: hold resources in RAII members (`unique_ptr`, `vector`, `string`); declare none of the five special members; `= default` the comparison.
**Trade-offs**: defaults are correct and move-aware for free. Drop to Rule of Five only when wrapping a raw OS handle.

## Value-based errors with `std::expected` (C++23)
**When to use**: recoverable, expected failures; hot paths; `-fno-exceptions`.
**How**: return `std::expected<T, E>`; chain `.and_then(f).transform(g).or_else(h)` to keep the happy path linear.
**Trade-offs**: explicit error propagation; no stack-unwinding cost; reserve exceptions for truly exceptional cases.

## Default the spaceship
**When to use**: value types needing comparison.
**How**: `auto operator<=>(const T&) const = default;` (+ `bool operator==(...) const = default;`).
**Trade-offs**: generates all six relationals member-wise; floating-point members yield `partial_ordering`.

## Constrain with concepts, branch with `if constexpr`, fold with fold-expressions
**When to use**: generic code (replaces SFINAE / tag dispatch).
**How**: named `concept`s in `requires`/`template<C T>`; `if constexpr` to select per-type code; `(pack op ...)` to reduce packs.
**Trade-offs**: readable diagnostics, subsumption ordering — vastly better than `enable_if`.

## Deducing this (C++23)
**When to use**: collapse const/non-const/lvalue/rvalue member overloads, or write a recursive lambda.
**How**: `template<class Self> auto&& get(this Self&& self){ return std::forward<Self>(self).m; }`.
**Trade-offs**: one definition for all qualifier combinations; perfect-forwards the object.

## Ranges pipeline + `ranges::to`
**When to use**: data transformation without intermediate containers.
**How**: `data | views::filter(p) | views::transform(f) | std::ranges::to<std::vector>()`.
**Trade-offs**: lazy single-pass, zero intermediate allocation; never let a view outlive its source.

## Projections over comparators
**When to use**: sorting/searching by a member.
**How**: `std::ranges::sort(people, {}, &Person::age);`.
**Trade-offs**: cleaner and less error-prone than writing a lambda comparator.

## `jthread` + stop_token
**When to use**: any worker thread.
**How**: `std::jthread t([](std::stop_token st){ while(!st.stop_requested()) work(); });` — destructor stops + joins.
**Trade-offs**: eliminates forgot-to-join terminate and missing-cancellation bugs.

## Release/acquire publish-protect
**When to use**: one thread publishes data for another.
**How**: producer `store(true, memory_order_release)` after writing; consumer spins on `load(memory_order_acquire)` then reads.
**Trade-offs**: cheaper than `seq_cst`; requires a happens-before proof. Default to `seq_cst` otherwise.

## `std::generator` lazy sequence (C++23)
**When to use**: producing a sequence on demand.
**How**: a coroutine that `co_yield`s; consume as a range (`gen() | views::take(n)`).
**Trade-offs**: cleaner than a stateful iterator class; frame is heap-allocated unless elided.

## `bit_cast` for safe type punning
**When to use**: reinterpret bits (e.g. float↔uint).
**How**: `auto u = std::bit_cast<std::uint32_t>(f);`.
**Trade-offs**: constexpr, well-defined; requires equal size + trivially copyable. Beats `reinterpret_cast`/union (UB).

## `<charconv>` for fast number↔string
**When to use**: performance-sensitive parsing/formatting.
**How**: `std::from_chars(b, e, value)` / `std::to_chars(b, e, value)`.
**Trade-offs**: no allocation, no locale, exact round-trip; beats `stringstream`/`stoi`.

## `import std;` (C++23)
**When to use**: new module-based code; faster builds.
**How**: `import std;` (or `import std.compat;` for C names in global namespace).
**Trade-offs**: replaces dozens of headers, skips re-parsing; needs toolchain module support.

## copy-and-swap for the strong guarantee
**When to use**: assignment that must be exception-safe.
**How**: take the parameter by value (copy), then `swap(*this, other)` (noexcept).
**Trade-offs**: commit-or-rollback; one extra move but bulletproof.
