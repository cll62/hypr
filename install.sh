#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

# ------------------- MESAJ FONKSİYONLARI -------------------
info()    { echo "[ℹ] $*"; }
success() { echo "[✔] $*"; }
warning() { echo "[⚠] $*" >&2; }
error()   { echo "[✖] $*" >&2; exit 1; }

# ------------------- GİRİŞ FONKSİYONLARI -------------------
is_yes() {
    [[ "${1,,}" =~ ^(e|evet|y|yes)$ ]]
}
# ------------------- DEĞİŞKENLER -------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER=$(whoami)
REAL_HOME=$HOME
AUTO_YES=0
mod=0  # 0: Full Kurulum, 1: Dotfiles

# ------------------- LOG DİZİNLERİ -------------------
LOGDIR="$HOME/.cache/hyprland-logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/install-$(date +%Y%m%d_%H%M%S).log"
TMPDIR="${TMPDIR:-/tmp}"

exec > >(tee -a "$LOGFILE") 2>&1
cleanup() {
    rm -rf "$TMPDIR/yay-bin" 2>/dev/null || true
}
trap 'cleanup; echo; echo "[✖] Bir hata oluştu! Log dosyasını inceleyin: $LOGFILE"; echo' ERR

{
    echo "========================================================="
    echo " 🌀 Hyprland Otomatik Kurulum Logu"
    echo " Tarih   : $(date)"
    echo " Kullanıcı: $REAL_USER"
    echo " Sistem   : $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
    echo " Kabuk    : $SHELL"
    echo "========================================================="
    echo
} >> "$LOGFILE"


# ===============================================================
# Kurulum Modu Seçimi
# ===============================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dotfiles) mod=1 ;;
        --full) mod=0 ;;
        --yes) AUTO_YES=1 ;;
        *) error "Geçersiz parametre: $1 (Kullanım: --full, --dotfiles, --yes)" ;;
    esac
    shift
done

if [[ "$mod" -eq 1 ]]; then
    info "🎨 Dotfiles modu seçildi."
else
    info "🧱 Full kurulum modu seçildi."
fi

# ===============================================================
# Chaotic-AUR Kurulumu
# ===============================================================
setup_chaotic_aur() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda Chaotic-AUR adımı atlanıyor."
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
        error "Chaotic-AUR anahtarı eklenemedi. Lütfen ağ bağlantınızı kontrol edin."
    fi

    sudo pacman -U --noconfirm \
        "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" \
        "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" \
        || error "Chaotic-AUR paketleri indirilemedi."

    sudo pacman -Syu --noconfirm --needed || warning "chaotic-mirrorlist güncellenemedi."
    success "Chaotic-AUR yapılandırması tamamlandı."
}

# ===============================================================
# pacman.conf Yapılandırması
# ===============================================================
configure_pacman() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda pacman.conf adımı atlanıyor."
        return
    fi
    info "Yeni /etc/pacman.conf uygulanıyor..."
    local custom_pacman_conf="$SCRIPT_DIR/.config/pacman/pacman.conf"

    if [[ -f "$custom_pacman_conf" ]]; then
        sudo cp /etc/pacman.conf "/etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S)" || warning "pacman.conf yedeklenemedi."
        sudo cp -f "$custom_pacman_conf" /etc/pacman.conf || error "pacman.conf kopyalanamadı!"
        sudo pacman -Sy --noconfirm || warning "Paket listesi güncellenemedi."
        success "Yeni pacman.conf başarıyla uygulandı."
    else
        warning "pacman.conf bulunamadı. Chaotic-AUR devre dışı kalabilir."
    fi
}

# ===============================================================
# yay Kurulumu
# ===============================================================
setup_yay() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda yay kurulumu adımı atlanıyor."
        return
    fi

    if command -v yay &>/dev/null; then
        success "yay zaten kurulu."
        return
    fi
    sudo pacman -Syu --noconfirm || warning "Sistem güncellenemedi."

    info "yay kurulumu başlatılıyor..."
    if pacman -Si yay &>/dev/null; then
        sudo pacman -S --needed --noconfirm yay && success "yay kuruldu." && return
    fi

    sudo pacman -S --needed --noconfirm base-devel git || error "Gerekli AUR araçları yüklenemedi."
    rm -rf "$TMPDIR/yay-bin"
    git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin" || error "yay klonlama başarısız."
    pushd "$TMPDIR/yay-bin" >/dev/null
    makepkg -si --noconfirm || error "yay kurulumu başarısız oldu."
    popd >/dev/null
    success "yay başarıyla kuruldu."
    hash -r
}

