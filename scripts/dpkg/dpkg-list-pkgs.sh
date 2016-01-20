#!/bin/bash

if [ $# -eq 0 ] ; then

  sudo dpkg --get-selections

else

  sudo dpkg --get-selections > $1

fi

