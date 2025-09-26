#!/bin/bash

selection=$(cliphist list | rofi -dmenu -i -theme "$HOME/.config/rofi/walkey.rasi")

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
fi
