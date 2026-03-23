# openmpi-5.0.7-gnu-14.2.0.sh
#
# Description: openmpi 5.0.7 compiled with gnu 14.2.0 environment
#
OMPI=/opt/openmpi/bin/5.0.7/gnu/14.2.0
PATH=$OMPI/bin:$PATH
LD_LIBRARY_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$OMPI/lib/openmpi:$OMPI/lib:$LD_RUN_PATH
MANPATH=$OMPI/share/man:$MANPATH
#HDF5
HDF5=/opt/HDF5/bin/1.14.6/gnu/14.2.0/
PATH=$HDF5/bin:$PATH
LD_LIBRARY_PATH=$HDF5/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$HDF5/lib:$LD_LIBRARY_PATH
export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH
