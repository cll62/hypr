#!/bin/bash

DUVAR_KAGIDI_DIZINI="$HOME/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
ROFI_TEMA="$HOME/.config/rofi/launchers/type-1/style-9"

rofi_menusu() {
    if [ ! -d "$DUVAR_KAGIDI_DIZINI" ]; then
        echo "Hata: $DUVAR_KAGIDI_DIZINI dizini bulunamadı!" >&2
        exit 1
    fi

    find "${DUVAR_KAGIDI_DIZINI}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \)
}

main() {
    secim=$(rofi_menusu | rofi -dmenu -i -theme "$ROFI_TEMA")

    if [ -z "$secim" ]; then
        echo "İşlem iptal edildi."
        exit 0
    fi

    SECILEN_DUVAR_KAGIDI="$secim"

    swww img "$SECILEN_DUVAR_KAGIDI" --transition-type any --transition-fps 60 --transition-duration .5

    cp "$SECILEN_DUVAR_KAGIDI" "$HOME/wallpapers/wall"

    matugen image -c "$MATUGEN_CONFIG" "$SECILEN_DUVAR_KAGIDI"

    echo "Duvar kağıdı ayarlandı ve yeni renkler uygulandı: $SECILEN_DUVAR_KAGIDI"
}

main