#!/bin/bash
set -euo pipefail

#---------------------------#
#       RENKLI ÇIKTI        #
#---------------------------#
info()    { echo -e "\e[1;34m[INFO]\e[0m $*"; }
success() { echo -e "\e[1;32m[SUCCESS]\e[0m $*"; }
error()   { echo -e "\e[1;31m[ERROR]\e[0m $*"; }

# Hata olursa cleanup
cleanup() {
  [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

#---------------------------#
#     YAY KURULUMU          #
#---------------------------#
install_yay() {
  if ! command -v yay &>/dev/null; then
    info "Yay kuruluyor..."
    sudo pacman -Sy --needed --noconfirm base-devel git
    TMPDIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin"
    pushd "$TMPDIR/yay-bin" >/dev/null
    makepkg -si --noconfirm --needed
    popd >/dev/null
    success "Yay başarıyla kuruldu."
  else
    success "Yay zaten kurulu."
  fi
}

#---------------------------#
#     PAKETLERİ KUR         #
#---------------------------#
install_packages() {
  local pkgs=(
    7zip bash-completion bat brightnessctl brave-bin btop chafa cliphist
    cantarell-fonts eza expac fastfetch fd file-roller fzf gnome-disk-utility
    gnome-keyring gst-plugin-pipewire gst-plugins-bad gvfs hypridle hyprland
    hyprlock hyprpicker hyprshot hyprsunset impala kitty libappindicator-gtk3
    materia-gtk-theme mpv mpv-mpris nano ncdu neovim nwg-displays
    nwg-look onlyoffice-bin otf-codenewroman-nerd pacman-contrib pavucontrol
    pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-gnome
    pulsemixer qt5ct qt6ct reflector ripgrep rsync 
    sddm starship swayimg swaync swayosd swww tealdeer thunar thunar-archive-plugin thunar-volman
    tumbler ttf-jetbrains-mono-nerd udiskie waybar wget wireplumber wofi
    xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs yazi
    zathura zathura-pdf-poppler zoxide
  )

  local missing=()
  for pkg in "${pkgs[@]}"; do
    pacman -Q "$pkg" &>/dev/null || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    info "Eksik paketler tespit edildi. Kuruluyor..."
    yay -S --needed --noconfirm "${missing[@]}"
  else
    success "Tüm paketler zaten kurulu."
  fi
}
#---------------------------#
#   MANUEL PAKETLERİ KUR    #
#---------------------------#
install_local_packages() {
  local src="$HOME/hypr/source"

  if [[ -d "$src" ]]; then
    shopt -s nullglob
    for pkgfile in "$src"/*.pkg.tar.zst; do
      [[ -f "$pkgfile" ]] && sudo pacman -U --needed --noconfirm "$pkgfile"
    done
    shopt -u nullglob
    success "Yerel .pkg.tar.zst paketleri kuruldu."
  fi
}

#---------------------------#
#   ICON & CURSOR KUR       #
#---------------------------#
install_icons_and_cursors() {
  local src="$HOME/hypr/source"
  local dest="$HOME/.local/share/icons"

  mkdir -p "$dest"
  info "Icon ve cursor temaları yükleniyor..."

  # BeautyLine
  if [[ -f "$src/BeautyLine-20240419145957.tar.gz" ]]; then
    tar -xf "$src/BeautyLine-20240419145957.tar.gz" -C "$dest"
    success "BeautyLine icon teması kuruldu."
  else
    info "BeautyLine icon teması bulunamadı."
  fi

  # Bibata
  if [[ -f "$src/Bibata-Modern-Ice.tar.xz" ]]; then
    tar -xf "$src/Bibata-Modern-Ice.tar.xz" -C "$dest"
    success "Bibata cursor teması kuruldu."
  else
    info "Bibata cursor teması bulunamadı."
  fi
}
#---------------------------#
#   VARSAYILAN THEME AYAR   #
#---------------------------#
set_default_themes() {
  local icon="BeautyLine"
  local cursor="Bibata-Modern-Ice"

  info "Varsayılan icon ve cursor temaları ayarlanıyor..."

  # GTK 3
  mkdir -p "$HOME/.config/gtk-3.0"
  cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=Materia-dark-compact
gtk-icon-theme-name=$icon
gtk-cursor-theme-name=$cursor
gtk-font-name=Cantarell 10
gtk-cursor-theme-size=12
gtk-application-prefer-dark-theme=1
EOF

  # GTK 4
  mkdir -p "$HOME/.config/gtk-4.0"
  cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=Materia-dark-compact
gtk-icon-theme-name=$icon
gtk-cursor-theme-name=$cursor
gtk-font-name=Cantarell 10
gtk-cursor-theme-size=12
gtk-application-prefer-dark-theme=1
EOF

  # XCURSOR (Hyprland & Wayland için)
  mkdir -p "$HOME/.icons/default"
  cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$cursor
EOF

  # Çevresel değişkenler (oturumda cursor için)
  echo "export XCURSOR_THEME=$cursor" >> "$HOME/.profile"
  echo "export XCURSOR_SIZE=12" >> "$HOME/.profile"

  success "Varsayılan temalar: Icon=$icon, Cursor=$cursor"
}


#---------------------------#
#       SERVİSLERİ AYARLA   #
#---------------------------#
enable_services() {
  local system_svcs=(sddm avahi-daemon)
  local user_svcs=(pipewire.service pipewire-pulse.service)
  for svc in "${system_svcs[@]}"; do
    systemctl is-enabled "$svc" &>/dev/null || sudo systemctl enable "$svc"
  done

  for usvc in "${user_svcs[@]}"; do
    systemctl --user is-enabled "$usvc" &>/dev/null || systemctl --user enable "$usvc"
  done

  success "Gerekli servisler etkinleştirildi."
}

#---------------------------#
#      AYARLARI KOPYALA     #
#---------------------------#
copy_configs() {
  local src="$HOME/hypr"

  if [[ ! -d "$src" ]]; then
    error "$src dizini bulunamadı. Çıkılıyor."
    exit 1
  fi

  info "$src dizininden konfigürasyonlar kopyalanıyor..."
  rsync -av \
    --exclude='.git' \
    --exclude='install.sh' \
    --exclude='/source' \
    --exclude='README.md' \
    "$src/" "$HOME/"
  success "Konfigürasyonlar kopyalandı."

  for script in "$HOME/.config/hypr/script/"*.sh; do
    [[ -f "$script" ]] && chmod +x "$script"
  done
}

#---------------------------#
#     GNOME TERMINAL FIX    #
#---------------------------#
symlink_terminal() {
  if [[ ! -e /usr/bin/gnome-terminal ]]; then
    sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
    success "Kitty terminal, gnome-terminal olarak linklendi."
  fi
}

#---------------------------#
#     SDDM AUTOLOGIN AYARI  #
#---------------------------#
configure_sddm() {
  local user
  user=$(whoami)

  info "SDDM autologin ayarlanıyor..."
  sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
Relogin=false
User=$user
Session=hyprland
EOF
  success "SDDM autologin ayarlandı."
}

#---------------------------#
#    PACMAN GÖRSEL AYARI    #
#---------------------------#
customize_pacman() {
  if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf
    success "Pacman görsel ayarları eklendi."
  else
    success "Pacman görsel ayarları zaten mevcut."
  fi
}

#---------------------------#
#           MAIN            #
#---------------------------#
main() {
  install_yay
  install_packages
  install_local_packages
  enable_services
  copy_configs
  install_icons_and_cursors
  set_default_themes
  symlink_terminal
  configure_sddm
  customize_pacman

  success "Kurulum tamamlandı. Lütfen sistemi yeniden başlatın."
}

main
