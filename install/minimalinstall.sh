#!/bin/bash
set -euo pipefail

install_yay() {
  if ! command -v yay &>/dev/null; then
    echo "[+] yay bulunamadı, kuruluyor..."
    sudo pacman -Sy --needed --noconfirm base-devel git
    pushd /tmp >/dev/null
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf /tmp/yay-bin
  else
    echo "[✓] yay zaten kurulu."
  fi
}

install_packages() {
  local pkgs="bash-completion brightnessctl btop chafa chromium cliphist cantarell-fonts \
eza expac fastfetch fd fzf gst-plugin-pipewire gst-plugins-bad hypridle hyprland hyprlock \
hyprpicker hyprshot hyprsunset impala imv kitty libappindicator-gtk3 materia-gtk-theme \
mousepad mpv nano ncdu nwg-displays nwg-look otf-codenewroman-nerd pacman-contrib \
pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-gnome \
pulsemixer python-pywal16 ripgrep rsync sddm starship swaync swayosd swww tealdeer thunar \
thunar-archive-plugin thunar-volman tumbler ttf-jetbrains-mono-nerd udiskie waybar wget \
wireplumber wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs yazi zoxide"

  local missing=()
  for pkg in $pkgs; do
    pacman -Q "$pkg" &>/dev/null || missing+=("$pkg")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "[+] Eksik paketler kuruluyor: ${missing[*]}"
    yay -S --needed --noconfirm "${missing[@]}"
  else
    echo "[✓] Tüm paketler kurulu."
  fi
}

enable_services() {
  for svc in sddm avahi-daemon; do
    if ! systemctl is-enabled "$svc" &>/dev/null; then
      echo "[+] $svc etkinleştiriliyor..."
      sudo systemctl enable  "$svc"
    fi
  done

  for usvc in pipewire.service pipewire-pulse.service; do
    if ! systemctl --user is-enabled "$usvc" &>/dev/null; then
      echo "[+] Kullanıcı servisi $usvc etkinleştiriliyor..."
      systemctl --user enable  "$usvc"
    fi
  done
}

setup_hypr() {
  if [ ! -d "$HOME/hypr" ]; then
    echo "[-] Hata: $HOME/hypr bulunamadı"
    exit 1
  fi

  echo "[+] Hypr yapılandırması kopyalanıyor..."
  rsync -av --exclude='.git' --exclude='install' --exclude='README.md' "$HOME/hypr/" "$HOME/"

  if [ -f "$HOME/hypr/install/sddm.conf" ]; then
    echo "[+] SDDM yapılandırması uygulanıyor..."
    sudo cp -arf "$HOME/hypr/install/sddm.conf" /etc/sddm.conf
  fi

  if [ ! -L /usr/bin/gnome-terminal ]; then
    echo "[+] gnome-terminal yerine kitty yönlendiriliyor..."
    sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
  fi
}

apply_wallpaper() {
  if [ -f "$HOME/wallpapers/pywallpaper.jpg" ]; then
    echo "[+] Pywal ile duvar kağıdı ayarlanıyor..."
    wal -i "$HOME/wallpapers/pywallpaper.jpg" -n
  fi
}

tune_pacman() {
  if ! grep -q "ILoveCandy" /etc/pacman.conf; then
    echo "[+] Pacman.conf renklendiriliyor..."
    sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf
  fi
}

main() {
  install_yay
  install_packages
  enable_services
  setup_hypr
  apply_wallpaper
  tune_pacman
  echo "[✓] Kurulum tamamlandı. Lütfen sistemi yeniden başlatın."
}

main
