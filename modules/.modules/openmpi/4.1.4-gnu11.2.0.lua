whatis("OpenMPI 4.1.4 built with GCC 11.2.0")

help([[
OpenMPI 4.1.4 compiled with GCC 11.2.0
]])

depends_on("gcc/15.1.0")

local ompi = "/opt/mpi/bin/openmpi/4.1.4/gnu/11.2.0"

if not isDir(ompi) then
  LmodError("OpenMPI 4.1.4/gnu11.2.0 not found at " .. ompi)
end

prepend_path("PATH",            pathJoin(ompi, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(ompi, "lib"))
prepend_path("LD_RUN_PATH",     pathJoin(ompi, "lib"))
prepend_path("MANPATH",         pathJoin(ompi, "share/man"))

setenv("MPICC",  "mpicc")
setenv("MPICXX", "mpicxx")
setenv("MPIFC",  "mpifort")
setenv("MPIF77", "mpifort")
setenv("MPIF90", "mpifort")
