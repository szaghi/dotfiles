#!/bin/bash

if [ "$1" = "-lic"  ] ; then
  /data2/stefano/ansys/shared_files/licensing/linx64/lmgrd -l /home/stefano/.Trash/icemcfd14.log -c /data2/stefano/ansys/shared_files/licensing/license.dat
  sudo /data2/stefano/ansys/shared_files/licensing/start_ansysli
else
  /data2/stefano/ansys/v140/icemcfd/linux64_amd/bin/icemcfd
fi
