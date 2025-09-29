#!/bin/bash

DUVAR_KAGIDI_DIZINI="$HOME/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
SABIT_DUVAR_KAGIDI="$HOME/wallpapers/current_wallpaper.png"
BRAVE_ARKA_PLAN_DIZINI="$HOME/.config/BraveSoftware/Brave-Browser/Default/sanitized_background_images"
BRAVE_ARKA_PLAN_DOSYA="$BRAVE_ARKA_PLAN_DIZINI/current_wallpaper.png"


WALLPAPER=$(find "$DUVAR_KAGIDI_DIZINI" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | shuf -n 1)

if [ -n "$WALLPAPER" ]; then
  
  swww img "$WALLPAPER" --transition-type outer --transition-fps 60 --transition-duration .5
  
  cp "$WALLPAPER" "$SABIT_DUVAR_KAGIDI"

  mkdir -p "$BRAVE_ARKA_PLAN_DIZINI" || { echo "Hata: Brave dizini oluşturulamadı!" >&2; exit 1; }
  cp "$SABIT_DUVAR_KAGIDI" "$BRAVE_ARKA_PLAN_DOSYA"

  matugen image -c "$MATUGEN_CONFIG" "$WALLPAPER"
fi