#!/bin/bash
echo "Bu betik, Arch Linux sistemi için özelleştirilmiş Hyprland kurulumu yapar."
echo "Otomatik (a) veya manuel (m) kurulum seçebilirsiniz."

# Log dosyasını başlat
exec 1> >(tee -a install.log)
exec 2>&1

# Fonksiyonlar
check_requirements() {
  if ! command -v yay &>/dev/null; then
    echo "Hata: yay kurulu değil. Lütfen önce aur.sh scriptini çalıştırın."
    exit 1
  fi
}

validate_input() {
  local prompt="$1"
  local default="$2"
  local valid_options="$3"
  local choice
  if [ -n "$prompt" ]; then
    read -p "$prompt (varsayılan: $default): " choice
  else
    read -p "Seçiminiz (varsayılan: $default): " choice
  fi
  choice=${choice:-$default}
  if [[ ! " $valid_options " =~ " $choice " ]]; then
    echo "Geçersiz seçim: $choice. Lütfen [$valid_options] içinden seçin."
    exit 1
  fi
  echo "$choice"
}

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

# Bağımlılık kontrolü
check_requirements

# Kullanıcıdan seçim al
install_choice=$(validate_input "Otomatik (varsayılan) veya manuel kurulum mu? (a/m): " "a" "a m")
backup_choice=$(validate_input "Mevcut .config dizinini yedeklemek ister misiniz? (y/n, varsayılan: y): " "y" "y n")

# Yedekleme
if [[ "$backup_choice" == "y" ]]; then
  if [ -d "$HOME/.config_backup" ]; then
    echo "Uyarı: $HOME/.config_backup zaten var. Üzerine yazılsın mı? (y/n, varsayılan: n)"
    overwrite=$(validate_input "" "n" "y n")
    if [[ "$overwrite" != "y" ]]; then
      echo "Yedekleme iptal edildi."
      exit 1
    fi
  fi
  if [ -d "$HOME/.config" ]; then
    rsync -a --exclude='.config_backup' "$HOME/.config/" "$HOME/.config_backup/" || {
      echo "Yedekleme başarısız"
      exit 1
    }
    echo "Yedekleme oluşturuldu: $HOME/.config_backup"
  else
    echo "Hata: \$HOME/.config dizini bulunamadı"
    exit 1
  fi
fi

# Paket listesi
packages="
7zip
bash-completion
bat
blueman
bluez
bottom
brightnessctl
brave-bin
btop
cava
chafa
cliphist
clock-rs-git
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
materia-gtk-theme
meld
mpv
mpv-mpris
neovim
noto-fonts
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
reflector-simple
ripgrep
rsync
sddm
spotdl
spotify
spotify-adblock-git
starship
sublime-text-4
swaync
swayosd
swww
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

# Yüklü ve eksik paketleri kontrol et
installed_packages=()
missing_packages=()
for pkg in $packages; do
  if pacman -Q "$pkg" >/dev/null 2>&1; then
    installed_packages+=("$pkg")
  else
    missing_packages+=("$pkg")
  fi
done

# Özet bilgi
if [ ${#installed_packages[@]} -gt 0 ]; then
  echo "Zaten yüklü paketler (atlanacak): ${installed_packages[*]}"
fi
if [ ${#missing_packages[@]} -gt 0 ]; then
  echo "Kurulacak paketler: ${missing_packages[*]}"
else
  echo "Tüm paketler zaten yüklü, kurulum atlanıyor."
fi

# Otomatik kurulum
if [[ "$install_choice" == "a" ]]; then
  echo "Otomatik kurulum başlatılıyor..."
  if [ ${#missing_packages[@]} -gt 0 ]; then
    yay -S --needed --noconfirm --verbose "${missing_packages[@]}" || {
      echo "Hata: Şu paketlerin kurulumu başarısız oldu: ${missing_packages[*]}"
      exit 1
    }
  else
    echo "Paket kurulumu gerekmiyor."
  fi
  sudo systemctl enable --now sddm || {
    echo "SDDM servisi etkinleştirilemedi veya başlatılamadı"
    exit 1
  }
  sudo systemctl enable --now bluetooth || {
    echo "Bluetooth servisi etkinleştirilemedi veya başlatılamadı"
    exit 1
  }
  systemctl --user enable --now pipewire.service pipewire-pulse.service || {
    echo "Pipewire servisleri etkinleştirilemedi veya başlatılamadı"
    exit 1
  }
  sudo systemctl enable --now avahi-daemon || {
    echo "Avahi-daemon etkinleştirilemedi veya başlatılamadı"
    exit 1
  }
  if [ -f "$HOME/hypr/.config/sddm/sddm.conf" ]; then
    sudo cp -arf "$HOME/hypr/.config/sddm/sddm.conf" /etc/sddm.conf
  else
    echo "Hata: SDDM config dosyası bulunamadı"
    exit 1
  fi
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
  copy_config_files

  if [ -f "$HOME/wallpapers/walls/my_fav.jpg" ]; then
    wal -i "$HOME/wallpapers/walls/my_fav.jpg" -n || {
      echo "Duvar kağıdı ayarlanamadı"
      exit 1
    }
  else
    echo "Hata: Duvar kağıdı dosyası bulunamadı"
    exit 1
  fi
fi

# Manuel kurulum
if [[ "$install_choice" == "m" ]]; then
  echo "Manuel kurulum başlatılıyor..."
  mirror_choice=$(validate_input "Mirrorlist'i Türkiye için en iyisiyle değiştirmek ister misiniz? (y/n, varsayılan: y): " "y" "y n")
  if [[ "$mirror_choice" == "y" ]]; then
    yay -S --needed --noconfirm reflector rsync || {
      echo "Reflector veya rsync kurulumu başarısız"
      exit 1
    }
    sudo reflector --country 'TR' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist || {
      echo "Mirrorlist güncellenemedi"
      exit 1
    }
  fi

  for package in $packages; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      echo "$package zaten yüklü, atlanıyor."
      continue
    fi
    choice=$(validate_input "$package kurulmasını ister misiniz? (y/n, varsayılan: y): " "y" "y n")
    if [[ "$choice" == "y" ]]; then
      yay -S --needed --noconfirm --verbose "$package" || {
        echo "$package kurulumu başarısız"
        exit 1
      }
    fi
  done

  bluetooth_choice=$(validate_input "Bluetooth desteği kurulsun mu? (y/n, varsayılan: y): " "y" "y n")
  if [[ "$bluetooth_choice" == "y" ]]; then
    if ! pacman -Q blueman >/dev/null 2>&1 || ! pacman -Q bluez >/dev/null 2>&1; then
      yay -S --needed --noconfirm blueman bluez || {
        echo "Bluetooth paketleri kurulumu başarısız"
        exit 1
      }
    else
      echo "Bluetooth paketleri zaten yüklü."
    fi
    sudo systemctl enable --now bluetooth || {
      echo "Bluetooth servisi etkinleştirilemedi veya başlatılamadı"
      exit 1
    }
  fi

  pipewire_pkgs="pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber"
  pipewire_choice=$(validate_input "Pipewire ve ağ ekranları yapılandırılsın mı? (y/n, varsayılan: y): " "y" "y n")
  if [[ "$pipewire_choice" == "y" ]]; then
    for pkg in $pipewire_pkgs; do
      if pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "$pkg zaten yüklü, atlanıyor."
        continue
      fi
      yay -S --needed --noconfirm --verbose "$pkg" || {
        echo "$pkg kurulumu başarısız"
        exit 1
      }
    done
    systemctl --user enable --now pipewire.service pipewire-pulse.service || {
      echo "Pipewire servisleri etkinleştirilemedi veya başlatılamadı"
      exit 1
    }
  fi

  if [ -f "$HOME/wallpapers/walls/my_fav.jpg" ]; then
    wal -i "$HOME/wallpapers/walls/my_fav.jpg" -n || {
      echo "Duvar kağıdı ayarlanamadı"
      exit 1
    }
  else
    echo "Hata: Duvar kağıdı dosyası bulunamadı"
    exit 1
  fi
  if [ -f "$HOME/hypr/.config/sddm/sddm.conf" ]; then
    sudo cp -arf "$HOME/hypr/.config/sddm/sddm.conf" /etc/sddm.conf
  else
    echo "Hata: SDDM config dosyası bulunamadı"
    exit 1
  fi
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
  copy_config_files
fi

echo "Tam kurulum tamamlandı! Yeniden başlat ve duvar kağıdını değiştir."