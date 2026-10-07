#!/bin/bash
# Gera as versões da web das capturas cruas de tools/capture/scenes.py.
#
#   tools/capture/encode.sh [pasta crua] [destino]
#
# Padrão: build/capture/<idioma>/ -> landing/assets/media/<idioma>/. Para cada
# vídeo: WebM (VP9) e MP4 (H.264) em 720x1604 a 30 fps, e o poster (WebP) do
# primeiro quadro. Para cada print: o PNG original e um WebP de 720 de largura.
set -euo pipefail
cd "$(dirname "$0")/../.."
SRC=${1:-build/capture}
DST=${2:-landing/assets/media}
F=(ffmpeg -nostdin -v error -y)
SIZE="scale=720:1604:flags=lanczos"

for dir in "$SRC"/*/; do
  lang=$(basename "$dir")
  out="$DST/$lang"
  mkdir -p "$out"
  for video in "$dir"*.mp4; do
    [ -e "$video" ] || continue
    name=$(basename "$video" .mp4)
    # O começo da gravação é o gravador ligando: fica de fora.
    "${F[@]}" -ss 0.6 -i "$video" -vf "$SIZE,fps=30,format=yuv420p" -an \
      -c:v libx264 -preset slow -crf 22 -profile:v high -movflags +faststart "$out/$name.mp4"
    "${F[@]}" -ss 0.6 -i "$video" -vf "$SIZE,fps=30" -an \
      -c:v libvpx-vp9 -b:v 0 -crf 34 -row-mt 1 -deadline good -cpu-used 2 "$out/$name.webm"
    "${F[@]}" -ss 0.7 -i "$video" -frames:v 1 -vf "$SIZE" -c:v libwebp -quality 86 "$out/$name-poster.webp"
    echo "$out/$name.{mp4,webm} + poster"
  done
  for shot in "$dir"*.png; do
    [ -e "$shot" ] || continue
    name=$(basename "$shot" .png)
    cp "$shot" "$out/$name.png"
    "${F[@]}" -i "$shot" -vf "scale=720:-2:flags=lanczos" -c:v libwebp -quality 86 "$out/$name.webp"
    echo "$out/$name.{png,webp}"
  done
done
