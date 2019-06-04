#!/bin/bash
# File: mount_nas.sh
# Author: Stefano Zaghi <stefano.zaghi@gmail.com>
# Date: 29.08.2017
# Last Modified Date: 29.08.2017
# Last Modified By: Stefano Zaghi <stefano.zaghi@gmail.com>
#!/bin/bash
sudo mount -t nfs 192.168.3.101:/data/disk2/stefano /mnt/nas-muscari/
sudo mount -t nfs 192.168.2.24:/media/odroid/nas1/stefano /mnt/nas-odroid/
sudo mount -t nfs 192.168.2.23:/share/homes /mnt/nas-zaghi
