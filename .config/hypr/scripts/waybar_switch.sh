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
    echo "0" >"$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE")

NEXT_STATE=$(((CURRENT_STATE + 1) % ${#CONFIGS[@]}))

CONFIG_FILE="${CONFIGS[$NEXT_STATE]}"

FULL_CONFIG_PATH="$WAYBAR_CONFIG_DIR/$CONFIG_FILE"


if [ ! -f "$FULL_CONFIG_PATH" ]; then
    notify-send -u critical "Waybar HATA" "Config dosyası bulunamadı: $CONFIG_FILE"
    exit 1
fi

if [ ! -f "$WAYBAR_STYLE_FILE" ]; then
    notify-send -u critical "Waybar HATA" "Ana stil dosyası bulunamadı: style.css"
    exit 1
fi

pkill waybar

waybar -c "$FULL_CONFIG_PATH" -s "$WAYBAR_STYLE_FILE" &

echo "$NEXT_STATE" >"$STATE_FILE"

notify-send "$CONFIG_FILE yüklendi."