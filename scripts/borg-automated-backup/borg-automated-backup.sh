#!/bin/bash
# File: .scripts/borg-automated-backup.sh
# Author: Stefano Zaghi <stefano.zaghi@gmail.com>
# Date: 07.07.2017
# Last Modified Date: 04.09.2017
# Last Modified By: Stefano Zaghi <stefano.zaghi@gmail.com>
#!/bin/sh

function run_borg {
  # use borg for automated backup
  REPOSITORY=$1
  BACKUP=$2
  borg create --stats $REPOSITORY::`hostname`-`date +%Y-%m-%d-%T` $BACKUP
  borg prune -v $REPOSITORY --prefix `hostname`- --keep-daily=7 --keep-weekly=4 --keep-monthly=6
}

# backup on nas-zaghi
run_borg /mnt/nas-zaghi/stefano/zaghi-backup/home/ /home/stefano
#run_borg /mnt/nas-zaghi/stefano/zaghi-backup/backup/ /backup/stefano/

# backup on nas-odroid
run_borg /mnt/nas-odroid/zaghi-backup/home/fortran/ /home/stefano/fortran

# backup on nas-muscari
# run_borg /mnt/nas-muscari/zaghi-backup/home/ /home/stefano

exit 0
