# Chapter 5 (Clause 5): Fortran concepts

## Core Idea
The **high-level syntax** — the grammar above the statement/expression level — and the foundational concepts of program structure, names, statement classification, and statement ordering. This is the skeleton onto which every other clause hangs.

## Frameworks Introduced
- **Program unit hierarchy** (R501–R511): a `program` is one or more `program-unit`s. A `program-unit` is one of: `main-program`, `external-subprogram` (function/subroutine), `module`, `submodule`, `block-data`.
  - Each program unit = optional `specification-part` then optional `execution-part` then optional `internal-subprogram-part`, bracketed by its begin/end statements.
- **specification-part vs execution-part** (R504, R509): specifications (USE, IMPORT, IMPLICIT, declarations) come first; executable constructs follow. Statement *ordering* is defined rigorously by `program-unit` (R502); expression hierarchy by `expr` (R1023).
- **declaration-construct** (R507/R508): derived-type-def, **enum-def**, **enumeration-type-def** (← new typed enums, F2023), generic-stmt, interface-block, parameter-stmt, procedure-declaration-stmt, type-declaration-stmt, etc.

## Key Concepts
- **executable construct** (R514): the unit of control flow — action-stmt, ASSOCIATE, BLOCK, CHANGE TEAM, CRITICAL, DO, IF, SELECT, WHERE, FORALL, etc.
- **action-stmt** (R515): a single executable statement (assignment, CALL, ALLOCATE, etc.).
- **keyword**: a name used in a specific syntactic role; *statement keywords* (e.g. `INTEGER`) vs *argument keywords* (dummy names in `name=value`).
- **companion concepts**: program, image, execution sequence — the runtime model.
- **statement order**: specification statements precede executable statements; within specifications, USE → IMPORT → IMPLICIT → other declarations.

## Mental Models
- Read every program unit as the same template: **header → specs → executables → contained procedures → end**. Modules omit executables; block-data has only specs.
- The R-rule for `program-unit` *is* the statement-ordering law — there's no separate "ordering table" to memorize; the grammar enforces it.

## Code Examples
The five program-unit forms, schematically:
```fortran
program main           ! main-program
  use mymod            ! specification-part
  implicit none
  integer :: i         ! declaration-construct
  i = compute()        ! execution-part
contains               ! internal-subprogram-part
  integer function compute()
    compute = 42
  end function
end program main

module mymod           ! module: specs + module-subprograms, no top-level executables
contains
  subroutine s; end subroutine
end module
```
- **What it demonstrates**: the uniform header→specs→exec→contains→end skeleton (R1401, R1404).

## Anti-patterns
- **Interleaving declarations and executables**: F still requires specs *before* executables in a scoping unit (BLOCK construct gives a nested scope if you need late declarations).
- **Confusing module-subprogram-part with internal-subprogram-part**: modules contain module procedures (callable via USE); main programs/subprograms contain *internal* procedures (host-associated, not separately accessible).

## Key Takeaways
1. Five program-unit kinds: main-program, external-subprogram, module, submodule, block-data.
2. The order is law: specifications before executables; the `program-unit` R-rule encodes it.
3. `enumeration-type-def` appears in R508 — typed enumerations are a first-class F2023 declaration construct.
4. "Executable construct" ⊋ "action statement": constructs (DO/IF/SELECT/BLOCK/ASSOCIATE) wrap action statements.

## Connects To
- **Ch 14**: Program units — full rules for each unit kind.
- **Ch 11**: Execution control — the executable constructs introduced here.
- **Ch 7**: Types — derived-type-def and the new enumeration-type-def.