# ===============================================================
# Paket Kurulumu
# ===============================================================
install_required_packages() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda paket kurulumu atlanıyor."
        return
    fi

    local PKGLIST_FILE="$SCRIPT_DIR/pkglist.txt"
    [[ ! -f "$PKGLIST_FILE" ]] && error "Paket listesi bulunamadı: $PKGLIST_FILE"
    if ! grep -q -E '^[^\s#]' "$PKGLIST_FILE"; then
        warning "Paket listesi boş."
        return
    fi
    mapfile -t pkgs < <(grep -E '^[^\s#]' "$PKGLIST_FILE")

    yay -S --needed --noconfirm  "${pkgs[@]}" || warning "Bazı paketler yüklenemedi."
    success "Paket kurulumu tamamlandı."
}

# ===============================================================
# Servis Etkinleştirme
# ===============================================================
enable_system_services() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda servis etkinleştirme adımı atlanıyor."
        return
    fi

    local services=(sddm avahi-daemon power-profiles-daemon ufw NetworkManager)
    for svc in "${services[@]}"; do
        if ! sudo systemctl is-enabled "$svc" &>/dev/null; then
            sudo systemctl enable "$svc" && success "$svc etkinleştirildi."
        else
            info "$svc zaten etkin."
        fi
    done

    if command -v ufw &>/dev/null; then
        sudo ufw --force reset
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw --force enable

        if compgen -G "/etc/ufw/*.rules" > /dev/null; then
            sudo chmod 600 /etc/ufw/*.rules 2>/dev/null || true
        fi

        if sudo ufw status | grep -q "active"; then
            success "UFW etkin ve güvenli biçimde yapılandırıldı."
        else
            warning "UFW etkinleştirilemedi, manuel kontrol önerilir."
        fi
    fi

}

# ===============================================================
# Dotfiles ve Kullanıcı Ayarları
# ===============================================================
configure_user_settings() {
    info "Kullanıcı yapılandırmaları uygulanıyor..."
    rsync -a --exclude=.git --exclude=install.sh --exclude=pkglist.txt --exclude='.config/pacman/' "$SCRIPT_DIR/" "$REAL_HOME/" || error "rsync hatası."

    if [[ -d "$REAL_HOME/.config/hypr/scripts" ]]; then
        find "$REAL_HOME/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \;
        success "Hyprland script izinleri ayarlandı."
    fi

    info "Kullanıcı dizinleri oluşturuluyor..."
    xdg-user-dirs-update || warning "xdg-user-dirs-update başarısız."
    success "Kullanıcı dizinleri güncellendi."

    local choice_sddm="E"
    if [[ "$mod" -eq 0 && "$AUTO_YES" -eq 0 ]]; then
        read -rp "SDDM için otomatik giriş yapılsın mı? (E/h): " choice_sddm || true
    fi
    if is_yes "$choice_sddm"; then
sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
Relogin=false
User=$REAL_USER
Session=hyprland
EOF
        success "SDDM otomatik giriş yapılandırıldı."
    fi

    if [[ ! -L /usr/local/bin/gnome-terminal ]] && [[ -f /usr/bin/kitty ]]; then
        sudo ln -sf /usr/bin/kitty /usr/local/bin/gnome-terminal
        success "kitty → gnome-terminal sembolik bağlantısı oluşturuldu."
    fi
}

# ===============================================================
# Yeniden Başlatma
# ===============================================================
prompt_reboot() {
    if [[ "$mod" -eq 1 ]]; then
        info "Dotfiles modunda değişiklikleri uygulamak için oturumu kapatıp yeniden girin."
        return
    fi

    if [[ "$AUTO_YES" -eq 1 ]]; then
    info "Kurulum tamamlandı. Sistem 5 saniye içinde yeniden başlatılacak..."
    sleep 5
    sudo systemctl reboot
    return
    fi


    read -rp "Kurulum tamamlandı. Şimdi yeniden başlatılsın mı? (E/h): " choice
    if is_yes "$choice"; then
        sudo systemctl reboot
    else
        info "Yeniden başlatma atlandı."
    fi
}

# ===============================================================
# Ana Fonksiyon
# ===============================================================
main() {
    [[ $EUID -eq 0 ]] && error "Bu betik root olarak çalıştırılamaz."
    if [[ "$mod" -eq 0 ]]; then
        setup_chaotic_aur
        configure_pacman
        sudo pacman -Syu --noconfirm || warning "Sistem güncellenemedi."
        setup_yay
        install_required_packages
        enable_system_services
    fi
    configure_user_settings
    prompt_reboot
    echo
    success "Kurulum tamamlandı!"
    info "📜 Log kaydedildi: $LOGFILE"
    echo
}

main "$@"
