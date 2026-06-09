# Chapter 5: Directive and Construct Syntax

## Core Idea
The syntactic machinery common to all OpenMP directives: how to spell them (C/C++ `#pragma omp` vs Fortran `!$omp`), the clause-format grammar (modifiers, argument lists, array sections/shaping, iterators), conditional compilation, and the shared `if`/`init`/`destroy` clauses.

## Frameworks Introduced
- **Directive format** (§5.1):
  - C/C++: `#pragma omp directive-specification new-line` (or `_Pragma("omp ...")`). Whitespace allowed around `#`; tokens subject to macro replacement.
  - Fortran free-form: `!$omp directive-specification`; fixed-form sentinels `!$omp`/`c$omp`/`*$omp` in column 1. Continuation per source form.
  - **Paired begin/end**: directives whose name starts with `begin` (e.g. `begin declare target` … `end declare target`) bracket a region; an `end` directive may carry `end-clause`s.
- **Clause format** (§5.2):
  - **OpenMP argument lists**, **reserved locators** (`omp_all_memory`), **OpenMP operations**, **array shaping** `([n1][n2]...) ptr`, **array sections** `a[lower : length : stride]`, and the **`iterator` modifier** `iterator(i=0:n)` for clauses that iterate (e.g. `depend`, `map`).
  - Clause **modifiers**: many clauses take modifiers, e.g. `map(to: x)`, `reduction(task, +: s)`, `schedule(monotonic: static)`.
- **Conditional compilation** (§5.3): the `_OPENMP` macro (`yyyymm`, = `202411` for 6.0) and the `!$` free-form / `c$`/`*$` fixed-form Fortran sentinels for conditionally-compiled lines.
- **Shared clauses**: `if([directive-name-modifier:] cond)` (§5.5), `init`/`destroy` (§5.6–5.7, for `interop`/`depobj` objects), `directive-name-modifier` (§5.4, disambiguates `if`/`nowait` on combined constructs).

## Key Concepts
- **`if(directive-name: cond)`**: on a combined construct (e.g. `target teams distribute parallel for`), the modifier says *which* leaf the `if` applies to.
- **array section** `a[start:length:stride]` (C) / `a(lb:ub)` (Fortran) — required to specify what a `map`/`depend`/`reduction` clause covers for arrays/pointers.
- **`iterator(i=0:n: ...)`** — generates a set of list items for `depend`/`map` (e.g. a dependence per neighbor).
- **metadirective family** lives in ch9 (variant directives) — `5.x` is the base syntax it builds on.

## Code Examples
```c
#pragma omp parallel for if(parallel: n > 1000) schedule(static)
for (int i = 0; i < n; ++i) a[i] = b[i] + c[i];

// array section in a map clause; iterator in a depend clause
#pragma omp target map(tofrom: a[0:n])
#pragma omp task depend(iterator(j=0:nneigh), in: halo[j][0:sz])
```
```fortran
!$omp parallel do default(none) shared(a,b) private(i)
do i = 1, n
  a(i) = b(i)*2
end do
!$omp end parallel do
```
- **Demonstrates**: `#pragma omp` / `!$omp` forms, `if` with a directive-name modifier, array sections in `map`, the `iterator` modifier, and a Fortran paired begin/end.

## Anti-patterns
- **Omitting array bounds in `map`/`depend`**: `map(a)` on a pointer is ambiguous — write `map(tofrom: a[0:n])`.
- **Ambiguous `if` on a combined construct**: without `if(target: ...)` the modifier-less `if` may not apply where you intend.
- **Mixing free/fixed Fortran sentinels**: follow the source form; `!$omp` (free) vs column-1 `c$omp` (fixed).
- **Forgetting `_OPENMP` guards** for code that must also compile without OpenMP.

## Key Takeaways
1. C/C++ `#pragma omp ...`; Fortran `!$omp ...` (+ paired `begin`/`end` for some directives).
2. `_OPENMP` = `202411` (v6.0); guard host-only builds with `#ifdef _OPENMP` / `!$`.
3. Array sections `a[start:len:stride]` and the `iterator` modifier specify *what* `map`/`depend`/`reduction` cover.
4. On combined constructs, `if(directive-name: cond)` targets a specific leaf.
5. `init`/`destroy` clauses manage `interop`/`depobj` objects.

## Connects To
- **Ch 7**: data clauses use array sections and modifiers defined here.
- **Ch 9**: variant directives (`metadirective`, `declare variant`) build on this syntax.
- **Ch 14**: `depend(iterator(...), ...)` for task dependences.
- **Ch 6**: base-language binding of the directive syntax.
