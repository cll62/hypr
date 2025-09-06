#!/bin/bash

options="󰌾 kilit\n󰍃 çıkış\n󰜉 yeniden başlat\n󰐥 kapat"
choice="$(echo -e "$options" | wofi -dmenu)"
case $choice in
"󰌾 kilit")
  hyprlock
  ;;
"󰍃 çıkış")
  hyprctl dispatch exit
  ;;
"󰜉 yeniden başlat")
  systemctl reboot
  ;;
"󰐥 kapat")
  systemctl poweroff
  ;;
*) ;;
esac
