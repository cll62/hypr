#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"

WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | shuf -n 1)

if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon &
  sleep 1
fi

if [ -n "$WALLPAPER" ]; then
  swww img "$WALLPAPER" --transition-fps 255 --transition-type outer --transition-duration 0.8

else
  echo "No wallpapers found in $WALLPAPER_DIR"
fi

 swww img "$WALLPAPER" --transition-type any --transition-fps 60 --transition-duration .5
 cp "$WALLPAPER" "$HOME/wallpapers/wall"
 matugen image -c "$MATUGEN_CONFIG" "$WALLPAPER"
 
