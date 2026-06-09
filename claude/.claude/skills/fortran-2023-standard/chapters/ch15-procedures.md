# Chapter 15 (Clause 15): Procedures

## Core Idea
The procedure model: interfaces (implicit vs explicit, abstract), dummy/actual argument association, the purity hierarchy (**F2023 adds `SIMPLE`** above PURE), elemental procedures, and generic resolution. The clause that governs every call.

## Frameworks Introduced
- **Purity hierarchy** (prefix-spec R1530): `PURE` ⊃ `SIMPLE` (F2023); also `ELEMENTAL`, `IMPURE`, `RECURSIVE`/`NON_RECURSIVE`, `MODULE`.
  - **PURE** (15.7): no side effects — no global state modification, no I/O, INTENT(IN) for nonpointer dummies, no volatile, no STOP. Required for DO CONCURRENT bodies, FORALL, specification expressions.
  - **SIMPLE** (15.8, **F2023**): a *pure* procedure that is also **referentially transparent** — additionally **may not reference any use- or host-associated variable** (except constant-expression inquiries) and **no COMMON**; all called procedures and internal subprograms must be SIMPLE; no ENTRY. Result depends only on arguments.
  - **ELEMENTAL**: defined on scalars, applies element-wise to conformable arrays; implicitly PURE unless IMPURE.
- **Interfaces** (15.4): **explicit** interface required (15.4.2.2) when the procedure has optional/keyword args, assumed-shape/assumed-rank/coarray/allocatable/pointer dummies, a result that is array/pointer/allocatable, is elemental, or is bound by `bind(c)` — i.e. nearly all modern code. **Abstract interface** + `PROCEDURE(iface)` declares procedure-pointer/dummy-procedure shapes.
- **Argument association** (15.5.2): positional then keyword (`name=actual`); OPTIONAL dummies tested with `PRESENT`; INTENT governs definability (ch08).
- **Generic resolution** (15.5.5): overload by distinguishing arguments — disambiguated by type, **kind** type parameter, rank, and presence; length params do **not** disambiguate.

## Key Concepts
- **Explicit interface** comes free from: module procedures, internal procedures, intrinsics. External procedures need an `interface` block.
- **Dummy procedure / procedure pointer**: pass/store procedures via `PROCEDURE(abstract_iface) :: p`.
- **Elemental** is the idiomatic way to write a scalar kernel and apply it array-wide without explicit loops.
- **`MODULE` prefix**: the separate-module-procedure body (submodule); must match the interface's characteristics and dummy names exactly (C1558).
- **Statement functions** and **ENTRY**: obsolescent.

## Reference Tables
### Purity / prefix specs
| Prefix | Guarantee | Notable constraints |
|---|---|---|
| `PURE` | no side effects | INTENT(IN) dummies, no I/O, no global writes |
| `SIMPLE` (F2023) | pure **+ result depends only on args** | no use/host vars, no COMMON, callees SIMPLE |
| `ELEMENTAL` | element-wise over arrays | implicitly PURE (unless IMPURE) |
| `IMPURE` | opt out of implied purity | not with PURE/SIMPLE |
| `RECURSIVE`/`NON_RECURSIVE` | self-call allowed/forbidden | mutually exclusive |

## Worked Example
```fortran
pure elemental function clamp(x, lo, hi) result(y)   ! element-wise, pure
  real, intent(in) :: x, lo, hi
  real :: y
  y = max(lo, min(hi, x))
end function
! clamp applies to scalars AND arrays: b = clamp(a, 0.0, 1.0)

simple function f(x) result(r)        ! F2023: referentially transparent
  real, intent(in) :: x
  real :: r
  r = x*x + 1.0                        ! uses ONLY x — no module/host/common state
end function
```
Generic resolution by kind:
```fortran
interface solve
  module procedure solve_sp   ! real(real32) arg
  module procedure solve_dp   ! real(real64) arg  -- distinguished by KIND
end interface
```
- **Demonstrates**: elemental scalar-kernel-over-arrays, the new SIMPLE referential-transparency contract, and kind-based generic overloading.

## Anti-patterns
- **External procedure without an explicit interface** for modern features: passing an assumed-shape array or using keyword/optional args without an interface block is a conformance error (15.4.2.2) and a silent-bug source — put procedures in modules.
- **Expecting PURE to mean referentially transparent**: PURE still permits reading module variables; use **SIMPLE** (F2023) when the result must depend only on arguments (e.g. for aggressive parallelization / memoization).
- **Disambiguating generics by length parameter**: only kind params, rank, type, and presence disambiguate — length params do not.
- **Statement functions / ENTRY in new code**: obsolescent — use internal/module procedures.
- **Relying on argument aliasing**: passing the same variable to two non-pointer dummies that get modified is undefined.

## Key Takeaways
1. **F2023 `SIMPLE`** = PURE + result depends only on arguments (no use/host/COMMON state) — the strongest transparency contract, ideal for parallel/GPU kernels.
2. Modern dummies (assumed-shape/rank, optional, allocatable, pointer, elemental, bind(c)) **require an explicit interface** — keep procedures in modules to get it automatically.
3. ELEMENTAL writes one scalar kernel that applies element-wise — implicitly PURE.
4. Generics resolve by type, **kind**, rank, and presence — never by length parameter.
5. INTENT + PRESENT + keyword arguments are the safe calling discipline; argument aliasing is undefined.

## Connects To
- **Ch 8**: Attributes — INTENT, OPTIONAL, dummy-array shapes feed the interface rules.
- **Ch 11**: Execution control — DO CONCURRENT bodies must be pure; SIMPLE strengthens that.
- **Ch 14**: Program units — MODULE PROCEDURE bodies live in submodules.
- **Ch 16**: Intrinsics — many intrinsics are SIMPLE or ELEMENTAL.
