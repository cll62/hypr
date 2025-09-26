#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu/type-1"
theme='style-1'

calisma_suresi="`uptime -p | sed -e 's/up //g'`"
ana_bilgisayar=`hostname`

kapat=' Kapat'
yeniden_baslat=' Yeniden Başlat'
kilitle=' Kilitle'
oturum_kapat=' Oturumu Kapat'

rofi_calistir() {
	rofi -dmenu \
		-p "$ana_bilgisayar" \
		-mesg "Çalışma Süresi: $calisma_suresi" \
		-theme ${dir}/${theme}.rasi
}

komut_uygula() {
	if [[ $1 == '--kapat' ]]; then
		systemctl poweroff
	elif [[ $1 == '--yeniden-baslat' ]]; then
		systemctl reboot
	elif [[ $1 == '--oturum-kapat' ]]; then
		hyprctl dispatch exit
	fi
}

rofi_menusu() {
	echo -e "$kilitle\n$oturum_kapat\n$yeniden_baslat\n$kapat" | rofi_calistir
}

secim="$(rofi_menusu)"
case ${secim} in
    $kapat)
		komut_uygula --kapat
        ;;
    $yeniden_baslat)
		komut_uygula --yeniden-baslat
        ;;
    $kilitle)
		hyprlock
        ;;
    $oturum_kapat)
		komut_uygula --oturum-kapat
        ;;
esac