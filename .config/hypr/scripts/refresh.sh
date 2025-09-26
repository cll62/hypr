#!/bin/bash

if pgrep -x "waybar" > /dev/null; then
    pkill -x "waybar"
    pkill -x "swaync"
else
    waybar &
    swaync &
fi
