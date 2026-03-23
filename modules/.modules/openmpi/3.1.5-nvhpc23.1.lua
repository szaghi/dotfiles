whatis("OpenMPI 3.1.5 bundled with NVIDIA HPC SDK 23.1")

help([[
OpenMPI 3.1.5 from NVIDIA HPC SDK 23.1 bundle.
Automatically loads nvhpc/23.1.
]])

depends_on("nvhpc/23.1")

local sdk  = "/opt/nvidia/hpc_sdk-v12.0/Linux_x86_64/23.1"
local ompi = pathJoin(sdk, "comm_libs/openmpi/openmpi-3.1.5")

if not isDir(ompi) then
  LmodError("OpenMPI 3.1.5/nvhpc23.1 not found at " .. ompi)
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
