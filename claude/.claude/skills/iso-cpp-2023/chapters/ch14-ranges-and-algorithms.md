# Chapter 14: Ranges & Algorithms (Clauses 26, 27)

## Core Idea
The ranges library (C++20, hugely extended in C++23) reframes algorithms to operate on **ranges** (a begin + a sentinel) instead of iterator pairs, and provides **lazy, composable views** chained with `|`. This replaces hand-written loops with declarative pipelines that don't allocate or copy until materialized.

## Frameworks Introduced

- **Range & view concepts** (Clause 26 `[ranges]`): `range`, `view` (cheap-to-copy, non-owning), `borrowed_range`, `sized_range`, plus the iterator-category-mirroring `input_range`…`contiguous_range`.

- **Range adaptors / views** (composable, lazy, `|`-chainable):
  - C++20: `views::filter`, `views::transform`, `views::take`, `views::drop`, `views::join`, `views::split`, `views::reverse`, `views::keys`/`values`, `views::iota`, `views::common`.
  - **C++23 additions**: `views::zip`, `views::zip_transform`, `views::adjacent`/`adjacent_transform`, `views::chunk`, `views::chunk_by`, `views::slide`, `views::stride`, `views::enumerate`, `views::join_with`, `views::cartesian_product`, `views::as_const`, `views::as_rvalue`, `views::repeat`.
  - **`std::ranges::to<Container>`** (C++23): materialize a view into a concrete container — `r | views::transform(f) | ranges::to<std::vector>()`.

- **Constrained algorithms** (Clause 27 `[algorithms]`, `std::ranges::`): every `<algorithm>` has a `ranges::` form that takes a range (or iterator+sentinel), supports **projections** (a member/accessor applied before the predicate), and returns richer result structs. C++23 adds `ranges::fold_left`/`fold_right`/`fold_left_first` and `ranges::starts_with`/`ends_with`/`contains`.

## Key Concepts
- **Lazy evaluation**: views compute on demand during iteration — no intermediate containers. A pipeline of N adaptors still makes one pass.
- **Projections**: `ranges::sort(people, {}, &Person::age)` sorts by `age` without a custom comparator.
- **Dangling protection**: `borrowed_range` and `ranges::dangling` catch returning iterators into temporaries at compile time.
- **`fold_left`** (C++23): the standard left-fold (`std::accumulate`'s constrained, projection-aware successor).

## Mental Models
- **Build pipelines with `|`, materialize with `ranges::to`** — keep transformations lazy until you need a concrete container.
- **Use projections to avoid writing comparators/lambdas** — `{}, &T::member` is cleaner and less error-prone.
- **Prefer `ranges::` algorithms** — they're safer (range + sentinel, dangling checks, projections) than the iterator-pair forms.
- **Views are non-owning** — never let a view outlive its underlying range; storing a view to a temporary dangles.

## Code Examples
```cpp
namespace rv = std::views;
// C++23 pipeline: enumerate + filter + transform → vector
auto result = data
    | rv::enumerate                          // (index, value) pairs (C++23)
    | rv::filter([](auto p){ return std::get<1>(p) > 0; })
    | rv::transform([](auto p){ return std::get<0>(p); })
    | std::ranges::to<std::vector>();         // materialize (C++23)

// projection: sort people by age, no comparator
std::ranges::sort(people, {}, &Person::age);

// C++23 fold
int total = std::ranges::fold_left(nums, 0, std::plus{});
```
- **What it demonstrates**: C++23 `enumerate`/`ranges::to`/`fold_left` and projection-based sorting.

## Reference Tables

| C++23 view | Produces |
|---|---|
| `views::zip` | tuples of corresponding elements |
| `views::enumerate` | (index, element) pairs |
| `views::chunk(n)` | subranges of size n |
| `views::slide(n)` | sliding windows of size n |
| `views::stride(n)` | every nth element |
| `views::cartesian_product` | n-ary cross product |
| `ranges::to<C>()` | materialize into container C |

| C++23 algorithm | Role |
|---|---|
| `ranges::fold_left` | left fold (accumulate successor) |
| `ranges::contains` | membership test |
| `ranges::starts_with`/`ends_with` | prefix/suffix |

## Key Takeaways
1. Ranges replace iterator pairs with range+sentinel and add projections, dangling protection, and richer results — prefer `ranges::` algorithms.
2. Views are lazy, non-owning, `|`-composable; a multi-adaptor pipeline is still one pass and zero intermediate allocations.
3. C++23 adds `zip`/`enumerate`/`chunk`/`slide`/`stride`/`cartesian_product` and `ranges::to` for materialization.
4. C++23 `ranges::fold_left`/`fold_right` are the constrained, projection-aware folds.
5. Never let a view outlive its source range — views to temporaries dangle.

## Connects To
- **Ch 13 (Iterators)**: range concepts mirror the iterator concept hierarchy.
- **Ch 07 (Concepts)**: ranges are built entirely on concepts.
- **Ch 15 (Coroutines)**: `std::generator` (C++23) is a coroutine-based view.
