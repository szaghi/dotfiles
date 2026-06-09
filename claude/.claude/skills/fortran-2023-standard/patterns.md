# Patterns — Fortran 2023 idioms the standard enables

Concrete techniques sanctioned (or newly enabled) by the standard. Format: **When to use / How / Trade-offs.**

## Modular encapsulation with submodules
**When**: a module's procedure *bodies* change often but its *interface* is stable, and rebuild time hurts.
**How**: declare `MODULE FUNCTION/SUBROUTINE` interfaces in the module; put bodies in `SUBMODULE (parent) impl`. (Ch 14)
**Trade-offs**: extra file/unit; payoff is localized recompilation — users of the module don't rebuild when a body changes.

## Polymorphic dispatch (SELECT TYPE) + abstract base
**When**: runtime type-based behavior over a type hierarchy.
**How**: `ABSTRACT` base with `DEFERRED` type-bound procedures; `CLASS(base)` containers; `SELECT TYPE` to narrow. (Ch 7, 11)
**Trade-offs**: dynamic dispatch cost; clearer than manual tag fields.

## Rank-agnostic kernels (assumed-rank + SELECT RANK)
**When**: one routine must accept arrays of several ranks (e.g. generic I/O, interop shims).
**How**: dummy `a(..)`; `SELECT RANK (a)` with `rank(1)/rank(2)/rank(*)/rank default`. (Ch 8, 11)
**Trade-offs**: per-rank branches; avoids N near-duplicate procedures.

## Parallel reduction with DO CONCURRENT REDUCE (F2023)
**When**: data-parallel accumulation (sum/min/max/logical) you want the processor to parallelize/offload.
**How**: `do concurrent (i=1:n) reduce(+:acc) default(none) shared(a)`. (Ch 11)
**Trade-offs**: independence/REDUCE is a *programmer assertion*; the processor may still run serially — verify offload (and timing, per GPU-benchmark discipline).

## Referentially transparent kernels with SIMPLE (F2023)
**When**: a function whose result must depend only on its arguments (parallel safety, memoization, GPU).
**How**: `simple function f(x)` — no use/host vars, no COMMON, only-SIMPLE callees. (Ch 15)
**Trade-offs**: stricter than PURE; cannot read module state — pass everything as arguments.

## Element-wise scalar kernels (ELEMENTAL)
**When**: a scalar operation you want to apply across whole arrays without explicit loops.
**How**: `pure elemental function clamp(x,lo,hi)`; call on scalars or conformable arrays. (Ch 15)
**Trade-offs**: must be pure; great for vectorization and readability.

## Conditional expressions instead of temporary-laden IF (F2023)
**When**: choose one of several values inline without a statement-level branch.
**How**: `y = ( cond ? a : cond2 ? b : c )`; only the chosen branch evaluates. (Ch 10)
**Trade-offs**: all branches must share type/kind/rank; replaces MERGE (which evaluates both arms).

## Type-tracking declarations (TYPEOF / CLASSOF, F2023)
**When**: declare a local/temporary that must match another entity's (possibly deferred) type.
**How**: `typeof(a) :: tmp` (non-poly) / `classof(p) :: q` (poly). (Ch 7)
**Trade-offs**: tracks deferred params correctly (unlike restating the declaration).

## Safe dynamic memory (ALLOCATE with STAT/SOURCE/MOLD)
**When**: dynamic arrays with failure handling or cloning.
**How**: `allocate(a(n), stat=s, errmsg=m)`; `allocate(b, source=a)` to clone; F2023 `allocate(c(bounds_array))` for rank from a bounds array. (Ch 9)
**Trade-offs**: SOURCE copies values (cost); MOLD copies only shape/type.

## String tokenizing (SPLIT / TOKENIZE, F2023)
**When**: parsing delimited text.
**How**: `call tokenize(string, set=',', tokens=toks)` (all) or `split(...)` (one at a time). (Ch 16)
**Trade-offs**: replaces hand-rolled index/scan loops; SIMPLE procedures.

## IEEE-aware numerics (status save/restore + FMA)
**When**: detecting FP exceptions or controlling rounding around a kernel.
**How**: `ieee_get_status` → clear flags/set halting off → compute → `ieee_get_flag` → `ieee_set_status`; use `ieee_fma(a,b,c)` for compensated accuracy. (Ch 17)
**Trade-offs**: must restore caller state; query `ieee_support_*` first.

## C interop with descriptors and string bridges
**When**: calling C with Fortran arrays/strings.
**How**: `bind(c, name=)`; `c_loc`/`c_f_pointer` for memory; F2023 `f_c_string`/`c_f_strpointer` for strings; CFI descriptor for assumed-shape/rank. (Ch 18)
**Trade-offs**: mind column-major vs row-major (reversed dims); contiguity may force copies.

## Disciplined modules (USE ONLY + ISO_FORTRAN_ENV kinds)
**When**: every module import, every kind declaration.
**How**: `use mod, only: ...`; `use, intrinsic :: iso_fortran_env, only: real64`; `real(real64) :: x`. (Ch 14, 16)
**Trade-offs**: more verbose; eliminates namespace pollution and nonportable kind integers.
