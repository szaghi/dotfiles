whatis("NVIDIA HPC SDK 26")

help([[
NVIDIA HPC SDK 26 — installed at /opt/nvidia/hpc_sdk/Linux_x86_64/2026
Includes nvfortran, nvc, nvc++, and bundled OpenMPI.
Sets CC=nvc, CXX=nvc++, FC=nvfortran.

WSL2 development box — this module carries several MPI/UCX workarounds for a
GPU+MPI stack that is broken in places a real cluster is not. Each is correct
HERE and a performance regression (or meaningless) on real InfiniBand +
GPUDirect RDMA, so they must never be copied into a Slurm/cluster job script:
  * /usr/lib/wsl/lib on LD_LIBRARY_PATH      -> WSL GPU driver shim
  * UCX_MEMTYPE_CACHE=n                       -> WSL memtype detection unreliable
  * UCX_RNDV_THRESH=inf                       -> device-memory rendezvous aborts
                                                 in ucp_proto_rndv_send_start via
                                                 /dev/dxg (issue #12); force eager
  * UCX_TLS=^cma                              -> CMA same-node shmem broken on WSL
  * OMPI_MCA_coll_hcoll_enable=0              -> hcoll offload needs absent IB HW
]])

local root = "/opt/nvidia/hpc_sdk/Linux_x86_64/2026"

family("compiler")

if not isDir(root) then
  LmodError("NVIDIA HPC SDK 26 not found at " .. root)
end

setenv("NVHPC_ROOT", root)

prepend_path("PATH",            pathJoin(root, "compilers/bin"))
prepend_path("PATH",            pathJoin(root, "comm_libs/mpi/bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "compilers/lib"))
prepend_path("LD_LIBRARY_PATH", "/usr/lib/wsl/lib")
prepend_path("MANPATH",         pathJoin(root, "compilers/man"))

-- WSL2-only MPI/UCX workarounds (see help() above) — NOT for clusters.
-- Set as environment so the bare bundled mpirun picks them up; UCX_TLS and the
-- hcoll disable are duplicated onto the alias only because `-x` propagates them
-- to ranks launched on other hosts (irrelevant on this single box, kept for
-- parity with cluster-style invocation).
setenv("UCX_MEMTYPE_CACHE",          "n")    -- WSL memtype detection unreliable
setenv("UCX_RNDV_THRESH",            "inf")  -- issue #12: force eager, no device-mem rendezvous
setenv("UCX_TLS",                    "^cma") -- WSL CMA same-node shmem broken
setenv("OMPI_MCA_pml",               "ucx")  -- select UCX point-to-point layer
setenv("OMPI_MCA_coll_hcoll_enable", "0")    -- hcoll offload needs absent IB HW
set_alias("mpirun", "mpirun --mca pml ucx -x UCX_TLS=^cma -x OMPI_MCA_coll_hcoll_enable=0")

setenv("CC",  "nvc")
setenv("CXX", "nvc++")
setenv("FC",  "nvfortran")
setenv("F77", "nvfortran")
setenv("F90", "nvfortran")
