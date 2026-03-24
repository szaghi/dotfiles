whatis("OpenMPI 5.0.10 built with GCC 15.2.0")

help([[
OpenMPI 5.0.10 compiled with GCC 15.2.0
Automatically loads gcc/15.2.0 if no compiler is active.
]])

depends_on("gcc/15.2.0")

local ompi = "/opt/openmpi/bin/5.0.10/gnu/15.2.0"

if not isDir(ompi) then
  LmodError("OpenMPI 5.0.10/gnu15.2.0 not found at " .. ompi)
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
