# Chapter 5: Datatypes

## Core Idea
**Derived datatypes** describe non-contiguous, structured memory layouts so MPI can send/receive them in one call without manual packing — the key to communicating array sections, struct arrays, and halo regions efficiently.

## Frameworks Introduced
- **Derived datatype constructors**:
  - **`MPI_Type_contiguous(count, old)`**: count copies, contiguous.
  - **`MPI_Type_vector(count, blocklen, stride, old)`**: equally-spaced blocks (e.g. a column of a row-major matrix, a strided halo face). `MPI_Type_create_hvector` for byte strides.
  - **`MPI_Type_indexed(count, blocklens[], displs[], old)`**: irregular blocks/displacements; `MPI_Type_create_hindexed` (bytes), `MPI_Type_create_indexed_block` (uniform block size).
  - **`MPI_Type_create_struct(count, blocklens[], displs[], types[])`**: heterogeneous — different types per block (a C struct / Fortran derived type).
  - **`MPI_Type_create_subarray(ndims, sizes[], subsizes[], starts[], order, old)`**: an n-D subarray of a larger array (the natural halo/tile descriptor).
  - **`MPI_Type_create_resized(old, lb, extent)`**: adjust lower bound/extent (for correct strided packing of struct arrays).
- **`MPI_Type_commit(&type)`** before use; **`MPI_Type_free(&type)`** after. Constructed types must be committed.
- **Type signature & matching**: the *sequence of basic types* on send must match the receive (the map/displacements need not).
- **Pack/Unpack** (`MPI_Pack`/`MPI_Unpack` with `MPI_PACKED`): manual serialization into a contiguous buffer — fallback when a derived type is awkward, or for incremental message assembly.

## Key Concepts
- **extent vs size**: *size* = bytes of actual data; *extent* = span from lower to upper bound (includes gaps). Strided/struct types often need `MPI_Type_create_resized` so an array of them packs correctly.
- **count is in elements** of the datatype, not bytes.
- **`MPI_Get_address`** for portable displacement computation in struct types (don't hand-compute offsets).
- **`MPI_BOTTOM`** + absolute addresses: send scattered data referenced by absolute address (with `MPI_Get_address` displacements).
- **Predefined types**: `MPI_INT`, `MPI_DOUBLE`, `MPI_CHAR`, `MPI_BYTE` (untyped), `MPI_DOUBLE_PRECISION`/`MPI_INTEGER` (Fortran), `MPI_AINT`/`MPI_COUNT`/`MPI_OFFSET`.

## Code Examples
```c
// Halo face of a 3D array: a 2D subarray descriptor
int sizes[3]    = {NX, NY, NZ};
int subsizes[3] = {1, NY, NZ};          // a YZ face (one X-slice)
int starts[3]   = {1, 0, 0};            // first interior slice
MPI_Datatype face;
MPI_Type_create_subarray(3, sizes, subsizes, starts, MPI_ORDER_C, MPI_DOUBLE, &face);
MPI_Type_commit(&face);
MPI_Sendrecv(grid, 1, face, left,  0,
             grid, 1, face, right, 0, comm, MPI_STATUS_IGNORE);
MPI_Type_free(&face);
```
- **Demonstrates**: a `subarray` type describing a halo face, sent in one `MPI_Sendrecv` with no manual packing — the canonical stencil-halo idiom.

## Anti-patterns
- **Manual pack loops where a derived type fits**: a `vector`/`subarray` type lets MPI (and the hardware) handle strided access — faster and clearer than a hand copy.
- **Forgetting `MPI_Type_commit`**: using an uncommitted derived type is erroneous.
- **Hand-computing struct displacements**: use `MPI_Get_address`; padding/alignment differ across compilers.
- **Wrong extent on struct/strided arrays**: an array of a derived type packs wrong without `MPI_Type_create_resized` — off-by-stride corruption.
- **`MPI_BYTE` for typed data across heterogeneous systems**: skips type conversion — only for raw bytes.
- **Leaking derived types**: `MPI_Type_free` what you commit.

## Key Takeaways
1. Derived types (`vector`/`indexed`/`struct`/`subarray`) send structured/non-contiguous memory in one call — no manual packing.
2. `MPI_Type_create_subarray` is the natural halo/tile descriptor for stencil codes.
3. Always `MPI_Type_commit` before use, `MPI_Type_free` after; count is in elements.
4. Mind **extent vs size**: resize struct/strided types (`MPI_Type_create_resized`) for correct array packing; use `MPI_Get_address` for displacements.
5. Type *signatures* must match on send/recv; `MPI_Pack`/`MPI_Unpack` is the manual fallback.

## Connects To
- **Ch 3**: derived types are the `datatype` argument to send/recv.
- **Ch 6**: collectives over derived types.
- **Ch 14**: file views in MPI-IO are built from derived types (subarray for distributed arrays).
- **Ch 12**: RMA transfers typed via datatypes.
