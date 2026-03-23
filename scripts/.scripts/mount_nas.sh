#!/bin/bash
# File: mount_nas.sh
# Author: Stefano Zaghi <stefano.zaghi@gmail.com>
# Date: 29.08.2017
# Last Modified Date: 21.06.2024
# Last Modified By: Stefano Zaghi <stefano.zaghi@gmail.com>
#!/bin/bash
# sudo mount -t nfs "${NAS_ODROID_IP:-192.168.2.24}:/media/odroid/nas1/stefano" /mnt/nas-odroid/
NAS_ODROID_IP="${NAS_ODROID_IP:-192.168.1.16}"
sudo mount -t nfs -o vers=3 "${NAS_ODROID_IP}:/share/homes" /media/stefano/zaghi-nas
