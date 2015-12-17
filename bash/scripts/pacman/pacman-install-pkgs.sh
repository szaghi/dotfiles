#!/bin/bash -
set -o nounset
if [ $# -ne 2 ] ; then
  echo "`basename $0`"
  echo "Usage:"
  echo "  `basename $0` main-pkgs-list local-pkgs-list"
  exit 1
elif [ $# -eq 2 ] ; then
  sudo pacman -S --needed $(cat $1)
  yaourt --noconfirm -S $(cat $2 | grep -vx "$(pacman -Qqm)")
fi
exit 2
