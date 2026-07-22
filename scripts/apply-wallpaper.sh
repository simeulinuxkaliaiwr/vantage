#!/usr/bin/env bash
set -Eeuo pipefail

# apply-wallpaper.sh <image-or-video> [transition-type] [transition-pos]
# Video: extracts a still frame so pywal always runs on a valid image.
# One path (apply-wallpaper-colors-only.sh) propagates the palette
# to foot, Hyprland, qutebrowser, and zsh either way.
#
# [transition-type]/[transition-pos] are optional and used by the
# BarMorph wallpaper picker to make the awww "grow" transition start
# from the same point on screen where the bar was, instead of the
# screen center. Omitting them keeps the default awww/swww transition.

input="${1:?Usage: apply-wallpaper.sh <image-or-video> [transition-type] [transition-pos]}"
transition_type="${2:-}"
transition_pos="${3:-}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cache_dir="$HOME/.cache/quickshell-rice"
mkdir -p "$cache_dir"

[[ -f "$input" ]] || { echo "File not found: $input" >&2; exit 1; }

mime="$(file --brief --mime-type -- "$input")"
palette_image="$input"

if [[ "$mime" == video/* ]]; then
  command -v ffmpeg >/dev/null || { echo "ffmpeg is required for video wallpapers" >&2; exit 1; }

  # unique filename per run (nanosecond timestamp), not a fixed one —
  # pywal seems to cache the color scheme by the INPUT PATH rather than
  # content, so reusing the same path for different videos would make
  # it reuse the old video's colors even with a new frame written there
  palette_image="$cache_dir/wallpaper-frame-$(date +%s%N).png"

  ffmpeg -hide_banner -loglevel error -y -ss 00:00:01 -i "$input" -frames:v 1 "$palette_image" \
    || ffmpeg -hide_banner -loglevel error -y -i "$input" -frames:v 1 "$palette_image"
  [[ -s "$palette_image" ]] || { echo "Failed to extract video frame" >&2; exit 1; }

  find "$cache_dir" -maxdepth 1 -name 'wallpaper-frame-*.png' ! -name "$(basename "$palette_image")" -delete 2>/dev/null || true

  pkill -x mpvpaper 2>/dev/null || true
  setsid mpvpaper -o "no-audio --loop-file=inf" '*' "$input" >/dev/null 2>&1 &
elif [[ "$mime" == image/* ]]; then
  pkill -x mpvpaper 2>/dev/null || true
  awww_extra_args=()
  if [[ -n "$transition_type" ]]; then
    awww_extra_args+=(--transition-type "$transition_type" --transition-duration 0.9)
    [[ -n "$transition_pos" ]] && awww_extra_args+=(--transition-pos "$transition_pos")
  fi
  if command -v awww >/dev/null; then
    awww img "${awww_extra_args[@]}" "$input"
  elif command -v swww >/dev/null; then
    swww img "${awww_extra_args[@]}" "$input"
  fi
else
  echo "Unsupported format: $mime" >&2; exit 1
fi

command -v wal >/dev/null || { echo "pywal (wal) not found" >&2; exit 1; }

if [[ -n "$palette_image" ]]; then
	safe_name="${palette_image//\//_}"
	rm -f "$HOME/.cache/wal/schemes/${safe_name}"* 2>/dev/null || true
fi
wal -n -q -i "$palette_image"

[[ -s "$HOME/.cache/wal/colors.json" ]] || { echo "pywal did not generate colors.json" >&2; exit 1; }

printf '%s\n' "$input"          > "$cache_dir/current-wallpaper"
printf '%s\n' "$palette_image"  > "$cache_dir/current-palette-image"

"$script_dir/apply-wallpaper-colors-only.sh" "$HOME/.cache/wal/colors.json" "$palette_image"
echo "OK: wallpaper applied, colors propagated (foot/Hyprland/qutebrowser/zsh)."
