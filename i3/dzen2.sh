#!/bin/bash
HEIGHT=12
WIDTH=0
RESOLUTION=$(xrandr | grep " connected" | cut -d" " -f 3)
RESOLUTIONW=$(echo $RESOLUTION | cut -d"x" -f1)
RESOLUTIONH=$(echo $RESOLUTION | cut -d"x" -f2 | cut -d'+' -f 1)
X=$(($RESOLUTIONW-$WIDTH))
Y=$(($RESOLUTIONH-$HEIGHT-1))
