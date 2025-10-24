#!/bin/bash

WALLPAPER_PATH="$HOME/.config/wallpapers/current_wallpaper.png"
CONFIG_FILE="$HOME/.config/gtk-3.0/settings.ini"
gnome_schema="org.gnome.desktop.interface"

swww img "$WALLPAPER_PATH" --transition-type outer --transition-duration 1.5
matugen image -c "$HOME/.config/matugen/config.toml" "$WALLPAPER_PATH"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Hata: GTK ayar dosyası bulunamadı: $CONFIG_FILE" >&2
    exit 1
fi

get_setting() {
    grep "$1" "$CONFIG_FILE" | sed 's/.*\s*=\s*//'
}

gtk_theme="$(get_setting 'gtk-theme-name')"
icon_theme="$(get_setting 'gtk-icon-theme-name')"
cursor_theme="$(get_setting 'gtk-cursor-theme-name')"
cursor_size="$(get_setting 'gtk-cursor-theme-size')"
font_name="$(get_setting 'gtk-font-name')"
prefer_dark_theme="$(get_setting 'gtk-application-prefer-dark-theme')"

if [ "$prefer_dark_theme" == "0" ]; then
    prefer_dark_theme_value="prefer-light"
else
    prefer_dark_theme_value="prefer-dark"
fi

echo "GTK-Theme: $gtk_theme"
echo "Icon Theme: $icon_theme"
echo "Cursor Theme: $cursor_theme"
echo "Cursor Size: $cursor_size"
echo "Color Theme: $prefer_dark_theme_value"
echo "Font Name: $font_name"

gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
gsettings set "$gnome_schema" icon-theme "$icon_theme"
gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
gsettings set "$gnome_schema" font-name "$font_name"
gsettings set "$gnome_schema" color-scheme "$prefer_dark_theme_value"