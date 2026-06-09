# Chapter 7 (Clause 7): Types

## Core Idea
The type system: five intrinsic types, derived types, and the **three F2023 enum concepts**, plus the kind/length type-parameter machinery, polymorphism (CLASS), and the new **TYPEOF / CLASSOF** specifiers. A type = name + value set + value notation + operations.

## Frameworks Introduced
- **Type classification**: intrinsic (integer, real, complex, character, logical) vs nonintrinsic (derived, enum, enumeration). A nonintrinsic name is usable only where accessible; intrinsic types are always accessible.
- **Type parameters** (7.2): every type parameter is integer, of two kinds —
  - **kind type parameter** (named `KIND`): a *constant expression*, known at compile time, **participates in generic resolution**.
  - **length type parameter** (e.g. character `LEN`): need not be known at compile time, may change during execution, **does not** participate in generic resolution.
  - `type-param-value` (R701) = `scalar-int-expr` | `*` (assumed) | `:` (deferred). C702: `:` only for POINTER/ALLOCATABLE.
- **declaration-type-spec** (R703): `intrinsic-type-spec`, `TYPE(...)`, `CLASS(derived)`, `CLASS(*)` (unlimited polymorphic), `TYPE(*)` (assumed-type), and **F2023: `TYPEOF(data-ref)`** (non-polymorphic, mirrors data-ref's type) and **`CLASSOF(data-ref)`** (polymorphic, mirrors data-ref's type).
- **Polymorphism**: `CLASS(t)` → declared type t, dynamic type any extension of t. `CLASS(*)` → unlimited polymorphic. C708: CLASS/CLASSOF entities must be dummy args or ALLOCATABLE/POINTER.

## Key Concepts
- **declared type vs dynamic type**: the static type vs the runtime type of a polymorphic entity; resolved via SELECT TYPE (ch11).
- **assumed-type `TYPE(*)`**: unlimited polymorphic dummy; usable only as actual arg or to a handful of inquiry intrinsics (C715) — for opaque pass-through (often to C).
- **derived type** (7.5): user type with components, type parameters (KIND/LEN), type-bound procedures, finalizers, and single inheritance (`EXTENDS`).
- **extensible / extended / abstract type**: `EXTENDS(parent)` for inheritance; `ABSTRACT` + `DEFERRED` bindings for abstract base types.
- **default initialization** & **finalization** (7.5.6 FINAL subroutines).
- **structure constructor** `t(comp=val, ...)`; **enum/enumeration constructor**.

## The three enum concepts (F2023) — the key new feature
| Construct | Syntax | Is a type? | Interoperable? | Values |
|---|---|---|---|---|
| **Interop enum** (F2003) | `ENUM, BIND(C) ... ENUMERATOR :: ... END ENUM` | No — integer named constants | Yes (C enum) | integers; first=0 (or set), then +1 |
| **Enum type** (F2023) | `ENUM [, BIND(C)] :: name ... END ENUM` declared as `TYPE(name)` | **Yes** | Yes if BIND(C) | integer representation; needs constructor `name(expr)` |
| **Enumeration type** (F2023) | `ENUMERATION TYPE :: name ... END ENUMERATION TYPE` | **Yes** | **No** | ordinal-valued; not a derived type |

## Code Examples
F2023 enum type with constructor (interoperable):
```fortran
module enum_mod
  enum, bind(c) :: myenum
    enumerator :: one = 1, two, three   ! two=2, three=3
  end enum
contains
  subroutine sub(a) bind(c)
    type(myenum), value :: a
    print *, a                          ! prints integer value
  end subroutine
end module

program example
  use enum_mod
  type(myenum) :: x  = one              ! enumerator -> enum var
  type(myenum) :: y  = myenum(12345)    ! constructor from integer
  call sub(three)
end program
! INVALID:  type(myenum) :: z = 12345   ! bare integer, no constructor
!           call sub(999)               ! not type-compatible
!           call sub(f1)                ! wrong enum type
```
- **What it demonstrates**: an enum *type* (`type(myenum)`) is type-checked, unlike the old integer-valued `ENUM, BIND(C)` constants — you cannot assign a bare integer without the constructor.

TYPEOF / CLASSOF (F2023):
```fortran
subroutine wrap(x)
  class(*), intent(in) :: x
  ! ... TYPEOF/CLASSOF let you declare locals matching another entity's type
end subroutine
real :: a(100)
typeof(a) :: tmp        ! tmp is real(100), non-polymorphic, mirrors a
```
- **What it demonstrates**: `TYPEOF`/`CLASSOF` declare an entity whose type *tracks* a data-ref's type (incl. deferred params), without restating it.

## Anti-patterns
- **Using `:` (deferred param) on a non-POINTER/ALLOCATABLE entity**: violates C702.
- **Putting a length param where a kind param's generic resolution is expected**: length params don't disambiguate generics — only kind params do.
- **Assigning a bare integer to an enum-type variable**: the F2023 *enum type* requires the constructor; the old `ENUM, BIND(C)` constants behaved like plain integers (a real source of confusion now that both exist).
- **Declaring `CLASS(t)` for a non-dummy, non-allocatable, non-pointer local**: C708 forbids it.

## Reference Tables
### type-param-value (R701)
| Form | Meaning | Constraint |
|---|---|---|
| `scalar-int-expr` | explicit value | kind param must be constant expr (C701) |
| `*` | assumed (from arg / selector / named const) | length params only |
| `:` | deferred (set by ALLOCATE/assignment/ptr-assign) | POINTER/ALLOCATABLE only (C702) |

## Key Takeaways
1. Two parameter species: **kind** (compile-time constant, drives generic resolution) vs **length** (runtime-variable, does not).
2. **F2023 adds `TYPEOF` and `CLASSOF`** — declare an entity that mirrors another's type without repeating it.
3. **F2023 adds true enum *types* and *enumeration* types** distinct from the legacy integer `ENUM, BIND(C)`; enum types are type-checked and need a constructor.
4. `TYPE(*)` = assumed-type (opaque pass-through, esp. to C); `CLASS(*)` = unlimited polymorphic.
5. Declared type vs dynamic type is resolved at runtime with SELECT TYPE; CLASS entities must be dummy/allocatable/pointer.

## Connects To
- **Ch 8**: Attribute declarations — how types are attached to objects (ALLOCATABLE, POINTER, etc.).
- **Ch 11**: Execution control — SELECT TYPE resolves dynamic type.
- **Ch 15**: Procedures — type-bound procedures, generic resolution by kind param.
- **Ch 18**: C interoperability — `ENUM, BIND(C)`, `TYPE(*)`, interoperable enum types.
