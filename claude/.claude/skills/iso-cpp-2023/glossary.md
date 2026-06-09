# Glossary — ISO/IEC 14882 C++23 (working draft N4950)

**ADL (argument-dependent lookup)** — unqualified function lookup also searches argument types' namespaces (Ch 6).
**aggregate** — array or class with no user-provided ctors / private data; supports aggregate init (Ch 5).
**atomic_ref** — atomic operations on a non-atomic object you don't own (C++20) (Ch 15).
**[[assume(e)]]** — C++23 optimizer hint; UB if `e` is false; `e` not evaluated (Ch 4).
**barrier** — reusable phase-synchronization primitive (Ch 15).
**bit_cast** — well-defined, constexpr type-pun between equal-size trivially-copyable types (Ch 16).
**concept** — named compile-time bool predicate constraining templates (Ch 7).
**conditionally-supported** — construct an implementation may or may not support (Ch 1).
**consteval** — immediate function; every call must be a constant (Ch 4).
**constexpr** — may be evaluated at compile time; functions implicitly inline (Ch 4).
**constinit** — guarantees static initialization; does NOT imply const (Ch 4).
**contiguous_iterator** — random-access iterator over pointer-contiguous storage (Ch 13).
**CTAD** — class template argument deduction (`vector v{1,2,3}`) (Ch 7).
**data race** — conflicting accesses (≥1 write), unordered, ≥1 non-atomic ⇒ UB (Ch 1, 15).
**decltype(auto)** — deduction preserving value category and reference (Ch 4).
**deducing this** — C++23 explicit object parameter `this Self&& self` (Ch 3, 6).
**expected<T,E>** — C++23 value-based success-or-error type with monadic ops (Ch 12).
**fold expression** — `(pack op ...)` reduces a parameter pack (Ch 7).
**flat_map / flat_set** — C++23 sorted-vector-backed associative containers (Ch 13).
**generator<T>** — C++23 coroutine-based lazy range (Ch 15).
**glvalue** — expression determining object/function identity (lvalue ∪ xvalue) (Ch 1).
**happens-before** — sequenced-before (intra-thread) + synchronizes-with (inter-thread) (Ch 1, 15).
**header unit** — importable header (`import <vector>;`) (Ch 9).
**if consteval** — C++23 compile-time-vs-runtime branch (Ch 3).
**if constexpr** — compile-time branch discarding the untaken branch (Ch 7).
**IFNDR** — ill-formed, no diagnostic required (e.g. ODR violations) (Ch 1).
**ill-formed** — rule violation; diagnostic required (Ch 1).
**immediate function** — a `consteval` function (Ch 4).
**implicit conversion sequence (ICS)** — ranked chain used by overload resolution (Ch 6).
**jthread** — C++20 auto-joining thread carrying a stop_token (Ch 15).
**latch** — single-use countdown synchronization (Ch 15).
**lvalue** — glvalue that is not an xvalue (named, persistent) (Ch 1).
**mdspan** — C++23 non-owning multidimensional array view with layout policy (Ch 13).
**memory location** — scalar object (non-bit-field) or maximal adjacent nonzero bit-field run (Ch 1).
**memory_order** — relaxed/acquire/release/acq_rel/seq_cst consistency lattice (Ch 15).
**module** — C++20 named compiled interface unit; `export`/`import` (Ch 9).
**module linkage** — visibility within a module's own TUs, importer-invisible (Ch 2, 9).
**move_only_function** — C++23 movable-only callable wrapper (Ch 12).
**[[no_unique_address]]** — allow an empty member to share storage (Ch 5).
**[[nodiscard]]** — warn if a return value is ignored (Ch 4).
**noexcept** — specifier (promise) and operator (query); enables fast moves (Ch 8).
**NTTP** — non-type template parameter; C++20 allows class (structural) types (Ch 7).
**ODR (one-definition rule)** — exactly one definition per used entity; violation IFNDR (Ch 1).
**optional<T>** — a value or nothing; monadic ops in C++23 (Ch 12).
**partial_ordering** — `<=>` result for floating-point (NaN ⇒ unordered) (Ch 3).
**print / println** — C++23 type-safe formatted output (`<print>`) (Ch 12, 16).
**projection** — accessor applied before a ranges-algorithm predicate/comparator (Ch 14).
**prvalue** — pure value initializing an object or computing an operand (Ch 1).
**range** — a begin iterator + a sentinel (Ch 14).
**ranges::to** — C++23 materialize a view into a container (Ch 14).
**RAII** — acquire in ctor, release in dtor; backbone of exception safety (Ch 5, 8).
**Rule of Zero / Five** — declare no special members, or consider all five (Ch 5).
**scoped_lock** — RAII lock of multiple mutexes with deadlock avoidance (Ch 15).
**source_location** — C++20 caller location object replacing __FILE__/__LINE__ (Ch 11).
**spaceship (`<=>`)** — three-way comparison; `= default` synthesizes relationals (Ch 3, 5).
**span** — non-owning contiguous view (Ch 12).
**stacktrace** — C++23 portable call-stack capture (Ch 11).
**stdfloat** — C++23 fixed-width floating types (`float32_t` etc.) (Ch 2, 16).
**stop_token** — cooperative cancellation token (Ch 15).
**string_view** — non-owning string view (Ch 12).
**strong_ordering** — total-order `<=>` result (Ch 3).
**structured binding** — `auto [a,b] = expr;` decomposition (Ch 4).
**subsumption** — partial order on constraints breaking overload ties (Ch 7).
**temporary materialization** — prvalue → xvalue conversion creating the temporary (Ch 3).
**three-way comparison** — see spaceship (Ch 3).
**undefined behavior (UB)** — no requirements; optimizer assumes it never happens (Ch 1).
**value category** — lvalue / xvalue / prvalue classification of an expression (Ch 1).
**view** — cheap-to-copy, non-owning, lazy range adaptor (Ch 14).
**well-formed** — obeys all rules; implementation must accept and execute (Ch 1).
**xvalue** — expiring glvalue whose resources may be reused (`std::move`) (Ch 1).
**zip / enumerate / chunk / stride** — C++23 range views (Ch 14).
