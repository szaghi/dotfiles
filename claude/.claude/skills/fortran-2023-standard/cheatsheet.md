# Cheatsheet — Fortran 2023 Standard

## What's NEW in Fortran 2023 (vs F2018)
| Feature | Form | Ch |
|---|---|---|
| Conditional expressions | `( cond ? a : ... : b )` | 10 |
| SIMPLE procedures | `simple function f(x)` (pure + arg-only) | 15 |
| Enum *types* / enumeration types | `ENUM :: t` (TYPE(t)) / `ENUMERATION TYPE :: t` | 7 |
| TYPEOF / CLASSOF | `typeof(a) :: t` / `classof(p) :: q` | 7 |
| DO CONCURRENT REDUCE | `reduce(+:s)` locality | 11 |
| String parsing | `SPLIT`, `TOKENIZE` (SIMPLE) | 16 |
| Logical kind selection | `SELECTED_LOGICAL_KIND(bits)` | 16 |
| Circular / degree trig | `SINPI/COSPI/...`, `SIND/COSD/...` | 16 |
| C string interop | `C_F_STRPOINTER`, `F_C_STRING` | 18 |
| Edit descriptors | `AT` (auto-trim), `LZS/LZP/LZ` (leading zeros) | 13 |
| Rank-from-bounds ALLOCATE | `allocate(a(bounds_array))` | 9 |
| `IEEE_MAX_NUM`/`MIN_NUM` w/ sNaN | returns the number (was NaN) | 4, 17 |

## F2023 breaking changes from F2018 — check these
- `SYSTEM_CLOCK`: **all integer args must share kind** and have ≥ default-int exponent range. (fixes likely needed in timing code)
- BLOCK + DATA: using a DATA-only variable *before* its DATA stmt no longer allowed.
- `ASSOCIATED(P,T)`: POINTER/TARGET must have **same rank**.

## Decision rules

### INTENT — pick the right one
- Read-only input → **INTENT(IN)** (cannot define).
- Produce fresh output, prior value irrelevant → **INTENT(OUT)** (⚠ undefined on entry; allocatables **deallocated**).
- Update in place, must keep prior value → **INTENT(INOUT)** (actual always definable).
- *Never* use INTENT(OUT) to preserve a value — it zeroes/deallocates on entry.

### Array dummy bounds — avoid the rebasing trap
- Want shape, origin irrelevant → `a(:)` (lower bound **rebases to 1**).
- Need a specific origin / ghost cells → `a(lb:ub)` **explicit-shape** (preserves bounds).
- Pass to C / vectorized kernel → ensure **simply contiguous** or `CONTIGUOUS` (else hidden copy).

### Purity — how strong?
- Has side effects / I/O → plain (or `IMPURE`).
- No side effects, may read module state → **PURE**.
- Result depends only on args (parallel/GPU/memoizable) → **SIMPLE** (F2023).
- Scalar op applied array-wide → **ELEMENTAL** (implicitly pure).

### Allocatable vs pointer
- Owned, scoped lifetime, no aliasing → **ALLOCATABLE** (preferred; optimizer-friendly).
- Must alias / build linked structures / point at TARGET → **POINTER** (manual lifetime; can dangle).

### Loop choice
- Independent iterations, want parallel/offload → **DO CONCURRENT** (+`REDUCE`/`LOCAL`/`DEFAULT(NONE)`).
- Reduction → `DO CONCURRENT ... REDUCE(op:acc)` (F2023).
- Sequential dependence → ordinary `DO`.
- *Never* new FORALL (obsolescent).

### Kind selection
- Need ~double → `selected_real_kind(15,307)` **or** `use iso_fortran_env, only: real64`.
- Never `real(8)` / `real*8` — kind integers are processor-dependent (Annex A).

### Enum — which of the three?
- C-interop integer constants only → `ENUM, BIND(C)` (legacy; values are plain integers).
- A real, type-checked enum → **enum type** `ENUM :: t` → `TYPE(t)` (constructor `t(expr)` needed).
- Ordinal, non-interoperable distinct type → **enumeration type** `ENUMERATION TYPE :: t`.

## Tells & smells
- `if (allocated(a) .and. a(1) > 0)` → **bug**: Fortran does not short-circuit `.AND.`; use nested IF or a conditional expression.
- Reading a non-SAVE local you didn't assign → **undefined**, not 0.
- `>100×` GPU speedup → almost always a missing `!$acc wait` before `system_clock` (timing artifact).
- Mixed FP32-store/FP64-compute on a consumer GPU → **slower** than full FP64 (1:64 ratio); not an optimization.
- Naive `sum()` for FP64-quality diagnostics → O(N·eps) error; use pairwise/Kahan or `IEEE_FMA`.
- Different results across compilers → check **Annex A** (likely processor-dependent, not a bug).
- `*****` in output → fixed-width descriptor overflow; use `I0`/`G0`.

## Modern-style defaults
- `implicit none` (+ `(external)` to force EXTERNAL declarations) in every scoping unit.
- `use mod, only: ...` everywhere; kinds from `ISO_FORTRAN_ENV`.
- Procedures in **modules** (free explicit interfaces); heavy bodies in **submodules**.
- Free source form; `CHARACTER(LEN=n)` not `CHARACTER*n`; generic intrinsic names (`SQRT` not `DSQRT`).
- Replace: arithmetic IF → `IF`; computed GOTO → `SELECT CASE`; FORALL → `DO CONCURRENT`; COMMON/EQUIVALENCE → module variables.
