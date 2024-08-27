# openmpi-4.1.4-intel-2021.5.0.sh
#
# Description: openmpi 4.1.4 compiled with intel 2021.5.0 environment
#
source /opt/intel/oneapi/setvars.sh
OMPI=/opt/mpi/bin/openmpi/4.1.4/intel/2021.5.0/
PATH=$OMPI/bin:$PATH
LD_LIBRARY_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_RUN_PATH
MANPATH=$OMPI/share/man:$MANPATH
export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH
