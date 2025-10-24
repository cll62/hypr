#!/usr/bin/env bash

kilitle="Ekranı Kilitle"
oturum_kapat="Oturumu Kapat"
yeniden_baslat="Yeniden Başlat"
kapat="Bilgisayarı Kapat"
rofi_calistir() {
	rofi -dmenu \
		-theme "$HOME/.config/rofi/main.rasi"
}

rofi_menusu() {
	echo -e "$kilitle\n$oturum_kapat\n$yeniden_baslat\n$kapat" | rofi_calistir
}

secim="$(rofi_menusu)"
case ${secim} in
    $kapat)
		systemctl poweroff
        ;;
    $yeniden_baslat)
		systemctl reboot
        ;;
    $kilitle)
		hyprlock
        ;;
    $oturum_kapat)
		hyprctl dispatch exit
        ;;
esac