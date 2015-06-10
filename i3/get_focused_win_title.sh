#!/bin/bash
win_id=`xdotool getactivewindow`
win_title=`xdotool getwindowname $win_id`
echo $win_title
