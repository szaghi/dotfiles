#!/bin/bash -
set -o nounset
if [ $# -ne 2 ] ; then
  echo "`basename $0`"
  echo "Usage:"
  echo "  `basename $0` main-pkgs-list local-pkgs-list"
  exit 1
elif [ $# -eq 2 ] ; then
  pacman -Qqe | grep -vx "$(pacman -Qqg base)" | grep -vx "$(pacman -Qqm)" > $1
  pacman -Qqm > $2
fi
exit 2
