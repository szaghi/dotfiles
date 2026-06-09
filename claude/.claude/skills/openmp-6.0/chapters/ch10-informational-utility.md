# Chapter 10: Informational and Utility Directives

## Core Idea
Directives that *don't* generate parallel work but inform the compiler or runtime: **`assume`/`assumes`** (optimization hints/contracts), **`error`** (compile/run-time diagnostics), **`nothing`** (explicit no-op for metaprogramming), and **`requires`** (mandate implementation features).

> ⚠ **Errata (Nov 2025)** applied below at §10.5 (`requires`).

## Frameworks Introduced
- **`assume`/`assumes`** (§10.1–10.2): assert facts the compiler may exploit — `no_openmp`, `no_openmp_routines`, `no_parallelism`, `holds(expr)`, `absent(directive-list)`, `contains(directive-list)`. A *contract* (undefined behavior if violated), not a check.
- **`error`** directive (§10.2): emit an implementation-defined diagnostic.
  - **`at(compilation | execution)`** — when the error fires.
  - **`severity(warning | fatal)`** — `fatal` aborts (compilation unit or program); `warning` just displays.
  - **`message("...")`** — the text to include.
  - Fires the OMPT `runtime-error` event when `at(execution)`.
- **`nothing`** (§10.x): a directive that does nothing — useful as a `metadirective` branch or macro expansion target.
- **`requires`** directive (§10.5): declare that the compilation unit *requires* implementation features — `unified_shared_memory`, `unified_address`, `reverse_offload`, `dynamic_allocators`, `atomic_default_mem_order(...)`, `self_maps`. An implementation lacking a required feature must reject the program.

## Errata correction (Nov 2025)
- **§10.5 (`requires`)**: a restriction's wording flipped — "[...] **must appear** lexically [...]" is corrected to "[...] **must not appear** lexically [...]". (A sign-error fix: the constraint forbids, not requires, the lexical appearance — verify the exact restriction in the spec before relying on the original text.)

## Key Concepts
- **`assume` is a promise, not a query**: if the asserted condition is false, behavior is undefined — only use facts you can guarantee. Big optimization lever (e.g. `assumes no_openmp` lets the compiler skip OpenMP scaffolding).
- **`requires unified_shared_memory`** changes the whole `target` data model — host and device share an address space, so `map` clauses become largely unnecessary. Declaring it commits the *entire* compilation unit.
- **`error at(compilation) severity(fatal)`** is the directive analog of `#error` — fail the build on a misconfiguration.
- `requires` must be specified consistently and lexically per the (errata-corrected) restriction.

## Code Examples
```c
// contract: this region contains no OpenMP, no parallelism -> aggressive opt
#pragma omp assume no_openmp no_parallelism
{ /* hot serial kernel */ }

// fail the build if compiled without the needed device feature
#pragma omp requires unified_shared_memory

// emit a fatal compile-time error from a metadirective fallback
#pragma omp error at(compilation) severity(fatal) message("no supported target")
```
- **Demonstrates**: `assume` as an optimization contract, `requires` committing the unit to USM, and `error` failing the build.

## Anti-patterns
- **`assume`-ing a fact you can't guarantee**: false assumptions are undefined behavior, not a diagnosed error — worse than no hint.
- **`requires unified_shared_memory` then still writing full `map` clauses**: redundant; USM changes the data model (though explicit maps remain legal/optimizing hints).
- **Relying on the pre-errata §10.5 wording**: the `must`/`must not` flip changes a `requires` placement restriction — check the corrected text.
- **`error at(execution)` for things knowable at compile time**: prefer `at(compilation)` to fail fast.

## Key Takeaways
1. `assume`/`assumes` are optimization *contracts* (UB if violated), not checks — use only guaranteed facts.
2. `requires` mandates implementation features (USM, reverse_offload, dynamic_allocators…) for the whole compilation unit; a lacking implementation must reject.
3. `error at(compilation) severity(fatal)` = build-time `#error`; `at(execution)` fires at runtime + an OMPT event.
4. **Errata**: §10.5 `requires` restriction is "must **not** appear lexically" (sign correction).
5. `nothing` is the explicit no-op for metaprogramming/metadirective branches.

## Connects To
- **Ch 9**: `nothing`/`error` as `metadirective` branches.
- **Ch 15**: `requires unified_shared_memory`/`reverse_offload` reshape the `target` model.
- **Ch 18**: `error at(execution)` raises the OMPT `runtime-error` event.
