# nvidia-26.sh
#
# Description: nvidia SDK 26 environment
#
SDK=/opt/nvidia/hpc_sdk/Linux_x86_64/2026
export NVHPC_ROOT=$SDK
PATH=$SDK/compilers/bin:$SDK/comm_libs/mpi/bin:$PATH
LD_LIBRARY_PATH=$SDK/compilers/lib:$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH
MANPATH=$SDK/compilers/man:$MANPATH
export UCX_MEMTYPE_CACHE=n
alias mpirun='mpirun --mca pml ucx -x UCX_TLS=^cma --mca coll_hcoll_enable 0 -x OMPI_MCA_coll_hcoll_enable=0'
export PATH LD_LIBRARY_PATH MANPATH
