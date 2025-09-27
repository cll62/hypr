#!/bin/bash

selection=$(cliphist list | rofi -dmenu -i -theme "$HOME/.config/rofi/launchers/type-1/style-2")

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
fi
