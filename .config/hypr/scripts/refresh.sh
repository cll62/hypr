#!/bin/bash

ref=(
    swaync
    swayosd-server
    waybar
)

for prg in "${ref[@]}"; do
    pkill -TERM "${prg}" 2> /dev/null
done

sleep 0.5 

for prg in "${ref[@]}"; do
    if command -v "${prg}" &> /dev/null; then
        "${prg}" &
    fi
done

sleep 1 

hyprctl reload

exit 0