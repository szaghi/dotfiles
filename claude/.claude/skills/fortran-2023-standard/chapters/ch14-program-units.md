# Chapter 14 (Clause 14): Program units

## Core Idea
The five program-unit kinds in detail: **main program**, **module** (+ USE association), **submodule** (separates interface from implementation), block data, and the external subprogram. The clause that governs modularity, encapsulation, and separate compilation.

## Frameworks Introduced
- **Main program** (14.1): `[PROGRAM name]` … `END [PROGRAM [name]]`. Exactly one per program; cannot be referenced from anywhere (C: no self-reference). May be defined in another language (then no Fortran main-program unit).
- **Module** (14.2): declarations + specifications + definitions; public identifiers reach other units via **use association**. Module spec-part forbids statement functions, ENTRY, FORMAT (C1403). `module-subprogram` may be a function, subroutine, or **separate-module-subprogram** (the implementation half of a submodule interface).
- **USE statement** (R1409): `USE [, INTRINSIC | NON_INTRINSIC ::] module-name [, rename-list]` or `USE module, ONLY: only-list`.
  - **rename** `local => used`; operator rename `OPERATOR(.x.) => OPERATOR(.y.)`.
  - **ONLY:** restricts the imported set — the disciplined default for large modules.
  - `module-nature` disambiguates an intrinsic vs nonintrinsic module of the same name (C1406: not both).
- **Submodule** (14.2.3): `SUBMODULE (parent[:ancestor]) name`; holds the *bodies* of module procedures whose interfaces are declared `MODULE PROCEDURE`/`MODULE FUNCTION` in the parent — **breaks compile-time coupling** between interface and implementation.

## Key Concepts
- **Accessibility**: PUBLIC (default) / PRIVATE control what USE exposes; PROTECTED makes a public variable read-only outside.
- **Use-associated entity** is "previously declared/defined" — you do not redeclare it.
- **Intrinsic modules**: `ISO_FORTRAN_ENV`, `ISO_C_BINDING`, `IEEE_*` — accessed with `USE, INTRINSIC ::` to be explicit.
- **Submodule benefit**: changing a module procedure's *body* (in a submodule) does not force recompilation of the module's *users* — only the submodule recompiles. Cuts rebuild cascades in large codebases.
- **Block data** (obsolescent): initializes named COMMON; superseded by module variables with initializers.

## Worked Example
Submodule splitting interface from implementation:
```fortran
module geometry
  implicit none
  interface
    module function area(r) result(a)   ! interface only
      real, intent(in) :: r
      real :: a
    end function
  end interface
end module

submodule (geometry) geometry_impl       ! implementation in a submodule
contains
  module function area(r) result(a)       ! the body
    real, intent(in) :: r
    real :: a
    a = 3.14159 * r**2
  end function
end submodule
```
Disciplined USE:
```fortran
use geometry, only: area
use, intrinsic :: iso_fortran_env, only: real64, output_unit
use mymod, only: mysolve => solve        ! rename to avoid clash
```
- **Demonstrates**: the submodule interface/body split (faster rebuilds), `ONLY:` to limit imports, `USE, INTRINSIC`, and renaming.

## Anti-patterns
- **Bare `USE module` without `ONLY:`** in large code: pollutes the namespace and creates accidental dependencies — prefer `ONLY:`.
- **Putting heavy implementations directly in a module**: every body change recompiles all users; move bodies to a **submodule** to localize rebuilds.
- **Block data / named COMMON for new code**: obsolescent — use module variables with initializers.
- **Referencing the main program / circular `USE`**: forbidden (no self-reference, no module self-use directly or indirectly).
- **Declaring an intrinsic procedure in a module without INTRINSIC**: must carry the INTRINSIC attribute or be used as intrinsic there.

## Key Takeaways
1. **Submodules** separate a module's interface from its implementation → changing a procedure body recompiles only the submodule, not its users.
2. Always prefer `USE module, ONLY: ...` for namespace discipline; rename with `local => used`.
3. Modules are the unit of encapsulation: PUBLIC/PRIVATE/PROTECTED govern exposure.
4. Exactly one main program; it may be non-Fortran (then omit the Fortran main-program unit).
5. Block data + named COMMON are obsolescent — use module variables.

## Connects To
- **Ch 5**: Fortran concepts — the program-unit grammar overview.
- **Ch 15**: Procedures — `MODULE PROCEDURE` separate bodies, explicit interfaces.
- **Ch 16**: Intrinsic modules — ISO_FORTRAN_ENV, ISO_C_BINDING, IEEE_*.
- **Ch 19**: Scope/association — use association rules in full.
