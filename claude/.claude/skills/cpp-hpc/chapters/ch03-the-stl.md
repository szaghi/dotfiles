# Chapter 3: The Standard Template Library

## Core Idea
The STL is three orthogonal pieces — **containers** (hold data), **iterators** (traverse it), **algorithms** (operate on it) — composed through iterators. Knowing each container's complexity and reaching for a standard algorithm instead of a hand loop yields code that is correct, fast, and parallelizable.

## Frameworks Introduced

- **Containers** (choose by access pattern + complexity):
  - **`vector<T>`** — dynamic contiguous array; O(1) indexed access and amortized append (over-allocates); the default. `reserve()` to avoid reallocation.
  - **`array<T,N>`** — fixed compile-time size, stack-allocated, no allocation; documents intent when size is known.
  - **`map`/`set`** — ordered (balanced tree), O(log n); **`unordered_map`/`unordered_set`** — hash table, O(1) average.
  - **`deque`**, **`list`**, container adaptors (`stack`, `queue`, `priority_queue`).

- **Iterators** (the glue): generalize pointers — `begin()`/`end()` define a half-open range `[first, last)` (last excluded). Categories input → forward → bidirectional → random-access → contiguous determine which algorithms apply. **Prefer pre-increment `++it`** over post-increment.

- **Algorithms** (operate via iterators): `std::sort`, `std::find`, `std::accumulate`, `std::transform`, `std::for_each`, `std::reduce`, `std::copy`, `std::count_if`, `std::min/max_element`. They take iterator ranges + an optional predicate/lambda, decoupling the operation from the container.

## Key Concepts
- **Half-open ranges `[first, last)`**: `last` is one-past-the-end, never dereferenced — the convention behind `begin()/end()` and all range loops.
- **Iterator invalidation**: `vector` reallocation (on growth) invalidates all iterators/pointers; node-based containers (`list`/`map`) keep them valid across insertion. Know this before storing iterators.
- **Algorithm + lambda > hand loop**: `std::sort(v.begin(), v.end(), cmp)` is clearer, less bug-prone, and (with execution policies) parallelizable — unlike a raw `for`.
- **Composite containers**: `vector<array<double,3>>` packs structured data contiguously — good cache behavior for arrays of small fixed records.
- **`emplace_back` vs `push_back`**: `emplace` constructs in place (no temporary); prefer it for non-trivial elements.

## Mental Models
- **Reach for a standard algorithm before writing a loop** — `sort`/`find`/`accumulate`/`transform` are correct, optimized, and become parallel by adding an execution policy (Ch 4).
- **Pick the container by its dominant operation** — `vector` default; `unordered_map` for O(1) key lookup; `array` for fixed size; node-based when you need stable iterators under insertion.
- **`reserve()` before a known-size fill** — turns repeated reallocations (each O(n)) into one allocation.
- **Pass ranges as `[first, last)`** — the half-open convention is universal; `end()` is a sentinel, not an element.

## Code Examples
```cpp
#include <array>
#include <vector>
#include <algorithm>
#include <numeric>

std::vector<std::array<double,3>> data;       // contiguous array-of-records
data.reserve(N);                              // no reallocation during fill
for (int i = 0; i < N; ++i)
    data.emplace_back(std::array<double,3>{double(i), 2.0*i, 3.0*i});

// Sort by the 2nd component — algorithm + lambda, not a hand loop
std::sort(data.begin(), data.end(),
          [](const auto& a, const auto& b){ return a[1] < b[1]; });

double total = std::accumulate(/*range*/ data.begin(), data.end(), 0.0,
          [](double s, const auto& r){ return s + r[0]; });
```
- **What it demonstrates**: a composite container with `reserve`/`emplace`, and algorithm-with-lambda over a half-open range.

## Reference Tables

| Container | Lookup | Insert | Iterators stable on insert? |
|---|---|---|---|
| `vector` | O(1) idx | O(1)* end | no (realloc) |
| `array<T,N>` | O(1) idx | fixed | n/a |
| `map`/`set` | O(log n) | O(log n) | yes |
| `unordered_map`/`set` | O(1) avg | O(1) avg | refs yes; iters on rehash no |

| Algorithm | Does |
|---|---|
| `sort` | order a range |
| `find`/`find_if` | locate element |
| `accumulate`/`reduce` | fold (reduce parallelizable) |
| `transform` | map a function over a range |
| `for_each` | apply to each element |

## Key Takeaways
1. The STL composes containers, iterators, and algorithms through half-open ranges `[first, last)`.
2. Prefer standard algorithms + lambdas over hand loops — clearer, optimized, and parallelizable with execution policies.
3. Choose containers by complexity and iterator-invalidation rules; `vector` is the default, `unordered_map` for O(1) lookup.
4. `reserve()` before known-size fills; `emplace_back` constructs in place without a temporary.
5. `vector` reallocation invalidates iterators — know invalidation before storing them.

## Connects To
- **Ch 02 (Modern C++)**: lambdas, `auto`, and move semantics used throughout.
- **Ch 04 (Parallel patterns)**: execution policies make these algorithms parallel.
- **Ch 10 (Kokkos)**: `View` + `parallel_for` generalize STL patterns to the GPU.
