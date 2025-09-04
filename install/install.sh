#!/bin/bash
set -euo pipefail

install_all(){ 
  command -v yay &>/dev/null || { sudo pacman-key --recv-key 3056513887B78AEB || sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keys.gnupg.net; sudo pacman-key --lsign-key 3056513887B78AEB; sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst; grep -q "chaotic-aur" /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf; sudo pacman -Sy --needed --noconfirm yay || { sudo pacman -Sy --needed --noconfirm base-devel; pushd /tmp; git clone https://aur.archlinux.org/yay-bin.git; cd yay-bin; makepkg -si --noconfirm; popd; rm -rf /tmp/yay-bin; }; }

  pkgs="7zip bash-completion bat brightnessctl brave-bin btop cava chafa cliphist cantarell-fonts eza expac fastfetch fd file-roller fzf gnome-disk-utility gst-plugin-pipewire gst-plugins-bad gvfs hypridle hyprland hyprlock hyprpicker hyprshot hyprsunset impala imv kitty libappindicator-gtk3 localsend materia-gtk-theme meld mpv mpv-mpris nano ncdu neovim noto-fonts nwg-displays nwg-look onlyoffice-bin otf-codenewroman-nerd pacman-contrib pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-gnome pulsemixer python-pywal16 qogir-icon-theme qt5ct qt6ct reflector-simple ripgrep rsync sddm spotify spotify-adblock-git starship sublime-text-4 swaync swayosd swww tealdeer thunar thunar-archive-plugin thunar-volman tumbler ttf-jetbrains-mono-nerd udiskie visual-studio-code-bin waybar wget wireplumber wlogout wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs yazi yt-dlp zathura zathura-pdf-poppler zathura-pywal-git zoxide"
  for pkg in $pkgs; do pacman -Q $pkg &>/dev/null || missing+=("$pkg"); done
  [ ${#missing[@]} -gt 0 ] && yay -S --needed --noconfirm "${missing[@]}"

  for svc in sddm avahi-daemon; do systemctl is-enabled $svc &>/dev/null || sudo systemctl enable $svc; done
  for usvc in pipewire.service pipewire-pulse.service; do systemctl --user is-enabled $usvc &>/dev/null || systemctl --user enable $usvc; done

  [ -d "$HOME/hypr" ] || { echo "Hata: \$HOME/hypr bulunamadı"; exit 1; }
  rsync -av --exclude='.git' --exclude='install' --exclude='README.md' "$HOME/hypr/" "$HOME/"
  
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
  echo -e "[Autologin]\nRelogin=false\nUser=$(whoami)\nSession=hyprland" | sudo tee /etc/sddm.conf >/dev/null
  [ -f "$HOME/wallpapers/pywallpaper.jpg" ] && wal -i "$HOME/wallpapers/pywallpaper.jpg" -n

  grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf
}

install_all
echo "Kurulum tamamlandı. Lütfen sistemi yeniden başlatın. "
