# intel.sh
#
# Description: Intel HPC environment
#

# oneapi
source /opt/intel/oneapi/setvars.sh

# zlib
ZLIB=/opt/zlib/bin/1.3/icx/20230622
LD_LIBRARY_PATH=$ZLIB/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$ZLIB/lib:$LD_RUN_PATH
MANPATH=$ZLIB/share:$MANPATH
PATH=$ZLIB/include:$PATH

# szip
SZIP=/opt/szip/bin/2.1.1/ifx/20230622/
LD_LIBRARY_PATH=$SZIP/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$SZIP/lib:$LD_RUN_PATH
PATH=$SZIP/include:$PATH

# HDF5
HDF5=/opt/HDF5/bin/1.14.2/intel/20230622
LD_LIBRARY_PATH=$HDF5/lib:$LD_LIBRARY_PATH
LD_RUN_PATH=$HDF5/lib:$LD_RUN_PATH
MANPATH=$HDF5/share:$MANPATH
PATH=$HDF5/include:$HDF5/bin:$PATH

export PATH LD_LIBRARY_PATH LD_RUN_PATH MANPATH
