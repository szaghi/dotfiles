# Chapter 9 (Clause 9): Use of data objects

## Core Idea
How to *refer to* data: designators (substrings, components, complex parts, array elements/sections), image selectors for coarrays, and the **dynamic association machinery** — ALLOCATE/DEALLOCATE/NULLIFY with STAT/ERRMSG/SOURCE/MOLD.

## Frameworks Introduced
- **Designator** (9.1): the syntax that picks out a variable or part — name, array element, array section, substring, structure component, coindexed object, complex part.
- **Array sections** (9.5.3.4): three subscript forms —
  - **element**: `a(i)`
  - **subscript triplet** `lb:ub:stride`: a regular slice; `a(2:8:2)`, `a(:)`, `a(::−1)`.
  - **vector subscript** `a(idx)`: gather/scatter by an integer index array (may not be a pointer target; duplicates forbidden on the LHS).
- **Complex part designators** (9.4.4, F2008): `z%RE` and `z%IM` — real-valued, same shape as `z`, *assignable* (`x%im = 0.0`). Equivalent to `REAL(z)`/`AIMAG(z)` for reading.
- **Image selector** (9.6): `coarray[image]` / `coarray[cosubscripts, STAT=, TEAM=, TEAM_NUMBER=]` — references a coarray on another image.
- **ALLOCATE** (9.7.1, R929): `ALLOCATE([type-spec ::] allocation-list [, alloc-opt-list])`
  - `alloc-opt`: `STAT=`, `ERRMSG=`, **`SOURCE=`** (allocate + copy value & shape), **`MOLD=`** (allocate with shape/type of expr, no value copy).
  - **F2023 bounds-array form**: `ALLOCATE(arr([lower:]upper))` where bounds are *integer arrays* → rank set by the bounds array (rank-agnostic allocation).

## Key Concepts
- **simply contiguous** (9.5.4): a designator the compiler can *prove* contiguous syntactically — gates passing to CONTIGUOUS dummies / C without a copy.
- **STAT= / ERRMSG=**: nonzero STAT on failed (de)allocation; ERRMSG receives the message; without STAT, failure stops execution.
- **NULLIFY**: disassociate a pointer (`nullify(p)` ≡ `p => null()`).
- **deallocation rules**: allocatables auto-deallocate at scope exit; deallocating a pointer whose target is allocatable/another pointer follows 9.7.3.3.
- **type parameter inquiry** (9.4.5): `x%kind`, `s%len`.

## Reference Tables
### ALLOCATE options
| Option | Effect |
|---|---|
| `SOURCE=expr` | allocate, then copy shape **and** value of expr |
| `MOLD=expr` | allocate with type/shape of expr; value undefined |
| `STAT=v` | v=0 success, nonzero failure (suppresses auto-stop) |
| `ERRMSG=c` | character variable receives failure message |
| `type-spec ::` | allocate polymorphic/deferred objects to a concrete type |

### Array section subscripts
| Form | Example | Notes |
|---|---|---|
| element | `a(i)` | scalar |
| triplet | `a(2:8:2)` | regular slice; negative stride reverses |
| vector | `a([1,3,3])` | gather; **no dup on LHS**, not a target |

## Worked Example
```fortran
real, allocatable :: a(:,:), b(:,:)
integer :: ub(2) = [100, 50], st
allocate(a(ub), stat=st)            ! F2023: rank-2 from bounds array ub
allocate(b, source=a)               ! same shape AND values as a
a(2:99, ::2) = 0.0                   ! triplet section, stride 2 on dim 2
z%im = 0.0                           ! assign imaginary part (complex-part designator)
if (this_image() == 1) x[2] = 5     ! coarray: set x on image 2
```
- **Demonstrates**: F2023 bounds-array ALLOCATE, SOURCE= cloning, strided section assignment, assignable complex part, and a coarray image selector.

## Anti-patterns
- **Duplicate indices in a vector subscript on the LHS**: `a([1,1]) = [...]` is undefined — forbidden.
- **Passing a strided section to a CONTIGUOUS dummy / C**: not simply contiguous → hidden copy or error; allocate contiguous or accept the copy knowingly.
- **ALLOCATE without STAT in failure-prone paths**: an allocation failure stops the program; use STAT= to recover.
- **Forgetting SOURCE= copies value, MOLD= does not**: choosing MOLD when you needed the values gives undefined contents.

## Key Takeaways
1. **F2023**: `ALLOCATE(arr(bounds_array))` sets rank from an integer bounds array — rank-agnostic allocation.
2. `SOURCE=` copies shape + value; `MOLD=` copies shape/type only.
3. `z%RE` / `z%IM` are real, shaped like `z`, and **assignable**.
4. Vector subscripts gather/scatter but forbid LHS duplicates and can't be pointer targets.
5. "Simply contiguous" is a *syntactic* contiguity proof — the gate to copy-free CONTIGUOUS/C passing.

## Connects To
- **Ch 8**: Attributes — ALLOCATABLE/POINTER/CONTIGUOUS are declared there, exercised here.
- **Ch 11**: Execution control — coarray/team constructs (CHANGE TEAM, image control).
- **Ch 16**: Intrinsics — MOVE_ALLOC, ALLOCATED, ASSOCIATED, image-query intrinsics.
- **Ch 18**: C interop — simply-contiguous designators and c_f_pointer.
