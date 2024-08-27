# openmpi-3.1.5-nvidia-20.7.sh
#
# Description: openmpi 3.1.5 compiled with nvidia 20.7 environment
#
OMPI=/opt/nvidia/hpc_sdk/Linux_x86_64/20.7/comm_libs/openmpi/openmpi-3.1.5
PATH=$OMPI/bin:$PATH
LD_LIBRARY_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_RUN_PATH
MANPATH=$OMPI/share/man:$MANPATH
export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH
