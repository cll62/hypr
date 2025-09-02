#!/bin/bash
set -e

echo "Hyprland otomatik kurulum betiği başlatıldı."
exec > >(tee -i install.log) 2>&1

copy_config_files() {
  if [ -d "$HOME/hypr" ]; then
    rsync -av --exclude='.git' --exclude='install' --exclude='install/' --exclude='README.md' "$HOME/hypr/" "$HOME/" || {
      echo "Kopyalama başarısız"
      exit 1
    }
    echo "✅ Tüm dosyalar başarıyla kopyalandı (var olan dosyaların üzerine yazıldı)."
  else
    echo "Hata: \$HOME/hypr klasörü bulunamadı"
    exit 1
  fi
}

enable_service_if_needed() {
  local svc="$1"
  if systemctl is-enabled "$svc" >/dev/null 2>&1; then
    echo "$svc zaten etkin."
  else
    sudo systemctl enable "$svc" && echo "$svc etkinleştirildi." || echo "Hata: $svc etkinleştirilemedi."
  fi
}

enable_user_service_if_needed() {
  local svc="$1"
  if systemctl --user is-enabled "$svc" >/dev/null 2>&1; then
    echo "$svc kullanıcı servisi zaten etkin."
  else
    systemctl --user enable "$svc" && echo "$svc kullanıcı servisi etkinleştirildi." || echo "Hata: $svc kullanıcı servisi etkinleştirilemedi."
  fi
}

# 1. YAY / AUR kontrolü ve kurulumu
if ! command -v yay &>/dev/null; then
  echo "yay bulunamadı, Chaotic-AUR ve yay kuruluyor..."

  if ! pacman-key --list-keys 3056513887B78AEB >/dev/null 2>&1; then
    sudo pacman-key --recv-key 3056513887B78AEB || sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keys.gnupg.net
    sudo pacman-key --lsign-key 3056513887B78AEB
  fi

  sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
  sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
  fi

  sudo pacman -Sy --needed --noconfirm yay || {
    echo "yay kurulumu başarısız, elle yükleme başlatılıyor..."
    sudo pacman -Sy --needed --noconfirm base-devel
    pushd /tmp
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/yay-bin
  }
fi

echo "yay hazır."

# 2. Mevcut .config dizinini yedekleme
backup_choice=""
read -t 10 -p "Mevcut .config dizinini yedeklemek ister misiniz? (y/n, varsayılan: y, 10 saniye): " backup_choice
backup_choice=${backup_choice:-y}

if [[ "$backup_choice" == "y" ]] && [ -d "$HOME/.config" ]; then
  if [ -d "$HOME/.config_backup" ]; then
    echo "Uyarı: $HOME/.config_backup zaten var. Üzerine yazılsın mı? (y/n, varsayılan: n)"
    read overwrite
    overwrite=${overwrite:-n}
    [[ "$overwrite" != "y" ]] && echo "Yedekleme iptal edildi." && exit 1
  fi
  rsync -a --exclude='.config_backup' "$HOME/.config/" "$HOME/.config_backup/"
  echo "Yedekleme oluşturuldu: $HOME/.config_backup"
fi

# 3. Paket listesi
packages="
7zip
bash-completion
bat
blueman
bluez
brightnessctl
brave-bin
btop
cava
chafa
cliphist
cantarell-fonts
eza
expac
fastfetch
fd
file-roller
fzf
gnome-disk-utility
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
imv
kitty
libappindicator-gtk3
localsend
materia-gtk-theme
meld
mpv
mpv-mpris
ncdu
neovim
noto-fonts
nwg-displays
nwg-look
onlyoffice-bin
otf-codenewroman-nerd
pacman-contrib
pavucontrol
pipewire
pipewire-alsa
pipewire-jack
pipewire-pulse
playerctl
polkit-gnome
pulsemixer
python-pywal16
qogir-icon-theme
qt5ct
qt6ct
reflector-simple
ripgrep
rsync
sddm
spotify
spotify-adblock-git
starship
sublime-text-4
swaync
swayosd
swww
tealdeer
thunar
thunar-archive-plugin
thunar-volman
tumbler
ttf-jetbrains-mono-nerd
udiskie
visual-studio-code-bin
waybar
wget
wireplumber
wlogout
wofi
xdg-desktop-portal-gtk
xdg-desktop-portal-hyprland
xdg-user-dirs
yazi
yt-dlp
zathura
zathura-pdf-poppler
zathura-pywal-git
zoxide
"

# 4. Eksik paketleri yükleme
missing_packages=()
for pkg in $packages; do
  if ! pacman -Q "$pkg" >/dev/null 2>&1; then
    missing_packages+=("$pkg")
  fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
  echo "Kurulacak paketler: ${missing_packages[*]}"
  yay -S --needed --noconfirm --verbose "${missing_packages[@]}"
else
  echo "Tüm paketler zaten yüklü."
fi

# 5. Servisler
enable_service_if_needed sddm
enable_service_if_needed bluetooth
enable_user_service_if_needed pipewire.service
enable_user_service_if_needed pipewire-pulse.service
enable_service_if_needed avahi-daemon

# 6. Config kopyalama
copy_config_files

# 7. Duvar kağıdı
if [ -f "$HOME/wallpapers/pywallpaper.jpg" ]; then
  wal -i "$HOME/wallpapers/pywallpaper.jpg" -n || echo "Duvar kağıdı uygulanamadı."
fi

# 8. SDDM config ve terminal linki
if [ -f "$HOME/hypr/install/sddm.conf" ]; then
  sudo cp -arf "$HOME/hypr/install/sddm.conf" /etc/sddm.conf
fi
sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal

# 9. Pacman conf
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
  echo "Pacman yapılandırmasına renk ekleniyor..."
sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf || { echo "Hata: pacman.conf güncellenemedi"; exit 1; }
fi

# 10. Yeniden başlatma
read -t 10 -p "Sistemi şimdi yeniden başlatmak ister misiniz? (y/n, varsayılan: y, 10 saniye): " restart_choice
restart_choice=${restart_choice:-y}
if [[ "$restart_choice" == "y" ]]; then
  echo "Sistem yeniden başlatılıyor..."
  sudo reboot
else
  echo "Kurulum tamamlandı. Lütfen manuel olarak sistemi yeniden başlatın."
fi
