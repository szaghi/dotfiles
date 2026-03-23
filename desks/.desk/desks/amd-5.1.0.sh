# amd-5.1.0.sh
#
# Description: amd SDK 5.1.0 environment
#

SDK=/opt/amd/rocm-afar-6711-drop-5.1.0
PATH=$SDK/bin:$PATH
LD_LIBRARY_PATH=$SDK/lib:$LD_LIBRARY_PATH
MANPATH=$SDK/share/man:$MANPATH

export PATH LD_LIBRARY_PATH MANPATH
