#!/usr/bin/env bash
# FFmpeg は必須。ImageMagick があればラベル付きPNG、無ければ単色PNGのみ生成。
# Git Bash / WSL / Linux / macOS: chmod +x generate_placeholders.sh && ./generate_placeholders.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/html/assets"

echo "[jp-slot] Output: $ASSETS"

mkdir -p "$ASSETS/symbols" "$ASSETS/characters/luna" "$ASSETS/frames" "$ASSETS/cutins"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg が見つかりません。"
  exit 1
fi

MAGICK=""
if command -v magick >/dev/null 2>&1; then
  MAGICK="magick"
elif command -v convert >/dev/null 2>&1 && convert -version 2>/dev/null | grep -qi ImageMagick; then
  MAGICK="convert"
fi

ff_png() {
  local out="$1" color="$2"
  ffmpeg -y -f lavfi -i "color=c=${color}:s=${3:-144}x${4:-144}:d=1" -frames:v 1 "$out" 2>/dev/null
}

mk_sym() {
  local name="$1" color="$2" label="$3"
  local out="$ASSETS/symbols/${name}.png"
  if [[ -n "$MAGICK" ]]; then
    "$MAGICK" -size 144x144 "xc:${color}" -fill white -gravity center \
      -pointsize 16 -annotate 0 "${label}" "$out"
  else
    ff_png "$out" "${color}"
  fi
}

mk_sym cherry "#6b1414" "CHERRY"
mk_sym bell "#c9a227" "BELL"
mk_sym watermelon "#1e6b3a" "MELON"
mk_sym bar "#444444" "BAR"
mk_sym seven "#223388" "7"
mk_sym wild "#8844aa" "WILD"
mk_sym character "#aa4488" "CHAR"

IDLE="$ASSETS/characters/luna/idle.png"
if [[ -n "$MAGICK" ]]; then
  "$MAGICK" -size 512x1024 xc:'#1a1520' -fill '#8899aa' -gravity center \
    -pointsize 28 -annotate 0 'LUNA (placeholder)' "$IDLE"
else
  ffmpeg -y -f lavfi -i "color=c=#1a1520:s=512x1024:d=1" -frames:v 1 "$IDLE" 2>/dev/null
fi

FRAME="$ASSETS/frames/luxury_frame.png"
if [[ -n "$MAGICK" ]]; then
  "$MAGICK" -size 1024x720 xc:'#0a0608' -strokewidth 6 -fill none \
    -stroke '#d4af37' -draw "rectangle 80,120 944,600" \
    -stroke '#8b1538' -draw "rectangle 300,200 724,520" \
    -fill '#f5e6c8' -gravity north -pointsize 22 -annotate 0 'luxury_frame (reel area guide)' \
    "$FRAME"
else
  ffmpeg -y -f lavfi -i "color=c=#0a0608:s=1024x720:d=1" -frames:v 1 "$FRAME" 2>/dev/null
fi

mk_cutin_img() {
  local n="$1" num="$2"
  local out="$ASSETS/cutins/img_${n}.png"
  if [[ -n "$MAGICK" ]]; then
    "$MAGICK" -size 1280x720 xc:'#101010cc' -fill '#eeeeee' -gravity center \
      -pointsize 56 -annotate 0 "CUTIN IMAGE ${num}" "$out"
  else
    ffmpeg -y -f lavfi -i "color=c=#202020:s=1280x720:d=1" -frames:v 1 "$out" 2>/dev/null
  fi
}

mk_cutin_img "01" "01"
mk_cutin_img "02" "02"
mk_cutin_img "03" "03"

mk_webm() {
  local out="$1" dur="$2" color="$3"
  local fst=$(awk -v d="$dur" 'BEGIN{printf "%.2f", d-0.35}')
  ffmpeg -y -f lavfi -i "color=c=${color}:s=1280x720:d=${dur}" \
    -vf "format=yuv420p,fade=t=in:st=0:d=0.35,fade=t=out:st=${fst}:d=0.35" \
    -c:v libvpx-vp9 -b:v 1M -pix_fmt yuv420p -an "$out"
}

mk_webm "$ASSETS/cutins/vid_01.webm" 2 "yellow"
mk_webm "$ASSETS/cutins/vid_02.webm" 2.5 "orange"
mk_webm "$ASSETS/cutins/vid_03.webm" 4 "gold"
mk_webm "$ASSETS/cutins/vid_04.webm" 3 "purple"
mk_webm "$ASSETS/cutins/vid_05.webm" 3.5 "red"

mk_char_webm() {
  local out="$1" dur="$2" color="$3"
  local fst=$(awk -v d="$dur" 'BEGIN{printf "%.2f", d-0.4}')
  ffmpeg -y -f lavfi -i "color=c=${color}:s=720x1280:d=${dur}" \
    -vf "format=yuv420p,fade=t=in:st=0:d=0.4,fade=t=out:st=${fst}:d=0.4" \
    -c:v libvpx-vp9 -b:v 1M -pix_fmt yuv420p -an "$out"
}

mk_char_webm "$ASSETS/characters/luna/win.webm" 2 "#334466"
mk_char_webm "$ASSETS/characters/luna/bigwin.webm" 2 "#662233"

echo "[jp-slot] 完了（ImageMagick 無しの場合は単色PNGのみ）。"
