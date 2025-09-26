#!/usr/bin/env bash

check() {
  command -v "$1" 1>/dev/null
}

check hyprpicker || {
  notify-send "Renk Seçici" "hyprpicker kurulu değil. Lütfen yükleyin."
  exit 1
}

killall -q hyprpicker

color=$(hyprpicker)

[ -z "$color" ] && exit 0

check wl-copy && {
  echo "$color" | sed 's/\n//g' | wl-copy
  notify-send "Renk Seçici" "Bu renk panoya kopyalandı: $color"
} || {
  notify-send "Renk Seçici" "Renk seçildi: $color" "wl-copy kurulu değil, renk panoya kopyalanamadı."
}