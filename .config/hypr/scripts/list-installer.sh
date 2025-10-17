#!/bin/bash
INSTALLER_DIR="$HOME/.config/hypr/scripts"
declare -a menu_order=(
    " Sistem Güncelle"
    " Resmi Paket Yükle"
    " AUR Paket Yükle"
    " Paket Kaldır"
    " Web Uygulaması Oluştur"
    " Web Uygulaması Kaldır"
)
declare -A options
options[" Sistem Güncelle"]="system-update.sh"
options[" AUR Paket Yükle"]="pkg-aur-install.sh"
options[" Resmi Paket Yükle"]="pkg-packman-install.sh"
options[" Paket Kaldır"]="pkg-remove.sh"
options[" Web Uygulaması Oluştur"]="webapp-install.sh"
options[" Web Uygulaması Kaldır"]="webapp-remove.sh"
menu=""
for display_name in "${menu_order[@]}"; do
    menu="${menu}${display_name}\n"
done
menu=$(echo -e "$menu" | head -c -1)
selected=$(echo -e "$menu" | rofi -dmenu -i -p ">" -theme "$HOME/.config/rofi/cliphist")
if [[ -n "$selected" ]]; then
    script_name="${options[$selected]}"
    if [[ -f "$INSTALLER_DIR/$script_name" ]]; then
        kitty --class installer -e bash -c "cd '$INSTALLER_DIR' && ./$script_name"
    else
        notify-send "Hata" "Script bulunamadı: $script_name"
    fi
fi