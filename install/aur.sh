#!/bin/bash

# Hata işleme ve loglama
set -e
exec > >(tee -i aur_install.log) 2>&1
echo "AUR kurulumu başladı: $(date)"

# Fonksiyonlar
validate_input() {
  local prompt=$1
  local default=$2
  local valid_options=$3
  local choice
  read -p "$prompt" choice
  choice=${choice:-$default}
  if [[ ! $valid_options =~ $choice ]]; then
    echo "Geçersiz seçim: $choice. Lütfen tekrar deneyin."
    exit 1
  fi
  echo "$choice"
}

# Chaotic-AUR ve yay kurulumu
if [[ "$(uname -m)" == "x86_64" ]] && ! command -v yay &>/dev/null; then
  echo "Chaotic-AUR deposu ekleniyor..."
  if ! pacman-key --list-keys 3056513887B78AEB >/dev/null 2>&1; then
    echo "Chaotic-AUR anahtarı alınıyor..."
    sudo pacman-key --recv-key 3056513887B78AEB || sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keys.gnupg.net || { echo "Hata: Anahtar alınamadı"; exit 1; }
    sudo pacman-key --lsign-key 3056513887B78AEB || { echo "Hata: Anahtar imzalanamadı"; exit 1; }
  fi

  echo "Chaotic-AUR keyring ve mirrorlist yükleniyor..."
  sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || { echo "Hata: Chaotic-AUR keyring yüklenemedi"; exit 1; }
  sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || { echo "Hata: Chaotic-AUR mirrorlist yüklenemedi"; exit 1; }

  if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf >/dev/null || { echo "Hata: pacman.conf güncellenemedi"; exit 1; }
  fi

  echo "yay Chaotic-AUR'dan yükleniyor..."
  sudo pacman -Sy --needed --noconfirm yay || { echo "Hata: yay kurulumu başarısız"; exit 1; }
fi

# Eğer yay hâlâ kurulu değilse, AUR'den elle yükle
if ! command -v yay &>/dev/null; then
  echo "yay AUR'den elle yükleniyor..."
  sudo pacman -Sy --needed --noconfirm base-devel || { echo "Hata: base-devel kurulumu başarısız"; exit 1; }
  pushd /tmp || { echo "Hata: /tmp dizinine geçilemedi"; exit 1; }
  rm -rf yay-bin
  git clone https://aur.archlinux.org/yay-bin.git || { echo "Hata: yay-bin klonlanamadı"; exit 1; }
  cd yay-bin
  makepkg -si --noconfirm || { echo "Hata: yay-bin kurulumu başarısız"; exit 1; }
  popd
  rm -rf /tmp/yay-bin
fi

# Pacman'e renk ve eğlence ekle
if ! grep -q "ILoveCandy" /etc/pacman.conf; then
  echo "Pacman yapılandırmasına renk ekleniyor..."
sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf || { echo "Hata: pacman.conf güncellenemedi"; exit 1; }
fi

echo "AUR kurulumu tamamlandı!"