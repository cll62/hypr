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

THEME_NAMES=()
for i in "${!CONFIGS[@]}"; do
  THEME_NAMES+=("Config $((i + 1))")
done

SELECTED_NAME=$(printf '%s\n' "${THEME_NAMES[@]}" | rofi -dmenu -i -theme "$HOME/.config/rofi/launchers/type-1/style-2" -p "Waybar Temaları" -matching fuzzy -format 's' )

if [ -z "$SELECTED_NAME" ]; then
  exit 0
fi

for i in "${!THEME_NAMES[@]}"; do
  if [ "${THEME_NAMES[$i]}" == "$SELECTED_NAME" ]; then
    SELECTED_INDEX=$i
    break
  fi
done

CONFIG_FILE="${CONFIGS[$SELECTED_INDEX]}"
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

echo "$SELECTED_INDEX" >"$STATE_FILE"

notify-send " waybar $SELECTED_NAME yüklendi"
