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
BORG_NAS_ZAGHI="${BORG_NAS_ZAGHI:-/mnt/nas-zaghi/stefano/zaghi-backup/home/}"
run_borg "$BORG_NAS_ZAGHI" /home/stefano
#BORG_NAS_ZAGHI_BACKUP="${BORG_NAS_ZAGHI_BACKUP:-/mnt/nas-zaghi/stefano/zaghi-backup/backup/}"
#run_borg "$BORG_NAS_ZAGHI_BACKUP" /backup/stefano/

# backup on nas-odroid
BORG_NAS_ODROID="${BORG_NAS_ODROID:-/mnt/nas-odroid/zaghi-backup/home/fortran/}"
run_borg "$BORG_NAS_ODROID" /home/stefano/fortran

# backup on nas-muscari
# BORG_NAS_MUSCARI="${BORG_NAS_MUSCARI:-/mnt/nas-muscari/zaghi-backup/home/}"
# run_borg "$BORG_NAS_MUSCARI" /home/stefano

exit 0
