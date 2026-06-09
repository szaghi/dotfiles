# Chapter 2: Glossary

## Core Idea
The normative vocabulary — **~968 defined terms** that fix the precise meaning of every word the rest of the spec relies on. When two readings conflict, the glossary decides. This chapter maps the load-bearing terms; the alphabetical quick-reference is in `glossary.md`.

## Key Concepts (the definitions everything hinges on)
- **construct** — an executable directive + the associated base-language code. **region** — all code encountered during an instance of a construct/routine (dynamic, includes callees).
- **task** — a specific instance of executable code + its data environment. **implicit task** (one per team thread, tied) vs **explicit task** (`task`/`taskloop`-generated, deferrable). **task scheduling point** — where a thread may switch tasks.
- **team** — the threads executing a `parallel` region. **league** — the teams from a `teams` construct. **contention group** — tasks run by one thread pool; threads don't migrate across groups.
- **data-sharing attribute** — `shared`/`private`/`firstprivate`/`lastprivate`/`reduction`/`linear` — how a variable behaves in a region.
- **data-mapping attribute** — `to`/`from`/`tofrom`/`alloc` — how a variable is moved to/from a device data environment (`map` clause).
- **device data environment** — the storage a device sees; populated by `map`/`target data`/`target enter/exit data`.
- **flush** — the memory operation enforcing a consistent view; **acquire flush** / **release flush** establish **happens-before** order (the OpenMP memory model).
- **binding region / binding thread set** — which region/threads a construct's effect is scoped to (governs `loop`, `barrier`, etc.).
- **worksharing construct** — divides work across a team (worksharing-loop, `sections`, `single`, `workshare`); **partitioned** = each thread does a partition.
- **base language identifier / array base / array section** — terms the errata sharpens (see ch07).

## Mental Models
- **Two attribute systems, never conflate them**: *data-sharing* (thread-level: shared vs private) and *data-mapping* (device-level: host↔device movement). A variable can have both. (ch07)
- **"happens-before" is built from flushes**: OpenMP's memory model is release/acquire — a release flush before an acquire flush on the same data establishes ordering. Without matching flushes, threads may see stale values.
- **Resolve disputes by the glossary**: an OpenMP term (e.g. "task," "region," "thread," "device") has a *specific* meaning here that may differ from base-language or colloquial usage.

## Anti-patterns
- **Reading "private"/"shared" as the only attribute axis**: device `map` is a separate concern — a variable can be `firstprivate` *and* mapped.
- **Assuming shared-memory visibility without a flush**: the weak memory model requires explicit (or construct-implied) flushes for cross-thread visibility.
- **Treating "task" loosely**: implicit vs explicit, tied vs untied — the scheduling rules differ sharply.

## Key Takeaways
1. ~968 normative terms; alphabetical subset in `glossary.md`.
2. Data-sharing (thread) and data-mapping (device) are two distinct, composable attribute systems.
3. The memory model is release/acquire flushes building happens-before — visibility is not automatic.
4. construct (static) vs region (dynamic, includes callees) — reason over the region.
5. Where an OpenMP term conflicts with base-language usage, the glossary definition governs.

## Connects To
- **Ch 7**: data environment — data-sharing and data-mapping attributes applied.
- **Ch 16**: synchronization — flush, happens-before, the memory model in operation.
- **Ch 1**: execution model — team/league/contention-group/task definitions originate here.
- **glossary.md**: alphabetical reference.
