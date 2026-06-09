# Chapter 19 (Clause 19): Scope, association, and definition

## Core Idea
The rules for *where a name means what* (scoping), the **kinds of association** that link entities, and the precise **definition/undefinition** status of variables (when a variable holds a usable value vs. is undefined). The clause that resolves "is this variable defined here?" and "do these two names refer to the same thing?"

## Frameworks Introduced
- **Scope levels** (19.1): identifiers have **global** (program/module/external-procedure/common-block/bind-c names), **local** (scoping-unit names), or **construct/statement** scope (e.g. an ASSOCIATE name, a DO CONCURRENT index, an implied-DO variable).
- **Associations** (19.5) — the link kinds:
  - **name association**: argument, use, host, and *construct* association (the same entity reachable by another name).
  - **pointer association** (19.5.2): a pointer ↔ its target; status is *associated* / *disassociated* / *undefined*.
  - **storage association** (19.5.3): EQUIVALENCE and COMMON overlay storage (obsolescent technique).
  - **inheritance association** (19.5.4): a polymorphic object and its parent-type component.
- **Variable definition status** (19.6): a variable is *defined* (has a valid value) or *undefined*. The clause enumerates exactly which events define (assignment, input, ALLOCATE with SOURCE, DATA, …) and undefine (INTENT(OUT) entry, deallocation, failed I/O, end of a procedure for non-SAVE locals, …) a variable.
- **Variable definition context** (19.6.7) / **pointer association context** (19.6.8): the syntactic positions where a variable may be defined / a pointer associated — the formal basis for INTENT(IN) constraints (ch08).

## Key Concepts
- **Host association**: an internal/module procedure sees its host's entities unless shadowed; the source of "where did this variable come from" confusion.
- **`IMPORT`**: control host association into an interface body (block it, or import specific names).
- **Undefined ≠ zero**: a non-SAVE local without initialization is *undefined* between invocations — reading it is a program error, not a guaranteed 0.
- **SAVE / initialization**: an initialized variable (`integer :: n = 0`) implicitly has SAVE and is *initially defined*; without init and without SAVE it is *initially undefined* and undefined on each entry.
- **Pointer initial status is undefined** unless declared `=> null()` or NULLIFYed — never test/deref a pointer of undefined status.

## Reference Tables
### The associations (19.5)
| Association | Links | Mechanism |
|---|---|---|
| argument | actual ↔ dummy | procedure call |
| use | module entity ↔ local name | USE |
| host | host entity ↔ inner scope | nesting |
| construct | selector ↔ ASSOCIATE/SELECT name | construct |
| pointer | pointer ↔ target | `=>` |
| storage | overlaid storage | COMMON/EQUIVALENCE (obsolescent) |
| inheritance | polymorphic ↔ parent component | EXTENDS |
| linkage | Fortran ↔ C entity | BIND(C) |

## Worked Example
Definition status that bites:
```fortran
subroutine f()
  integer :: counter          ! NOT saved, NOT initialized -> undefined each entry
  integer :: n = 0            ! initialized -> implicit SAVE, defined, persists
  real, pointer :: p          ! pointer status UNDEFINED -> must not test/deref
  real, pointer :: q => null()! disassociated -> associated(q) is .false., safe to test
  counter = counter + 1       ! ERROR: reads an undefined variable
end subroutine
```
Host association + IMPORT:
```fortran
module m
  integer :: shared_n
contains
  subroutine outer()
    integer :: x
    call inner()
  contains
    subroutine inner()        ! sees x and shared_n by host association
      x = shared_n            ! both visible without redeclaration
    end subroutine
  end subroutine
end module
```
- **Demonstrates**: the undefined-vs-initialized distinction, safe vs unsafe pointer status, and host association reaching outer/module entities.

## Anti-patterns
- **Assuming an uninitialized local is 0**: it is *undefined* (and undefined on each call without SAVE) — initialize explicitly or declare SAVE.
- **Relying on the implicit-SAVE of an initializer accidentally**: `integer :: n = 0` persists across calls — surprising if you wanted a fresh 0 each time (use an explicit assignment in the body).
- **Testing/dereferencing a pointer of undefined status**: only *disassociated* (`=> null()`) pointers are safe to test with `ASSOCIATED`.
- **COMMON/EQUIVALENCE for new code**: storage association is obsolescent — use modules.
- **Shadowing a host name unintentionally**: a local declaration silently hides the host's entity; use `IMPORT, NONE`/explicit imports in interface bodies to control it.

## Key Takeaways
1. Eight association kinds link entities; "associated" is meaningless without naming *which* (cf. ch03).
2. A non-SAVE, non-initialized local is **undefined** every entry — reading it is an error, not a guaranteed zero.
3. An initializer (`= value`) implies SAVE and persistence — sometimes a surprise.
4. Only `=> null()`/NULLIFYed pointers have *disassociated* (safely testable) status; default is *undefined*.
5. Host association makes outer/module entities visible inward; control it with `IMPORT`.

## Connects To
- **Ch 3**: Terms — the 9 associations are defined there; this clause gives their rules.
- **Ch 8**: Attributes — INTENT(IN) maps onto "variable definition context" (19.6.7).
- **Ch 14**: Program units — use/host association in modules and submodules.
- **Ch 9**: Data objects — pointer association set by ALLOCATE/pointer assignment.
