whatis("OpenMPI 5.0.7 built with GCC 14.2.0 + HDF5 1.14.6")

help([[
OpenMPI 5.0.7 compiled with GCC 14.2.0
HDF5 1.14.6 compiled with GCC 14.2.0 is included.
Automatically loads gcc/15.1.0 if no compiler is active.
]])

depends_on("gcc/15.1.0")

local ompi = "/opt/openmpi/bin/5.0.7/gnu/14.2.0"
local hdf5 = "/opt/HDF5/bin/1.14.6/gnu/14.2.0"

if not isDir(ompi) then
  LmodError("OpenMPI 5.0.7/gnu14.2.0 not found at " .. ompi)
end

prepend_path("PATH",            pathJoin(ompi, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(ompi, "lib"))
prepend_path("LD_RUN_PATH",     pathJoin(ompi, "lib"))
prepend_path("MANPATH",         pathJoin(ompi, "share/man"))

if isDir(hdf5) then
  prepend_path("PATH",            pathJoin(hdf5, "bin"))
  prepend_path("LD_LIBRARY_PATH", pathJoin(hdf5, "lib"))
  prepend_path("LD_RUN_PATH",     pathJoin(hdf5, "lib"))
end

setenv("MPICC",   "mpicc")
setenv("MPICXX",  "mpicxx")
setenv("MPIFC",   "mpifort")
setenv("MPIF77",  "mpifort")
setenv("MPIF90",  "mpifort")
