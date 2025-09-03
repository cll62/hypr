#!/bin/bash
set -e

install_all(){ 
  command -v yay &>/dev/null  || { sudo pacman -Sy --needed --noconfirm base-devel; pushd /tmp; git clone https://aur.archlinux.org/yay-bin.git; cd yay-bin; makepkg -si --noconfirm; popd; rm -rf /tmp/yay-bin; }; }

  pkgs="bash-completion  brightnessctl btop chafa  chromium cliphist cantarell-fonts eza expac fastfetch fd fzf  gst-plugin-pipewire gst-plugins-bad hypridle hyprland hyprlock hyprpicker hyprshot hyprsunset impala imv kitty libappindicator-gtk3  materia-gtk-theme mousepad mpv nano ncdu  nwg-displays nwg-look otf-codenewroman-nerd pacman-contrib pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-gnome pulsemixer python-pywal16  ripgrep rsync sddm starship swaync swayosd swww tealdeer thunar thunar-archive-plugin thunar-volman tumbler ttf-jetbrains-mono-nerd udiskie waybar wget wireplumber  wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs yazi zoxide"
  for pkg in $pkgs; do pacman -Q $pkg &>/dev/null || missing+=("$pkg"); done
  [ ${#missing[@]} -gt 0 ] && yay -S --needed --noconfirm "${missing[@]}"

  for svc in sddm avahi-daemon; do systemctl is-enabled $svc &>/dev/null || sudo systemctl enable $svc; done
  for usvc in pipewire.service pipewire-pulse.service; do systemctl --user is-enabled $usvc &>/dev/null || systemctl --user enable $usvc; done

  [ -d "$HOME/hypr" ] || { echo "Hata: \$HOME/hypr bulunamadı"; exit 1; }
  rsync -av --exclude='.git' --exclude='install' --exclude='README.md' "$HOME/hypr/" "$HOME/"
  [ -f "$HOME/hypr/install/sddm.conf" ] && sudo cp -arf "$HOME/hypr/install/sddm.conf" /etc/sddm.conf
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal

  [ -f "$HOME/wallpapers/pywallpaper.jpg" ] && wal -i "$HOME/wallpapers/pywallpaper.jpg" -n

  grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i '/^\[options\]/a Color\nILoveCandy\nVerbosePkgLists' /etc/pacman.conf
}

install_all
echo "Kurulum tamamlandı. Lütfen sistemi yeniden başlatın ve SUPER+W duvar kağıdını değiştirin. "
