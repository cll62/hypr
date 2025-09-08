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

