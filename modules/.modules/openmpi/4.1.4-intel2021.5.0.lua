whatis("OpenMPI 4.1.4 built with Intel 2021.5.0")

help([[
OpenMPI 4.1.4 compiled with Intel oneAPI 2021.5.0
Automatically loads intel/oneapi if no compiler is active.
]])

depends_on("intel/oneapi")

local ompi = "/opt/mpi/bin/openmpi/4.1.4/intel/2021.5.0"

if not isDir(ompi) then
  LmodError("OpenMPI 4.1.4/intel2021.5.0 not found at " .. ompi)
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
