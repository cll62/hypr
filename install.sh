#!/bin/bash
# =========================================================
# Hyprland Kurulum ve Yapılandırma Betiği
# =========================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ------------------- RENKLİ MESAJ FONKSİYONLARI -------------------
info()    { echo -e "\e[1;34m[ Bilgi ]\e[0m $*"; }
success() { echo -e "\e[1;32m[ Başarılı ]\e[0m $*"; }
warning() { echo -e "\e[1;33m[ Uyarı ]\e[0m $*" >&2; }
error()   { echo -e "\e[1;31m[ Hata ]\e[0m $*" >&2; exit 1; }

# ------------------- YARDIMCI FONKSİYONLAR -------------------
is_yes() {
    local choice_upper
    choice_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$choice_upper" in
        E|Y|EVET|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------- GEÇİCİ VE LOG DİZİNLERİ -------------------
TMPDIR=$(mktemp -d)
LOGFILE="$TMPDIR/install.log"
exec > >(tee -a "$LOGFILE") 2>&1

cleanup() {
    [[ -d "$TMPDIR" ]] && rm -rf "$TMPDIR" || true
}
trap cleanup EXIT

# ------------------- KULLANICI VE YETKİLER  -------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER=$(whoami) # Betiği başlatan kullanıcı
REAL_HOME=$HOME      # Betiği başlatan kullanıcının ev dizini
reconfigure_only=0   # 0: Full Kurulum, 1: Yalnızca Yapılandırma
AUTO_YES=0           # 0: Soru sor, 1: Otomatik "Evet" veya varsayılanı seç

# ===============================================================
# 0️⃣ Kurulum Modu Seçimi
# ===============================================================
get_mode_choice() {
    echo ""
    info "Lütfen kurulum modunu seçin:"
    echo " 1) Full Kurulum "
    echo " 2) Dotfiles Kurulumu"
    echo ""

    local choice
    if [[ "$AUTO_YES" -eq 1 ]]; then
        info "Otomatik mod aktif, Full Kurulum (1) seçiliyor."
        choice=1
    else
        read -rp "Seçiminiz (1 veya 2): " choice
    fi

    case "$choice" in
        1)
            info "Full Kurulum modu seçildi."
            reconfigure_only=0
            ;;
        2)
            info "Yalnızca Yeniden Yapılandırma modu seçildi."
            reconfigure_only=1
            ;;
        *)
            error "Geçersiz seçim ($choice). Lütfen 1 veya 2 girin."
            ;;
    esac
}

