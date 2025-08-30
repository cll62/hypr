#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers/walls"

dmenu() {
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Hata: $WALLPAPER_DIR dizini bulunamadı!"
    exit 1
  fi
  find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

main() {
  choice=$(dmenu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Wallpaper Seç:" -n)
  if [ -z "$choice" ]; then
    echo "Hata: Duvar kâğıdı seçilmedi!"
    exit 1
  fi

  selected_wallpaper=$(echo "$choice" | sed 's/^img://')
  swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
  wal -i "$selected_wallpaper" --cols16
  swaync-client --reload-css
  # SwayOSD yenileme
  if pgrep swayosd-server >/dev/null; then
    if ! pkill -USR1 swayosd-server 2>/dev/null; then
      pkill swayosd-server 2>/dev/null
      swayosd-server &
    fi
  else
    swayosd-server &
  fi
  
  cat ~/.cache/wal/colors-kitty.conf >~/.config/kitty/current-theme.conf
  cp ~/.cache/wal/colors-hyprland ~/.config/hypr/colors.conf

  color1=$(awk 'match($0, /color2=\47(.*)\47/,a) { print a[1] }' ~/.cache/wal/colors.sh)
  color2=$(awk 'match($0, /color3=\47(.*)\47/,a) { print a[1] }' ~/.cache/wal/colors.sh)
  cava_config="$HOME/.config/cava/config"
  if [ -f "$cava_config" ]; then
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color1'/" "$cava_config"
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color2'/" "$cava_config"
    if pgrep cava >/dev/null; then
      pkill -USR2 cava 2>/dev/null
    fi
  fi

  source ~/.cache/wal/colors.sh && cp "$selected_wallpaper" ~/wallpapers/pywallpaper.jpg
}

main