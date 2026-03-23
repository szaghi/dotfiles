whatis("NVIDIA HPC SDK 24.11")

help([[
NVIDIA HPC SDK 24.11 — installed at /opt/nvidia/hpc_sdk/Linux_x86_64/24.11
Includes nvfortran, nvc, nvc++, and bundled OpenMPI.
Sets CC=nvc, CXX=nvc++, FC=nvfortran.
WSL2: adds /usr/lib/wsl/lib to LD_LIBRARY_PATH for GPU access.
UCX_MEMTYPE_CACHE=n is set to avoid UCX/CUDA memory detection issues.
mpirun is aliased with UCX flags tuned for this setup.
]])

local root = "/opt/nvidia/hpc_sdk/Linux_x86_64/24.11"

family("compiler")

if not isDir(root) then
  LmodError("NVIDIA HPC SDK 24.11 not found at " .. root)
end

setenv("NVHPC_ROOT", root)

prepend_path("PATH",            pathJoin(root, "compilers/bin"))
prepend_path("PATH",            pathJoin(root, "comm_libs/mpi/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "compilers/lib"))
prepend_path("LD_LIBRARY_PATH", "/usr/lib/wsl/lib")
prepend_path("MANPATH",         pathJoin(root, "compilers/man"))

setenv("UCX_MEMTYPE_CACHE", "n")
set_alias("mpirun",
  "mpirun --mca pml ucx -x UCX_TLS=^cma --mca coll_hcoll_enable 0 -x OMPI_MCA_coll_hcoll_enable=0")

setenv("CC",  "nvc")
setenv("CXX", "nvc++")
setenv("FC",  "nvfortran")
setenv("F77", "nvfortran")
setenv("F90", "nvfortran")
