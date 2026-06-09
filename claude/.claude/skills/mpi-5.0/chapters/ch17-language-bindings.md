# Chapter 17 (§19–20): Language Bindings and the Standard ABI

## Core Idea
How MPI maps to C and Fortran (handle types, argument conventions, the `mpi_f08` module), the large-count (`_c`) routines, and — the **MPI 5.0 headline feature** — a **standard Application Binary Interface** so one compiled binary can run against *any* conforming MPI implementation.

## Frameworks Introduced
- **C bindings**: opaque handle types (`MPI_Comm`, `MPI_Datatype`, `MPI_Request`, `MPI_Win`, `MPI_File`, …); functions return `int` error codes; `MPI_Count`/`MPI_Aint`/`MPI_Offset` for large/address-sized values.
- **Fortran bindings** — three, in increasing modernity:
  - `mpif.h` (legacy include, deprecated),
  - the `mpi` module (legacy),
  - **`use mpi_f08`** (modern): **derived-type handles** (`TYPE(MPI_Comm)` etc.), proper `INTENT`, `ASYNCHRONOUS` buffer attributes, optional `ierror` — type-safe and the recommended choice.
- **Large-count routines** (`_c` suffix, e.g. `MPI_Send_c`, `MPI_Type_contiguous_c`): take `MPI_Count` instead of `int` for counts — needed when message element counts exceed `INT_MAX` (large buffers). The base names take `int`.
- **Standard ABI** (§20, **MPI 5.0**): a defined binary interface — handle representations, constant values, struct layouts — so an executable/library compiled against the ABI links and runs against **any** ABI-conforming MPI without recompilation.
  - **`MPI_Abi_get_version(&major, &minor)`** and **`MPI_Abi_get_info(...)`** query ABI support/version at runtime; callable any time.

## Key Concepts
- **The ABI ends the "recompile per MPI implementation" tax**: historically a binary built against MPICH wouldn't run against Open MPI (different handle sizes/constants). The MPI 5.0 standard ABI lets one binary be portable across conforming implementations — huge for distributing MPI software and containers.
- **`use mpi_f08` is the correct Fortran binding for new code** — it catches argument-type errors at compile time (handles are distinct types, not bare `INTEGER`), and `ASYNCHRONOUS` protects nonblocking buffers from compiler reordering (a real correctness issue with `mpif.h`).
- **`_c` large-count routines** matter once buffers exceed ~2 GiB-elements; use them in big-data MPI rather than risking `int` overflow in `count`.
- **`ASYNCHRONOUS` attribute** on nonblocking buffers in `mpi_f08` is essential — the compiler must not move accesses across the `MPI_Wait` (the Fortran analog of "don't touch the `Isend` buffer early").

## Anti-patterns
- **`mpif.h` for new Fortran code**: no type checking, no `ASYNCHRONOUS` protection — use `use mpi_f08`.
- **Passing the wrong handle type with the old `mpi` module/`mpif.h`**: silently compiles (all `INTEGER`) and fails at runtime; `mpi_f08`'s typed handles catch it.
- **`int`-count routines for >2 GiB-element messages**: overflow — use the `_c` variants.
- **Assuming binary portability pre-5.0 / without checking the ABI**: query `MPI_Abi_get_version`; only ABI-conforming implementations guarantee it.
- **Omitting `ASYNCHRONOUS` on nonblocking buffers in Fortran**: the compiler may reorder/optimize across `MPI_Wait`, corrupting data.

## Key Takeaways
1. **MPI 5.0 standard ABI**: one binary runs against any ABI-conforming implementation — query with `MPI_Abi_get_version`/`MPI_Abi_get_info`.
2. Fortran: **`use mpi_f08`** (typed handles, `INTENT`, `ASYNCHRONOUS`) for new code; `mpif.h`/`mpi` module are legacy.
3. `_c`-suffixed routines take `MPI_Count` for large (>`INT_MAX`) element counts.
4. C handles are opaque types; functions return `int` error codes.
5. Mark nonblocking Fortran buffers `ASYNCHRONOUS` to block unsafe compiler reordering.

## Connects To
- **Ch 2**: handle/argument conventions and completion semantics.
- **Ch 16**: deprecated bindings (`mpif.h`, C++) vs modern `mpi_f08`.
- **Ch 18**: the full binding-signature reference (Annex A).
- **fortran-2023-standard**: `mpi_f08` uses modern Fortran features (assumed-shape, `INTENT`, `ASYNCHRONOUS`).
