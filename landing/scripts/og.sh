#!/bin/bash
# Gera landing/assets/og-image.png (pt-BR), og-image-en.png e og-image-es.png a partir de og.html.
set -e
cd "$(dirname "$0")"
for lang in pt en es; do
  out=../assets/og-image.png; [ $lang != pt ] && out=../assets/og-image-$lang.png
  google-chrome --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size=1200,630 --screenshot="$(realpath -m $out)" \
    "file://$PWD/og.html#$lang" 2>/dev/null
done
ls -la ../assets/og-image*.png
