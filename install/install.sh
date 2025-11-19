#!/bin/bash

set -eE -o pipefail

export HYPR_INSTALL="$HOME/hypr/install"
USER_NAME=${1:-$USER}
TTY_TARGET="tty1"

sudo cp -f "$HOME/hypr/.config/pacman/pacman.conf" /etc/pacman.conf
sudo cp -f "$HOME/hypr/.config/pacman/chaotic-mirrorlist" /etc/pacman.d/chaotic-mirrorlist

sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -Sy --noconfirm
if ! pacman -Qq chaotic-keyring chaotic-mirrorlist &>/dev/null; then
    sudo pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
    sudo pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
fi
sudo pacman -S --noconfirm --needed chaotic-keyring chaotic-mirrorlist
sudo pacman -S --noconfirm --needed yay

mapfile -t packages < <(grep -v '^#' "$HYPR_INSTALL/pkglist.txt" | grep -v '^$')
if [ ${#packages[@]} -gt 0 ]; then
    sudo pacman -S --noconfirm --needed "${packages[@]}"
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 53317/udp
sudo ufw allow 53317/tcp
sudo ufw --force enable
sudo systemctl enable ufw
sudo systemctl enable power-profiles-daemon
sudo systemctl enable avahi-daemon
sudo systemctl enable swayosd-libinput-backend.service
xdg-user-dirs-update
mkdir -p "$HOME/.config"
cp -R "$HOME/hypr/.config/." "$HOME/.config/"
rm -rf "$HOME/.config/pacman/"
chmod -R +x "$HOME/.config/hypr/scripts"
cp -f "$HOME/hypr/.bashrc" "$HOME/.bashrc"
cp -f "$HOME/hypr/.bash_profile" "$HOME/.bash_profile" 
mkdir -p "$HOME/.local/share/applications"
cp -r "$HOME/hypr/.local/share/applications/." "$HOME/.local/share/applications/"
sudo ln -sf /usr/bin/kitty /usr/local/bin/gnome-terminal
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    gsettings set org.gnome.desktop.wm.preferences theme "adw-gtk3-dark"
    gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
    gsettings set org.gnome.desktop.interface icon-theme "McMojave-circle-black-dark"
fi
sudo mkdir -p /etc/systemd/system/getty@${TTY_TARGET}.service.d
cat <<EOF | sudo tee /etc/systemd/system/getty@${TTY_TARGET}.service.d/override.conf >/dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${USER_NAME} --noclear %I \$TERM
EOF
sudo systemctl daemon-reload
systemctl --user daemon-reload
sudo systemctl enable getty@${TTY_TARGET}.service
echo "Hyprland autologin kurulumu tamamlandı!"
echo "Şimdi sistemi yeniden başlatabilirsin:"
