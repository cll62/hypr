#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"

# Wallpaper listesi
dmenu() {
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Hata: $WALLPAPER_DIR dizini bulunamadı!"
    exit 1
  fi
  find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

main() {
  choice=$(dmenu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style.css --show dmenu --prompt "Wallpaper Seç:" -n)
  if [ -z "$choice" ]; then
    echo "Hata: Duvar kâğıdı seçilmedi!"
    exit 1
  fi

  selected_wallpaper=$(echo "$choice" | sed 's/^img://')

  # Duvar kağıdını ayarla
  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
  cp "$selected_wallpaper" "$HOME/wallpapers/wall"

  # Matugen ile renk paletini oluştur
  matugen image -c "$MATUGEN_CONFIG" "$selected_wallpaper"

  # Waybar ve Hyprland renklerini yeniden yükle (post_hook zaten config.toml’de tanımlı)
  echo "Yeni renkler uygulandı."
}

main
