#!/bin/sh

function run_borg {
  # use borg for automated backup
  REPOSITORY=$1
  BACKUP=$2
  borg create --stats $REPOSITORY::`hostname`-`date +%Y-%m-%d-%T` $BACKUP
  borg prune -v $REPOSITORY --prefix `hostname`- --keep-daily=7 --keep-weekly=4 --keep-monthly=6
}

# home directories to backup
HBKS="/home/stefano/curriculum_vitae /home/stefano/dotfiles /home/stefano/downloads /home/stefano/fortran /home/stefano/github /home/stefano/insean /home/stefano/papers /home/stefano/python /home/stefano/reports /home/stefano/talks /home/stefano/tex"

# backup on nas-zaghi
run_borg /mnt/nas-zaghi/stefano/zaghi-backup/home/ $HBKS
run_borg /mnt/nas-zaghi/stefano/zaghi-backup/backup/ /backup/stefano/

# backup on nas-muscari
run_borg /mnt/nas-muscari/zaghi-backup/home/ $HBKS
