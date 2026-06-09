# Chapter 7: Data Environment

## Core Idea
The two attribute systems that decide *what each variable means in a region*: **data-sharing** (thread-level: shared vs private) and **data-mapping** (device-level: host↔device movement). Plus reductions, induction, and data-copying. The single most correctness-critical chapter.

> ⚠ **Errata (Nov 2025)** applied below at §7.5.9, §7.5.10, §7.9.9.

## Frameworks Introduced
- **Data-sharing attribute clauses** (§7.5):
  - **`shared(list)`** — one instance, all threads access it (synchronize yourself).
  - **`private(list)`** — per-thread uninitialized copy.
  - **`firstprivate(list)`** — per-thread copy initialized from the original.
  - **`lastprivate([modifier:] list)`** — private, and the value from the *sequentially last* iteration/section is copied out.
  - **`default(shared | firstprivate | private | none)`** — implicit attribute for unlisted variables; **`none` forces explicit listing** (adopt it).
  - **`linear(list [: step])`** — private with a linear induction relationship to the iteration.
- **Reduction & induction** (§7.6): **`reduction([modifier,] op : list)`** — per-thread partials combined by `op` (`+ * - & | ^ && || max min` + user-defined via `declare reduction`). Modifiers: `inscan` (with `scan` directive), `task`, `default`. **`induction`** generalizes linear progressions.
- **Data-mapping control** (§7.9):
  - **`map([map-type-modifier,] map-type : list)`** — move list items into/out of the device data environment. **map-types**: `to` (H→D on entry), `from` (D→H on exit), `tofrom` (both), `alloc`/`storage` (allocate, no copy), `release`/`delete` (exit).
  - **map-type defaults**: `tofrom` normally; `storage` for assumed-size/assumed-type or with `delete`.
  - **`defaultmap(implicit-behavior [: variable-category])`** — implicit map behavior; on `target`, `defaultmap` takes precedence over `default` for intersecting categories.
- **Data-copying** (§7.8): **`copyin`** (broadcast a threadprivate from primary), **`copyprivate`** (broadcast from one thread on `single`).

## Errata corrections (Nov 2025)
- **§7.5.9 (`has_device_addr`)**: added restriction — *if a list item is an array section or array element, the array base must be a base-language identifier.*
- **§7.5.10 (`is_device_ptr`)**: the text now reads "is an array section **or an array element**".
- **§7.9.9 (`defaultmap`)**: *if `implicit-behavior` is `private`, the attribute is a data-sharing attribute of `private`* (a `private` defaultmap behaves as data-sharing private, not a map).

## Key Concepts
- **Predetermined attributes**: loop iteration variables → private; `threadprivate` → threadprivate; etc. — cannot be overridden by clauses.
- **`default(none)`** is the OpenMP discipline analog of `implicit none`: forces you to classify every variable, catching accidental sharing.
- **map ≠ data-sharing**: a variable can be `firstprivate` *and* mapped; on `target`, both attribute systems apply.
- **reduction on `target`/`teams`**: combines across teams/threads; needs the right modifier and an initializer for user-defined reductions.

## Code Examples
```c
#pragma omp parallel for default(none) shared(a, b) private(tmp) reduction(+: sum)
for (int i = 0; i < n; ++i) { tmp = a[i]*b[i]; sum += tmp; }

#pragma omp target map(to: a[0:n], b[0:n]) map(from: c[0:n])
#pragma omp teams distribute parallel for reduction(+: total)
for (int i = 0; i < n; ++i) { c[i] = a[i] + b[i]; total += c[i]; }
```
- **Demonstrates**: `default(none)` + explicit sharing + reduction; device `map(to/from)` separating input/output transfers, with a cross-team reduction.

## Anti-patterns
- **Omitting `default(none)`**: implicit `shared` hides accidental races — make every variable explicit.
- **`map(tofrom:)` everywhere**: doubles transfer cost; use `to` for inputs, `from` for outputs, `alloc` for scratch.
- **`firstprivate` a large array thinking it's free**: it copies per thread.
- **Manual accumulation into a `shared` var**: data race — use `reduction`.
- **`has_device_addr`/`is_device_ptr` on a non-identifier array base** (post-errata): now explicitly restricted.
- **Forgetting array bounds in `map`**: `map(a)` on a pointer is ambiguous — `map(tofrom: a[0:n])`.

## Key Takeaways
1. Two attribute systems: **data-sharing** (shared/private/firstprivate/lastprivate/reduction/linear) and **data-mapping** (map to/from/tofrom/alloc) — composable, never conflate.
2. `default(none)` forces explicit classification — the key discipline.
3. Reductions, not manual shared accumulation; `to`/`from` not blanket `tofrom`.
4. **Errata**: `defaultmap(private)` → data-sharing private; `has_device_addr`/`is_device_ptr` array bases must be base-language identifiers.
5. On `target`, `defaultmap` overrides `default` for intersecting variable categories.

## Connects To
- **Ch 13**: worksharing-loop reductions and `lastprivate`.
- **Ch 14**: task reductions (`reduction(task, ...)`).
- **Ch 15**: `target`/`map` device data environment.
- **Ch 8**: allocators for privatized/mapped storage.
- **Ch 16**: synchronization for `shared` access correctness.
