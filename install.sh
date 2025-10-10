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
        ".config/BraveSoftware/Brave-Browser/Default/Preferences"
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
        echo -e "\e[1;33mNot: Sorun yaşarsanız, yapılandırmalarınızı buradan geri yükleyebilirsiniz.\e[0m"
    else
        info "Yedeklenecek mevcut yapılandırma bulunamadı."
    fi
}

install_yay() {
    if ! command -v yay &>/dev/null; then
        info "yay kurulu değil, kuruluyor..."
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
        info "PKGBUILD dosyası: $TMPDIR/yay-bin/PKGBUILD"
        sleep 1
        
        pushd "$TMPDIR/yay-bin" >/dev/null
        makepkg -si --noconfirm || {
            error "yay-bin kurulumu başarısız oldu!"
            exit 1
        }
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
        gum
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
    local icons_dest="$HOME/.local/share/icons"
    local fonts_dest="$HOME/.local/share/fonts" 
    
    info "İkon ve Font dizinleri oluşturuluyor..."
    mkdir -p "$icons_dest"
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
  
    local file="$src/BeautyLine-20240419145957.tar.gz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$icons_dest/BeautyLine" ]]; then
            info "BeautyLine ikon teması çıkarılıyor..."
            tar -xf "$file" -C "$icons_dest" || {
                error "BeautyLine teması çıkarılamadı!"
                exit 1
            }
            success "BeautyLine ikon teması kuruldu."
        else
            success "BeautyLine ikon teması zaten kurulu."
        fi
    else
        info "BeautyLine arşivi bulunamadı: $file"
    fi

    file="$src/Tela-dracula.tar.xz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$icons_dest/Tela-dracula" ]]; then
            info "Tela-dracula ikon teması çıkarılıyor..."
            tar -xf "$file" -C "$icons_dest" || {
                error "Tela-dracula teması çıkarılamadı!"
                exit 1
            }
            success "Tela-dracula ikon teması kuruldu."
        else
            success "Tela-dracula ikon teması zaten kurulu."
        fi
    else
        info "Tela-dracula arşivi bulunamadı: $file"
    fi

    file="$src/Bibata-Modern-Ice.tar.xz"
    if [[ -f "$file" ]]; then
        if [[ ! -d "$icons_dest/Bibata-Modern-Ice" ]]; then
            info "Bibata imleç teması çıkarılıyor..."
            tar -xf "$file" -C "$icons_dest" || {
                error "Bibata imleç teması çıkarılamadı!"
                exit 1
            }
            success "Bibata imleç teması kuruldu."
        else
            success "Bibata imleç teması zaten kurulu."
        fi
    else
        info "Bibata imleç arşivi bulunamadı: $file"
    fi
    success "Tüm temalar ve fontlar hazır."
}

set_default_themes() {
    local icon="BeautyLine"
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
general="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,0,1,Regular"
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
general="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,0,1,Regular"
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
    local system_svcs=(sddm avahi-daemon)
    local user_svcs=(pipewire.service pipewire-pulse.service)

    info "Sistem servisleri etkinleştiriliyor..."
    local failed_system=()
    for svc in "${system_svcs[@]}"; do
        info "Servis etkinleştiriliyor: $svc"
        if sudo systemctl enable "$svc" --now 2>/dev/null; then
            success "$svc etkinleştirildi"
        else
            error "$svc etkinleştirilemedi"
            failed_system+=("$svc")
        fi
    done
    
    echo
    info "Sistem servis durumları kontrol ediliyor..."
    for svc in "${system_svcs[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            success "✓ $svc çalışıyor"
        else
            warning "✗ $svc çalışmıyor"
        fi
    done

    echo
    info "Kullanıcı servisleri etkinleştiriliyor..."
    systemctl --user daemon-reexec 2>/dev/null || true
    
    local failed_user=()
    for usvc in "${user_svcs[@]}"; do
        info "Kullanıcı servisi etkinleştiriliyor: $usvc"
        if systemctl --user enable "$usvc" --now 2>/dev/null; then
            success "$usvc etkinleştirildi"
        else
            warning "$usvc etkinleştirilemedi (normal olabilir)"
            failed_user+=("$usvc")
        fi
    done
    
    echo
    info "Kullanıcı servis durumları kontrol ediliyor..."
    for usvc in "${user_svcs[@]}"; do
        if systemctl --user is-active --quiet "$usvc" 2>/dev/null; then
            success "✓ $usvc çalışıyor"
        else
            warning "✗ $usvc çalışmıyor (oturum açtıktan sonra başlayacak)"
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
        info "Yapılandırma dosyaları kopyalanıyor (Yeniden Yapılandırma - Brave hariç)..."
        rsync -a \
            --exclude=.git \
            --exclude=install.sh \
            --exclude=source \
            --exclude=.config/BraveSoftware \
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
        install_yay
        customize_pacman
        install_packages
        install_local_packages
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