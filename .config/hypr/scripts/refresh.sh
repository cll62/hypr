#!/bin/bash


_ps=(
    swaync
    swayosd-server
)
for _prs in "${_ps[@]}"; do
    pkill -TERM "${_prs}" 2> /dev/null
done

sleep 0.1 

if command -v swayosd-server &> /dev/null; then
    swayosd-server &
fi

if command -v swaync &> /dev/null; then
    swaync &
fi


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

if pgrep -x "waybar" > /dev/null; then
    pkill -x "waybar"
else    

    if [ ! -f "$STATE_FILE" ]; then
        CURRENT_STATE=0
    else
        CURRENT_STATE=$(cat "$STATE_FILE")
    fi

    if [ "$CURRENT_STATE" -ge "${#CONFIGS[@]}" ] || [ "$CURRENT_STATE" -lt 0 ]; then
        CURRENT_STATE=0
    fi

    CONFIG_FILE="${CONFIGS[$CURRENT_STATE]}"
    FULL_CONFIG_PATH="$WAYBAR_CONFIG_DIR/$CONFIG_FILE"

    if [ ! -f "$FULL_CONFIG_PATH" ]; then
      notify-send -u critical "Yenileme HATA" "$CONFIG_FILE dosyası yok!"
      exit 1
    fi
    if [ ! -f "$WAYBAR_STYLE_FILE" ]; then
      notify-send -u critical "Yenileme HATA" "style.css dosyası yok!"
      exit 1
    fi
    
    waybar -c "$FULL_CONFIG_PATH" -s "$WAYBAR_STYLE_FILE" &
fi

sleep 1
hyprctl reload

exit 0