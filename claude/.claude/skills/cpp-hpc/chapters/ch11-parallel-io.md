# Chapter 11: Parallel File Systems & Parallel I/O — HDF5, NetCDF, VTK

## Core Idea
At scale, naive I/O (every rank writing its own file, or one rank gathering everything) does not work — it overwhelms the filesystem or serializes. The solution is **self-describing, parallel-aware formats** (HDF5, NetCDF) that let many ranks write one coherent file collectively, plus **visualization formats** (VTK) to inspect the results.

## Frameworks Introduced

- **HDF5** (Hierarchical Data Format): a self-describing binary container.
  - Structure: a file is a tree of **groups** (like directories) holding **datasets** (typed N-dimensional arrays). Each dataset has a **dataspace** (its shape) and attached **metadata** (attributes).
  - **Parallel HDF5** (built on MPI-IO): all ranks open the file collectively and each writes its slab of a shared dataset — **hyperslab selection** maps each rank's local data to its region of the global array. **Chunking** stores the dataset in blocks for partial I/O and compression.

- **NetCDF** (Network Common Data Form): self-describing array data for scientific/climate data; modern NetCDF-4 is layered on HDF5, adding a dimension/variable model convenient for structured grids and time series. Also supports parallel I/O.

- **VTK** (Visualization Toolkit): formats + library for scientific visualization. Write simulation output as VTK datasets (structured/unstructured grids, point/cell data) for **ParaView**/**VisIt**; **XDMF** pairs lightweight XML metadata with HDF5 heavy data for large parallel datasets.

## Key Concepts
- **Self-describing**: the file carries its own schema (types, shapes, names, units) — readable years later without external documentation, and portable across machines/endianness.
- **Collective parallel I/O**: ranks coordinate so the filesystem sees a few large, aligned writes instead of thousands of small ones — the difference between scalable and unusable.
- **Hyperslab / slab selection**: each rank describes its sub-region of the global array; the library + MPI-IO assemble one coherent file.
- **Chunking + compression**: storing a dataset in chunks enables reading sub-regions, parallel writes, and transparent compression.
- **The I/O bottleneck**: at extreme scale, I/O (not compute) often dominates; minimize output frequency, write collectively, and use parallel filesystems (Lustre/GPFS) with proper striping.

## Mental Models
- **Never write one-file-per-rank at scale** — it creates millions of files that cripple the metadata server; write one shared file collectively with parallel HDF5/NetCDF.
- **Use a self-describing format, not raw binary** — HDF5/NetCDF carry schema and survive machine/endianness changes; raw dumps are unportable and undocumented.
- **Separate light metadata from heavy data** — XDMF (XML) + HDF5 lets visualization tools read structure cheaply and stream the bulk arrays.
- **I/O is a first-class performance concern at scale** — profile it; reduce write frequency; tune filesystem striping.

## Code Examples
```cpp
// Parallel HDF5: all ranks write their slab of a shared dataset (sketch)
hid_t fapl = H5Pcreate(H5P_FILE_ACCESS);
H5Pset_fapl_mpio(fapl, MPI_COMM_WORLD, MPI_INFO_NULL);          // MPI-IO driver
hid_t file = H5Fcreate("out.h5", H5F_ACC_TRUNC, H5P_DEFAULT, fapl);

hid_t filespace = H5Screate_simple(2, global_dims, nullptr);    // global array shape
hid_t dset = H5Dcreate(file, "field", H5T_NATIVE_DOUBLE, filespace,
                       H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

// each rank selects its hyperslab of the global array
H5Sselect_hyperslab(filespace, H5S_SELECT_SET, offset, nullptr, local_dims, nullptr);
hid_t memspace = H5Screate_simple(2, local_dims, nullptr);
hid_t xfer = H5Pcreate(H5P_DATASET_XFER);
H5Pset_dxpl_mpio(xfer, H5FD_MPIO_COLLECTIVE);                   // collective write
H5Dwrite(dset, H5T_NATIVE_DOUBLE, memspace, filespace, xfer, local_data);
```
- **What it demonstrates**: collective parallel-HDF5 writing where each rank writes its hyperslab of one shared dataset.

## Reference Tables

| Format | Role | Built on |
|---|---|---|
| HDF5 | hierarchical self-describing data | MPI-IO (parallel) |
| NetCDF-4 | array/dimension model | HDF5 |
| VTK | visualization datasets | — (ParaView/VisIt) |
| XDMF | light metadata + heavy HDF5 | XML + HDF5 |

| At scale, avoid | Do instead |
|---|---|
| one file per rank | one shared file, collective I/O |
| raw binary dumps | self-describing HDF5/NetCDF |
| frequent full dumps | checkpoint sparingly, compress |

## Key Takeaways
1. Use self-describing parallel formats (HDF5, NetCDF-4-on-HDF5) — never one-file-per-rank or raw binary at scale.
2. Parallel HDF5 (over MPI-IO) lets all ranks write their hyperslab of one shared dataset collectively.
3. Chunking enables partial I/O, parallel writes, and compression; XDMF separates light metadata from heavy HDF5 data.
4. Write VTK datasets for ParaView/VisIt visualization.
5. I/O is a first-class performance concern at extreme scale — write collectively, reduce frequency, tune the parallel filesystem.

## Connects To
- **Ch 07 (Advanced MPI)**: MPI-IO underlies parallel HDF5.
- **Ch 01 (Toolchain)**: linking HDF5/NetCDF via CMake `find_package`/Spack.
- **Ch 13 (Numerical libraries)**: PETSc/Trilinos integrate with HDF5 for checkpointing.
