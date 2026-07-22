#!/usr/bin/env bash
set -Eeuo pipefail

# wallpaper-list-thumbnails.sh
#
# Lists wallpapers in ~/Pictures/Wallpapers, printing per line:
#   <original path>\t<cached thumbnail path>
#
# Images: resized copy via magick/convert.
# Videos: frame extracted with ffmpeg.
# Both cached in ~/.cache/quickshell-rice/wallpaper-thumbnails/,
# named by path hash — only regenerated if missing.

WALL_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/quickshell-rice/wallpaper-thumbnails"
mkdir -p "$THUMB_DIR"

if command -v magick >/dev/null 2>&1; then
  RESIZE_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  RESIZE_CMD="convert"
else
  RESIZE_CMD=""
fi

HAVE_FFMPEG=0
command -v ffmpeg >/dev/null 2>&1 && HAVE_FFMPEG=1

find "$WALL_DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
     -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' \) \
  | sort | while IFS= read -r f; do

    hash="$(printf '%s' "$f" | md5sum | cut -d' ' -f1)"
    thumb="$THUMB_DIR/$hash.png"

    if [[ ! -s "$thumb" ]]; then
      case "$f" in
        *.[mM][pP]4|*.[mM][kK][vV]|*.[wW][eE][bB][mM]|*.[mM][oO][vV])
          if [[ "$HAVE_FFMPEG" == "1" ]]; then
            ffmpeg -y -ss 1 -i "$f" -frames:v 1 -vf "scale=244:-1" \
              "$thumb" -loglevel error 2>/dev/null || true
          fi
          ;;
        *)
          if [[ -n "$RESIZE_CMD" ]]; then
            "$RESIZE_CMD" "$f" -resize "244x132>" "$thumb" 2>/dev/null || true
          fi
          ;;
      esac
    fi

    if [[ -s "$thumb" ]]; then
      printf '%s\t%s\n' "$f" "$thumb"
    else
      printf '%s\t%s\n' "$f" "$f"
    fi
  done
