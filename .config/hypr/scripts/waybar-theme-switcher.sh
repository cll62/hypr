#!/usr/bin/env bash

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$WAYBAR_DIR/.theme_state"

if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

pkill waybar

case "$STATE" in
    1)
        waybar -c "$WAYBAR_DIR/config.jsonc" -s "$WAYBAR_DIR/style.css" &
        echo "2" > "$STATE_FILE"
        ;;
    2)
        waybar -c "$WAYBAR_DIR/config2.jsonc" -s "$WAYBAR_DIR/style2.css" &
        echo "3" > "$STATE_FILE"
        ;;
    3)
        waybar -c "$WAYBAR_DIR/config3.jsonc" -s "$WAYBAR_DIR/style3.css" &
        echo "1" > "$STATE_FILE"
        ;;
    *)
        waybar -c "$WAYBAR_DIR/config.jsonc" -s "$WAYBAR_DIR/style.css" &
        echo "2" > "$STATE_FILE"
        ;;
esac
