# 🌟 Hypr – My Hyprland Dotfiles

**Hypr** 🖥️, Arch Linux için hazırlanmış, minimal kurulumdan sonra **Hyprland** ve gerekli paketleri otomatik olarak kuran bir full bootstrapperdır. Tek komutla masaüstünüz hazır hale gelir!  

---


## ⚡ Kurulum

1. Depoyu klonlayın:

```bash
git clone --depth 1 https://github.com/cll62/hypr
cd hypr/
```

2. Kurulum betiğini çalıştırın:

```bash
chmod +x install.sh
./install.sh
```

3. Kurulum tamamlandıktan sonra sistemi yeniden başlatın:

```bash
reboot
```

---

## 🛠️ Özelleştirme

- ➕ Yeni paket ekleme/çıkarma: `install_packages` fonksiyonundaki `pkgs=(...)` listesine ekleyin/çıkarın 
- 📦 Manuel paket ekleme: `source/` içine `.pkg.tar.zst` ekleyin  
- 🎨 Yeni icon/cursor teması ekleme: `source/` içine ekleyin ve `install_icons_and_cursors` fonksiyonuna ekleyin  
- ✍️ GTK font ve tema ayarlarını değiştirme: `set_default_themes` fonksiyonunu düzenleyin  

---

## ⌨️ Keybindings

### 🖥️ Uygulama Kısayolları
| Kısayol            | İşlev                          |
|-------------------|--------------------------------|
| Super + Return     | Terminal aç (`kitty`)           |
| Super + Space      | Floating terminal aç            |
| Super + T          | Sistem monitörü (`btop`)        |
| Super + E          | Dosya yöneticisi (`thunar`)     |
| Alt + E            | Terminal Dosya Yöneticisi (`yazi`) |
| Super + D          | Uygulama başlatıcı (`wofi`)     |
| Super + B          | Web tarayıcı (`brave`)          |
| Super + Alt + B    | Web tarayıcı (private)          |
| Super + C          | Sublime Text                    |
| Super + N          | Neovim (`kitty -e nvim`)        |
| Alt + S            | Swaync                          |
| Super + V          | Clipboard geçmişi (`cliphist`)  |

### 🌐 Web Uygulamaları
| Kısayol            | İşlev                          |
|-------------------|--------------------------------|
| Alt + C            | ChatGPT                         |
| Super + G          | Grok                            |
| Super + Y          | YouTube                         |
| Super + X          | X                               |
| Alt + W            | WhatsApp                        |
| Alt + Y            | YouTube Music                   |
| Alt + M            | Mebbis                          |
| Super + O          | Microsoft 365                   |
| Alt + G            | GitHub                          |
| Super + Z          | Math Editor                     |

### 🪟 Pencere Yönetimi
| Kısayol            | İşlev                          |
|-------------------|--------------------------------|
| Super + Q          | Pencereyi kapat                 |
| Super + H          | Floating toggle                 |
| Super + P          | Pseudo                          |
| Super + J          | Split toggle                    |
| Super + F          | Fullscreen toggle               |
| Super + ←/→/↑/↓    | Fokus değiştirme                |
| Super + Shift + ←/→/↑/↓ | Pencere boyutlandırma       |
| Super + Mouse 1    | Pencere taşı                     |
| Super + Mouse 2    | Pencere boyutlandır               |

### 🖼️ Çalışma Alanları
| Kısayol               | İşlev                         |
|----------------------|-------------------------------|
| Super + 1..0          | Workspace 1..10               |
| Super + Shift + 1..0  | Pencereyi workspace 1..10 taşır |

### 🔊 Ses ve Parlaklık
| Kısayol                  | İşlev                           |
|---------------------------|--------------------------------|
| XF86AudioRaiseVolume      | Ses yükselt                     |
| XF86AudioLowerVolume      | Ses azalt                        |
| XF86AudioMute             | Sessiz/aktif toggle             |
| XF86AudioMicMute          | Mikrofon sessiz/aktif toggle   |
| XF86MonBrightnessUp       | Parlaklık artır                  |
| XF86MonBrightnessDown     | Parlaklık azalt                  |

### 📸 Ekran Görüntüsü
| Kısayol            | İşlev                         |
|-------------------|-------------------------------|
| Print              | Pencere screenshot            |
| Ctrl + Print       | Bölge screenshot              |
| Alt + Print        | Aktif ekran screenshot        |

### 🛠️ Diğer
| Kısayol            | İşlev                         |
|-------------------|-------------------------------|
| Super + Tab        | Logout                         |
| Super + K          | Keybindings script             |
| Alt + N            | Night mode                     |
| Super + W          | Wallpaper değiştir             |
| Super + R          | Waybar refresh                 |
| Alt + R            | SwayNC refresh                 |
| Super + M          | Müzik aç/kapat (mpv)           |
| Super + L          | Ekranı kilitle                  |

### 🔍 Ekran Yakınlaştırma
| Kısayol                  | İşlev                           |
|---------------------------|--------------------------------|
| Super + Ctrl + Z          | Zoom in                         |
| Super + Ctrl + X          | Zoom out                        |
| Super + Ctrl + Q          | Zoom reset                      |
| Super + Ctrl + Mouse up   | Zoom in                         |
| Super + Ctrl + Mouse down | Zoom out                        |

### 🎶 OSD ve Multimedya
| Kısayol                  | İşlev                           |
|---------------------------|--------------------------------|
| XF86AudioRaiseVolume      | Ses yükselt (OSD)              |
| XF86AudioLowerVolume      | Ses azalt (OSD)                |
| XF86AudioMute             | Sessiz toggle (OSD)            |
| XF86AudioMicMute          | Mikrofon sessiz toggle (OSD)   |
| XF86MonBrightnessUp       | Parlaklık artır (OSD)           |
| XF86MonBrightnessDown     | Parlaklık azalt (OSD)           |
| XF86AudioNext             | Sonraki parça                   |
| XF86AudioPause            | Oynat/durdur                    |
| XF86AudioPrev             | Önceki parça                     |
