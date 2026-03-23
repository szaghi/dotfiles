# openmpi-3.1.5-nvidia-23.1.sh
#
# Description: openmpi 3.1.5 compiled with nvidia 23.1 environment
#

# openmpi
OMPI=/opt/nvidia/hpc_sdk-v12.0/Linux_x86_64/23.1/comm_libs/openmpi/openmpi-3.1.5
PATH=$OMPI/bin:$PATH
LD_LIBRARY_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_RUN_PATH
MANPATH=$OMPI/share/man:$MANPATH

# nvf
NVF=/opt/nvidia/hpc_sdk-v12.0/Linux_x86_64/23.1/compilers
PATH=$NVF/bin:$PATH
LD_LIBRARY_PATH=$NVF/lib:$LD_LIBRARY_PATH

export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH
