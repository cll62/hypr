#!/usr/bin/env bash

WAYBAR_CONFIG_DIR="$HOME/.config/waybar/configs"
WAYBAR_STYLE_FILE="$HOME/.config/waybar/style.css"
STATE_FILE="$WAYBAR_CONFIG_DIR/.theme_state"

CONFIGS=(
    "config1.jsonc"
    "config2.jsonc"
    "config3.jsonc"
    "config4.jsonc"
    "config5.jsonc"
    "config6.jsonc"
    "config7.jsonc"
    "config8.jsonc"
    "config9.jsonc"
    "config10.jsonc"
)

if [ ! -f "$STATE_FILE" ]; then
    CURRENT_STATE="0"
    echo "$CURRENT_STATE" > "$STATE_FILE"
else
    CURRENT_STATE=$(cat "$STATE_FILE")
fi

if [ "$CURRENT_STATE" -ge "${#CONFIGS[@]}" ] || [ "$CURRENT_STATE" -lt 0 ]; then
    CURRENT_STATE="0"
    echo "$CURRENT_STATE" > "$STATE_FILE"
fi

CONFIG_FILE="${CONFIGS[$CURRENT_STATE]}"
FULL_CONFIG_PATH="$WAYBAR_CONFIG_DIR/$CONFIG_FILE"

if [ ! -f "$FULL_CONFIG_PATH" ]; then
    notify-send -u critical "Waybar Başlatma HATA" "$CONFIG_FILE dosyası yok!"
    exit 1
fi

if [ ! -f "$WAYBAR_STYLE_FILE" ]; then
    notify-send -u critical "Waybar Başlatma HATA" "style.css dosyası yok!"
    exit 1
fi

pkill waybar

waybar -c "$FULL_CONFIG_PATH" -s "$WAYBAR_STYLE_FILE" &