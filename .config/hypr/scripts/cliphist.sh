#!/bin/bash

selection=$(cliphist list | rofi -dmenu -i -theme "$HOME/.config/rofi/main")

if [ -n "$selection" ]; then
    echo "$selection" | cliphist decode | wl-copy
fi
