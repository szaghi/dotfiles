# Chapter 8 (Clause 8): Attribute declarations and specifications

## Core Idea
How objects get a type and **attributes** — the full attribute catalogue (ALLOCATABLE, POINTER, TARGET, INTENT, SAVE, VALUE, CONTIGUOUS, …) and the **array-shape taxonomy** that governs how dummy arrays receive bounds. The single richest clause for everyday declaration correctness.

## Frameworks Introduced
- **Type declaration statement** (8.2): `declaration-type-spec [, attr-spec]... :: entity-decl-list`. Attributes may be set on the type-decl line or by standalone attribute statements (8.6).
- **INTENT** (8.5.10, R828: IN | OUT | INOUT):
  - **IN**: shall not be defined/redefined (C846: not in a variable-definition context). For pointers, association shall not change.
  - **OUT**: **becomes undefined on entry** (except default-initialized subcomponents); allocatable INTENT(OUT) is **deallocated on entry**; actual arg must be definable.
  - **INOUT**: actual arg must *always* be definable — **not** equivalent to omitting INTENT (which requires definability only if actually redefined).
  - C849: INTENT(OUT) forbidden for EVENT_TYPE/LOCK_TYPE/NOTIFY_TYPE (would corrupt sync state).
- **Array-shape taxonomy** (8.5.8) — the bounds rules that bite:
  - **explicit-shape**: `a(n)`, `a(lb:ub)` — all bounds given.
  - **assumed-shape**: `a(:)` — extent from actual; **lower bound defaults to 1** unless you write `a(lb:)`.
  - **deferred-shape**: `a(:)` with ALLOCATABLE/POINTER — shape set by ALLOCATE/assignment.
  - **assumed-size**: `a(*)` — last dim size unknown (legacy/interop; no whole-array ops).
  - **implied-shape**: `parameter :: a(*) = [...]` — shape from the constant.
  - **assumed-rank**: `a(..)` — rank itself assumed from actual (F2018; for generic/interop pass-through).

## Key Concepts
- **ALLOCATABLE** vs **POINTER**: allocatable = owned, auto-deallocated at scope exit, no aliasing; pointer = may alias a TARGET, manual lifetime, can dangle.
- **CONTIGUOUS** (8.5.7): asserts/requires contiguous storage — enables vectorization and C interop; the processor may copy to satisfy it.
- **TARGET / POINTER**: only a TARGET (or another pointer's target) may be pointer-associated.
- **VALUE**: pass-by-value copy (esp. for C interop / `bind(c)`).
- **PROTECTED**: a module variable that is read-only outside its defining module.
- **SAVE**: retains value between invocations; module/initialized variables get it implicitly.
- **VOLATILE / ASYNCHRONOUS**: defeat optimization for externally/async-modified data.
- **BIND(C)**: C linkage for the entity.
- **RANK clause** (8.5.17): specify rank separately, supporting rank-agnostic code.

## Reference Tables
### Array dummy bounds — the rebasing trap
| Declaration | Lower bound in callee | Use when |
|---|---|---|
| `a(:)` assumed-shape | **1** (rebased!) unless `a(lb:)` | want shape, accept rebasing |
| `a(lb:)` assumed-shape | `lb` | preserve a known origin |
| `a(lb:ub)` explicit-shape | as declared | arrays-with-ghosts / interior selections |
| `a(*)` assumed-size | n/a (no whole-array) | legacy/C interop only |
| `a(..)` assumed-rank | n/a | generic/interop pass-through |

## Worked Example
INTENT semantics that surprise people:
```fortran
subroutine move(from, to)
  type(person), intent(in)  :: from   ! cannot be modified here
  type(person), intent(out) :: to     ! UNDEFINED on entry; actual must be definable
end subroutine

subroutine grow(buf)
  real, allocatable, intent(out) :: buf(:)  ! DEALLOCATED on entry — old contents lost
  allocate(buf(100))
end subroutine
```
For a derived type `X` with pointer component `P`, `intent(in)` blocks `X%P => t` (changing the pointer) but allows `X%P = 0` (defining its target) — the intent restricts the pointer-as-subobject, not its target (NOTE 3).
- **Demonstrates**: INTENT(OUT) zeroes/deallocates on entry — never use it to "update in place"; use INTENT(INOUT).

## Anti-patterns
- **Assumed-shape rebasing** (`feedback_fortran_rank_n_dummy_bounds`): a dummy `a(:)` silently rebases the lower bound to 1, breaking interior selections of arrays-with-ghosts — use **explicit bounds** `a(lb:ub)` for ghost-cell arrays.
- **INTENT(OUT) to preserve a value**: it makes the dummy undefined on entry (and deallocates allocatables) — use INTENT(INOUT) when the prior value should survive.
- **INTENT(OUT) on a sync type**: forbidden (C849) for EVENT/LOCK/NOTIFY_TYPE.
- **Aliasing via POINTER where ALLOCATABLE suffices**: allocatable gives automatic lifetime and no-alias guarantees the optimizer can exploit.
- **Omitting CONTIGUOUS then passing a strided section to C / a vectorized kernel**: forces a hidden copy or breaks interop.

## Key Takeaways
1. INTENT(OUT) makes the dummy **undefined on entry** and **deallocates allocatables** — semantically different from INTENT(INOUT) and from omitting INTENT.
2. Assumed-shape `a(:)` **rebases the lower bound to 1**; use explicit bounds for ghost/halo arrays.
3. Prefer ALLOCATABLE over POINTER unless aliasing is genuinely required — it's safer and faster.
4. CONTIGUOUS is a contract that enables vectorization/interop, possibly via a processor copy.
5. PROTECTED + module = read-only-outside; SAVE is implicit for initialized and module variables.

## Connects To
- **Ch 7**: Types — the type half of a declaration; CLASS/POINTER interplay.
- **Ch 9**: Use of data objects — array sections, ALLOCATE, pointer association at runtime.
- **Ch 15**: Procedures — INTENT governs dummy/actual argument rules; explicit-interface needs.
- **Ch 18**: C interoperability — BIND(C), VALUE, CONTIGUOUS, assumed-rank for `c_f_pointer`.
