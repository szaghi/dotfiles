# Chapter 18 (Clause 18): Interoperability with C

## Core Idea
How Fortran and C exchange types, variables, and procedures: the `ISO_C_BINDING` module, `BIND(C)` linkage, interoperable types/arrays, C pointers, and the **C descriptor** (`CFI_cdesc_t` / `ISO_Fortran_binding.h`) for assumed-shape/assumed-rank/allocatable interop. **F2023 adds string interop** (`C_F_STRPOINTER`, `F_C_STRING`).

## Frameworks Introduced
- **`ISO_C_BINDING`** module: interoperable kinds (`C_INT`, `C_DOUBLE`, `C_FLOAT`, `C_CHAR`, `C_SIZE_T`, …); opaque types `C_PTR`, `C_FUNPTR`; constants `C_NULL_PTR`, `C_NULL_FUNPTR`, `C_NULL_CHAR`.
- **Pointer bridge procedures**: `C_LOC(x)` → `C_PTR`; `C_F_POINTER(cptr, fptr [, shape, lower])` → associate a Fortran pointer with a C address; `C_FUNLOC`/`C_F_PROCPOINTER` for procedures; `C_ASSOCIATED`, `C_SIZEOF`.
- **F2023 string interop**: `C_F_STRPOINTER(cstr, fstrptr [, nchars])` makes a Fortran character pointer over a C string; `F_C_STRING(string)` builds a NUL-terminated C string from a Fortran one.
- **`BIND(C)`**: gives an entity C linkage and an optional `NAME=` binding label; applies to procedures, derived types (`type, bind(c)`), variables, and common blocks.
- **C descriptor** (18.4–18.5): `CFI_cdesc_t` in `ISO_Fortran_binding.h` lets C receive/construct Fortran assumed-shape, assumed-rank, allocatable, and pointer arrays — with `CFI_establish`, `CFI_allocate`, `CFI_section`, `CFI_setpointer`, etc.

## Key Concepts
- **Interoperable type**: a type with a defined C correspondence — intrinsic types of `C_*` kinds, `bind(c)` derived types (sequence-like, no allocatable/pointer components, no type-bound procedures), interoperable enum types.
- **`VALUE` attribute**: pass-by-value, matching C's default scalar passing.
- **Array interop**: explicit-shape/assumed-size arrays map to C arrays directly (column-major ↔ row-major — **C sees transposed dimensions**); assumed-shape/rank require the C descriptor.
- **CONTIGUOUS / simply contiguous**: needed to pass without a copy to C expecting a flat buffer.
- **Procedure interop**: `bind(c)` procedures with interoperable dummies; the Fortran name and C name linked via the binding label.

## Worked Example
```fortran
use, intrinsic :: iso_c_binding
interface
  function c_malloc(n) bind(c, name='malloc') result(p)
    import :: c_ptr, c_size_t
    integer(c_size_t), value :: n
    type(c_ptr) :: p
  end function
end interface

real(c_double), pointer :: buf(:)
type(c_ptr) :: cp
cp = c_malloc(int(100*c_sizeof(0.0_c_double), c_size_t))
call c_f_pointer(cp, buf, [100])      ! view C memory as Fortran array

! F2023 string interop:
character(:), pointer :: fstr
call c_f_strpointer(c_str_from_lib(), fstr)   ! Fortran view of a C string
character(len=:), allocatable :: cs
cs = f_c_string('hello')              ! NUL-terminated C string
```
Interoperable derived type:
```fortran
type, bind(c) :: vec3
  real(c_double) :: x, y, z          ! no allocatable/pointer/TBP components
end type
```
- **Demonstrates**: `bind(c, name=)` linkage, `C_F_POINTER` over C memory, F2023 `C_F_STRPOINTER`/`F_C_STRING`, and a `bind(c)` struct.

## Anti-patterns
- **Forgetting column-major vs row-major**: a Fortran `a(m,n)` is C `a[n][m]` — index order is reversed; mismatches silently corrupt data.
- **Passing assumed-shape to plain C without a descriptor**: C needs `CFI_cdesc_t`; a bare pointer loses bounds/stride. Use explicit-shape/contiguous or the descriptor API.
- **`bind(c)` type with allocatable/pointer components or TBPs**: not interoperable — flatten to interoperable members.
- **Manual NUL-termination of strings**: use F2023 `F_C_STRING`/`C_F_STRPOINTER` instead of appending `C_NULL_CHAR` by hand.
- **Assuming `default` integer/real kinds match C**: always use `C_INT`/`C_DOUBLE`/etc. kinds.

## Key Takeaways
1. Bridge memory with `C_LOC` + `C_F_POINTER`; bridge procedures with `C_FUNLOC` + `C_F_PROCPOINTER`.
2. **F2023 `C_F_STRPOINTER` / `F_C_STRING`** handle Fortran↔C string conversion — stop hand-rolling NUL termination.
3. Use `C_*` kinds from `ISO_C_BINDING`; `VALUE` for by-value scalars; `bind(c, name=)` for linkage.
4. Fortran arrays are **column-major** → C sees reversed dimension order; assumed-shape/rank/allocatable need the C descriptor (`ISO_Fortran_binding.h`).
5. Interoperable `bind(c)` derived types must avoid allocatable/pointer components and type-bound procedures.

## Connects To
- **Ch 7**: Types — interoperable enum types, assumed-type `TYPE(*)` for opaque pass-through.
- **Ch 8**: Attributes — BIND(C), VALUE, CONTIGUOUS.
- **Ch 16**: Intrinsics — full ISO_C_BINDING procedure list.
- **Ch 9**: Data objects — simply-contiguous designators for copy-free passing.
