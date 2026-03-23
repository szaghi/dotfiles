whatis("OpenMPI 3.1.5 bundled with NVIDIA HPC SDK 20.7")

depends_on("nvhpc/20.7")

local ompi = "/opt/nvidia/hpc_sdk/Linux_x86_64/20.7/comm_libs/openmpi/openmpi-3.1.5"

if not isDir(ompi) then
  LmodError("OpenMPI 3.1.5/nvhpc20.7 not found at " .. ompi)
end

prepend_path("PATH",            pathJoin(ompi, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(ompi, "lib"))
prepend_path("LD_RUN_PATH",     pathJoin(ompi, "lib"))
prepend_path("MANPATH",         pathJoin(ompi, "share/man"))

setenv("MPICC",  "mpicc")
setenv("MPICXX", "mpicxx")
setenv("MPIFC",  "mpifort")
