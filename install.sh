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

warning() {
    echo -e "\e[1;33m[ Uyarı ]\e[0m $*"
}

cleanup() {
    [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

backup_existing_configs() {
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    local configs_to_backup=(
        ".config/hypr"
        ".config/fastfetch"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".config/qt5ct"
        ".config/qt6ct"
        ".config/bash"
        ".config/matugen"
        ".config/nvim"
        ".config/swayosd"
        ".config/Thunar"
        ".config/yazi"
        ".config/zathura"
        ".config/starship.toml"
        ".config/mimeapps.list"
        ".bashrc"
        ".config/waybar"
        ".config/kitty"
        ".config/rofi"
        ".config/swaync"
    )
    
    local has_existing=0
    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$HOME/$config" ]]; then
            has_existing=1
            break
        fi
    done
    
    if [[ $has_existing -eq 1 ]]; then
        info "Mevcut yapılandırmalar yedekleniyor..."
        mkdir -p "$backup_dir"
        
        for config in "${configs_to_backup[@]}"; do
            if [[ -e "$HOME/$config" ]]; then
                local parent_dir
                parent_dir=$(dirname "$config")
                mkdir -p "$backup_dir/$parent_dir"
                cp -r "$HOME/$config" "$backup_dir/$config" 2>/dev/null || true
                info "Yedeklendi: $config"
            fi
        done
        
        success "Yedekleme tamamlandı: $backup_dir"
    else
        info "Yedeklenecek mevcut yapılandırma bulunamadı."
    fi
}

chaotic_aur() {
    info "Chaotic-AUR deposu eklenmeye çalışılıyor..."

    if ! sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null; then
        warning "UYARI: Chaotic-AUR GPG anahtarını alma başarısız oldu."
        return 1
    fi
    
    sudo pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || warning "UYARI: GPG anahtarını yerel olarak imzalama başarısız oldu."

    if ! sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --needed --noconfirm 2>/dev/null; then
        warning "UYARI: Anahtar ve yansıtma listesi paketlerini yükleme başarısız oldu. Chaotic-AUR devre dışı bırakılıyor."
        return 1
    fi

    if ! grep -q "chaotic-aur" /etc/pacman.conf; then
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
        success "Chaotic-AUR deposu başarıyla eklendi."
    else
        info "Chaotic-AUR deposu zaten /etc/pacman.conf dosyasında mevcut."
    fi

    info "Sistem paket listeleri güncelleniyor (Syu)..."
    sudo pacman -Syu --noconfirm

    return 0 
}

install_yay() {
    if ! command -v yay &>/dev/null; then
        info "yay kurulu değil, AUR'dan manuel olarak derlenip kuruluyor..."
        
        sudo pacman -Sy --needed --noconfirm base-devel git || {
            error "Temel geliştirme araçları (base-devel, git) yüklenemedi!"
            exit 1
        }
        
        info "yay-bin deposu klonlanıyor..."
        TMPDIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin" || {
            error "yay-bin deposu klonlanamadı!"
            exit 1
        }
        
        info "yay-bin paketi derlenip kuruluyor..."
        
        pushd "$TMPDIR/yay-bin" >/dev/null
        makepkg -si --noconfirm || {
            error "yay-bin kurulumu başarısız oldu! İnternet bağlantınızı kontrol edin."
            exit 1
        }
        popd >/dev/null
        
        success "yay başarıyla kuruldu (Manuel AUR yöntemi)."
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
        beautyline
        bibata-cursor-theme
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
        gum
        gvfs
        hypridle
        hyprland
        hyprlock
        hyprpicker
        hyprshot
        hyprsunset
        kitty
        libappindicator-gtk3
        libreoffice-fresh
        libreoffice-fresh-tr
        localsend
        matugen-git
        mpv
        mpv-mpris
        nano
        ncdu
        neovim
        network-manager-applet
        networkmanager
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
        reflector-simple
        ripgrep
        rofi
        rsync
        sddm
        starship
        sublime-text-4
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
        info "Eksik paketler tespit edildi (${#missing[@]} adet)"
        
        info "Toplu kurulum deneniyor..."
        if yay -S --needed --noconfirm "${missing[@]}" 2>/dev/null; then
            success "Tüm paketler başarıyla kuruldu."
            return 0
        fi
        
        warning "Toplu kurulum başarısız, paketler tek tek kuruluyor..."
        
        local failed=()
        local installed=()
        local total=${#missing[@]}
        local current=0
        
        for pkg in "${missing[@]}"; do
            ((current++))
            
            if pacman -Q "$pkg" &>/dev/null; then
                success "[$current/$total] $pkg zaten kurulu"
                installed+=("$pkg")
                continue
            fi
            
            info "[$current/$total] Kuruluyor: $pkg"
            
            if yay -S --needed --noconfirm "$pkg" 2>/dev/null; then
                installed+=("$pkg")
            else
                error "Paket kurulamadı: $pkg"
                failed+=("$pkg")
            fi
        done
        
        echo
        if [[ ${#installed[@]} -gt 0 ]]; then
            success "${#installed[@]} paket başarıyla kuruldu."
        fi
        
        if [[ ${#failed[@]} -gt 0 ]]; then
            warning "Başarısız paketler (${#failed[@]} adet):"
            for pkg in "${failed[@]}"; do
                echo "  - $pkg"
            done
            
            echo
            read -r -p "Başarısız paketlerle devam edilsin mi? (E/h): " -n 1 choice
            echo
            if [[ ! "$choice" =~ ^[EeYy]$ ]]; then
                error "Kullanıcı tarafından iptal edildi."
                exit 1
            fi
            warning "Kuruluma devam ediliyor..."
        else
            success "Tüm paketler başarıyla kuruldu."
        fi
    else
        success "Tüm paketler zaten kurulu."
    fi
}


install_icons_and_cursors() {
    local src="$HOME/hypr/source"
    local fonts_dest="$HOME/.local/share/fonts" 
    
    mkdir -p "$fonts_dest" 
    
    local font_file="$src/fonts.tar.xz" 
    
    if [[ -f "$font_file" ]]; then
        
        info "Font arşivi çıkarılıyor: $font_file"
        
        tar -xf "$font_file" -C "$fonts_dest" --overwrite || { 
             error "Font arşivi ($font_file) çıkarılamadı!"
             return 1
           }
        
        info "Font önbelleği güncelleniyor..."
        fc-cache -f "$fonts_dest" 2>/dev/null || true
        
        success "Fontlar başarıyla kuruldu ve önbellek güncellendi."
    else
        warning "Font arşivi bulunamadı: $font_file. Font kurulumu atlanıyor."
    fi
 
}

set_default_themes() {
    local icon="BeautyLine"
    local cursor="Bibata-Modern-Classic"
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
fixed="CaskaydiaCove Nerd Font Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
general="Cantarell,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
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
fixed="CaskaydiaCove Nerd Font Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
general="Cantarell,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
EOF
    success "Qt temaları ayarlandı."

    local profile="$HOME/.profile"
    if [[ ! -f "$profile" ]]; then
        info ".profile dosyası oluşturuluyor..."
    fi
    
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
    local system_svcs=(sddm avahi-daemon NetworkManager)
    local user_svcs=(pipewire.service pipewire-pulse.service)

    info "Sistem servisleri kontrol ediliyor ve etkinleştiriliyor..."
    local failed_system=()
    for svc in "${system_svcs[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            success "$svc zaten etkinleştirilmiş."
        else
            info "Servis etkinleştiriliyor: $svc"
            if sudo systemctl enable "$svc" 2>/dev/null; then
                success "$svc etkinleştirildi"
            else
                error "$svc etkinleştirilemedi"
                failed_system+=("$svc")
            fi
        fi
    done

    echo
    info "Kullanıcı servisleri kontrol ediliyor ve etkinleştiriliyor..."
    systemctl --user daemon-reexec 2>/dev/null || true
    
    local failed_user=()
    for usvc in "${user_svcs[@]}"; do
        if systemctl --user is-enabled "$usvc" &>/dev/null; then
             success "$usvc zaten etkinleştirilmiş."
        else
            info "Kullanıcı servisi etkinleştiriliyor: $usvc"
            if systemctl --user enable "$usvc" 2>/dev/null; then
                success "$usvc etkinleştirildi"
            else
                warning "$usvc etkinleştirilemedi (normal olabilir)"
                failed_user+=("$usvc")
            fi
        fi
    done
    
    if [[ ${#failed_system[@]} -gt 0 ]]; then
        echo
        warning "Başarısız sistem servisleri: ${failed_system[*]}"
    fi
    
    success "Servis yapılandırması tamamlandı."
}

copy_configs() {
    local src="$HOME/hypr"
    local mode="${1:-full}"
    
    if [[ ! -d "$src" ]]; then
        error "Yapılandırma dizini bulunamadı: $src"
        exit 1
    fi

    if [[ "$mode" == "reconfigure" ]]; then
        info "Yapılandırma dosyaları kopyalanıyor (Yeniden Yapılandırma)..."
        rsync -a \
            --exclude=.git \
            --exclude=install.sh \
            --exclude=source \
            "$src/" "$HOME/"
    else
        info "Yapılandırma dosyaları kopyalanıyor (Tam Kurulum)..."
        rsync -a \
            --exclude=.git \
            --exclude=install.sh \
            --exclude=source \
            "$src/" "$HOME/"
    fi

    info "Betiklere çalıştırma izni veriliyor..."
    if [[ -d "$HOME/.config/hypr/scripts" ]]; then
        find "$HOME/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        success "Betikler çalıştırılabilir yapıldı."
    else
        warning "scripts dizini bulunamadı, chmod atlanıyor."
    fi
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

    if grep -q "^#ParallelDownloads" "$conf"; then
        info "Paralel indirme etkinleştiriliyor..."
        sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' "$conf"
        updated=1
        success "Paralel indirme etkinleştirildi (10 bağlantı)"
    elif ! grep -q "^ParallelDownloads" "$conf"; then
        info "Paralel indirme ekleniyor..."
        sudo sed -i "/^\[options\]/a ParallelDownloads = 10" "$conf"
        updated=1
        success "Paralel indirme eklendi (10 bağlantı)"
    else
        success "Paralel indirme zaten etkin"
    fi

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
    local reconfigure_only=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--reconfigure)
                reconfigure_only=1
                shift
                ;;
            *)
                error "Bilinmeyen parametre: $1"
                echo "Kullanım: $0 [-r|--reconfigure]"
                exit 1
                ;;
        esac
    done

    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modu (-r) etkin. Sadece yapılandırma dosyaları güncelleniyor."
        
        backup_existing_configs
        copy_configs "reconfigure"
        
        success "Tüm yapılandırma güncellemeleri tamamlandı. Değişikliklerin etkili olması için Hyprland oturumunuzu yeniden başlatın."
    else
        info "Tam kurulum modu etkin."
        
        backup_existing_configs
        
        if chaotic_aur; then
            info "Chaotic-AUR deposu başarıyla aktif edildi. yay depodan kuruluyor..."
            if sudo pacman -S yay --needed --noconfirm; then
                success "yay Chaotic-AUR deposundan başarıyla kuruldu."
            else
                warning "Chaotic-AUR'dan yay kurulamadı. Manuel AUR kurulumu deneniyor..."
                install_yay 
            fi
        else
            warning "Chaotic-AUR eklenemedi. yay, manuel olarak AUR'dan kuruluyor..."
            install_yay
        fi

        customize_pacman
        install_packages
        enable_services
        copy_configs "full"
        install_icons_and_cursors
        set_default_themes
        fix_terminal
        configure_sddm
        final_message
    fi
}
main "$@"