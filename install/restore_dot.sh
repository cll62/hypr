#!/bin/bash
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
copy_config_files
