#!/bin/bash

if [ "$#" -lt 3 ]; then
  echo -e "\e[32mYeni bir web uygulaması oluşturalım! Uygulama başlatıcısından (app launcher) erişebilirsin.\n\e[0m"
  if ! command -v gum &> /dev/null; then
    echo "Hata: 'gum' yüklü değil. Lütfen önce yükleyin:"
    echo "  yay -S gum"
    read -p "Devam etmek için Enter tuşuna basın..."
    exit 1
  fi

  APP_NAME=$(gum input --prompt "Uygulama Adı> " --placeholder "Favori web uygulamam")
  APP_URL=$(gum input --prompt "URL> " --placeholder "https://ornek.com")
  ICON_REF=$(gum input --prompt "Simge URL'si> " --placeholder "https://dashboardicons.com adresini ziyaret edin (PNG olmalı!)")
  CUSTOM_EXEC=""
  MIME_TYPES=""
  INTERACTIVE_MODE=true
else
  APP_NAME="$1"
  APP_URL="$2"
  ICON_REF="$3"
  CUSTOM_EXEC="$4"
  MIME_TYPES="$5"
  INTERACTIVE_MODE=false
fi

echo "HATA AYIKLAMA: APP_NAME='$APP_NAME'"
echo "HATA AYIKLAMA: APP_URL='$APP_URL'"
echo "HATA AYIKLAMA: ICON_REF='$ICON_REF'"

if [[ -z "$APP_NAME" || -z "$APP_URL" || -z "$ICON_REF" ]]; then
  echo "Uygulama adı, URL ve simge URL'si belirtilmelidir!"
  read -p "Devam etmek için Enter tuşuna basın..."
  exit 1
fi

ICON_DIR="$HOME/.local/share/icons"
if [[ $ICON_REF =~ ^https?:// ]]; then
  ICON_PATH="$ICON_DIR/$APP_NAME.png"
  if curl -sL -o "$ICON_PATH" "$ICON_REF"; then
    ICON_PATH="$ICON_DIR/$APP_NAME.png"
  else
    echo "Hata: Simge indirilemedi."
    exit 1
  fi
else
  ICON_PATH="$ICON_DIR/$ICON_REF"
fi

if [[ -n $CUSTOM_EXEC ]]; then
  EXEC_COMMAND="$CUSTOM_EXEC"
else
  EXEC_COMMAND="$HOME/.config/hypr/scripts/webapp-launch.sh \"$APP_URL\""
fi

DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=$APP_NAME
Exec=$EXEC_COMMAND
Terminal=false
Type=Application
Icon=$ICON_PATH
StartupNotify=true
EOF

if [[ -n $MIME_TYPES ]]; then
  echo "MimeType=$MIME_TYPES" >>"$DESKTOP_FILE"
fi

chmod +x "$DESKTOP_FILE"

if [[ $INTERACTIVE_MODE == true ]]; then
  echo -e "\e[32mUygulama başarıyla oluşturuldu!\e[0m"
  echo -e "Uygulama menüsünde **$APP_NAME** adını arayabilirsiniz (SUPER + D)."
  ./show-done.sh
fi
