whatis("OpenMPI 3.1.5 bundled with NVIDIA HPC SDK 22.3")

depends_on("nvhpc/22.3")

local sdk  = "/opt/nvidia/hpc_sdk/Linux_x86_64/22.3"
local ompi = pathJoin(sdk, "comm_libs/openmpi/openmpi-3.1.5")

if not isDir(ompi) then
  LmodError("OpenMPI 3.1.5/nvhpc22.3 not found at " .. ompi)
end

prepend_path("PATH",            pathJoin(ompi, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(ompi, "lib"))
prepend_path("LD_RUN_PATH",     pathJoin(ompi, "lib"))
prepend_path("MANPATH",         pathJoin(ompi, "share/man"))

setenv("MPICC",  "mpicc")
setenv("MPICXX", "mpicxx")
setenv("MPIFC",  "mpifort")
