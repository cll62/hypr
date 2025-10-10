#!/bin/bash
echo -e "\e[32mSistem güncellemeleri kontrol ediliyor...\e[0m\n"
echo "Resmi depolar kontrol ediliyor..."
pacman_updates=$(checkupdates 2>/dev/null)
echo "AUR paketleri kontrol ediliyor..."
aur_updates=$(yay -Qua 2>/dev/null)
all_updates=""
update_count=0
if [[ -n "$pacman_updates" ]]; then
    all_updates="$pacman_updates"
    update_count=$((update_count + $(echo "$pacman_updates" | wc -l)))
fi
if [[ -n "$aur_updates" ]]; then
    if [[ -n "$all_updates" ]]; then
        all_updates="$all_updates\n$aur_updates"
    else
        all_updates="$aur_updates"
    fi
    update_count=$((update_count + $(echo "$aur_updates" | wc -l)))
fi
if [[ $update_count -eq 0 ]]; then
    echo -e "\e[32m✓ Sistem güncel!\e[0m"
    ./show-done.sh
    exit 0
fi
fzf_args=(
    --preview 'if pacman -Si {1} &>/dev/null; then pacman -Si {1}; else yay -Siia {1}; fi'
    --preview-label="Paket bilgisi - Tüm paketleri güncellemek için ENTER'a basın"
    --preview-label-pos='bottom'
    --preview-window 'right:60%:wrap'
    --bind 'alt-p:toggle-preview'
    --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind 'alt-k:preview-up,alt-j:preview-down'
    --header="$update_count paket güncellemesi mevcut"
    --color 'pointer:blue,marker:blue'
    --no-multi
)
echo -e "$all_updates" | fzf "${fzf_args[@]}" > /dev/null
if [[ $? -eq 0 ]]; then
    echo -e "\n\e[33mSistem güncellemesi başlatılıyor...\e[0m\n"
    yay -Syu --noconfirm
    sudo updatedb
    echo -e "\n\e[32m✓ Sistem güncellemesi tamamlandı!\e[0m"
    ./show-done.sh
else
    echo -e "\n\e[31mGüncelleme iptal edildi.\e[0m"
fi