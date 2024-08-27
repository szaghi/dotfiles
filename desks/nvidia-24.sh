# nvidia-24.7.sh
#
# Description: nvidia SDK 24.7 environment
#

SDK=/opt/nvidia/hpc_sdk/Linux_x86_64/2024
PATH=$SDK/compilers/bin:$SDK/comm_libs/mpi/bin:$PATH
LD_LIBRARY_PATH=$SDK/compilers/lib:$LD_LIBRARY_PATH
MANPATH=$SDK/compilers/man:$MANPATH

export PATH LD_LIBRARY_PATH MANPATH
