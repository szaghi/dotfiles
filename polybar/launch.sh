#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Top Bar
polybar top &

is_second_monitor_connected=$(xrandr --query | grep 'HDMI-0')
if [[ $is_second_monitor_connected = *connected* ]]; then
   polybar top_left &
fi
