#!/bin/bash

ICON_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications/"

if [ "$#" -eq 0 ]; then
  while IFS= read -r -d '' file; do
    if grep -q '^Exec=.*webapp-launch.*' "$file"; then
      WEB_APPS+=("$(basename "${file%.desktop}")")
    fi
  done < <(find "$DESKTOP_DIR" -name '*.desktop' -print0)

  if ((${#WEB_APPS[@]})); then
    IFS=$'\n' SORTED_WEB_APPS=($(sort <<<"${WEB_APPS[*]}"))
    unset IFS
    APP_NAMES_STRING=$(gum choose --no-limit --header "Kaldırılacak web uygulamasını seçin..." --selected-prefix="✗ " "${SORTED_WEB_APPS[@]}")
    APP_NAMES=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && APP_NAMES+=("$line")
    done <<< "$APP_NAMES_STRING"
  else
    echo "Kaldırılacak web uygulaması bulunamadı."
    exit 1
  fi
else
  APP_NAMES=("$@")
fi

if [[ ${#APP_NAMES[@]} -eq 0 ]]; then
  echo "Web uygulaması adları belirtilmelidir."
  exit 1
fi

for APP_NAME in "${APP_NAMES[@]}"; do
  rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
  rm -f "$ICON_DIR/$APP_NAME.png"
  echo "$APP_NAME kaldırıldı"
  ./show-done.sh
done