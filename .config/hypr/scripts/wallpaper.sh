#!/bin/bash

DUVAR_KAGIDI_DIZINI="$HOME/.config/wallpapers"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
SABIT_DUVAR_KAGIDI="$HOME/wallpapers/current_wallpaper.png"

rofi_menusu() {
    if [ ! -d "$DUVAR_KAGIDI_DIZINI" ]; then
        echo "Hata: $DUVAR_KAGIDI_DIZINI dizini bulunamadı!" >&2
        exit 1
    fi
    
    find "$DUVAR_KAGIDI_DIZINI" \
        -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
        -print0 | shuf -z |
    while IFS= read -r -d $'\0' img; do
        echo -en "$img\0icon\x1f$img\n"
    done
}

main() {
    secim=$(rofi_menusu | rofi -show-icons -dmenu -theme "$HOME/.config/rofi/wallselect.rasi" -p "Duvar Kağıdı Seç >")

    if [ -z "$secim" ]; then
        echo "İşlem iptal edildi."
        exit 0
    fi

    SECILEN_DUVAR_KAGIDI="$secim"

    convert "$SECILEN_DUVAR_KAGIDI" "$SABIT_DUVAR_KAGIDI"

    swww img "$SECILEN_DUVAR_KAGIDI" --transition-type any --transition-fps 60 --transition-duration .5 \
        || { echo "Hata: swww geçişi başarısız oldu!" >&2; exit 1; }

    matugen image -c "$MATUGEN_CONFIG" "$SECILEN_DUVAR_KAGIDI" \
        || { echo "Hata: Matugen renk uygulaması başarısız!" >&2; exit 1; }

    echo "Başarılı! Duvar kağıdı ayarlandı ve Matugen renkleri uygulandı: $(basename "$SECILEN_DUVAR_KAGIDI")"
}

main
