#!/bin/bash
set -euo pipefail

info() {
    echo -e "\e[1;34m[ Bilgi ]\e[0m $*"
}

error() {
    echo -e "\e[1;31m[ Hata ]\e[0m $*" >&2
}

success() {
    echo -e "\e[1;32m[ Başarılı ]\e[0m $*"
}

cleanup() {
    [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

install_yay() {
    if ! command -v yay &>/dev/null; then
        info "yay kurulu değil, kuruluyor..."
        sudo pacman -Sy --needed --noconfirm base-devel git || { error "Temel geliştirme araçları (base-devel, git) yüklenemedi!"; exit 1; }
        
        info "yay-bin deposu klonlanıyor..."
        TMPDIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin" || { error "yay-bin deposu klonlanamadı!"; exit 1; }
        
        info "yay-bin paketi derlenip kuruluyor..."
        pushd "$TMPDIR/yay-bin" >/dev/null
        makepkg -si --noconfirm || { error "yay-bin kurulumu başarısız oldu!"; exit 1; }
        popd >/dev/null
        
        success "yay başarıyla kuruldu."
    else
        success "yay zaten kurulu."
    fi
}

install_packages() {
    local pkgs=(
        7zip
        adw-gtk-theme
        bash-completion
        bat
        brave-bin
        brightnessctl
        btop
        cantarell-fonts
        chafa
        cliphist
        eza
        expac
        fastfetch
        fd
        file-roller
        fzf
        gnome-disk-utility
        gnome-keyring
        gst-plugin-pipewire
        gst-plugins-bad
        gvfs
        hypridle
        hyprland
        hyprlock
        hyprpicker
        hyprshot
        hyprsunset
        impala
        kitty
        libappindicator-gtk3
        libreoffice-fresh
        libreoffice-fresh-tr
        mpv
        mpv-mpris
        nano
        ncdu
        neovim
        nwg-displays
        nwg-look
        pacman-contrib
        pavucontrol
        pipewire
        pipewire-alsa
        pipewire-jack
        pipewire-pulse
        playerctl
        polkit-gnome
        pulsemixer
        qt5ct
        qt6ct
        reflector
        ripgrep
        rofi
        rsync
        sddm
        starship
        swayimg
        swaync
        swayosd
        swww
        tealdeer
        thunar
        thunar-archive-plugin
        thunar-volman
        tree
        tumbler
        ttf-jetbrains-mono-nerd
        udiskie
        visual-studio-code-bin
        waybar
        wget
        wireplumber
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-user-dirs
        xournalpp
        yazi
        zathura
        zathura-pdf-poppler
        zoxide
    )

    local missing=()
    for pkg in "${pkgs[@]}"; do
        pacman -Q "$pkg" &>/dev/null || missing+=("$pkg")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        info "Eksik paketler tespit edildi: ${missing[*]}"
        if yay -S --needed --noconfirm "${missing[@]}"; then
            success "Tüm paketler başarıyla kuruldu."
        else
            error "Paket kurulumu sırasında hata oluştu!"
            exit 1
        fi
    else
        success "Tüm paketler zaten kurulu."
    fi
}

install_local_packages() {
    local src="${1:-$HOME/hypr/source}"  
    local packages=() 
    
    if [[ ! -d "$src" ]]; then
        info "Yerel paket dizini bulunamadı: $src"
        return 0  
    fi
    
    info "Yerel paket dizini bulundu: $src"
    
    shopt -s nullglob  
    local pkgfiles=("$src"/*.pkg.tar.zst) 
    
    if [[ ${#pkgfiles[@]} -eq 0 ]]; then
        info "Yerel dizinde .pkg.tar.zst dosyası bulunamadı."
        shopt -u nullglob
        return 0
    fi
    
    for pkgfile in "${pkgfiles[@]}"; do
        packages+=("$pkgfile")
    done
    
    shopt -u nullglob
    
    info "Kurulacak yerel paket sayısı: ${#packages[@]}"
    info "Yerel paketler kuruluyor..."
    
    if sudo pacman -U --needed --noconfirm "${packages[@]}"; then
        success "Yerel paketler başarıyla kuruldu."
    else
        error "Yerel paketler kurulamadı. Lütfen manuel kontrol edin."
        return 1  
    fi
}

install_icons_and_cursors() {
    local src="$HOME/hypr/source"
    local dest="$HOME/.local/share/icons"
    
    info "ikon dizini oluşturuluyor..."
    mkdir -p "$dest" 

    file="$src/BeautyLine-20240419145957.tar.gz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$dest/BeautyLine" ]]; then
            info "BeautyLine ikon teması çıkarılıyor..."
            tar -xf "$file" -C "$dest" || { error "BeautyLine teması çıkarılamadı!"; exit 1; }
            success "BeautyLine ikon teması kuruldu."
        else
            success "BeautyLine ikon teması zaten kurulu."
        fi
    else
        info "BeautyLine arşivi bulunamadı: $file"
    fi

    file="$src/Tela-dracula.tar.xz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$dest/Tela-dracula" ]]; then
            info "Tela-dracula ikon teması çıkarılıyor..."
            tar -xf "$file" -C "$dest" || { error "Tela-dracula teması çıkarılamadı!"; exit 1; }
            success "Tela-dracula ikon teması kuruldu."
        else
            success "Tela-dracula ikon teması zaten kurulu."
        fi
    else
        info "Tela-dracula arşivi bulunamadı: $file"
    fi

    file="$src/Bibata-Modern-Ice.tar.xz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$dest/Bibata-Modern-Ice" ]]; then
            info "Bibata imleç teması çıkarılıyor..."
            tar -xf "$file" -C "$dest" || { error "Bibata imleç teması çıkarılamadı!"; exit 1; }
            success "Bibata imleç teması kuruldu."
        else
            success "Bibata imleç teması zaten kurulu."
        fi
    else
        info "Bibata imleç arşivi bulunamadı: $file"
    fi
    success "Tüm temalar hazır."
}

set_default_themes() {
    local icon="Tela-dracula"
    local cursor="Bibata-Modern-Ice"
    local qt_style="Fusion"
    local scheme_path_qt5="$HOME/.config/qt5ct/colors/matugen.conf"
    local scheme_path_qt6="$HOME/.config/qt6ct/colors/matugen.conf"
    
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$cursor
EOF
    success "X11 imleç teması ayarlandı."

    info "Qt temaları ayarlanıyor..."
    mkdir -p "$HOME/.config/qt6ct"
    cat > "$HOME/.config/qt6ct/qt6ct.conf" <<EOF
[Appearance]
color_scheme_path=$scheme_path_qt6
custom_palette=true
icon_theme=$icon
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
general="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
EOF

    mkdir -p "$HOME/.config/qt5ct"
    cat > "$HOME/.config/qt5ct/qt5ct.conf" <<EOF
[Appearance]
color_scheme_path=$scheme_path_qt5
custom_palette=true
icon_theme=$icon
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
general="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
EOF
    success "Qt temaları ayarlandı."

    local profile="$HOME/.profile"
    if ! grep -q "XCURSOR_THEME=" "$profile" 2>/dev/null; then
        cat >> "$profile" <<EOF
export XCURSOR_THEME=$cursor
export XCURSOR_SIZE=12
export QT_QPA_PLATFORMTHEME=qt6ct
EOF
        success ".profile dosyasına ortam değişkenleri eklendi."
    else
        success ".profile dosyası zaten güncel."
    fi
}

enable_services() {
    local system_svcs=(sddm avahi-daemon)
    local user_svcs=(pipewire.service pipewire-pulse.service)

    info "Sistem servisleri etkinleştiriliyor..."
    for svc in "${system_svcs[@]}"; do
        info "Servis etkinleştiriliyor: $svc"
        sudo systemctl enable "$svc" --now
    done
    success "Sistem servisleri etkinleştirildi."

    info "Kullanıcı servisleri etkinleştiriliyor..."
    systemctl --user daemon-reexec 2>/dev/null || true
    for usvc in "${user_svcs[@]}"; do
        info "Kullanıcı servisi etkinleştiriliyor: $usvc"
        systemctl --user enable "$usvc" --now || true
    done
    success "Kullanıcı servisleri etkinleştirildi."
}

copy_configs() {
    local src="$HOME/hypr"
    
    if [[ ! -d "$src" ]]; then
        error "Yapılandırma dizini bulunamadı: $src"
        exit 1
    fi
    
    info "Yapılandırma dosyaları kopyalanıyor..."
    rsync -a --info=progress2 \
        --exclude=.git \
        --exclude=install.sh \
        --exclude=source \
        "$src/" "$HOME/"

    info "Betiklere çalıştırma izni veriliyor..."
    for script in "$HOME/.config/hypr/scripts/"*.sh; do
        [[ -f "$script" ]] && chmod +x "$script"
    done

    success "Yapılandırma dosyaları başarıyla kopyalandı."
}

fix_terminal() {
 if [[ ! -L /usr/bin/gnome-terminal ]]; then
    sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
    success "kitty, gnome-terminal olarak linklendi."
else
    success "gnome-terminal için sembolik link zaten mevcut."
fi
}

configure_sddm() {
    read -r -p "SDDM için otomatik giriş yapılsın mı? (E/h): " -n 1 choice
    echo
    
    if [[ "$choice" =~ ^[EeYy]$ ]]; then
        info "SDDM otomatik giriş ayarlanıyor..."
        local user
        user=$(whoami)
        sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
Relogin=false
User=$user
Session=hyprland
EOF
        success "SDDM otomatik giriş ayarlandı."
    else
        info "Otomatik giriş atlandı."
    fi
}

customize_pacman() {
    info "pacman ayarları iyileştiriliyor..."
    local opts=("Color" "ILoveCandy" "VerbosePkgLists")
    local conf="/etc/pacman.conf"
    local updated=0

    for opt in "${opts[@]}"; do
        if ! grep -q "^$opt" "$conf"; then
            info "Seçenek ekleniyor: $opt"
            sudo sed -i "/^\[options\]/a $opt" "$conf"
            updated=1
        else
            success "Seçenek zaten etkin: $opt"
        fi
    done

    if [[ $updated -eq 1 ]]; then
        success "pacman ayarları güncellendi."
    else
        success "pacman ayarları zaten güncel."
    fi
}

final_message() {
    echo
    echo -e "\e[1;36m==================================================\e[0m"
    echo -e "\e[1;32m✅ Hyprland kurulumu başarıyla tamamlandı!\e[0m"
    echo
    echo -e "Artık Hyprland masaüstü ortamınız hazır."
    echo -e "Değişikliklerin tam olarak uygulanabilmesi için"
    echo -e "\e[1;33msisteminizi yeniden başlatmanız gerekir.\e[0m"
    echo
    read -r -p "Bilgisayarı şimdi yeniden başlatmak ister misiniz? (E/h): " -n 1 choice
    echo
    if [[ "$choice" =~ ^[EeYy]$ ]]; then
        info "Sistem yeniden başlatılıyor..."
        sudo systemctl reboot
    else
        echo -e "\e[1;34m[ Bilgi ]\e[0m Sistemi daha sonra manuel olarak yeniden başlatabilirsiniz."
    fi
    echo -e "\e[1;36m==================================================\e[0m"
}

main() {
    install_yay
    install_packages
    install_local_packages
    enable_services
    copy_configs
    install_icons_and_cursors
    set_default_themes
    fix_terminal
    configure_sddm
    customize_pacman
    final_message
}
main