#!/bin/bash

DUVAR_KAGIDI_DIZINI="$HOME/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
SABIT_DUVAR_KAGIDI="$HOME/wallpapers/current_wallpaper.png"
BRAVE_ARKA_PLAN_DIZINI="$HOME/.config/BraveSoftware/Brave-Browser/Default/sanitized_background_images"
BRAVE_ARKA_PLAN_DOSYA="$BRAVE_ARKA_PLAN_DIZINI/current_wallpaper.png"

rofi_menusu() {
    if [ ! -d "$DUVAR_KAGIDI_DIZINI" ]; then
        echo "Hata: $DUVAR_KAGIDI_DIZINI dizini bulunamadı!" >&2
        exit 1
    fi

    find "${DUVAR_KAGIDI_DIZINI}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \)
}

main() {
    secim=$(rofi_menusu | rofi -dmenu -i -theme "$HOME/.config/rofi/launchers/type-1/style-2" -p "Wallpaper Seç" -matching fuzzy -format 's')

    if [ -z "$secim" ]; then
        echo "İşlem iptal edildi."
        exit 0
    fi

    SECILEN_DUVAR_KAGIDI="$secim"

    magick convert "$SECILEN_DUVAR_KAGIDI" "$SABIT_DUVAR_KAGIDI"

    swww img "$SECILEN_DUVAR_KAGIDI" --transition-type any --transition-fps 60 --transition-duration .5

    mkdir -p "$BRAVE_ARKA_PLAN_DIZINI" || { echo "Hata: Brave dizini oluşturulamadı!" >&2; exit 1; }
    cp "$SABIT_DUVAR_KAGIDI" "$BRAVE_ARKA_PLAN_DOSYA"

    matugen image -c "$MATUGEN_CONFIG" "$SECILEN_DUVAR_KAGIDI"

    echo "Duvar kağıdı ayarlandı, Brave arka planı güncellendi ve renkler uygulandı: $SECILEN_DUVAR_KAGIDI"
}

main
