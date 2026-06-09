# Chapter 18 (Annex A): Language Bindings Summary

## Core Idea
The consolidated **signature reference** — every MPI routine's C prototype and Fortran (`mpi_f08`, `mpi`, `mpif.h`) interface, plus all predefined constants, datatypes, and info keys, in one place. A lookup annex, not a concept chapter.

## Key Concepts (how to use it)
- **Find a signature fast**: Annex A lists C bindings (`A.3`), Fortran 2008 `mpi_f08` bindings (`A.4`), and legacy `mpi` bindings (`A.5`), grouped by chapter topic — go to the matching subsection (e.g. "Point-to-Point Communication C Bindings").
- **Predefined constants** (the values you pass): communicators (`MPI_COMM_WORLD`, `MPI_COMM_SELF`, `MPI_COMM_NULL`), wildcards (`MPI_ANY_SOURCE`, `MPI_ANY_TAG`, `MPI_PROC_NULL`), status (`MPI_STATUS_IGNORE`, `MPI_STATUSES_IGNORE`), null handles (`MPI_DATATYPE_NULL`, `MPI_REQUEST_NULL`, `MPI_OP_NULL`), error handlers (`MPI_ERRORS_ARE_FATAL`/`_RETURN`/`_ABORT`), `MPI_IN_PLACE`, `MPI_BOTTOM`, `MPI_INFO_NULL`.
- **Predefined datatypes**: C (`MPI_INT`, `MPI_DOUBLE`, `MPI_CHAR`, `MPI_BYTE`, `MPI_C_BOOL`, `MPI_AINT`, `MPI_COUNT`, `MPI_OFFSET`, complex types) and Fortran (`MPI_INTEGER`, `MPI_DOUBLE_PRECISION`, `MPI_REAL`, `MPI_LOGICAL`, `MPI_COMPLEX`, …); reduction ops (`MPI_SUM`/`MAX`/`MINLOC`/…).
- **Each routine appears in base and `_c` (large-count) form** — the annex shows both signatures.
- **Sizes/limits constants**: `MPI_MAX_PROCESSOR_NAME`, `MPI_MAX_ERROR_STRING`, `MPI_MAX_INFO_KEY`/`_VAL`, `MPI_MAX_OBJECT_NAME`, `MPI_MAX_PORT_NAME`.

## Mental Models
- **Annex A answers "what's the exact signature / argument order / constant name"** — pair it with the conceptual chapter (ch3–17) that explains *when/why*. The chapter gives semantics; the annex gives the prototype.
- **Pick the binding column for your language**: C, `mpi_f08` (preferred Fortran), or legacy — read the row in the right subsection.

## Anti-patterns
- **Guessing argument order/constant names from memory**: MPI has hundreds of routines with similar signatures (e.g. `MPI_Gather` vs `MPI_Gatherv` argument lists differ) — look up the exact prototype here.
- **Using a C constant name in Fortran or vice versa**: the annex shows the per-language spelling.
- **Mixing base and `_c` signatures**: match the count-argument type (`int` vs `MPI_Count`).

## Key Takeaways
1. Annex A is the **signature + constant reference**; use it alongside the conceptual chapter for semantics.
2. C, `mpi_f08`, and legacy Fortran bindings are listed per topic; pick your language's column.
3. The high-frequency constants (`MPI_COMM_WORLD`, `MPI_ANY_SOURCE`, `MPI_STATUS_IGNORE`, `MPI_IN_PLACE`, `MPI_INFO_NULL`, error handlers) and predefined datatypes/ops live here.
4. Every routine has base + `_c` (large-count) signatures.
5. Don't recall signatures from memory — verify argument order/constant spelling against the annex.

## Connects To
- **All chapters**: this is the signature index for every routine they describe.
- **Ch 17**: the binding conventions these signatures follow.
- **Ch 2**: the predefined constants/handles cataloged here.
