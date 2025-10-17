#!/bin/bash

selection=$(cliphist list | rofi -dmenu -i -theme "$HOME/.config/rofi/cliphist" -p "Pano")

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
fi
