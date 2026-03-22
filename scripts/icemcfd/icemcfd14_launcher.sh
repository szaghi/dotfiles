#!/bin/bash

ANSYS_ROOT="${ANSYS_ROOT:-/data2/stefano/ansys}"

if [ "$1" = "-lic"  ] ; then
  "$ANSYS_ROOT/shared_files/licensing/linx64/lmgrd" -l /home/stefano/.Trash/icemcfd14.log -c "$ANSYS_ROOT/shared_files/licensing/license.dat"
  sudo "$ANSYS_ROOT/shared_files/licensing/start_ansysli"
else
  "$ANSYS_ROOT/v140/icemcfd/linux64_amd/bin/icemcfd"
fi
