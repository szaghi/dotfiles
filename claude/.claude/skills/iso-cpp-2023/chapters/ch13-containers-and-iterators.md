# Chapter 13: Containers & Iterators (Clauses 24, 25)

## Core Idea
Containers are specified by **complexity guarantees** and **iterator/reference invalidation rules**, not just APIs. The iterator hierarchy (now expressed as **C++20 concepts**) defines what each algorithm can require. C++23 adds the **flat** associative containers and `std::mdspan`.

## Frameworks Introduced

- **Container categories** (Clause 24 `[containers]`):
  - **Sequence**: `vector`, `array`, `deque`, `list`, `forward_list`.
  - **Associative** (ordered, tree): `map`, `set`, `multimap`, `multiset`.
  - **Unordered** (hash): `unordered_map`/`set`/`multimap`/`multiset`.
  - **Container adaptors**: `stack`, `queue`, `priority_queue`.
  - **C++23 flat associative**: `flat_map`, `flat_set`, `flat_multimap`, `flat_multiset` — sorted-vector-backed, cache-friendly, faster iteration/lookup, slower insertion than tree maps.

- **The iterator concept hierarchy** (Clause 25 `[iterators]`, C++20 concepts):
  `input_iterator` ⊂ `forward_iterator` ⊂ `bidirectional_iterator` ⊂ `random_access_iterator` ⊂ `contiguous_iterator`; plus `output_iterator`. Algorithms constrain on these.

- **`std::mdspan`** (C++23, `<mdspan>`): a non-owning multidimensional array *view* over contiguous storage, parameterized by `extents`, a layout policy (`layout_right`/`layout_left`/`layout_stride`), and an accessor — the standard answer to multidimensional indexing (`m[i, j, k]` via C++23 multidim subscript).

## Key Concepts
- **Invalidation rules**: `vector` insertion may invalidate all iterators/references on reallocation; `list`/`map` node-based containers keep iterators valid across insertion; erasing invalidates only the erased element (node-based). Know these before storing iterators.
- **`reserve()`** on `vector` to avoid repeated reallocation; `shrink_to_fit()` non-binding.
- **`emplace`/`try_emplace`/`insert_or_assign`**: in-place construction; `try_emplace` avoids constructing the value if the key exists.
- **Heterogeneous lookup** (transparent comparators, `is_transparent`): look up a `map<string,…>` with a `string_view` key, no temporary `string`.
- **C++23 `<spanstream>`, `<generator>`** also enrich the container/iterator ecosystem.

## Mental Models
- **Pick the container by complexity + invalidation, not familiarity** — `vector` is the default; reach for `flat_map` when iteration/lookup dominate and insertions are batched; tree `map` when you need stable iterators under insertion.
- **`mdspan` decouples layout from algorithm** — write kernels against `mdspan` and swap `layout_right`/`layout_left` for row/column-major without touching the loop body. Directly relevant to HPC array work.
- **Reserve before a known-size fill** — turns O(n) reallocations into one.
- **Use transparent comparators** to kill temporary-string allocations in `map`/`set` lookups.

## Code Examples
```cpp
// C++23 flat_map — cache-friendly, sorted-vector backed
std::flat_map<int, std::string> fm{{3,"c"},{1,"a"},{2,"b"}};   // contiguous storage

// C++23 mdspan — multidimensional view over flat storage
std::vector<double> buf(rows * cols);
std::mdspan m(buf.data(), rows, cols);     // layout_right by default
m[i, j] = 1.0;                              // C++23 multidim subscript

// avoid reallocations
std::vector<int> v; v.reserve(n);
for (int i = 0; i < n; ++i) v.push_back(i);
```
- **What it demonstrates**: C++23 `flat_map`, `mdspan` over flat storage, and `reserve` discipline.

## Reference Tables

| Container | Lookup | Insert | Iterators stable on insert? |
|---|---|---|---|
| `vector` | O(n) / O(1) idx | amortized O(1) end | **no** (realloc) |
| `map` (tree) | O(log n) | O(log n) | yes |
| `unordered_map` | O(1) avg | O(1) avg | yes (refs); iters on rehash: no |
| `flat_map` (C++23) | O(log n) | O(n) | no |

| Iterator concept | Adds |
|---|---|
| input | single-pass read |
| forward | multi-pass |
| bidirectional | `--` |
| random_access | `+ n`, `[]`, `<` |
| contiguous | pointer-contiguous storage |

## Key Takeaways
1. Choose containers by complexity and iterator-invalidation rules — `vector` default, `flat_map` (C++23) for read-heavy, tree `map` for stable iterators.
2. The C++20 iterator concept hierarchy (input→contiguous) is what algorithms constrain on.
3. C++23 `std::mdspan` is a layout-parameterized multidimensional view — decouples storage layout from kernels (key for HPC).
4. `reserve()` before known-size fills; use transparent comparators to avoid temporary keys.
5. `try_emplace`/`insert_or_assign` give precise control over construct-vs-overwrite.

## Connects To
- **Ch 14 (Ranges/Algorithms)**: algorithms are constrained on the iterator concepts here.
- **Ch 06 (operator[])**: C++23 multidim subscript powers `mdspan`.
- **Ch 16 (Numerics)**: `mdspan` + `<stdfloat>` for numerical array kernels.
