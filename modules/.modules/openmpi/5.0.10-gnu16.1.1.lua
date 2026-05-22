whatis("OpenMPI 5.0.10 built with GCC 16.1.1")

help([[
OpenMPI 5.0.10 compiled with system GCC 16.1.1 (/usr/bin).
No module compiler dependency: the build uses the system gcc/g++/gfortran.
Host-specific: this build exists only on 'quark'.
]])

-- Host guard: this build is local to quark only.
local host = capture("hostname -s"):gsub("%s+$", "")
if host ~= "quark" then
  LmodError("openmpi/5.0.10-gnu16.1.1 is specific to host 'quark' (current host: " .. host .. ")")
end

local ompi = "/opt/openmpi/5.0.10/gnu/16.1.1"

if not isDir(ompi) then
  LmodError("OpenMPI 5.0.10/gnu16.1.1 not found at " .. ompi)
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
