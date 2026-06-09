# Chapter 16 (§16–18): Deprecated, Removed, Semantic Changes

## Core Idea
The "what not to use / what changed" reference: features still legal but discouraged (**deprecated**), features gone entirely (**removed**), and behavioral changes between versions (**semantic changes & warnings**). The migration map for older MPI code.

## Frameworks Introduced
- **Deprecated** (still work, may be removed later) — notable items:
  - Attribute caching old API: `MPI_Attr_get`/`_put`/`_delete`, `MPI_Keyval_create`/`_free`, `MPI_NULL_COPY_FN`/`MPI_DUP_FN`/`MPI_NULL_DELETE_FN` → superseded by `MPI_Comm_get_attr`/`_set_attr` + `MPI_Comm_create_keyval` (MPI-2.0).
  - `MPI_Type_extent`/`MPI_Type_lb`/`MPI_Type_ub` → `MPI_Type_get_extent`/`MPI_Type_get_true_extent`.
  - `MPI_Address` → `MPI_Get_address`; `MPI_Type_hvector`/`hindexed`/`struct` → `MPI_Type_create_*`.
  - `MPI_Errhandler_create`/`_set`/`_get` → `MPI_Comm_create_errhandler`/`_set_errhandler`/`_get_errhandler`.
  - `MPI_HOST`, the `mpif.h` Fortran include, and the `mpi` Fortran module's non-`_f08` interfaces are deprecated in favor of `use mpi_f08`.
  - Cancelling a **send** via `MPI_Cancel` is deprecated.
- **Removed** (no longer in the standard): the entire **C++ bindings** (deprecated MPI-2.2, removed MPI-3.0); various MPI-1 relics. A conforming MPI 5.0 implementation need not provide them.
- **Semantic changes & warnings**: documented behavioral differences between versions — places where the *same code* may behave differently under MPI 5.0 vs earlier.

## Key Concepts
- **Deprecated ≠ removed**: deprecated still compiles/runs (with possible warnings); removed is gone. Migrate deprecated proactively — it's the removal queue.
- **Use `use mpi_f08`** in Fortran: the modern, type-safe binding (typed handles `TYPE(MPI_Comm)` etc., proper `INTENT`); `mpif.h` and the old `mpi` module are legacy.
- **`MPI_Type_create_*`** is the modern derived-type API; the un-prefixed `MPI_Type_hvector`/etc. are deprecated.
- **No C++ bindings**: use the C API from C++ (every MPI implementation provides it).
- Cancelling sends is fragile and deprecated — design protocols that don't require it.

## Reference Tables
### Common deprecated → modern replacements
| Deprecated | Use instead |
|---|---|
| `MPI_Type_extent` | `MPI_Type_get_extent` |
| `MPI_Address` | `MPI_Get_address` |
| `MPI_Type_struct` | `MPI_Type_create_struct` |
| `MPI_Attr_get`/`_put` | `MPI_Comm_get_attr`/`_set_attr` |
| `MPI_Errhandler_set` | `MPI_Comm_set_errhandler` |
| `mpif.h` / `mpi` module | `use mpi_f08` |
| C++ bindings | C API (removed) |

## Anti-patterns
- **New code using `mpif.h` or the old `mpi` module**: use `use mpi_f08` for type safety and `INTENT` checking.
- **Using `MPI_Type_extent`/`MPI_Address`/`MPI_Type_struct`**: deprecated — use the `_get_extent`/`_create_*`/`Get_address` forms.
- **Seeking MPI C++ bindings**: removed; call the C API from C++.
- **Relying on `MPI_Cancel` for sends**: deprecated/fragile — restructure the protocol.
- **Assuming pre-5.0 behavior persists**: check the Semantic Changes list for behavioral deltas.

## Key Takeaways
1. Deprecated features still work but are the removal queue — migrate (caching API, `MPI_Type_extent`, `MPI_Address`, old errhandler API).
2. Fortran: use **`use mpi_f08`** (typed handles, `INTENT`); `mpif.h`/old `mpi` module are legacy.
3. **C++ bindings are removed** — use the C API from C++.
4. Cancelling sends is deprecated; design protocols that avoid it.
5. Consult the Semantic Changes list when porting code across MPI versions.

## Connects To
- **Ch 5**: modern `MPI_Type_create_*` vs deprecated constructors.
- **Ch 9**: modern error-handler API.
- **Ch 17**: language bindings — `mpi_f08` is the modern Fortran binding.
- **fortran-2023-standard**: `use mpi_f08` interoperates with modern Fortran (assumed-shape, `INTENT`).
