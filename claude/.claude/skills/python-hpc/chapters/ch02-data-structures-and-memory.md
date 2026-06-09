# Chapter 2: Data Structures, Algorithmic Complexity & RAM

## Core Idea
The right container is often a bigger win than any micro-optimization. Python's built-ins have specific complexity and memory profiles — **lists** (dynamic arrays, O(1) append amortized), **dicts/sets** (hash tables, O(1) average lookup), **tuples** (immutable, cached) — and choosing by access pattern, plus controlling per-object overhead, is the foundation of efficient Python.

## Frameworks Introduced

- **Container complexity (choose by access pattern)**:
  - **List** — dynamic array; O(1) indexed access and amortized append (with **over-allocation** so append rarely reallocates); O(n) insert/delete at front, O(n) membership (`in`). Use for ordered, index-accessed, append-heavy data.
  - **Tuple** — immutable, fixed-size, lower overhead, and small tuples are cached/interned by the runtime. Use for fixed records and dict keys.
  - **Dict / Set** — hash tables; O(1) *average* insert/lookup/membership, degrading toward O(n) under hash **collisions** (resolved by open-addressing **probing**). Use sets for membership tests and deduplication — `x in set` is O(1) vs `x in list` O(n).
  - **`bisect`** — binary search / sorted-insert on a list: O(log n) lookup if you keep it sorted, the cheap alternative to a tree.

- **The RAM-reduction toolkit**:
  - **`__slots__`** — declare fixed attributes on a class to drop the per-instance `__dict__`, cutting memory dramatically for many small objects.
  - **`array` module / NumPy arrays** — store homogeneous primitives packed, not as boxed Python objects (a list of a million ints holds a million PyObject pointers + objects; an array holds raw bytes).
  - **`bytes`/`bytearray`** — raw byte storage for binary data.
  - **Probabilistic / compressed structures** — **Bloom filters** (approximate membership in tiny space, no false negatives), **tries / DAWGs** (prefix-compressed string sets), **HyperLogLog** (cardinality) — trade exactness for order-of-magnitude memory savings on huge collections.

## Key Concepts
- **Amortized cost**: list append is O(1) *amortized* because over-allocation makes most appends free and occasional reallocations O(n) average out.
- **Hashing & collisions**: dict/set performance depends on a good hash and load factor; pathological collisions degrade to linear scans. Custom objects used as keys need consistent `__hash__`/`__eq__`.
- **Object overhead**: every Python object carries a header (refcount, type pointer); small ints/strings are interned. A `list` of numbers is pointers-to-objects, not packed values — the reason NumPy exists.
- **`sys.getsizeof`** measures a single object's footprint (not deep/contained); use it to compare representations.

## Mental Models
- **Pick the container by the operation you do most** — frequent membership → set; frequent indexed access → list; key→value → dict; fixed record → tuple/`__slots__` class.
- **`in` on a list is a code smell at scale** — O(n) per test; convert to a set for O(1).
- **For millions of small objects, reach for `__slots__` or pack into arrays** — boxed Python objects are the memory killer.
- **When exact membership isn't required at huge scale, a Bloom filter or trie can cut RAM by orders of magnitude** — accept tunable false positives for the saving.

## Code Examples
```python
# Membership: set is O(1), list is O(n)
seen = set(huge_iterable)          # build once
if key in seen: ...                # O(1) vs `key in huge_list` O(n)

# __slots__ removes per-instance __dict__ → big RAM cut for many objects
class Point:
    __slots__ = ("x", "y")         # no __dict__; fixed attributes only
    def __init__(self, x, y): self.x, self.y = x, y

# Sorted list + bisect for O(log n) lookup without a tree
import bisect
i = bisect.bisect_left(sorted_keys, target)
```
- **What it demonstrates**: the three highest-leverage structure choices — set membership, `__slots__`, and `bisect`.

## Reference Tables

| Container | Lookup | Append/Insert | Membership | Note |
|---|---|---|---|---|
| list | O(1) idx | O(1)* end, O(n) front | O(n) | over-allocates |
| tuple | O(1) idx | immutable | O(n) | cached, low overhead |
| dict/set | O(1) avg | O(1) avg | O(1) avg | hash table |
| sorted list + bisect | O(log n) | O(n) insert | O(log n) | cheap "tree" |

| RAM technique | Saves by | Trade-off |
|---|---|---|
| `__slots__` | dropping `__dict__` | fixed attribute set |
| `array`/NumPy | packing primitives | homogeneous only |
| Bloom filter | approximate membership | tunable false positives |
| trie/DAWG | prefix sharing | string sets only |

## Key Takeaways
1. Choose containers by dominant operation; `set` membership (O(1)) beats `list` membership (O(n)) at scale.
2. Lists over-allocate (amortized-O(1) append); dict/set are O(1) average but collision-sensitive.
3. `__slots__` and packed arrays slash memory for many small objects — boxed PyObjects are the RAM killer.
4. `bisect` gives O(log n) lookup on a sorted list without a tree structure.
5. Probabilistic/compressed structures (Bloom, trie, HyperLogLog) trade exactness for huge memory savings on big collections.

## Connects To
- **Ch 03 (NumPy)**: packed homogeneous arrays — the answer to list-of-objects overhead.
- **Ch 01 (Profiling)**: `memory_profiler`/`sys.getsizeof` to find the allocation hotspots.
- **Ch 05 (Generators)**: lazy iteration to avoid materializing large collections at all.
