#!/bin/bash
set -euo pipefail

#---------------------------#
#       RENKLI ÇIKTI        #
#---------------------------#
info()    { echo -e "\e[1;34m[INFO]\e[0m $*"; }
success() { echo -e "\e[1;32m[SUCCESS]\e[0m $*"; }
error()   { echo -e "\e[1;31m[ERROR]\e[0m $*"; }

#---------------------------#
#     YAY ve Chaotic AUR    #
#---------------------------#
install_yay_and_chaotic() {
  if ! command -v yay &>/dev/null; then
    info "Yay bulunamadı. Chaotic AUR deposu ekleniyor..."

    # Chaotic AUR anahtarını ekle
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB


    # Keyring ve mirrorlist paketlerini kur
    sudo pacman -U --noconfirm \
      https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
      https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

    # pacman.conf'a depo ekle
    if ! grep -q "chaotic-aur" /etc/pacman.conf; then
      echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
    fi

    # Yay kur
    info "Yay kuruluyor..."
    sudo pacman -Sy --needed --noconfirm yay || {
      sudo pacman -Sy --needed --noconfirm base-devel git
      pushd /tmp
      git clone https://aur.archlinux.org/yay-bin.git
      cd yay-bin
      makepkg -si --noconfirm --needed
      popd
      rm -rf /tmp/yay-bin
    }
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
    hyprlock hyprpicker hyprshot hyprsunset impala imv kitty libappindicator-gtk3
    materia-gtk-theme meld mpv mpv-mpris nano ncdu neovim nwg-displays
    nwg-look onlyoffice-bin otf-codenewroman-nerd pacman-contrib pavucontrol
    pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-gnome
    pulsemixer qogir-icon-theme qt5ct qt6ct reflector-simple
    ripgrep rsync sddm starship sublime-text-4
    swaync swayosd swww tealdeer thunar thunar-archive-plugin thunar-volman
    tumbler ttf-jetbrains-mono-nerd udiskie waybar wget wireplumber wofi
    xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs yazi yt-dlp
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
  sudo pacman -U --needed --noconfirm $HOME/hypr/source/qogir-icon-theme-2023.06.05-1-any.pkg.tar.zst
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
  rsync -av --exclude='.git' --exclude='install.sh' --exclude='source/' --exclude='README.md' "$src/" "$HOME/"
  success "Konfigürasyonlar kopyalandı."
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
  echo -e "[Autologin]\nRelogin=false\nUser=$user\nSession=hyprland" | sudo tee /etc/sddm.conf >/dev/null
}


#---------------------------#
#    PACMAN GÖRSEL AYARI    #
#---------------------------#
customize_pacman() {
  if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf
    success "Pacman görsel ayarları eklendi."
  fi
}

#---------------------------#
#           MAIN            #
#---------------------------#
main() {
  install_yay_and_chaotic
  install_packages
  enable_services
  copy_configs
  symlink_terminal
  configure_sddm
  customize_pacman

  success "Kurulum tamamlandı. Lütfen sistemi yeniden başlatın."
}

main