# ===============================================================
# 1️⃣ Chaotic-AUR
# ===============================================================
chaotic_aur() {
    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modunda Chaotic-AUR adımı atlanıyor."
        return
    fi
    info "Chaotic-AUR anahtarları ve mirror listesi kuruluyor..."
    local key="3056513887B78AEB"
    local keyservers=(hkps://keyserver.ubuntu.com hkps://keys.openpgp.org)
    local key_ok=0

    for ks in "${keyservers[@]}"; do
        if sudo pacman-key --recv-key "$key" --keyserver "$ks"; then
            sudo pacman-key --lsign-key "$key"
            success "GPG anahtarı başarıyla eklendi."
            key_ok=1
            break
        else
            warning "Anahtar alınamadı: $ks"
        fi
    done

    if [[ $key_ok -eq 0 ]]; then
        error "Chaotic-AUR anahtarı eklenemedi. Lütfen ağ bağlantınızı kontrol edin ve tekrar deneyin."
    fi

    sudo pacman -U --noconfirm \
        "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" \
        "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" \
        || error "Chaotic-AUR paketleri indirilemedi."
}

# ===============================================================
# 2️⃣ pacman.conf'u Uygulama
# ===============================================================
apply_pacman_conf() {
    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modunda pacman.conf adımı atlanıyor."
        return
    fi
    info "Chaotic-AUR deposunu içeren yeni /etc/pacman.conf uygulanıyor..."
    local custom_pacman_conf="$SCRIPT_DIR/.config/pacman/pacman.conf"
    
    if [[ -f "$custom_pacman_conf" ]]; then
        sudo cp /etc/pacman.conf "/etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S)" || warning "/etc/pacman.conf yedeklenirken bir sorun oluştu."
        
        sudo cp -f "$custom_pacman_conf" /etc/pacman.conf
        
        sudo pacman -Sy --noconfirm || warning "Paket listesi güncellenemedi."
        success "Yeni pacman.conf başarıyla uygulandı ve Chaotic-AUR aktif edildi."
    else
        warning "Yapılandırma dizininde pacman.conf bulunamadı. Chaotic-AUR devre dışı kalabilir."
    fi
}

# ===============
# 3️⃣ yay Kurulumu 
# ===============
install_yay() {
    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modunda yay kurulumu adımı atlanıyor."
        return
    fi
    
    if command -v yay &>/dev/null; then
        success "yay zaten kurulu."
        return
    fi

    info "yay kurulumu başlatılıyor..."

    if pacman -Si yay &>/dev/null; then
        info "Chaotic-AUR deposundan yay kuruluyor..."
        if sudo pacman -S --needed --noconfirm yay; then 
            success "yay Chaotic-AUR üzerinden başarıyla kuruldu."
            return
        fi
        warning "Chaotic-AUR'dan kurulum başarısız oldu. Manuel AUR kurulumuna geçiliyor."
    fi

    info "yay-bin manuel olarak AUR üzerinden derleniyor..."
    sudo pacman -S --needed --noconfirm base-devel git binutils fakeroot || error "Gerekli AUR araçları yüklenemedi."

    rm -rf "$TMPDIR/yay-bin"
    git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin"

    pushd "$TMPDIR/yay-bin" >/dev/null
    if makepkg -si --noconfirm; then 
        success "yay başarıyla kuruldu."
    else
        error "yay kurulumu başarısız oldu."
    fi
    popd >/dev/null
}

# ===============================================================
# 4️⃣ Paket Kurulumu
# ===============================================================
install_packages() {
    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modunda paket kurulumu adımı atlanıyor."
        return
    fi
    
    local PKGLIST_FILE="$SCRIPT_DIR/pkglist.txt"

    if [[ ! -f "$PKGLIST_FILE" ]]; then
        error "Paket listesi dosyası bulunamadı: $PKGLIST_FILE"
    fi
    
    local pkgs
    mapfile -t pkgs < <(grep -vE '^\s*#|^\s*$' "$PKGLIST_FILE")
    
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        warning "Paket listesi boş. Paket kurulumu atlanıyor."
        return 0
    fi

    if ! command -v yay &>/dev/null; then
        warning "yay bulunamadı; kurulum için yay kuruluyor."
        install_yay
    fi

    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then 
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "Tüm paketler zaten kurulu."
        return 0
    fi

    info "Eksik paketler tespit edildi (${#missing[@]}). Tüm eksikler yay ile kurulacak: ${missing[*]}"

    info "Tüm paketler normal kullanıcı yetkisiyle yay ile kuruluyor..."
    
    local installed_count=0
    local failed_pkgs=()

    if yay -S --needed --noconfirm "${missing[@]}"; then 
        success "Tüm eksik paketler başarıyla kuruldu."
        installed_count=${#missing[@]}
    else
        warning "Toplu kurulum başarısız oldu. Paketler tek tek deneniyor..."
        local total=${#missing[@]}
        local current=0
        for pkg in "${missing[@]}"; do
            ((current++))
            info "[$current/$total] Kuruluyor: $pkg"
            if yay -S --needed --noconfirm "$pkg"; then
                ((installed_count++))
            else
                warning "Kurulamadı: $pkg"
                failed_pkgs+=("$pkg")
            fi
        done

        if [[ ${#failed_pkgs[@]} -gt 0 ]]; then
            warning "Başarısız paketler: ${failed_pkgs[*]}"
            if [[ "$AUTO_YES" -eq 0 ]]; then
                local choice
                read -rp "Devam edilsin mi? (E/h): " choice
                if ! is_yes "$choice"; then
                    error "Kullanıcı iptal etti."
                fi
            else
                info "Otomatik mod aktif, başarısız paketler atlanıyor."
            fi
        fi
    fi

    [[ $installed_count -gt 0 ]] && success "$installed_count paket başarıyla kuruldu."
    success "Paket kurulum adımı tamamlandı."
}

# ===============================================================
# 5️⃣ Servisleri Etkinleştirme
# ===============================================================
enable_services() {
    if [[ "$reconfigure_only" -eq 1 ]]; then
        info "Yeniden yapılandırma modunda servis etkinleştirme adımı atlanıyor."
        return
    fi

    local system_svcs=(sddm avahi-daemon power-profiles-daemon ufw NetworkManager)

    info "Sistem servisleri etkinleştiriliyor..."
    local failed_system=()
    for svc in "${system_svcs[@]}"; do
        if sudo systemctl is-enabled "$svc" &>/dev/null; then
            success "$svc zaten etkin."
        else
            info "Etkinleştiriliyor: $svc"
            if ! sudo systemctl enable "$svc"; then
                failed_system+=("$svc")
            fi
        fi
    done

    [[ ${#failed_system[@]} -gt 0 ]] && warning "Başarısız sistem servisleri: ${failed_system[*]}"
    
    if command -v ufw &>/dev/null && ! sudo ufw status | grep -q "active"; then
        info "UFW etkinleştiriliyor ve varsayılanlar ayarlanıyor."
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw enable
        success "UFW etkinleştirildi."
    fi
    success "Servis yapılandırması tamamlandı."
}

# ===============================================================
# 6️⃣ Dotfiles+sddm +kitty
# ===============================================================
user_config() {
    info "Kullanıcı yapılandırmaları uygulanıyor..."
    
    if ! rsync -a \
        --exclude=.git \
        --exclude=install.sh \
        --exclude=pkglist.txt \
        --exclude='.config/pacman/' \
        "$SCRIPT_DIR/" "$REAL_HOME/"; then
        error "rsync hatası: yapılandırmalar kopyalanamadı."
    fi
    success "Yapılandırma dosyaları başarıyla kopyalandı."
    
    if [[ -d "$REAL_HOME/.config/hypr/scripts" ]]; then
        info "Hyprland betiklerine yürütme izni veriliyor..."
        find "$REAL_HOME/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \;
        success "Betik izinleri ayarlandı."
    else
        warning "Hyprland scripts dizini bulunamadı."
    fi
    
    if [[ "$reconfigure_only" -eq 0 ]]; then
        local choice_sddm
        if [[ "$AUTO_YES" -eq 1 ]]; then
            choice_sddm="E"
            info "Otomatik mod aktif, SDDM otomatik giriş ayarlanıyor."
        else
            read -rp "SDDM için otomatik giriş yapılsın mı? (E/h): " choice_sddm
        fi

        if is_yes "$choice_sddm"; then
            info "SDDM otomatik giriş yapılandırması /etc/sddm.conf dosyasına uygulanıyor..."

            if [[ -f /etc/sddm.conf ]]; then
                info "Mevcut /etc/sddm.conf yedekleniyor..."
                if ! sudo cp /etc/sddm.conf "/etc/sddm.conf.backup.$(date +%Y%m%d_%H%M%S)"; then
                    warning "SDDM yapılandırma dosyası yedeklenemedi, devam ediliyor."
                else
                    success "Mevcut /etc/sddm.conf yedeklendi."
                fi
            fi

            info "SDDM otomatik giriş ayarları /etc/sddm.conf dosyasına yazılıyor..."
            if sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
Relogin=false
User=$REAL_USER
Session=hyprland
EOF
            then
                success "SDDM otomatik giriş ayarları /etc/sddm.conf dosyasına başarıyla yazıldı."
            else
                error "SDDM otomatik giriş yapılandırması /etc/sddm.conf dosyasına yazılamadı. Lütfen izinleri kontrol edin."
            fi
        else
            info "SDDM otomatik giriş yapılandırması atlandı."
        fi
    else
        info "Yeniden yapılandırma modunda SDDM otomatik giriş adımı atlanıyor."
    fi

    if [[ ! -L /usr/local/bin/gnome-terminal ]] && [[ -f /usr/bin/kitty ]]; then
        info "kitty için /usr/local/bin/gnome-terminal sembolik bağlantısı oluşturuluyor..."
        if sudo ln -sf /usr/bin/kitty /usr/local/bin/gnome-terminal; then 
            success "Sembolik bağlantı oluşturuldu."
        else
            error "Sembolik bağlantı oluşturulamadı."
        fi
    else
        success "Terminal ayarı zaten uygun veya kitty kurulu değil."
    fi
}
# ===============================================================
# 7️⃣ Yeniden Başlatma
# ===============================================================
reboot_prompt() {
    local choice_reboot
    
    if [[ "$AUTO_YES" -eq 1 ]]; then
        choice_reboot="E"
        info "Otomatik mod aktif, sistem yeniden başlatılacak."
    else
        read -rp "İşlem tamamlandı. Şimdi yeniden başlatılsın mı? (E/h): " choice_reboot
    fi
    
    if is_yes "$choice_reboot"; then
        echo -e "\n\e[1;34mSistem yeniden başlatılıyor...\e[0m"
        sudo systemctl reboot
    else
        info "Yeniden başlatma iptal edildi. Yeni oturumu başlatmak için manuel olarak yeniden başlatmanız veya oturumu değiştirmeniz gerekecek."
    fi
}

# ===============================================================
# 8️⃣ MAIN 
# ===============================================================
main() {
    for arg in "$@"; do
        if [[ "$arg" == "--auto" ]]; then
            AUTO_YES=1
            break
        fi
    done
    
    get_mode_choice

    if [[ "$reconfigure_only" -eq 0 ]]; then
        info "--- Full Kurulum Modu Başlatılıyor ---"
        chaotic_aur
        apply_pacman_conf
        install_yay
        install_packages
        enable_services
    else
        info "--- Dotfiles Kurulumu Modu Başlatılıyor ---"
    fi

    user_config
    
    reboot_prompt
    
    success "İşlem tamamlandı!"
}

main "$@"