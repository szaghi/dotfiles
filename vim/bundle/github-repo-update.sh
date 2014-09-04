#!/bin/bash -
#===============================================================================
#
#          FILE: github-repo-update.sh
#
#         USAGE: ./github-repo-update.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (),
#  ORGANIZATION:
#       CREATED: 07/24/2014 14:54
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
for d in $(ls); do
  if [ -d $d ]; then
    cd $d
    if [ -d .git ]; then
      git pull
    fi
    cd ../
  fi
done

